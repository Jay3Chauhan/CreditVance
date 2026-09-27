import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/utils/app_toast.dart';

const _allowedSchemes = {'https', 'http', 'mailto', 'itms-apps', 'market'};

Future<bool> openRemoteLink(BuildContext context, String url) async {
  final uri = Uri.tryParse(url.trim());
  if (uri == null || !_allowedSchemes.contains(uri.scheme)) {
    if (context.mounted) AppToast.error(context, message: 'That link is not available');
    return false;
  }
  final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
  if (!opened && context.mounted) AppToast.error(context, message: 'Could not open the link');
  return opened;
}
