import 'package:nipaplay/utils/remote_access_address_utils.dart';

class RemoteInputAddressOption {
  const RemoteInputAddressOption({
    required this.baseUrl,
    required this.label,
  });

  final String baseUrl;
  final String label;
}

/// Builds picker options in input order, dropping loopback and duplicate URLs.
List<RemoteInputAddressOption> buildRemoteInputAddressOptions(
  Iterable<String> urls,
) {
  final options = <RemoteInputAddressOption>[];
  final seen = <String>{};

  for (final url in urls) {
    final trimmed = url.trim();
    if (trimmed.isEmpty || !seen.add(trimmed)) continue;

    final host = Uri.tryParse(trimmed)?.host ?? '';
    if (host.isEmpty) continue;

    final type = RemoteAccessAddressUtils.classifyUrl(trimmed);
    if (type == RemoteAccessAddressType.local) continue;

    options.add(
      RemoteInputAddressOption(
        baseUrl: trimmed,
        label: '$host · ${RemoteAccessAddressUtils.labelZh(type)}',
      ),
    );
  }

  return options;
}

/// Returns the remembered address if it is still available, otherwise the first.
String? resolveInitialRemoteInputAddress({
  required List<RemoteInputAddressOption> options,
  String? preferred,
}) {
  if (options.isEmpty) return null;

  final normalized = preferred?.trim();
  if (normalized != null && normalized.isNotEmpty) {
    for (final option in options) {
      if (option.baseUrl == normalized) return option.baseUrl;
    }
  }
  return options.first.baseUrl;
}
