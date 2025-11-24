import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../services/api_client.dart';
import '../services/auth_service.dart';

class ConnectionsMapScreen extends StatefulWidget {
  final int projectServerId;
  final String projectName;

  const ConnectionsMapScreen({
    super.key,
    required this.projectServerId,
    required this.projectName,
  });

  @override
  State<ConnectionsMapScreen> createState() => _ConnectionsMapScreenState();
}

class _ConnectionsMapScreenState extends State<ConnectionsMapScreen> {
  bool _loading = true;
  String? _error;

  List<Map<String, dynamic>> _structures = [];
  List<Map<String, dynamic>> _pipes = [];
  LatLng? _center;

  @override
  void initState() {
    super.initState();
    _loadMapData();
  }

  Future<void> _loadMapData() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final auth = context.read<AuthService>();
      final api = context.read<ApiClient>();
      final token = auth.token;

      if (token == null) {
        setState(() {
          _loading = false;
          _error = 'Sesión inválida. Inicia sesión nuevamente.';
        });
        return;
      }

      final data = await api.getProjectMapData(
        token: token,
        projectId: widget.projectServerId,
      );

      final structures = <Map<String, dynamic>>[];
      final pipes = <Map<String, dynamic>>[];

      if (data['structures'] is List) {
        structures.addAll(
          (data['structures'] as List).whereType<Map>().map(
            (e) => Map<String, dynamic>.from(e),
          ),
        );
      }

      if (data['pipes'] is List) {
        pipes.addAll(
          (data['pipes'] as List).whereType<Map>().map(
            (e) => Map<String, dynamic>.from(e),
          ),
        );
      }

      LatLng? center;
      if (structures.isNotEmpty) {
        final first = structures.first;
        final lat = _toDouble(first['lat']);
        final lon = _toDouble(first['lon']);
        if (lat != null && lon != null) {
          center = LatLng(lat, lon);
        }
      }

      setState(() {
        _structures = structures;
        _pipes = pipes;
        _center = center;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = 'Error al cargar datos de mapa: $e';
      });
    }
  }

  double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value.replaceAll(',', '.'));
    return null;
  }

  @override
  Widget build(BuildContext context) {
    Theme.of(context);

    Widget body;
    if (_loading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (_error != null) {
      body = Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _loadMapData,
              child: const Text("Reintentar"),
            ),
          ],
        ),
      );
    } else if (_structures.isEmpty && _pipes.isEmpty) {
      body = const Center(child: Text("No hay estructuras ni tuberías."));
    } else {
      body = Stack(
        children: [
          FlutterMap(
            options: MapOptions(
              initialCenter: _center ?? const LatLng(4.7, -74.1),
              initialZoom: 16,
            ),
            children: [
              TileLayer(
                urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                userAgentPackageName: 'com.inspectpozo.app',
              ),

              PolylineLayer(polylines: _buildPipePolylines()),
              MarkerLayer(markers: _buildStructureMarkers()),
            ],
          ),

          /// ====== LEYENDA INFERIOR DERECHA ======
          Positioned(
            right: 10,
            bottom: 10,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(8),
                boxShadow: const [
                  BoxShadow(
                    blurRadius: 4,
                    color: Colors.black26,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _legendItem(
                    shape: BoxShape.circle,
                    color: Colors.black,
                    text: "Pozo",
                  ),
                  const SizedBox(height: 6),
                  _legendItem(
                    shape: BoxShape.rectangle,
                    color: Colors.green,
                    text: "Sumidero",
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Container(width: 24, height: 4, color: Colors.redAccent),
                      const SizedBox(width: 8),
                      const Text("Tubería"),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Diagrama de conexiones · ${widget.projectName}'),
      ),
      body: body,
    );
  }

  Widget _legendItem({
    required BoxShape shape,
    required Color color,
    required String text,
  }) {
    return Row(
      children: [
        Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            color: color,
            shape: shape,
            border: shape == BoxShape.rectangle
                ? Border.all(color: Colors.black87, width: 1)
                : null,
          ),
        ),
        const SizedBox(width: 8),
        Text(text),
      ],
    );
  }

  List<Marker> _buildStructureMarkers() {
    final markers = <Marker>[];

    for (final s in _structures) {
      final lat = _toDouble(s['lat']);
      final lon = _toDouble(s['lon']);
      if (lat == null || lon == null) continue;

      final id = (s['id'] ?? '').toString();
      final tipo = (s['tipo'] ?? '').toString().toLowerCase();

      bool isPozo = tipo.contains("pozo");
      bool isSumidero = tipo.contains("sumidero");

      Color color;
      BoxShape shape;

      if (isPozo) {
        color = Colors.black;
        shape = BoxShape.circle;
      } else if (isSumidero) {
        color = Colors.green;
        shape = BoxShape.rectangle;
      } else {
        color = Colors.grey.shade600;
        shape = BoxShape.circle;
      }

      markers.add(
        Marker(
          point: LatLng(lat, lon),
          width: 10,
          height: 10,
          child: Tooltip(
            message: "$id · ${s['tipo']}",
            child: Container(
              decoration: BoxDecoration(
                color: color,
                shape: shape,
                border: shape == BoxShape.rectangle
                    ? Border.all(color: Colors.black87, width: 1.4)
                    : null,
              ),
            ),
          ),
        ),
      );
    }
    return markers;
  }

  List<Polyline> _buildPipePolylines() {
    final list = <Polyline>[];

    for (final p in _pipes) {
      if (p['coords'] is! List) continue;

      final points = <LatLng>[];
      for (final c in p['coords']) {
        if (c is List) {
          final lon = _toDouble(c[0]);
          final lat = _toDouble(c[1]);
          if (lat != null && lon != null) {
            points.add(LatLng(lat, lon));
          }
        }
      }

      if (points.length >= 2) {
        list.add(
          Polyline(points: points, strokeWidth: 4, color: Colors.redAccent),
        );
      }
    }

    return list;
  }
}
