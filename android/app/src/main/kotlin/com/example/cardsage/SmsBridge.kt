package com.example.cardsage

import android.Manifest
import android.app.Activity
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.provider.Settings
import android.provider.Telephony
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors

/**
 * Minimal, read-only SMS bridge for on-device credit card expense tracking.
 *
 * - `com.cardsage/sms` (MethodChannel): permission check/request, settings
 *   deep link, and an inbox query that only returns messages from known bank
 *   sender headers, so unrelated SMS bodies never reach Dart.
 * - `com.cardsage/sms_incoming` (EventChannel): content-free "new bank SMS"
 *   pings while the app is running; Dart follows up with an incremental
 *   inbox query so the SMS provider stays the single source of truth.
 *
 * Deliberately has no SEND_SMS / phone capabilities (Play policy minimisation).
 */
class SmsBridge(
    private val activity: Activity,
    messenger: BinaryMessenger,
) : MethodChannel.MethodCallHandler, EventChannel.StreamHandler {

    companion object {
        private const val METHOD_CHANNEL = "com.cardsage/sms"
        private const val EVENT_CHANNEL = "com.cardsage/sms_incoming"
        const val PERMISSION_REQUEST_CODE = 0x5A5
        private const val DEFAULT_LIMIT = 1500
        private const val MAX_LIMIT = 5000
        private val PERMISSIONS = arrayOf(Manifest.permission.READ_SMS, Manifest.permission.RECEIVE_SMS)
    }

    private val methodChannel = MethodChannel(messenger, METHOD_CHANNEL)
    private val eventChannel = EventChannel(messenger, EVENT_CHANNEL)
    private val executor: ExecutorService = Executors.newSingleThreadExecutor()
    private val mainHandler = Handler(Looper.getMainLooper())

    private var pendingPermissionResult: MethodChannel.Result? = null
    private var eventSink: EventChannel.EventSink? = null
    private var streamSenderKeys: List<String> = emptyList()
    private var receiver: BroadcastReceiver? = null

    init {
        methodChannel.setMethodCallHandler(this)
        eventChannel.setStreamHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "checkPermission" -> result.success(permissionState())
            "requestPermission" -> requestPermission(result)
            "openAppSettings" -> {
                openAppSettings()
                result.success(null)
            }
            "queryInbox" -> queryInbox(call, result)
            else -> result.notImplemented()
        }
    }

    private fun hasPermissions(): Boolean =
        PERMISSIONS.all { activity.checkSelfPermission(it) == PackageManager.PERMISSION_GRANTED }

    private fun permissionState(): Map<String, Any> = mapOf(
        "granted" to hasPermissions(),
        "shouldShowRationale" to PERMISSIONS.any { activity.shouldShowRequestPermissionRationale(it) },
    )

    private fun requestPermission(result: MethodChannel.Result) {
        if (hasPermissions()) {
            result.success(permissionState())
            return
        }
        if (pendingPermissionResult != null) {
            result.error("in_progress", "A permission request is already in progress", null)
            return
        }
        pendingPermissionResult = result
        activity.requestPermissions(PERMISSIONS, PERMISSION_REQUEST_CODE)
    }

    /** Forwarded from [MainActivity.onRequestPermissionsResult]. */
    fun onRequestPermissionsResult(requestCode: Int) {
        if (requestCode != PERMISSION_REQUEST_CODE) return
        pendingPermissionResult?.success(permissionState())
        pendingPermissionResult = null
        if (hasPermissions() && eventSink != null) registerReceiver()
    }

    private fun openAppSettings() {
        val intent = Intent(
            Settings.ACTION_APPLICATION_DETAILS_SETTINGS,
            Uri.fromParts("package", activity.packageName, null),
        ).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        activity.startActivity(intent)
    }

    private fun queryInbox(call: MethodCall, result: MethodChannel.Result) {
        if (!hasPermissions()) {
            result.error("permission_denied", "READ_SMS permission not granted", null)
            return
        }
        val since = call.argument<Number>("sinceMillis")?.toLong() ?: 0L
        val limit = (call.argument<Number>("limit")?.toInt() ?: DEFAULT_LIMIT).coerceIn(1, MAX_LIMIT)
        val senderKeys = (call.argument<List<String>>("senderKeys") ?: emptyList()).map { it.uppercase() }

        executor.execute {
            try {
                val rows = readInbox(since, limit, senderKeys)
                mainHandler.post { result.success(rows) }
            } catch (e: Exception) {
                mainHandler.post { result.error("query_failed", e.message, null) }
            }
        }
    }

    private fun readInbox(since: Long, limit: Int, senderKeys: List<String>): List<Map<String, Any>> {
        val rows = ArrayList<Map<String, Any>>()
        val projection = arrayOf(Telephony.Sms.ADDRESS, Telephony.Sms.BODY, Telephony.Sms.DATE)
        activity.contentResolver.query(
            Telephony.Sms.Inbox.CONTENT_URI,
            projection,
            "${Telephony.Sms.DATE} > ?",
            arrayOf(since.toString()),
            "${Telephony.Sms.DATE} ASC",
        )?.use { cursor ->
            val addressIdx = cursor.getColumnIndexOrThrow(Telephony.Sms.ADDRESS)
            val bodyIdx = cursor.getColumnIndexOrThrow(Telephony.Sms.BODY)
            val dateIdx = cursor.getColumnIndexOrThrow(Telephony.Sms.DATE)
            while (cursor.moveToNext() && rows.size < limit) {
                val address = cursor.getString(addressIdx) ?: continue
                if (!isBankSender(address, senderKeys)) continue
                val body = cursor.getString(bodyIdx) ?: continue
                rows.add(mapOf("address" to address, "body" to body, "date" to cursor.getLong(dateIdx)))
            }
        }
        return rows
    }

    /** Alphanumeric DLT headers only (never phone numbers), matching a known bank key. */
    private fun isBankSender(address: String, senderKeys: List<String>): Boolean {
        val upper = address.uppercase()
        if (upper.none { it.isLetter() }) return false
        return senderKeys.isEmpty() || senderKeys.any { upper.contains(it) }
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
        val keys = (arguments as? Map<*, *>)?.get("senderKeys") as? List<*>
        streamSenderKeys = keys?.mapNotNull { (it as? String)?.uppercase() } ?: emptyList()
        eventSink = events
        registerReceiver()
    }

    override fun onCancel(arguments: Any?) {
        unregisterReceiver()
        eventSink = null
    }

    private fun registerReceiver() {
        if (receiver != null || !hasPermissions()) return
        val smsReceiver = object : BroadcastReceiver() {
            override fun onReceive(context: Context, intent: Intent) {
                if (intent.action != Telephony.Sms.Intents.SMS_RECEIVED_ACTION) return
                val parts = Telephony.Sms.Intents.getMessagesFromIntent(intent) ?: return
                val fromBank = parts.any { part ->
                    val address = part?.originatingAddress
                    address != null && isBankSender(address, streamSenderKeys)
                }
                if (fromBank) {
                    eventSink?.success(mapOf("date" to System.currentTimeMillis()))
                }
            }
        }
        val filter = IntentFilter(Telephony.Sms.Intents.SMS_RECEIVED_ACTION)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            activity.registerReceiver(
                smsReceiver,
                filter,
                Manifest.permission.BROADCAST_SMS,
                null,
                Context.RECEIVER_EXPORTED,
            )
        } else {
            activity.registerReceiver(smsReceiver, filter, Manifest.permission.BROADCAST_SMS, null)
        }
        receiver = smsReceiver
    }

    private fun unregisterReceiver() {
        val current = receiver ?: return
        try {
            activity.unregisterReceiver(current)
        } catch (ignored: IllegalArgumentException) {
            // Receiver was already unregistered by the system.
        }
        receiver = null
    }

    fun dispose() {
        unregisterReceiver()
        eventSink = null
        pendingPermissionResult = null
        methodChannel.setMethodCallHandler(null)
        eventChannel.setStreamHandler(null)
        executor.shutdown()
    }
}
