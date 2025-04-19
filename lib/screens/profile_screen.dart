import 'dart:io';

import 'package:unimarket/screens/registrar_emprendimiento_screen.dart';
import 'package:unimarket/screens/registrar_producto_screen.dart';
import 'package:unimarket/services/emprendimiento_service.dart';
import 'package:unimarket/services/emprendedor_service.dart';
import 'package:unimarket/models/emprendimiento_model.dart';
import 'package:unimarket/services/producto_service.dart';
import 'package:unimarket/services/storage_service.dart';
import 'package:unimarket/models/emprendedor_model.dart';
import 'package:unimarket/services/cliente_service.dart';
import 'package:unimarket/models/producto_model.dart';
import 'package:unimarket/models/cliente_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';

class PerfilScreen extends StatefulWidget {
  const PerfilScreen({super.key});

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  final _clienteService = ClienteService();
  final _emprendedorService = EmprendedorService();
  final _emprendimientoService = EmprendimientoService();
  final _productoService = ProductoService();
  final _storageService = StorageService();

  late final String _uid;
  Cliente? _cliente;
  Emprendedor? _emprendedor;
  Emprendimiento? _emprendimiento;

  @override
  void initState() {
    super.initState();
    _uid = FirebaseAuth.instance.currentUser!.uid;
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    _cliente = await _clienteService.obtenerClientePorId(_uid);
    _emprendedor = await _emprendedorService.obtenerEmprendedorPorId(_uid);
    if (_emprendedor != null && _emprendedor!.emprendimientoIds.isNotEmpty) {
      _emprendimiento = await _emprendimientoService
          .obtenerPorId(_emprendedor!.emprendimientoIds.first);
    }
    if (mounted) setState(() {});
  }

  Future<void> _editarFotoPerfil() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null || !mounted) return;

    final usar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('¿Usar esta foto de perfil?'),
        content: CircleAvatar(
          radius: 60,
          backgroundImage: FileImage(File(picked.path)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
    if (usar != true || !mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      if (_cliente?.fotoPerfil != null) {
        await _storageService.eliminarArchivoPorUrl(_cliente!.fotoPerfil!);
      }
      final url = await _storageService.subirArchivo(
        File(picked.path),
        'clientes/$_uid/perfil.jpg',
      );
      await _clienteService.actualizarFotoPerfil(_uid, url);
      await _cargarDatos();
    } finally {
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_cliente == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi perfil', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: RefreshIndicator(
        onRefresh: _cargarDatos,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Center(
              child: GestureDetector(
                onTap: _editarFotoPerfil,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundImage: NetworkImage(
                        _cliente!.fotoPerfil ??
                            'https://ui-avatars.com/api/?name=${Uri.encodeComponent(_cliente!.nombre)}',
                      ),
                    ),
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        // ignore: deprecated_member_use
                        color: Colors.black.withOpacity(0.4),
                      ),
                      child: const Icon(Icons.edit, color: Colors.white, size: 30),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _cliente!.nombre,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                fontFamily: 'Poppins',
              ),
            ),
            Text(
              _cliente!.codigo,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 16),
            if (_emprendimiento == null)
              Center(
                child: ElevatedButton(
                  onPressed: () async {
                    final creado = await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => RegistrarEmprendimientoScreen()),
                    );
                    if (creado != null && mounted) _cargarDatos();
                  },
                  child: const Text('¿Quieres ser emprendedor?'),
                ),
              )
            else ...[
              _buildEmprendimientoSection(),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  final agregado = await Navigator.push<bool>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => RegistrarProductoScreen(
                        emprendimientoId: _emprendimiento!.id,
                      ),
                    ),
                  );
                  if (agregado == true && mounted) _cargarDatos();
                },
                child: const Text('Agregar producto'),
              ),
              const SizedBox(height: 24),
              const Text(
                'Mis productos',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Poppins',
                ),
              ),
              const SizedBox(height: 8),
              StreamBuilder<List<Producto>>(
                stream: _productoService.obtenerProductosPorEmprendimiento(_emprendimiento!.id),
                builder: (context, snap) {
                  if (!snap.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final productos = snap.data!;
                  if (productos.isEmpty) {
                    return const Text('Aún no has agregado productos.');
                  }
                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: productos.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) {
                      final p = productos[i];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundImage: NetworkImage(p.imagenes.first),
                        ),
                        title: Text(p.nombre),
                        subtitle: Text('\$${p.precio.toStringAsFixed(0)}'),
                      );
                    },
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmprendimientoSection() {
    final emp = _emprendimiento!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Column(
            children: [
              if (emp.imagenes.isNotEmpty)
                CircleAvatar(
                  radius: 40,
                  backgroundImage: NetworkImage(emp.imagenes.first),
                ),
              const SizedBox(height: 8),
              Text(
                emp.nombre,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if ((emp.descripcion ?? '').isNotEmpty) ...[
          const Text('Descripción', style: TextStyle(fontWeight: FontWeight.bold)),
          Text(emp.descripcion!),
          const SizedBox(height: 8),
        ],
        if ((emp.info ?? '').isNotEmpty) ...[
          const Text('Información de contacto', style: TextStyle(fontWeight: FontWeight.bold)),
          Text(emp.info!),
          const SizedBox(height: 8),
        ],
        if (emp.hashtags.isNotEmpty) ...[
          const Text('Hashtags', style: TextStyle(fontWeight: FontWeight.bold)),
          Wrap(
            spacing: 6,
            children: emp.hashtags.map((h) => Chip(label: Text(h))).toList(),
          ),
        ],
      ],
    );
  }
}

