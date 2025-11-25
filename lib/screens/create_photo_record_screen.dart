import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../services/api_client.dart';
import '../services/auth_service.dart';

class CreatePhotoRecordScreen extends StatefulWidget {
  final String estructuraId;
  final String estructuraLabel; // por ejemplo: "PZ0001 - Pozo"

  const CreatePhotoRecordScreen({
    super.key,
    required this.estructuraId,
    required this.estructuraLabel,
  });

  @override
  State<CreatePhotoRecordScreen> createState() =>
      _CreatePhotoRecordScreenState();
}

class _CreatePhotoRecordScreenState extends State<CreatePhotoRecordScreen> {
  final ImagePicker _picker = ImagePicker();

  XFile? _fotoPanoramica;
  XFile? _fotoInicial;
  XFile? _fotoAbierto;
  XFile? _fotoFinal;

  bool _saving = false;

  int get _completedCount {
    int c = 0;
    if (_fotoPanoramica != null) c++;
    if (_fotoInicial != null) c++;
    if (_fotoAbierto != null) c++;
    if (_fotoFinal != null) c++;
    return c;
  }

  // IDs calculados para cada fotografía (solo para mostrar en UI)
  String get _idPanoramica => '${widget.estructuraId}-panoramica';
  String get _idInicial => '${widget.estructuraId}-inicial';
  String get _idAbierto => '${widget.estructuraId}-abierto';
  String get _idFinal => '${widget.estructuraId}-final';

  void _setPhotoForSlot(String slot, XFile picked) {
    setState(() {
      switch (slot) {
        case 'panoramica':
          _fotoPanoramica = picked;
          break;
        case 'inicial':
          _fotoInicial = picked;
          break;
        case 'abierto':
          _fotoAbierto = picked;
          break;
        case 'final':
          _fotoFinal = picked;
          break;
      }
    });
  }

  Future<void> _pickFromSource(String slot, ImageSource source) async {
    final picked = await _picker.pickImage(
      source: source,
      maxWidth: 1600,
      imageQuality: 85,
    );
    if (picked == null) return;
    _setPhotoForSlot(slot, picked);
  }

  Future<void> _pickPhoto(String slot) async {
    // Permite elegir entre cámara o galería
    await showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('Tomar foto'),
              onTap: () {
                Navigator.pop(ctx);
                _pickFromSource(slot, ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Elegir de la galería'),
              onTap: () {
                Navigator.pop(ctx);
                _pickFromSource(slot, ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (_completedCount < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debes registrar las 4 fotografías requeridas.'),
        ),
      );
      return;
    }

    final auth = context.read<AuthService>();
    final api = context.read<ApiClient>();
    final token = auth.token;

    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sesión inválida, inicia sesión nuevamente.'),
        ),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      // Llamadas al backend para cada tipo de fotografía
      await api.uploadPhotoRecord(
        token: token,
        estructuraId: widget.estructuraId,
        tipo: 'panoramica',
        file: File(_fotoPanoramica!.path),
      );

      await api.uploadPhotoRecord(
        token: token,
        estructuraId: widget.estructuraId,
        tipo: 'inicial',
        file: File(_fotoInicial!.path),
      );

      await api.uploadPhotoRecord(
        token: token,
        estructuraId: widget.estructuraId,
        tipo: 'abierto',
        file: File(_fotoAbierto!.path),
      );

      await api.uploadPhotoRecord(
        token: token,
        estructuraId: widget.estructuraId,
        tipo: 'final',
        file: File(_fotoFinal!.path),
      );

      if (!mounted) return;
      setState(() => _saving = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Registro fotográfico completado correctamente.'),
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al guardar registro fotográfico: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Registro fotográfico'),
            Text(
              widget.estructuraLabel,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w400),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 550),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Estructura: ${widget.estructuraId}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Colors.blueGrey[900],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Debes registrar exactamente 4 fotografías:\n'
                    '- Panorámica\n'
                    '- Inicial\n'
                    '- Abierto\n'
                    '- Final',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Completadas: $_completedCount / 4',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ---- Fila 1: Panorámica + Inicial ----
                  Row(
                    children: [
                      Expanded(
                        child: _buildPhotoCard(
                          context: context,
                          title: 'Panorámica',
                          idText: _idPanoramica,
                          file: _fotoPanoramica,
                          onPick: () => _pickPhoto('panoramica'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildPhotoCard(
                          context: context,
                          title: 'Inicial',
                          idText: _idInicial,
                          file: _fotoInicial,
                          onPick: () => _pickPhoto('inicial'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // ---- Fila 2: Abierto + Final ----
                  Row(
                    children: [
                      Expanded(
                        child: _buildPhotoCard(
                          context: context,
                          title: 'Abierto',
                          idText: _idAbierto,
                          file: _fotoAbierto,
                          onPick: () => _pickPhoto('abierto'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildPhotoCard(
                          context: context,
                          title: 'Final',
                          idText: _idFinal,
                          file: _fotoFinal,
                          onPick: () => _pickPhoto('final'),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _saving ? null : _submit,
                      icon: _saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.save),
                      label: const Text('Guardar registro fotográfico'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoCard({
    required BuildContext context,
    required String title,
    required String idText,
    required XFile? file,
    required VoidCallback onPick,
  }) {
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Text(
              title,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.blueGrey[900],
              ),
            ),
            const SizedBox(height: 8),
            Container(
              height: 140,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
                color: Colors.grey[100],
              ),
              child: file == null
                  ? const Center(
                      child: Icon(
                        Icons.photo_camera_outlined,
                        size: 40,
                        color: Colors.grey,
                      ),
                    )
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(File(file.path), fit: BoxFit.cover),
                    ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onPick,
                icon: const Icon(Icons.camera_alt_outlined),
                label: Text(file == null ? 'Agregar foto' : 'Cambiar foto'),
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'ID: $idText',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.grey[700],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
