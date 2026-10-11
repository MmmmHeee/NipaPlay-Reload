import 'package:flutter_test/flutter_test.dart';
import 'package:nipaplay/utils/remote_access_address_options.dart';

void main() {
  group('buildRemoteInputAddressOptions', () {
    test('keeps non-loopback addresses in order with labels', () {
      final options = buildRemoteInputAddressOptions(<String>[
        'http://192.168.49.1:1180',
        'http://192.168.8.9:1180',
        'http://127.0.0.1:1180',
        'http://localhost:1180',
      ]);

      expect(options.map((option) => option.baseUrl), <String>[
        'http://192.168.49.1:1180',
        'http://192.168.8.9:1180',
      ]);
      expect(options.first.label, '192.168.49.1 · 内网');
    });

    test('deduplicates and labels WAN addresses', () {
      final options = buildRemoteInputAddressOptions(<String>[
        'http://203.0.113.7:1180',
        'http://203.0.113.7:1180',
      ]);

      expect(options, hasLength(1));
      expect(options.single.label, '203.0.113.7 · 外网');
    });

    test('returns empty when only loopback addresses exist', () {
      final options = buildRemoteInputAddressOptions(<String>[
        'http://127.0.0.1:1180',
        'http://localhost:1180',
      ]);

      expect(options, isEmpty);
    });
  });

  group('resolveInitialRemoteInputAddress', () {
    List<RemoteInputAddressOption> options() => buildRemoteInputAddressOptions(
          <String>['http://192.168.49.1:1180', 'http://192.168.8.9:1180'],
        );

    test('returns the first option when nothing is preferred', () {
      expect(
        resolveInitialRemoteInputAddress(options: options()),
        'http://192.168.49.1:1180',
      );
    });

    test('honours a remembered preference that is still available', () {
      expect(
        resolveInitialRemoteInputAddress(
          options: options(),
          preferred: 'http://192.168.8.9:1180',
        ),
        'http://192.168.8.9:1180',
      );
    });

    test('ignores a stale preference', () {
      expect(
        resolveInitialRemoteInputAddress(
          options: options(),
          preferred: 'http://10.0.0.5:1180',
        ),
        'http://192.168.49.1:1180',
      );
    });

    test('returns null for an empty list', () {
      expect(resolveInitialRemoteInputAddress(options: const []), isNull);
    });
  });
}
