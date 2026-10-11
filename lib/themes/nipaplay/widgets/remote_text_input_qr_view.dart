import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nipaplay/utils/remote_access_address_options.dart';
import 'package:qr_flutter/qr_flutter.dart';

class RemoteTextInputQrView extends StatefulWidget {
  const RemoteTextInputQrView({
    super.key,
    required this.inputUri,
    required this.displayKey,
    required this.fieldCount,
    this.addressOptions = const <RemoteInputAddressOption>[],
    this.initialBaseUrl,
    this.uriBuilder,
    this.onAddressSelected,
  });

  final Uri inputUri;
  final String displayKey;
  final int fieldCount;

  /// Candidate addresses; the picker is hidden when there are fewer than two.
  final List<RemoteInputAddressOption> addressOptions;
  final String? initialBaseUrl;

  /// Rebuilds the QR target for the selected base URL.
  final Uri Function(String baseUrl)? uriBuilder;

  /// Reports a newly selected address.
  final ValueChanged<String>? onAddressSelected;

  @override
  State<RemoteTextInputQrView> createState() => _RemoteTextInputQrViewState();
}

class _RemoteTextInputQrViewState extends State<RemoteTextInputQrView> {
  String? _selectedBaseUrl;
  final ScrollController _addressScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _selectedBaseUrl = _resolveSelection();
  }

  @override
  void dispose() {
    _addressScrollController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant RemoteTextInputQrView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialBaseUrl != widget.initialBaseUrl ||
        oldWidget.addressOptions != widget.addressOptions) {
      _selectedBaseUrl = _resolveSelection();
    }
  }

  String? _resolveSelection() {
    if (widget.addressOptions.isEmpty) return widget.initialBaseUrl;
    return resolveInitialRemoteInputAddress(
      options: widget.addressOptions,
      preferred: widget.initialBaseUrl,
    );
  }

  String get _qrData {
    final builder = widget.uriBuilder;
    final baseUrl = _selectedBaseUrl;
    if (builder != null && baseUrl != null && baseUrl.isNotEmpty) {
      return builder(baseUrl).toString();
    }
    return widget.inputUri.toString();
  }

  void _selectAddress(String baseUrl) {
    if (_selectedBaseUrl == baseUrl) return;
    setState(() => _selectedBaseUrl = baseUrl);
    widget.onAddressSelected?.call(baseUrl);
  }

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).colorScheme.onSurface;
    final options = widget.addressOptions;
    final instructions = SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '使用手机扫描二维码输入',
            style: TextStyle(
              color: textColor,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            widget.fieldCount > 1
                ? '一次填写 ${widget.fieldCount} 项；NipaPlay 内扫码打开原生表单，系统相机扫码打开浏览器。'
                : 'NipaPlay 内扫码会打开原生输入菜单，系统相机扫码会打开浏览器。',
            style: TextStyle(
              color: textColor.withValues(alpha: 0.66),
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (options.length > 1) ...[
            const SizedBox(height: 18),
            Text(
              '选择电视地址（扫码连不上时换一个）',
              style: TextStyle(
                color: textColor.withValues(alpha: 0.72),
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 190),
              child: Scrollbar(
                controller: _addressScrollController,
                child: SingleChildScrollView(
                  controller: _addressScrollController,
                  primary: false,
                  child: _RemoteInputAddressSelector(
                    options: options,
                    selectedBaseUrl: _selectedBaseUrl,
                    textColor: textColor,
                    onSelected: _selectAddress,
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 18),
          Text(
            'KEY ${widget.displayKey}',
            style: TextStyle(
              color: textColor,
              fontSize: 20,
              letterSpacing: 2,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _qrData,
            style: TextStyle(
              color: textColor.withValues(alpha: 0.54),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final horizontal = constraints.maxWidth >= 420;
          // Size against the dialog's remaining body, after its header and
          // safe-area margins. Only the instructions scroll, never the QR.
          final qrSize = math.max(
            0.0,
            math.min(
              320.0,
              math.min(
                horizontal ? constraints.maxWidth * 0.48 : constraints.maxWidth,
                horizontal
                    ? constraints.maxHeight
                    : constraints.maxHeight * 0.6,
              ),
            ),
          );
          final qr = SizedBox.square(
            dimension: qrSize,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: QrImageView(
                data: _qrData,
                version: QrVersions.auto,
                size: qrSize,
                padding: const EdgeInsets.all(12),
                backgroundColor: Colors.white,
              ),
            ),
          );

          if (horizontal) {
            return Row(
              children: [
                qr,
                const SizedBox(width: 24),
                Expanded(child: instructions),
              ],
            );
          }
          return Column(
            children: [
              qr,
              const SizedBox(height: 16),
              Expanded(child: instructions),
            ],
          );
        },
      ),
    );
  }
}

class _RemoteInputAddressSelector extends StatelessWidget {
  const _RemoteInputAddressSelector({
    required this.options,
    required this.selectedBaseUrl,
    required this.textColor,
    required this.onSelected,
  });

  final List<RemoteInputAddressOption> options;
  final String? selectedBaseUrl;
  final Color textColor;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final option in options)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: _RemoteInputAddressTile(
              option: option,
              selected: option.baseUrl == selectedBaseUrl,
              textColor: textColor,
              onTap: () => onSelected(option.baseUrl),
            ),
          ),
      ],
    );
  }
}

class _RemoteInputAddressTile extends StatefulWidget {
  const _RemoteInputAddressTile({
    required this.option,
    required this.selected,
    required this.textColor,
    required this.onTap,
  });

  final RemoteInputAddressOption option;
  final bool selected;
  final Color textColor;
  final VoidCallback onTap;

  @override
  State<_RemoteInputAddressTile> createState() =>
      _RemoteInputAddressTileState();
}

class _RemoteInputAddressTileState extends State<_RemoteInputAddressTile> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    return FocusableActionDetector(
      onShowFocusHighlight: (value) {
        if (_focused == value) return;
        setState(() => _focused = value);
      },
      shortcuts: const <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
        SingleActivator(LogicalKeyboardKey.numpadEnter): ActivateIntent(),
        SingleActivator(LogicalKeyboardKey.select): ActivateIntent(),
        SingleActivator(LogicalKeyboardKey.gameButtonA): ActivateIntent(),
      },
      actions: <Type, Action<Intent>>{
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            widget.onTap();
            return null;
          },
        ),
      },
      child: Semantics(
        button: true,
        selected: widget.selected,
        label: widget.option.label,
        excludeSemantics: true,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            // The focus ring is 1px thicker; absorb it in the padding so the
            // tile keeps its size and the surrounding layout does not shift.
            padding: EdgeInsets.symmetric(
              horizontal: _focused ? 11 : 12,
              vertical: _focused ? 9 : 10,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: widget.selected
                  ? accent.withValues(alpha: 0.18)
                  : Colors.transparent,
              border: Border.all(
                color: _focused
                    ? accent
                    : (widget.selected
                        ? accent.withValues(alpha: 0.6)
                        : widget.textColor.withValues(alpha: 0.16)),
                width: _focused ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  widget.selected
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_off_rounded,
                  size: 18,
                  color: widget.selected
                      ? accent
                      : widget.textColor.withValues(alpha: 0.5),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    widget.option.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: widget.textColor,
                      fontSize: 14,
                      fontWeight:
                          widget.selected ? FontWeight.w800 : FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
