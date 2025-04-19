import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:unimarket/models/producto_model.dart';
import 'package:unimarket/services/producto_service.dart';
import 'package:unimarket/services/storage_service.dart';
import 'package:uuid/uuid.dart';

class RegistrarProductoScreen extends StatefulWidget {
  final String emprendimientoId;
  const RegistrarProductoScreen({super.key, required this.emprendimientoId});

  @override
  State<RegistrarProductoScreen> createState() => _RegistrarProductoScreenState();
}

class _RegistrarProductoScreenState extends State<RegistrarProductoScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nombreCtrl = TextEditingController();
  final _descripcionCtrl = TextEditingController();
  final _precioCtrl = TextEditingController();

  final _picker = ImagePicker();
  final _storageService = StorageService();
  final _service = ProductoService();
  final List<File> _imagenes = [];

  bool _submitting = false;

  Future<void> _pickImages() async {
    final imgs = await _picker.pickMultiImage(imageQuality: 80);
    if (imgs.isNotEmpty) {
      setState(() => _imagenes.addAll(imgs.map((e) => File(e.path))));
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _imagenes.isEmpty) return;
    setState(() => _submitting = true);

    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;

      List<String> urls = [];
      for (int i = 0; i < _imagenes.length; i++) {
        final path = 'productos/$uid/${DateTime.now().millisecondsSinceEpoch}_$i.jpg';
        final url = await _storageService.subirArchivo(_imagenes[i], path);
        urls.add(url);
      }

      final prod = Producto(
        id: const Uuid().v4(),
        nombre: _nombreCtrl.text.trim(),
        descripcion: _descripcionCtrl.text.trim(),
        precio: double.parse(_precioCtrl.text.trim()),
        imagenes: urls,
        emprendimientoId: widget.emprendimientoId,
        rating: null,
        comentarioIds: [],
      );

      await _service.crearProducto(prod);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  OutlineInputBorder _border([Color? c]) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: c ?? Colors.grey.shade300),
      );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Registrar producto')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _nombreCtrl,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: 'Nombre',
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    border: _border(),
                    enabledBorder: _border(),
                    focusedBorder: _border(theme.primaryColor),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Requerido' : null,
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _descripcionCtrl,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Descripción',
                    alignLabelWithHint: true,
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    border: _border(),
                    enabledBorder: _border(),
                    focusedBorder: _border(theme.primaryColor),
                  ),
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _precioCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Precio',
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    border: _border(),
                    enabledBorder: _border(),
                    focusedBorder: _border(theme.primaryColor),
                  ),
                  validator: (v) =>
                      v == null || double.tryParse(v.trim()) == null ? 'Debe ser numérico' : null,
                ),
                const SizedBox(height: 24),

                if (_imagenes.isNotEmpty)
                  SizedBox(
                    height: 110,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _imagenes.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (_, i) => ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          _imagenes[i],
                          width: 110,
                          height: 110,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                if (_imagenes.isNotEmpty) const SizedBox(height: 16),

                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _pickImages,
                  icon: const Icon(Icons.photo_library_outlined),
                  label: const Text('Seleccionar imágenes'),
                ),
                const SizedBox(height: 28),

                FilledButton(
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: _submitting ? null : _submit,
                  child: _submitting
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.5),
                        )
                      : const Text('Crear producto', style: TextStyle(fontSize: 16)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
