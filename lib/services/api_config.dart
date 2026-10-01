import 'package:flutter/foundation.dart';

const _configuredApiBaseUrl = String.fromEnvironment('ROADWISE_API_URL');

String get roadwiseApiBaseUrl {
  final configuredUrl = _configuredApiBaseUrl.trim();
  if (configuredUrl.isNotEmpty) {
    return configuredUrl.replaceFirst(RegExp(r'/+$'), '');
  }

  if (defaultTargetPlatform == TargetPlatform.android) {
    return 'http://10.0.2.2:3000/api';
  }
  return 'http://127.0.0.1:3000/api';
}
