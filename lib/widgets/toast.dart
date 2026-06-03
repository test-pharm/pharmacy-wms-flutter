import 'package:flutter/material.dart';

enum ToastType { success, error, warning, info }

OverlayEntry? _currentToast;

void showToast(BuildContext context, String message, {Color? backgroundColor, ToastType type = ToastType.info, Duration duration = const Duration(seconds: 3)}) {
  _currentToast?.remove();
  if (!context.mounted) return;
  final overlay = Overlay.of(context, rootOverlay: true);
  final colors = {
    ToastType.success: Colors.green,
    ToastType.error: Colors.redAccent,
    ToastType.warning: Colors.orange,
    ToastType.info: Colors.blueAccent,
  };
  final icons = {
    ToastType.success: Icons.check_circle_outline,
    ToastType.error: Icons.error_outline,
    ToastType.warning: Icons.warning_amber_rounded,
    ToastType.info: Icons.info_outline,
  };
  final color = backgroundColor ?? colors[type]!;
  _currentToast = OverlayEntry(
    builder: (_) => Material(
      type: MaterialType.transparency,
      child: _ToastWidget(
        message: message,
        color: color,
        icon: icons[type]!,
        duration: duration,
      ),
    ),
  );
  overlay.insert(_currentToast!);
  Future.delayed(duration, () {
    _currentToast?.remove();
    _currentToast = null;
  });
}

class _ToastWidget extends StatefulWidget {
  final String message;
  final Color color;
  final IconData icon;
  final Duration duration;
  const _ToastWidget({required this.message, required this.color, required this.icon, required this.duration});
  @override
  State<_ToastWidget> createState() => _ToastWidgetState();
}

class _ToastWidgetState extends State<_ToastWidget> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<Offset> _slide;
  late Animation<double> _fade;
  late AnimationController _progressCtrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _slide = Tween<Offset>(begin: const Offset(0, -1), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _fade = Tween<double>(begin: 0, end: 1).animate(_ctrl);
    _ctrl.forward();
    _progressCtrl = AnimationController(vsync: this, duration: widget.duration)..forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _progressCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slide,
      child: FadeTransition(
        opacity: _fade,
        child: PositionedDirectional(
          top: MediaQuery.of(context).padding.top + 8,
          end: 16,
          child: Container(
            width: 340,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E2E),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: widget.color.withOpacity(0.4)),
              boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 12)],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(children: [
                  Icon(widget.icon, color: widget.color, size: 20),
                  const SizedBox(width: 10),
                  Expanded(child: Text(widget.message, style: const TextStyle(color: Colors.white, fontSize: 13))),
                ]),
                const SizedBox(height: 10),
                AnimatedBuilder(
                  animation: _progressCtrl,
                  builder: (_, __) => LinearProgressIndicator(
                    value: 1.0 - _progressCtrl.value,
                    backgroundColor: Colors.white12,
                    valueColor: AlwaysStoppedAnimation(widget.color),
                    minHeight: 2,
                    borderRadius: BorderRadius.circular(2),
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
