import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/api_client.dart';
import '../services/auth_service.dart';

class PipeDiagramScreen extends StatefulWidget {
  final String structureId;

  const PipeDiagramScreen({
    super.key,
    required this.structureId,
    required List anglesDegrees,
  });

  @override
  State<PipeDiagramScreen> createState() => _PipeDiagramScreenState();
}

class _PipeDiagramScreenState extends State<PipeDiagramScreen> {
  bool _loading = true;
  List<_PipeDiagramArrow> _arrows = [];

  @override
  void initState() {
    super.initState();
    _loadPipes();
  }

  Future<void> _loadPipes() async {
    final auth = context.read<AuthService>();
    final api = context.read<ApiClient>();
    final token = auth.token;

    if (token == null) {
      setState(() {
        _loading = false;
        _arrows = [];
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sesión inválida, inicia sesión de nuevo.'),
        ),
      );
      return;
    }

    try {
      final pipes = await api.getPipesForStructure(
        token: token,
        estructuraId: widget.structureId,
      );

      final arrows = <_PipeDiagramArrow>[];

      for (final pipe in pipes) {
        final inicioId = pipe['id_estructura_inicio']?.toString();
        final destinoId = pipe['id_estructura_destino']?.toString();
        final g = pipe['grados'];

        if (g == null) continue;

        final v = (g is num) ? g.toDouble() : double.tryParse(g.toString());
        if (v == null) continue;

        final pipeId = pipe['id']?.toString() ?? '';

        if (inicioId == widget.structureId) {
          arrows.add(
            _PipeDiagramArrow(angleDeg: v, isOutgoing: true, pipeId: pipeId),
          );
        } else if (destinoId == widget.structureId) {
          double corrected = v + 180;
          if (corrected >= 360) corrected -= 360;

          arrows.add(
            _PipeDiagramArrow(
              angleDeg: corrected,
              isOutgoing: false,
              pipeId: pipeId,
            ),
          );
        }
      }

      setState(() {
        _loading = false;
        _arrows = arrows;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _arrows = [];
      });
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error cargando tuberías: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text('Diagrama estructura ${widget.structureId}')),
      body: Center(
        child: _loading
            ? const CircularProgressIndicator()
            : _arrows.isEmpty
            ? Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'No se encontraron tuberías con ángulo para esta estructura.',
                  style: theme.textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              )
            : AspectRatio(
                aspectRatio: 1,
                child: CustomPaint(
                  painter: PipeDiagramPainter(
                    arrows: _arrows,
                    structureId: widget.structureId,
                  ),
                ),
              ),
      ),
    );
  }
}

/// Modelo interno para cada flecha del diagrama
class _PipeDiagramArrow {
  final double angleDeg;
  final bool isOutgoing; // true: sale del círculo, false: entra al círculo
  final String pipeId;

  const _PipeDiagramArrow({
    required this.angleDeg,
    required this.isOutgoing,
    required this.pipeId,
  });
}

/// Painter que dibuja un círculo sólido y flechas
class PipeDiagramPainter extends CustomPainter {
  final List<_PipeDiagramArrow> arrows;
  final String structureId;

  PipeDiagramPainter({required this.arrows, required this.structureId});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    // Círculo a la mitad del tamaño original (0.25 → 0.15)
    final radius = math.min(size.width, size.height) * 0.15;

    final circlePaint = Paint()
      ..color = const Color.fromARGB(255, 175, 183, 192)
      ..style = PaintingStyle.fill; // Círculo sólido

    final arrowPaint = Paint()
      ..color = const Color.fromARGB(255, 1, 2, 2)
      ..style = PaintingStyle
          .fill // Para flecha tipo punta de lanza
      ..strokeWidth = 8;

    // Círculo central sólido
    canvas.drawCircle(center, radius, circlePaint);

    // Texto del ID de la estructura
    final textPainter = TextPainter(
      text: TextSpan(
        text: structureId,
        style: const TextStyle(color: Colors.white, fontSize: 18),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        center.dx - textPainter.width / 2,
        center.dy - textPainter.height / 2,
      ),
    );

    // Flechas
    for (final arrow in arrows) {
      final angleDeg = arrow.angleDeg;
      final angleRad = (angleDeg - 90) * math.pi / 180.0;
      final dir = Offset(math.cos(angleRad), math.sin(angleRad));

      final start = arrow.isOutgoing
          ? Offset(center.dx + dir.dx * radius, center.dy + dir.dy * radius)
          : Offset(
              center.dx + dir.dx * radius * 1.8,
              center.dy + dir.dy * radius * 1.8,
            );

      final end = arrow.isOutgoing
          ? Offset(
              center.dx + dir.dx * radius * 1.8,
              center.dy + dir.dy * radius * 1.8,
            )
          : Offset(
              center.dx + dir.dx * (radius - 4),
              center.dy + dir.dy * (radius - 4),
            );

      _drawArrow(canvas, start, end, arrowPaint);

      // === ID del tubo AL LADO DE LA LÍNEA, CERCA DEL CENTRO Y SIGUIENDO EL ÁNGULO ===
      final midPoint = Offset((start.dx + end.dx) / 2, (start.dy + end.dy) / 2);

      final labelPainter = TextPainter(
        text: TextSpan(
          text: arrow.pipeId,
          style: const TextStyle(color: Colors.black87, fontSize: 14),
        ),
        textDirection: TextDirection.ltr,
      );
      labelPainter.layout();

      // Ángulo real de la flecha
      final dx = end.dx - start.dx;
      final dy = end.dy - start.dy;
      final arrowAngle = math.atan2(dy, dx);

      // Vector perpendicular para desplazar el texto a un lado de la línea
      const offsetDist = 18.0;
      final offsetX = math.cos(arrowAngle + math.pi / 2) * offsetDist;
      final offsetY = math.sin(arrowAngle + math.pi / 2) * offsetDist;

      final labelPos = Offset(midPoint.dx + offsetX, midPoint.dy + offsetY);

      canvas.save();
      canvas.translate(labelPos.dx, labelPos.dy);
      canvas.rotate(arrowAngle);
      labelPainter.paint(
        canvas,
        Offset(-labelPainter.width / 2, -labelPainter.height / 2),
      );
      canvas.restore();
      // =====================================================================
    }
  }

  /// Flecha tipo punta de lanza (triángulo sólido con cuerpo)
  void _drawArrow(Canvas canvas, Offset start, Offset end, Paint paint) {
    final dx = end.dx - start.dx;
    final dy = end.dy - start.dy;
    final angle = math.atan2(dy, dx);

    const shaftWidth = 3.0;
    const headLength = 10.0;
    const headWidth = 8.0;

    // Punto donde termina el cuerpo y empieza la punta
    final shaftEnd = Offset(
      end.dx - headLength * math.cos(angle),
      end.dy - headLength * math.sin(angle),
    );

    // Vector perpendicular
    final perpX = math.cos(angle + math.pi / 2);
    final perpY = math.sin(angle + math.pi / 2);

    // Rectángulo del cuerpo
    final p1 = Offset(
      start.dx + shaftWidth * perpX,
      start.dy + shaftWidth * perpY,
    );
    final p2 = Offset(
      start.dx - shaftWidth * perpX,
      start.dy - shaftWidth * perpY,
    );
    final p3 = Offset(
      shaftEnd.dx - shaftWidth * perpX,
      shaftEnd.dy - shaftWidth * perpY,
    );
    final p4 = Offset(
      shaftEnd.dx + shaftWidth * perpX,
      shaftEnd.dy + shaftWidth * perpY,
    );

    // Base de la punta
    final tipLeft = Offset(
      shaftEnd.dx + headWidth * perpX,
      shaftEnd.dy + headWidth * perpY,
    );
    final tipRight = Offset(
      shaftEnd.dx - headWidth * perpX,
      shaftEnd.dy - headWidth * perpY,
    );

    final path = Path()
      ..moveTo(p1.dx, p1.dy)
      ..lineTo(p2.dx, p2.dy)
      ..lineTo(p3.dx, p3.dy)
      ..lineTo(tipRight.dx, tipRight.dy)
      ..lineTo(end.dx, end.dy)
      ..lineTo(tipLeft.dx, tipLeft.dy)
      ..lineTo(p4.dx, p4.dy)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant PipeDiagramPainter oldDelegate) {
    return oldDelegate.arrows != arrows ||
        oldDelegate.structureId != structureId;
  }
}
