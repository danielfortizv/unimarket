import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:unimarket/models/emprendimiento_model.dart';
import 'package:unimarket/models/favorito_model.dart';
import 'package:unimarket/screens/producto_screen.dart';
import 'package:unimarket/services/emprendimiento_service.dart';
import 'package:unimarket/services/favorito_service.dart';
import 'package:unimarket/models/producto_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:unimarket/screens/chat_screen.dart';
import 'package:unimarket/services/chat_service.dart';
import 'package:unimarket/models/chat_model.dart';
import 'package:intl/intl.dart';


class EmprendimientoScreen extends StatefulWidget {
  final Emprendimiento emprendimiento;
  final void Function()? onToggleFavorito;

  const EmprendimientoScreen({super.key, required this.emprendimiento, this.onToggleFavorito});

  @override
  State<EmprendimientoScreen> createState() => _EmprendimientoScreenState();
}

class _EmprendimientoScreenState extends State<EmprendimientoScreen> {
  final EmprendimientoService _service = EmprendimientoService();
  final FavoritoService _favoritoService = FavoritoService();
  bool _esFavorito = false;

  @override
  void initState() {
    super.initState();
    _verificarFavorito();
  }

  Future<void> _verificarFavorito() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final favorito = await _favoritoService.obtenerFavorito(uid, widget.emprendimiento.id);
    if (mounted) {
      setState(() {
        _esFavorito = favorito != null;
      });
    }
  }

  Future<void> _toggleFavorito() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    if (_esFavorito) {
      final favorito = await _favoritoService.obtenerFavorito(uid, widget.emprendimiento.id);
      if (favorito != null) {
        await _favoritoService.eliminarFavorito(favorito.id);
      }
      if (mounted) {
        setState(() => _esFavorito = false);
        widget.onToggleFavorito?.call(); // 👈 callback para notificar al home
      }
    } else {
      final favorito = Favorito(
        id: '',
        clienteId: uid,
        emprendimientoId: widget.emprendimiento.id,
      );
      await _favoritoService.agregarFavorito(favorito);
      if (mounted) {
        setState(() => _esFavorito = true);
        widget.onToggleFavorito?.call(); // 👈 callback para notificar al home
      }
    }
  }

  final NumberFormat formatoPesos = NumberFormat.currency(locale: 'es_CO', symbol: '\$', decimalDigits: 0, customPattern: '\u00A4#,##0');

  @override
  Widget build(BuildContext context) {
    final emprendimiento = widget.emprendimiento;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'UNIMARKET',
          style: TextStyle(
            fontSize: 28,
            fontFamily: 'Poppins',
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 20.0),
            child: Icon(Icons.delivery_dining, size: 32),
          ),
          Padding(
            padding: EdgeInsets.only(right: 16.0),
            child: Icon(Icons.shopping_cart_outlined, size: 28),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundImage: NetworkImage(emprendimiento.imagenes.first),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          emprendimiento.nombre,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Poppins',
                          ),
                        ),
                        FutureBuilder<DocumentSnapshot>(
                          future: FirebaseFirestore.instance
                              .collection('emprendedores')
                              .doc(emprendimiento.emprendedorId)
                              .get(),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) return const SizedBox();
                            final data = snapshot.data!.data() as Map<String, dynamic>;
                            return Text(
                              data['nombre'],
                              style: const TextStyle(fontSize: 18, fontFamily: 'Poppins'),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _toggleFavorito,
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        backgroundColor: _esFavorito ? Colors.grey.shade400 : Colors.grey.shade200,
                      ),
                      child: Text(
                        _esFavorito ? 'Guardado' : 'Guardar',
                        style: const TextStyle(color: Colors.black),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        final userId = FirebaseAuth.instance.currentUser?.uid;
                        if (userId == null) return;

                        final chatService = ChatService();

                        // Verificar si ya existe un chat entre cliente y emprendedor
                        Chat? chatExistente = await chatService.obtenerChatEntreClienteYEmprendimiento(
                          userId,
                          emprendimiento.emprendedorId,
                        );

                        // Si no existe, crear uno nuevo
                        chatExistente ??= await chatService.crearChat(Chat(
                          id: '', // se genera automáticamente
                          clienteId: userId,
                          emprendimientoId: emprendimiento.id,
                          mensajes: [],
                        ));

                        // Navegar a la pantalla de chat
                        if (context.mounted) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ChatScreen(
                                chat: chatExistente!,
                                currentUserId: userId,
                                nombreEmprendimiento: emprendimiento.nombre,
                                fotoEmprendimiento: emprendimiento.imagenes.isNotEmpty
                                    ? emprendimiento.imagenes.first
                                    : '', // o una imagen por defecto si lo prefieres
                              ),
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        backgroundColor: Colors.grey.shade200,
                      ),
                      child: const Text('Mensaje', style: TextStyle(color: Colors.black)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Text('Productos', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 8),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('productos')
                    .where('emprendimientoId', isEqualTo: emprendimiento.id)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final productos = snapshot.data!.docs.map((doc) => Producto.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList();
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: productos.length,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 5 / 6,
                    ),
                    itemBuilder: (context, index) {
                      final producto = productos[index];
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ProductoDetailScreen(producto: producto),
                            ),
                          );
                        },
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Hero(
                              tag: producto.id, 
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  producto.imagenes.first,
                                  height: 140,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(producto.nombre, style: const TextStyle(fontFamily: 'Poppins')),
                            Text(formatoPesos.format(producto.precio), style: const TextStyle(color: Colors.grey, fontSize: 12)),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
              // Preguntas Frecuentes
              const SizedBox(height: 0),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Preguntas frecuentes',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add, size: 20),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) {
                          final controller = TextEditingController();
                          return AlertDialog(
                            titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                            actionsPadding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
                            title: const Text(
                              'Agregar una pregunta',
                              style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Poppins'),
                            ),
                            content: TextField(
                              controller: controller,
                              decoration: const InputDecoration(
                                hintText: 'Escribe tu pregunta',
                              ),
                            ),
                            actions: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  TextButton(
                                    child: const Text('Cancelar'),
                                    onPressed: () => Navigator.pop(context),
                                  ),
                                  ElevatedButton(
                                    child: const Text('Agregar'),
                                    onPressed: () async {
                                      final pregunta = controller.text.trim();
                                      if (pregunta.isNotEmpty) {
                                        await _service.agregarPreguntaFrecuenteAEmprendimiento(
                                          emprendimiento.id,
                                          pregunta,
                                        );
                                        Navigator.pop(context);
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ],
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ...emprendimiento.preguntasFrecuentes.entries.map((entry) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('• ${entry.key}', style: const TextStyle(fontWeight: FontWeight.w500)),
                      if (entry.value != null)
                        Padding(
                          padding: const EdgeInsets.only(left: 8.0, bottom: 8),
                          child: Text(entry.value!, style: const TextStyle(color: Colors.grey)),
                        ),
                    ],
                  )),

              // Productos similares (solo si hay resultados)
              FutureBuilder<List<Emprendimiento>>(
                future: _service.obtenerEmprendimientosSimilares(emprendimiento.id),
                builder: (context, snapshot) {
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const SizedBox(); // No se muestra nada si no hay similares
                  }

                  final similares = snapshot.data!;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 24),
                      const Text('Productos similares', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 220,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: similares.length,
                          itemBuilder: (context, index) {
                            final emp = similares[index];
                            return GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => EmprendimientoScreen(emprendimiento: emp),
                                  ),
                                );
                              },
                              child: Container(
                                width: 160,
                                margin: const EdgeInsets.only(right: 12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (emp.imagenes.isNotEmpty)
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: Image.network(
                                          emp.imagenes.first,
                                          width: 160,
                                          height: 120,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    const SizedBox(height: 6),
                                    Text(
                                      emp.nombre,
                                      style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      emp.rangoPrecios ?? '',
                                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      )
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}