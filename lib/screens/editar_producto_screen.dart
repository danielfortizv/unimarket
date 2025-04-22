import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:unimarket/models/producto_model.dart';
import 'package:unimarket/services/producto_service.dart';
import 'package:unimarket/services/storage_service.dart';

class EditarProductoScreen extends StatefulWidget {
  final Producto producto;
  const EditarProductoScreen({super.key, required this.producto});

  @override
  State<EditarProductoScreen> createState() => _EditarProductoScreenState();
}

class _EditarProductoScreenState extends State<EditarProductoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();
  final _descripcionCtrl = TextEditingController();
  final _precioCtrl = TextEditingController();
  final _picker = ImagePicker();
  final _storageService = StorageService();
  final _productoService = ProductoService();

  List<File> _nuevasImagenes = [];
  List<String> _imagenesActuales = [];
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _nombreCtrl.text = widget.producto.nombre;
    _descripcionCtrl.text = widget.producto.descripcion ?? '';
    _precioCtrl.text = widget.producto.precio.toStringAsFixed(0);
    _imagenesActuales = [...widget.producto.imagenes];
  }

  Future<void> _pickImages() async {
    final imgs = await _picker.pickMultiImage(imageQuality: 80);
    if (imgs.isNotEmpty) {
      setState(() => _nuevasImagenes.addAll(imgs.map((e) => File(e.path))));
    }
  }

  Future<void> _guardarCambios() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);

    try {
      List<String> nuevasUrls = [];
      for (int i = 0; i < _nuevasImagenes.length; i++) {
        final path = 'productos/${widget.producto.id}/editada_$i.jpg';
        final url = await _storageService.subirArchivo(_nuevasImagenes[i], path);
        nuevasUrls.add(url);
      }

      final actualizado = Producto(
        id: widget.producto.id,
        nombre: _nombreCtrl.text.trim(),
        descripcion: _descripcionCtrl.text.trim(),
        precio: double.parse(_precioCtrl.text.trim()),
        imagenes: [..._imagenesActuales, ...nuevasUrls],
        emprendimientoId: widget.producto.emprendimientoId,
        rating: widget.producto.rating,
        comentarioIds: widget.producto.comentarioIds,
      );

      await _productoService.actualizarProducto(actualizado);

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      setState(() => _submitting = false);
    }
  }

  void _eliminarImagenActual(int index) {
    setState(() => _imagenesActuales.removeAt(index));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    OutlineInputBorder border([Color? c]) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: c ?? Colors.grey.shade300),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Editar producto')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _nombreCtrl,
                  decoration: InputDecoration(labelText: 'Nombre', border: border()),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Requerido' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descripcionCtrl,
                  maxLines: 3,
                  decoration: InputDecoration(labelText: 'Descripción', border: border()),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _precioCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: 'Precio', border: border()),
                  validator: (v) => v == null || double.tryParse(v) == null ? 'Numérico' : null,
                ),
                const SizedBox(height: 16),

                if (_imagenesActuales.isNotEmpty)
                  SizedBox(
                    height: 110,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _imagenesActuales.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (_, i) => Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(_imagenesActuales[i], width: 110, height: 110, fit: BoxFit.cover),
                          ),
                          Positioned(
                            top: 4,
                            right: 4,
                            child: GestureDetector(
                              onTap: () => _eliminarImagenActual(i),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.black54,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Icon(Icons.close, size: 20, color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (_imagenesActuales.isNotEmpty) const SizedBox(height: 16),

                if (_nuevasImagenes.isNotEmpty)
                  SizedBox(
                    height: 110,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _nuevasImagenes.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (_, i) => ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(_nuevasImagenes[i], width: 110, height: 110, fit: BoxFit.cover),
                      ),
                    ),
                  ),
                if (_nuevasImagenes.isNotEmpty) const SizedBox(height: 16),

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
                  onPressed: _submitting ? null : _guardarCambios,
                  child: _submitting
                      ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2.5))
                      : const Text('Guardar cambios', style: TextStyle(fontSize: 16)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
