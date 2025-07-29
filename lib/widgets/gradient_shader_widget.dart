import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

class GradientShaderWidget extends StatefulWidget {
  final String filename;
  const GradientShaderWidget(this.filename, {super.key});

  @override
  State<GradientShaderWidget> createState() => _GradientShaderWidgetState();
}

class _GradientShaderWidgetState extends State<GradientShaderWidget>
    with SingleTickerProviderStateMixin {
  ui.FragmentShader? shader;
  late final Ticker _ticker;
  double _time = 0;

  @override
  void initState() {
    super.initState();
    _loadShader();
    _ticker = createTicker((elapsed) {
      setState(() {
        _time = elapsed.inMilliseconds / 1000;
      });
    })..start();
  }

  Future<void> _loadShader() async {
    final program = await ui.FragmentProgram.fromAsset(
      "assets/shaders/${widget.filename}",
    );
    setState(() {
      shader = program.fragmentShader();
    });
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: shader != null ? _ShaderPainter(shader!, _time) : null,
      size: Size.infinite,
    );
  }
}

class _ShaderPainter extends CustomPainter {
  final ui.FragmentShader shader;
  final double time;

  _ShaderPainter(this.shader, this.time);

  @override
  void paint(Canvas canvas, Size size) {
    shader.setFloat(0, size.width);
    shader.setFloat(1, size.height);
    shader.setFloat(2, time); // если в шейдере есть время

    canvas.drawRect(Offset.zero & size, Paint()..shader = shader);
  }

  @override
  bool shouldRepaint(_ShaderPainter oldDelegate) {
    return oldDelegate.time != time;
  }
}
