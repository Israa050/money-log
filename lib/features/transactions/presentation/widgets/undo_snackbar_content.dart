import 'package:flutter/material.dart';

/// Snackbar body for a pending delete: message plus a shrinking progress
/// bar that visualizes the undo window closing.
class UndoSnackBarContent extends StatefulWidget {
  const UndoSnackBarContent({
    super.key,
    required this.message,
    required this.duration,
  });

  final String message;
  final Duration duration;

  @override
  State<UndoSnackBarContent> createState() => _UndoSnackBarContentState();
}

class _UndoSnackBarContentState extends State<UndoSnackBarContent>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
  )..forward();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.message),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) => LinearProgressIndicator(
              value: 1 - _controller.value,
              minHeight: 2.5,
              backgroundColor: Colors.white24,
              valueColor: const AlwaysStoppedAnimation(Color(0xFF93B4FF)),
            ),
          ),
        ),
      ],
    );
  }
}
