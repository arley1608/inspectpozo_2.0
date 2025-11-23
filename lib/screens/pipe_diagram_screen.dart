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
  List<double> _angles = [];

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
        _angles = [];
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

      // Tomamos solo las tuberías donde esta estructura es inicio
      // y que tengan grados no nulo.
      final angles = <double>[];
      for (final pipe in pipes) {
        final inicioId = pipe['id_estructura_inicio']?.toString();
        if (inicioId == widget.structureId) {
          final g = pipe['grados'];
          if (g != null) {
            // Asegurar double
            final v = (g is num) ? g.toDouble() : double.tryParse(g.toString());
            if (v != null) {
              angles.add(v);
            }
          }
        }
      }

      setState(() {
        _loading = false;
        _angles = angles;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _angles = [];
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
            : _angles.isEmpty
            ? Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'No se encontraron tuberías con ángulo para esta estructura de inicio.',
                  style: theme.textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              )
            : AspectRatio(
                aspectRatio: 1,
                child: CustomPaint(
                  painter: PipeDiagramPainter(anglesDegrees: _angles),
                ),
              ),
      ),
    );
  }
}

/// Painter que dibuja un círculo central y una flecha por cada ángulo.
class PipeDiagramPainter extends CustomPainter {
  final List<double> anglesDegrees;

  PipeDiagramPainter({required this.anglesDegrees});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) * 0.25;

    final circlePaint = Paint()
      ..color = const Color(0xFF1565C0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    final arrowPaint = Paint()
      ..color = const Color(0xFF37474F)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    // Círculo central
    canvas.drawCircle(center, radius, circlePaint);

    // Flechas
    for (final angleDeg in anglesDegrees) {
      // Convertimos de grados a radianes.
      // Ajuste -90 para que 0° apunte hacia arriba.
      final angleRad = (angleDeg - 90) * math.pi / 180.0;

      final arrowLength = radius * 1.4;
      final end = Offset(
        center.dx + arrowLength * math.cos(angleRad),
        center.dy + arrowLength * math.sin(angleRad),
      );

      // Línea principal
      canvas.drawLine(center, end, arrowPaint);

      // Cabeza de flecha
      const headSize = 10.0;
      final back = Offset(
        end.dx - headSize * math.cos(angleRad),
        end.dy - headSize * math.sin(angleRad),
      );

      final leftHead = Offset(
        back.dx + headSize * math.cos(angleRad + math.pi / 6),
        back.dy + headSize * math.sin(angleRad + math.pi / 6),
      );
      final rightHead = Offset(
        back.dx + headSize * math.cos(angleRad - math.pi / 6),
        back.dy + headSize * math.sin(angleRad - math.pi / 6),
      );

      canvas.drawLine(end, leftHead, arrowPaint);
      canvas.drawLine(end, rightHead, arrowPaint);
    }
  }

  @override
  bool shouldRepaint(covariant PipeDiagramPainter oldDelegate) {
    return oldDelegate.anglesDegrees != anglesDegrees;
  }
}
