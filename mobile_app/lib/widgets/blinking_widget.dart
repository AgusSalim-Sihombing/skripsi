import 'package:flutter/material.dart';

class BlinkingWidget extends StatefulWidget {
  final Widget child;
  final Duration duration;

  const BlinkingWidget({
    super.key,
    required this.child,
    // Default durasi berkedip (1 cycle fade-in, 1 cycle fade-out)
    this.duration = const Duration(milliseconds: 750),
  });

  @override
  State<BlinkingWidget> createState() => _BlinkingWidgetState();
}

class _BlinkingWidgetState extends State<BlinkingWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);

    // Menjalankan animasi secara terus-menerus dan terbalik
    // (Misal: 0 -> 1 lalu 1 -> 0)
    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    // Pastikan membuang controller saat widget didestroy
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Menggunakan FadeTransition untuk mengubah opacity berdasarkan animasi
    return FadeTransition(opacity: _controller, child: widget.child);
  }
}
