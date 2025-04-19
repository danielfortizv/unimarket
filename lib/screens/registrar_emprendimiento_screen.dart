import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:unimarket/models/emprendedor_model.dart';
import 'package:unimarket/models/emprendimiento_model.dart';
import 'package:unimarket/services/cliente_service.dart';
import 'package:unimarket/services/emprendedor_service.dart';
import 'package:unimarket/services/emprendimiento_service.dart';
import 'package:unimarket/services/storage_service.dart';
import 'package:uuid/uuid.dart';

class RegistrarEmprendimientoScreen extends StatefulWidget {
  const RegistrarEmprendimientoScreen({super.key});

  @override
  State<RegistrarEmprendimientoScreen> createState() =>
      _RegistrarEmprendimientoScreenState();
}

class _RegistrarEmprendimientoScreenState
    extends State<RegistrarEmprendimientoScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _nombreCtrl = TextEditingController();
  final _descripcionCtrl = TextEditingController();
  final _contactoCtrl = TextEditingController();
  final _hashtagsCtrl = TextEditingController();
  final _storageService = StorageService();
  final service = EmprendimientoService();

  final _picker = ImagePicker();
  final List<File> _imagenes = [];

  bool _submitting = false;

  Future<void> _pickImages() async {
    final imgs = await _picker.pickMultiImage(imageQuality: 80);
    if (imgs.isNotEmpty) {
      setState(() => _imagenes.addAll(imgs.map((e) => File(e.path))));
    }
  }

  Future<void> _crearEmprendimiento() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);

    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final cliente = await ClienteService().obtenerClientePorId(uid);
      final emprendedorService = EmprendedorService();

      final yaExiste = await emprendedorService.obtenerEmprendedorPorId(uid);
      if (yaExiste == null) {
        final emprendedor = Emprendedor(
          id: cliente!.id,
          nombre: cliente.nombre,
          email: cliente.email,
          codigo: cliente.codigo,
          password: cliente.password,
          fotoPerfil: cliente.fotoPerfil,
          emprendimientoIds: [],
        );
        await emprendedorService.crearEmprendedor(emprendedor);
      }
      
      List<String> urls = [];
      for (int i = 0; i < _imagenes.length; i++) {
        final path = 'emprendimientos/$uid/imagen_$i.jpg';
        final url = await _storageService.subirArchivo(_imagenes[i], path);
        urls.add(url);
      }


      final id = const Uuid().v4();
      final emp = Emprendimiento(
        id: id,
        nombre: _nombreCtrl.text.trim(),
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
        productoIds: [],
        preguntasFrecuentes: {},
        rangoPrecios: null,
        rating: null,
        emprendedorId: uid,
        imagenes: [],
      );

      await service.crearEmprendimiento(emp);
      if (!mounted) return;
      Navigator.pop(context, emp);
      
      for (final url in urls) {
        await service.agregarImagenAEmprendimiento(emp.id, url);
      }

    } finally {
      if (mounted) setState(() => _submitting = false);
    }

  }


  @override
  void dispose() {
    _nombreCtrl.dispose();
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
      appBar: AppBar(
        title: const Text('Registrar emprendimiento'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                // NOMBRE
                TextFormField(
                  controller: _nombreCtrl,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: 'Nombre',
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    border: border(),
                    enabledBorder: border(),
                    focusedBorder: border(theme.primaryColor),
                  ),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Requerido' : null,
                ),
                const SizedBox(height: 16),

                // DESCRIPCIÓN
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
                ),
                const SizedBox(height: 16),

                // CONTACTO
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
                ),
                const SizedBox(height: 16),

                // HASHTAGS
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

                // PREVISUALIZACIÓN DE IMÁGENES
                if (_imagenes.isNotEmpty)
                  SizedBox(
                    height: 110,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _imagenes.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (_, i) => ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(_imagenes[i],
                            width: 110, height: 110, fit: BoxFit.cover),
                      ),
                    ),
                  ),
                if (_imagenes.isNotEmpty) const SizedBox(height: 16),

                // BOTÓN SELECCIONAR IMÁGENES
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _pickImages,
                  icon: const Icon(Icons.photo_library_outlined),
                  label: const Text('Seleccionar imágenes'),
                ),
                const SizedBox(height: 28),

                // BOTÓN CREAR
                FilledButton(
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: _submitting ? null : _crearEmprendimiento,
                  child: _submitting
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child:
                              CircularProgressIndicator(strokeWidth: 2.5),
                        )
                      : const Text(
                          'Crear emprendimiento',
                          style: TextStyle(fontSize: 16),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
