import 'dart:io';

import 'package:intl/intl.dart';
import 'package:unimarket/screens/registrar_emprendimiento_screen.dart';
import 'package:unimarket/screens/editar_emprendimiento_screen.dart';
import 'package:unimarket/screens/editar_producto_screen.dart';
import 'package:unimarket/screens/registrar_producto_screen.dart';
import 'package:unimarket/screens/chats_screen.dart'; // Agregado
import 'package:unimarket/services/emprendimiento_service.dart';
import 'package:unimarket/services/emprendedor_service.dart';
import 'package:unimarket/models/emprendimiento_model.dart';
import 'package:unimarket/services/producto_service.dart';
import 'package:unimarket/services/storage_service.dart';
import 'package:unimarket/models/emprendedor_model.dart';
import 'package:unimarket/services/cliente_service.dart';
import 'package:unimarket/screens/favorite_screen.dart';
import 'package:unimarket/models/producto_model.dart';
import 'package:unimarket/models/cliente_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:unimarket/widgets/avatar.dart';

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
  List<Emprendimiento> _emprendimientos = [];

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
      final resultados = await Future.wait(
        _emprendedor!.emprendimientoIds.map((id) async {
          final emp = await _emprendimientoService.obtenerPorId(id);
          return emp; // emp es Emprendimiento?
        }),
      );

      _emprendimientos = resultados.whereType<Emprendimiento>().toList();
      _emprendimiento ??= _emprendimientos.firstOrNull;
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
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Confirmar')),
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

  void _mostrarSelectorDeEmprendimiento() async {
    final resultado = await showModalBottomSheet<Emprendimiento?>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          const Text('Selecciona un emprendimiento', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          ..._emprendimientos.map((e) => ListTile(
                leading: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundImage: e.imagenes.isNotEmpty ? NetworkImage(e.imagenes.first) : null,
                      backgroundColor: Colors.grey[300],
                    ),
                    if (e.id == _emprendimiento?.id)
                      const Positioned(
                        bottom: 0,
                        right: 0,
                        child: Icon(Icons.circle, color: Colors.green, size: 12),
                      ),
                  ],
                ),
                title: Text(e.nombre, style: const TextStyle(fontWeight: FontWeight.w500)),
                onTap: () => Navigator.pop(context, e),
              )),
          ListTile(
            leading: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.green.withOpacity(0.1),
              ),
              padding: const EdgeInsets.all(6),
              child: const Icon(Icons.add, color: Colors.green),
            ),
            title: const Text('Crear nuevo emprendimiento', style: TextStyle(fontWeight: FontWeight.w500)),
            onTap: () async {
              Navigator.pop(context);
              final creado = await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const RegistrarEmprendimientoScreen()),
              );
              if (creado != null) await _cargarDatos();
            },
          ),
          const SizedBox(height: 12),
        ],
      ),
    );

    if (resultado != null) _seleccionarEmprendimiento(resultado);
  }

  Future<void> _responderPregunta(String pregunta) async {
    final controller = TextEditingController(
      text: _emprendimiento!.preguntasFrecuentes[pregunta]?.toString() ?? '',
    );

    final respuesta = await showDialog<String>(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Responder pregunta',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                pregunta,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Escribe tu respuesta aquí...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: const Color.fromARGB(255, 251, 252, 255),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    child: const Text('Cancelar'),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () => Navigator.pop(context, controller.text.trim()),
                    child: const Text('Responder'),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );

    if (respuesta != null && respuesta.isNotEmpty) {
      await _emprendimientoService.agregarRespuestaAPreguntaFrecuente(
        _emprendimiento!.id,
        pregunta,
        respuesta,
      );
      await _cargarDatos();
    }
  }

  void _seleccionarEmprendimiento(Emprendimiento emp) {
    setState(() => _emprendimiento = emp);
  }

  final NumberFormat formatoPesos = NumberFormat.currency(locale: 'es_CO', symbol: '\$', decimalDigits: 0, customPattern: '\u00A4#,##0');

  @override
  Widget build(BuildContext context) {
    if (_cliente == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.bookmark_border),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const FavoritosScreen()),
            );
          },
        ),
        title: InkWell(
          onTap: _emprendimientos.isNotEmpty ? _mostrarSelectorDeEmprendimiento : null,
          borderRadius: BorderRadius.circular(8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Text('Mi perfil', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(width: 4),
              Icon(Icons.arrow_drop_down, color: Colors.white),
            ],
          ),
        ),
        actions: [
          // Nuevo: Botón para ver chats del emprendimiento
          if (_emprendimiento != null)
            IconButton(
              icon: const Icon(Icons.message),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChatsScreen(
                      emprendimientoSeleccionado: _emprendimiento!.id,
                    ),
                  ),
                );
              },
            ),
          if (_emprendimiento != null)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () async {
                final actualizado = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EditarEmprendimientoScreen(emprendimiento: _emprendimiento!),
                  ),
                );
                if (actualizado == true) _cargarDatos();
              },
            ),
        ],
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
                    AvatarConDefault(
                      imageUrl: _cliente!.fotoPerfil,
                      radius: 50,
                      placeholderName: _cliente!.nombre,
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
                      MaterialPageRoute(builder: (_) => const RegistrarEmprendimientoScreen()),
                    );
                    if (creado != null && mounted) _cargarDatos();
                  },
                  child: const Text('¿Quieres ser emprendedor?'),
                ),
              )
            else ...[
              _buildEmprendimientoSection(),
              const SizedBox(height: 16),
              // Nuevo: Botón para ver todos los chats como emprendedor
              if (_emprendedor != null && _emprendimientos.isNotEmpty)
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ChatsScreen(), // Sin emprendimiento específico
                      ),
                    );
                  },
                  icon: const Icon(Icons.chat),
                  label: const Text('Ver todos mis chats'),
                ),
              const SizedBox(height: 8),
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
                        subtitle: Text(formatoPesos.format(p.precio)),
                        onTap: () async {
                          final actualizado = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => EditarProductoScreen(producto: p),
                            ),
                          );
                          if (actualizado == true && mounted) _cargarDatos();
                        },
                      );
                    },
                  );
                },
              ),
              if (_emprendimiento!.preguntasFrecuentes.isNotEmpty) ...[
                const SizedBox(height: 24),
                const Text(
                  'Preguntas frecuentes',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 8),
                ..._emprendimiento!.preguntasFrecuentes.entries.map((entry) {
                  final pregunta = entry.key;
                  final respuesta = entry.value?.toString();

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                        decoration: BoxDecoration(
                          border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: GestureDetector(
                                onTap: () async {
                                  final confirmar = await showDialog<bool>(
                                    context: context,
                                    builder: (_) => AlertDialog(
                                      title: const Text('¿Eliminar pregunta?'),
                                      content: const Text('¿Estás seguro de eliminar esta pregunta?'),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(context, false),
                                          child: const Text('Cancelar'),
                                        ),
                                        ElevatedButton(
                                          onPressed: () => Navigator.pop(context, true),
                                          child: const Text('Eliminar'),
                                        ),
                                      ],
                                    ),
                                  );
                                  if (confirmar == true) {
                                    await _emprendimientoService.eliminarPreguntaFrecuente(
                                      _emprendimiento!.id,
                                      pregunta,
                                    );
                                    await _cargarDatos();
                                  }
                                },
                                child: Container(
                                  width: 16,
                                  height: 16,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.grey,
                                  ),
                                  child: const Icon(Icons.close, size: 10, color: Colors.white),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: InkWell(
                                onTap: () => _responderPregunta(pregunta),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            pregunta,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                        if (respuesta == null || respuesta.isEmpty)
                                          Container(
                                            width: 10,
                                            height: 10,
                                            margin: const EdgeInsets.only(left: 8, right: 4, top: 4),
                                            decoration: const BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: Colors.green,
                                            ),
                                          )
                                        else
                                          IconButton(
                                            icon: const Icon(Icons.edit, size: 18, color: Colors.grey),
                                            onPressed: () => _responderPregunta(pregunta),
                                          ),
                                      ],
                                    ),
                                    if (respuesta != null && respuesta.isNotEmpty) ...[
                                      const SizedBox(height: 6),
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade100,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          respuesta,
                                          style: const TextStyle(fontSize: 14),
                                        ),
                                      ),
                                    ]
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    ],
                  );
                }),
              ],
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
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    emp.nombre,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  if ((emp.descripcion ?? '').isNotEmpty)
                    Text(emp.descripcion!),
                ],
              ),
            ),
            if (emp.imagenes.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(right: 15.0, top: 8),
                child: ClipOval(
                  child: Image.network(
                    emp.imagenes.first,
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if ((emp.info ?? '').isNotEmpty) ...[
          const Text(
            'Información',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          Text(
            emp.info!,
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 8),
        ],
        if (emp.hashtags.isNotEmpty) ...[
          const Text(
            'Hashtags',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          Wrap(
            spacing: 6,
            children: emp.hashtags
          .map((h) => Chip(
                label: Text(
            h,
            style: const TextStyle(fontSize: 14),
                ),
              ))
          .toList(),
          ),
        ],
      ],
    );
  }
}