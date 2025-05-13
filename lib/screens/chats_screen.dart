import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:unimarket/models/chat_model.dart';
import 'package:unimarket/models/emprendimiento_model.dart';
import 'package:unimarket/models/mensaje_model.dart';
import 'package:unimarket/models/emprendedor_model.dart';
import 'package:unimarket/models/cliente_model.dart';
import 'package:unimarket/screens/chat_screen.dart';
import 'package:unimarket/services/chat_service.dart';
import 'package:unimarket/services/emprendedor_service.dart';
import 'package:unimarket/services/cliente_service.dart';
import 'package:unimarket/services/mensaje_service.dart';
import 'package:unimarket/widgets/avatar.dart';

class ChatsScreen extends StatefulWidget {
  final String? emprendimientoSeleccionado; // Para mostrar chats específicos de un emprendimiento
  
  const ChatsScreen({super.key, this.emprendimientoSeleccionado});

  @override
  State<ChatsScreen> createState() => _ChatsScreenState();
}

class _ChatsScreenState extends State<ChatsScreen> {
  String _search = '';
  bool _esEmprendedor = false;
  Emprendedor? _emprendedor;
  final ChatService _chatService = ChatService();
  final EmprendedorService _emprendedorService = EmprendedorService();
  final ClienteService _clienteService = ClienteService();
  final MensajeService _mensajeService = MensajeService();

  @override
  void initState() {
    super.initState();
    _verificarTipoUsuario();
  }

  Future<void> _verificarTipoUsuario() async {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    _emprendedor = await _emprendedorService.obtenerEmprendedorPorId(userId);
    
    if (mounted) {
      setState(() {
        _esEmprendedor = _emprendedor != null;
      });
    }
  }

  String formatearFechaMensaje(dynamic horaRaw) {
    try {
      late DateTime fechaMsg;
      if (horaRaw is Timestamp) {
        fechaMsg = horaRaw.toDate().toLocal();
      } else if (horaRaw is DateTime) {
        fechaMsg = horaRaw.toLocal();
      } else if (horaRaw is String) {
        fechaMsg = DateTime.parse(horaRaw).toLocal();
      } else {
        return '';
      }

      final ahora = DateTime.now();
      final hoy = DateTime(ahora.year, ahora.month, ahora.day);
      final ayer = hoy.subtract(const Duration(days: 1));
      final soloDiaMsg = DateTime(fechaMsg.year, fechaMsg.month, fechaMsg.day);

      if (soloDiaMsg == hoy) {
        return DateFormat('h:mm a', 'en_US')
                .format(fechaMsg)
                .toLowerCase();
      } else if (soloDiaMsg == ayer) {
        return 'Ayer';
      } else {
        return DateFormat("d 'de' MMMM", 'es').format(fechaMsg);
      }
    } catch (_) {
      return '';
    }
  }

  Stream<List<Chat>> _obtenerChats() {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    
    if (widget.emprendimientoSeleccionado != null) {
      // Mostrar chats específicos de un emprendimiento
      return _chatService.obtenerChatsPorEmprendimiento(widget.emprendimientoSeleccionado!);
    } else if (_esEmprendedor) {
      // Mostrar chats del emprendedor
      return _chatService.obtenerChatsPorEmprendedor(userId);
    } else {
      // Mostrar chats del cliente
      return _chatService.obtenerChatsPorCliente(userId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.emprendimientoSeleccionado != null
              ? 'Chats del emprendimiento'
              : _esEmprendedor
                  ? 'Mis chats de emprendedor'
                  : 'Mis chats',
          style: const TextStyle(fontFamily: 'Poppins'),
        ),
      ),
      body: Column(
        children: [
          // Barra de búsqueda
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              onChanged: (value) => setState(() => _search = value.toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Buscar chat...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: const Color(0xFFE3F2FD),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // Lista de chats
          Expanded(
            child: StreamBuilder<List<Chat>>(
              stream: _obtenerChats(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final chats = snapshot.data!;
                if (chats.isEmpty) {
                  return const Center(child: Text('No hay chats disponibles.'));
                }

                return ListView.builder(
                  itemCount: chats.length,
                  itemBuilder: (context, index) {
                    final chat = chats[index];

                    return FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance
                          .collection('emprendimientos')
                          .doc(chat.emprendimientoId)
                          .get(),
                      builder: (context, empSnap) {
                        if (!empSnap.hasData || empSnap.data == null || empSnap.data!.data() == null) {
                          return const SizedBox();
                        }

                        final empData = empSnap.data!.data() as Map<String, dynamic>;
                        final emprendimiento = Emprendimiento.fromMap(empData, empSnap.data!.id);

                        // Obtener información del otro participante
                        return FutureBuilder<Map<String, dynamic>>(
                          future: _obtenerInfoOtroParticipante(chat, userId, emprendimiento),
                          builder: (context, infoSnapshot) {
                            if (!infoSnapshot.hasData) return const SizedBox();

                            final infoOtroParticipante = infoSnapshot.data!;
                            final nombreAMostrar = infoOtroParticipante['nombreAMostrar'] as String;
                            final fotoOtroParticipante = infoOtroParticipante['foto'] as String?;
                            final nombreOtroParticipante = infoOtroParticipante['nombre'] as String;

                            // Filtro por nombre (barra de búsqueda)
                            if (_search.isNotEmpty &&
                                !nombreAMostrar.toLowerCase().contains(_search)) {
                              return const SizedBox();
                            }

                            // Consulta para obtener el último mensaje y contar no leídos
                            return StreamBuilder<QuerySnapshot>(
                              stream: FirebaseFirestore.instance
                                  .collection('chats')
                                  .doc(chat.id)
                                  .collection('mensajes')
                                  .orderBy('hora', descending: true)
                                  .snapshots(),
                              builder: (context, msgSnapshot) {
                                if (!msgSnapshot.hasData) return const SizedBox();

                                final mensajes = msgSnapshot.data!.docs
                                    .map((doc) => Mensaje.fromMap({
                                      ...doc.data() as Map<String, dynamic>,
                                      'id': doc.id,
                                    }))
                                    .toList();

                                if (mensajes.isEmpty) return const SizedBox();

                                final ultimoMensaje = mensajes.first;
                                final horaString = ultimoMensaje.hora;
                                
                                // Contar mensajes no leídos correctamente
                                final int mensajesNoLeidos = mensajes
                                    .where((m) => 
                                        m.emisorId != userId && // No es mi mensaje
                                        !m.leidoPor.contains(userId)) // No lo he leído
                                    .length;

                                return ListTile(
                                  contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                                  leading: AvatarConDefault(
                                    imageUrl: fotoOtroParticipante,
                                    radius: 28,
                                    placeholderName: nombreAMostrar,
                                  ),
                                  title: Text(
                                    nombreAMostrar,
                                    style: const TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  subtitle: Padding(
                                    padding: const EdgeInsets.only(top: 4.0),
                                    child: Text(
                                      ultimoMensaje.contenido,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 14, fontFamily: 'Poppins'),
                                    ),
                                  ),
                                  trailing: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        formatearFechaMensaje(horaString),
                                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                                      ),
                                      if (mensajesNoLeidos > 0)
                                        Container(
                                          margin: const EdgeInsets.only(top: 6),
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Colors.blue,
                                            borderRadius: BorderRadius.circular(16),
                                          ),
                                          child: Text(
                                            mensajesNoLeidos.toString(),
                                            style: const TextStyle(color: Colors.white, fontSize: 13),
                                          ),
                                        ),
                                    ],
                                  ),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => ChatScreen(
                                          chat: chat,
                                          currentUserId: userId,
                                          // Pasar el nombre correcto según el tipo de usuario
                                          nombreEmprendimiento: _esEmprendedor
                                              ? nombreOtroParticipante // Si soy emprendedor, pasar el nombre del cliente
                                              : emprendimiento.nombre, // Si soy cliente, pasar el nombre del emprendimiento
                                          fotoEmprendimiento: fotoOtroParticipante ?? 
                                              'https://ui-avatars.com/api/?name=${Uri.encodeComponent(nombreOtroParticipante)}&background=EEEEEE&color=757575',
                                        ),
                                      ),
                                    );
                                  },
                                );
                              },
                            );
                          },
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<Map<String, dynamic>> _obtenerInfoOtroParticipante(Chat chat, String currentUserId, Emprendimiento emprendimiento) async {
    if (_esEmprendedor) {
      // Si soy emprendedor, mostrar solo el nombre del cliente
      final clienteDoc = await FirebaseFirestore.instance
          .collection('clientes')
          .doc(chat.clienteId)
          .get();
      
      final clienteData = clienteDoc.data();
      final nombreCliente = clienteData?['nombre'] ?? 'Cliente desconocido';
      
      return {
        'nombre': nombreCliente,
        'nombreAMostrar': nombreCliente, // Solo el nombre del cliente
        'foto': clienteData?['fotoPerfil']
      };
    } else {
      // Si soy cliente, mostrar SOLO el nombre del emprendimiento y su foto
      return {
        'nombre': emprendimiento.nombre,
        'nombreAMostrar': emprendimiento.nombre, // Solo el nombre del emprendimiento (ej: "MateTutor")
        'foto': emprendimiento.imagenes.isNotEmpty ? emprendimiento.imagenes.first : null
      };
    }
  }
}