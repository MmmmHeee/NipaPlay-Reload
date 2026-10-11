import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nipaplay/services/large_screen_ui_sfx_service.dart';
import 'package:nipaplay/themes/nipaplay/widgets/large_screen_view_container.dart';
import 'package:nipaplay/themes/nipaplay/widgets/remote_text_input_qr_view.dart';
import 'package:nipaplay/utils/remote_access_address_options.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  for (final size in [
    const Size(640, 360),
    const Size(960, 540),
    const Size(1280, 720),
    const Size(1920, 1080),
    const Size(360, 640),
  ]) {
    for (final textScale in [1.0, 1.5]) {
      testWidgets('QR fits $size with text scale $textScale and safe insets',
          (tester) async {
        SharedPreferences.setMockInitialValues({});
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(ChangeNotifierProvider(
          create: (_) => LargeScreenUiSfxService(),
          child: MaterialApp(
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                padding: const EdgeInsets.all(16),
                textScaler: TextScaler.linear(textScale),
              ),
              child: child!,
            ),
            home: NipaplayLargeScreenViewContainer(
              title: '连接 WebDAV 媒体库',
              subtitle: 'KEY ABC123 · 4 项 · 10 分钟内有效',
              maxWidth: 960,
              maxHeightFactor: 0.92,
              compact: true,
              child: RemoteTextInputQrView(
                inputUri: Uri.parse(
                  'http://192.168.100.100:1180/remote-input?token=0123456789abcdef0123456789abcdef',
                ),
                displayKey: 'ABC123',
                fieldCount: 4,
              ),
            ),
          ),
        ));
        await tester.pumpAndSettle();

        final qr = find.byType(QrImageView);
        final qrRect = tester.getRect(qr);
        final bodyRect = tester.getRect(find.byType(RemoteTextInputQrView));
        expect(qrRect.width, greaterThan(140));
        expect(qrRect.width, closeTo(qrRect.height, 0.01));
        expect(bodyRect.contains(qrRect.topLeft), isTrue);
        expect(bodyRect.contains(qrRect.bottomRight), isTrue);
        expect((Offset.zero & size).contains(qrRect.bottomRight), isTrue);
        expect(find.ancestor(of: qr, matching: find.byType(Scrollable)),
            findsNothing);
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('selecting another TV address updates the QR payload',
      (tester) async {
    final options = <RemoteInputAddressOption>[
      const RemoteInputAddressOption(
        baseUrl: 'http://192.168.49.1:1180',
        label: '192.168.49.1 · 内网',
      ),
      const RemoteInputAddressOption(
        baseUrl: 'http://192.168.8.9:1180',
        label: '192.168.8.9 · 内网',
      ),
    ];
    String? selected;

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: RemoteTextInputQrView(
          inputUri: Uri.parse('http://192.168.49.1:1180/api/remote/input/KEY'),
          displayKey: 'KEY',
          fieldCount: 1,
          addressOptions: options,
          initialBaseUrl: 'http://192.168.49.1:1180',
          uriBuilder: (baseUrl) => Uri.parse('$baseUrl/api/remote/input/KEY'),
          onAddressSelected: (baseUrl) => selected = baseUrl,
        ),
      ),
    ));
    await tester.pumpAndSettle();

    expect(
      find.text('http://192.168.49.1:1180/api/remote/input/KEY'),
      findsOneWidget,
    );

    await tester.tap(find.text('192.168.8.9 · 内网'));
    await tester.pumpAndSettle();

    expect(
      find.text('http://192.168.8.9:1180/api/remote/input/KEY'),
      findsOneWidget,
    );
    expect(selected, 'http://192.168.8.9:1180');
  });

  testWidgets('hides the picker when there is nothing to choose',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: RemoteTextInputQrView(
          inputUri: Uri.parse('http://192.168.8.9:1180/api/remote/input/KEY'),
          displayKey: 'KEY',
          fieldCount: 1,
          addressOptions: const <RemoteInputAddressOption>[
            RemoteInputAddressOption(
              baseUrl: 'http://192.168.8.9:1180',
              label: '192.168.8.9 · 内网',
            ),
          ],
          initialBaseUrl: 'http://192.168.8.9:1180',
          uriBuilder: (baseUrl) => Uri.parse('$baseUrl/api/remote/input/KEY'),
        ),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('选择电视地址（扫码连不上时换一个）'), findsNothing);
    expect(find.text('192.168.8.9 · 内网'), findsNothing);
    expect(
      find.text('http://192.168.8.9:1180/api/remote/input/KEY'),
      findsOneWidget,
    );
  });

  testWidgets('focus ring does not shift the picker layout', (tester) async {
    FocusManager.instance.highlightStrategy =
        FocusHighlightStrategy.alwaysTraditional;
    addTearDown(
      () => FocusManager.instance.highlightStrategy =
          FocusHighlightStrategy.automatic,
    );

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: RemoteTextInputQrView(
          inputUri: Uri.parse('http://192.168.49.1:1180/api/remote/input/KEY'),
          displayKey: 'KEY',
          fieldCount: 1,
          addressOptions: const <RemoteInputAddressOption>[
            RemoteInputAddressOption(
              baseUrl: 'http://192.168.49.1:1180',
              label: '192.168.49.1 · 内网',
            ),
            RemoteInputAddressOption(
              baseUrl: 'http://192.168.8.9:1180',
              label: '192.168.8.9 · 内网',
            ),
          ],
          initialBaseUrl: 'http://192.168.49.1:1180',
          uriBuilder: (baseUrl) => Uri.parse('$baseUrl/api/remote/input/KEY'),
        ),
      ),
    ));
    await tester.pumpAndSettle();

    final heading = find.text('选择电视地址（扫码连不上时换一个）');
    final before = tester.getTopLeft(heading);

    final tileFocusNode = Focus.of(
      tester.element(find.text('192.168.49.1 · 内网')),
    );
    tileFocusNode.requestFocus();
    await tester.pumpAndSettle();

    expect(tester.getTopLeft(heading), before);
  });
}
