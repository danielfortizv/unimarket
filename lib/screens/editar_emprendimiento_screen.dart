import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:unimarket/models/emprendimiento_model.dart';
import 'package:unimarket/services/emprendimiento_service.dart';
import 'package:unimarket/services/storage_service.dart';

class EditarEmprendimientoScreen extends StatefulWidget {
  final Emprendimiento emprendimiento;
  const EditarEmprendimientoScreen({super.key, required this.emprendimiento});

  @override
  State<EditarEmprendimientoScreen> createState() => _EditarEmprendimientoScreenState();
}

class _EditarEmprendimientoScreenState extends State<EditarEmprendimientoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descripcionCtrl = TextEditingController();
  final _contactoCtrl = TextEditingController();
  final _hashtagsCtrl = TextEditingController();
  final _picker = ImagePicker();
  final _storageService = StorageService();
  final _service = EmprendimientoService();

  final List<File> _nuevasImagenes = [];
  List<String> _imagenesExistentes = [];
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _descripcionCtrl.text = widget.emprendimiento.descripcion ?? '';
    _contactoCtrl.text = widget.emprendimiento.info ?? '';
    _hashtagsCtrl.text = widget.emprendimiento.hashtags.join(', ');
    _imagenesExistentes = List<String>.from(widget.emprendimiento.imagenes);
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
        final path = 'emprendimientos/${widget.emprendimiento.id}/${DateTime.now().millisecondsSinceEpoch}.jpg';
        final url = await _storageService.subirArchivo(_nuevasImagenes[i], path);
        nuevasUrls.add(url);
      }

      final actualizado = Emprendimiento(
        id: widget.emprendimiento.id,
        nombre: widget.emprendimiento.nombre,
        descripcion: _descripcionCtrl.text.trim(),
        info: _contactoCtrl.text.trim(),
        hashtags: _hashtagsCtrl.text
            .split(',')
            .map((e) {
              final h = e.trim();
              return h.isEmpty ? null : (h.startsWith('#') ? h : '#$h');
            })
            .whereType<String>()
            .toList(),
        productoIds: widget.emprendimiento.productoIds,
        preguntasFrecuentes: widget.emprendimiento.preguntasFrecuentes,
        rangoPrecios: widget.emprendimiento.rangoPrecios,
        rating: widget.emprendimiento.rating,
        emprendedorId: widget.emprendimiento.emprendedorId,
        imagenes: [..._imagenesExistentes, ...nuevasUrls],
      );

      await _service.actualizarEmprendimiento(actualizado, id: widget.emprendimiento.id);

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      setState(() => _submitting = false);
    }
  }

  void _eliminarImagenExistente(int index) {
    setState(() {
      _imagenesExistentes.removeAt(index);
    });
  }

  @override
  void dispose() {
    _descripcionCtrl.dispose();
    _contactoCtrl.dispose();
    _hashtagsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    OutlineInputBorder border([Color? c]) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: c ?? Colors.grey.shade300),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Editar emprendimiento')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _descripcionCtrl,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Descripción',
                    alignLabelWithHint: true,
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    border: border(),
                    enabledBorder: border(),
                    focusedBorder: border(theme.primaryColor),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Requerido' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _contactoCtrl,
                  decoration: InputDecoration(
                    labelText: 'Información de contacto',
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    border: border(),
                    enabledBorder: border(),
                    focusedBorder: border(theme.primaryColor),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Requerido' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _hashtagsCtrl,
                  decoration: InputDecoration(
                    labelText: 'Hashtags (separados por coma)',
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    border: border(),
                    enabledBorder: border(),
                    focusedBorder: border(theme.primaryColor),
                  ),
                ),
                const SizedBox(height: 24),

                // Mostrar imágenes existentes con botón para eliminar
                if (_imagenesExistentes.isNotEmpty)
                  SizedBox(
                    height: 110,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _imagenesExistentes.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (_, i) => Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              _imagenesExistentes[i],
                              width: 110,
                              height: 110,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            top: 4,
                            right: 4,
                            child: GestureDetector(
                              onTap: () => _eliminarImagenExistente(i),
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
                const SizedBox(height: 16),

                // Mostrar nuevas imágenes
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
