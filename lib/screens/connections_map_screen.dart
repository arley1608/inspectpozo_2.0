import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

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
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Diagrama de conexiones · ${widget.projectName}'),
      ),
      body: FlutterMap(
        options: const MapOptions(
          // Centro inicial (luego lo podemos cambiar según tus datos)
          initialCenter: LatLng(4.7, -74.1),
          initialZoom: 13,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.inspectpozo.app',
          ),
          // 🔜 Aquí después agregamos:
          // - MarkerLayer para estructuras
          // - PolylineLayer para tuberías
        ],
      ),
    );
  }
}
