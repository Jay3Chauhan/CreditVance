package com.example.cardsage

import android.content.ClipData
import android.content.ClipDescription
import android.content.ClipboardManager
import android.content.Context
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.os.PersistableBundle
import android.view.WindowManager
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

// local_auth's BiometricPrompt requires a FragmentActivity host.
class MainActivity : FlutterFragmentActivity() {
    private val channelName = "creditvance/secure"
    private val clipLabel = "creditvance-secure"
    private val handler = Handler(Looper.getMainLooper())
    private var pendingClear: Runnable? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName).setMethodCallHandler { call, result ->
            when (call.method) {
                "copySensitive" -> {
                    val text = call.argument<String>("text") ?: ""
                    val clearAfterMs = (call.argument<Number>("clearAfterMs") ?: 30000).toLong()
                    copySensitive(text, clearAfterMs)
                    result.success(null)
                }
                "clearClipboard" -> {
                    clearClipboard(force = true)
                    result.success(null)
                }
                "setSecureScreen" -> {
                    val enabled = call.argument<Boolean>("enabled") ?: true
                    if (enabled) {
                        window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
                    } else {
                        window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
                    }
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun clipboard(): ClipboardManager =
        applicationContext.getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager

    private fun copySensitive(text: String, clearAfterMs: Long) {
        val clip = ClipData.newPlainText(clipLabel, text)
        // Hides the value from the Android 13+ clipboard preview overlay and keyboard suggestions.
        val extras = PersistableBundle()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            extras.putBoolean(ClipDescription.EXTRA_IS_SENSITIVE, true)
        } else {
            extras.putBoolean("android.content.extra.IS_SENSITIVE", true)
        }
        clip.description.extras = extras
        clipboard().setPrimaryClip(clip)

        pendingClear?.let { handler.removeCallbacks(it) }
        val task = Runnable { clearClipboard(force = false) }
        pendingClear = task
        handler.postDelayed(task, clearAfterMs)
    }

    private fun clearClipboard(force: Boolean) {
        val cm = clipboard()
        if (!force) {
            // Only skip when we can positively see the user copied something else since.
            // Android 10+ hides clip descriptions from background apps; in that case clear anyway.
            val label = try { cm.primaryClipDescription?.label?.toString() } catch (_: Exception) { null }
            if (label != null && label != clipLabel) return
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            try {
                cm.clearPrimaryClip()
                return
            } catch (_: Exception) {
                // Fall back to overwriting.
            }
        }
        cm.setPrimaryClip(ClipData.newPlainText("", ""))
    }
}
