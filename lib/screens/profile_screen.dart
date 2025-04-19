import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:unimarket/models/cliente_model.dart';
import 'package:unimarket/models/emprendedor_model.dart';
import 'package:unimarket/models/emprendimiento_model.dart';
import 'package:unimarket/models/producto_model.dart';
import 'package:unimarket/services/cliente_service.dart';
import 'package:unimarket/services/emprendimiento_service.dart';
import 'package:unimarket/services/emprendedor_service.dart';
import 'package:unimarket/services/producto_service.dart';
import 'package:unimarket/services/storage_service.dart';
import 'package:uuid/uuid.dart';

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
            children: emp.hashtags.map((h) => Chip(label: Text('#$h'))).toList(),
          ),
        ],
      ],
    );
  }
}

/// ---------------------------
///  REGISTRAR EMPRENDIMIENTO
/// ---------------------------

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
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
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


/// ---------------------------
///  REGISTRAR PRODUCTO
/// ---------------------------
class RegistrarProductoScreen extends StatefulWidget {
  final String emprendimientoId;
  const RegistrarProductoScreen({super.key, required this.emprendimientoId});

  @override
  State<RegistrarProductoScreen> createState() => _RegistrarProductoScreenState();
}

class _RegistrarProductoScreenState extends State<RegistrarProductoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();
  final _service = ProductoService();

  final _nombreCtrl = TextEditingController();
  final _descripcionCtrl = TextEditingController();
  final _precioCtrl = TextEditingController();
  List<XFile> _imagenes = [];
  bool _submitting = false;

  Future<void> _pickImages() async {
    final imgs = await _picker.pickMultiImage();
    if (imgs.isNotEmpty) setState(() => _imagenes = imgs.take(5).toList());
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _imagenes.isEmpty) return;
    setState(() => _submitting = true);

    final urls = _imagenes.map((e) => e.path).toList();

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
    try {
      await _service.crearProducto(prod);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registrar producto')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nombreCtrl,
                decoration: const InputDecoration(labelText: 'Nombre'),
                validator: (v) => v == null || v.trim().isEmpty ? 'Requerido' : null,
              ),
              TextFormField(
                controller: _descripcionCtrl,
                decoration: const InputDecoration(labelText: 'Descripción'),
                maxLines: 3,
              ),
              TextFormField(
                controller: _precioCtrl,
                decoration: const InputDecoration(labelText: 'Precio'),
                keyboardType: TextInputType.number,
                validator: (v) =>
                    v == null || double.tryParse(v) == null ? 'Numérico' : null,
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: _pickImages,
                icon: const Icon(Icons.image),
                label: Text(_imagenes.isEmpty
                    ? 'Seleccionar imágenes'
                    : '${_imagenes.length} imagen(es) seleccionada(s)'),
              ),
              const SizedBox(height: 24),
              _submitting
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _submit,
                      child: const Text('Crear producto'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
