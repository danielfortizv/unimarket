import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:unimarket/models/chat_model.dart';
import 'package:unimarket/models/emprendimiento_model.dart';
import 'package:unimarket/models/mensaje_model.dart';
import 'package:unimarket/screens/chat_screen.dart';

class ChatsScreen extends StatefulWidget {
  const ChatsScreen({super.key});

  @override
  State<ChatsScreen> createState() => _ChatsScreenState();
}

class _ChatsScreenState extends State<ChatsScreen> {
  String _search = '';

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

      final ahora      = DateTime.now();
      final hoy        = DateTime(ahora.year, ahora.month, ahora.day);
      final ayer       = hoy.subtract(const Duration(days: 1));
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


  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(

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
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chats')
                  .where('clienteId', isEqualTo: userId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final chatDocs = snapshot.data!.docs;
                if (chatDocs.isEmpty) {
                  return const Center(child: Text('No hay chats disponibles.'));
                }

                return ListView.builder(
                  itemCount: chatDocs.length,
                  itemBuilder: (context, index) {
                    final chatDoc = chatDocs[index];
                    final chat = Chat.fromMap(chatDoc.data() as Map<String, dynamic>, chatDoc.id);

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

                        // Filtro por nombre (barra de búsqueda)
                        if (_search.isNotEmpty &&
                            !emprendimiento.nombre.toLowerCase().contains(_search)) {
                          return const SizedBox();
                        }

                        // Consulta para obtener el último mensaje
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
                                .map((doc) => Mensaje.fromMap(doc.data() as Map<String, dynamic>))
                                .toList();

                            if (mensajes.isEmpty) return const SizedBox();

                            final ultimoMensaje = mensajes.first;
                            final horaString = ultimoMensaje.hora; // Ej: "2025-04-16T09:34:54.090878"
                            final int mensajesNoLeidos = mensajes
                                .where((m) => m.emisorId != userId)
                                .length;

                            return ListTile(
                              contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                              leading: CircleAvatar(
                                radius: 28,
                                backgroundImage: NetworkImage(
                                  (emprendimiento.imagenes.isNotEmpty)
                                      ? emprendimiento.imagenes.first
                                      : 'https://via.placeholder.com/150',
                                ),
                              ),
                              title: Text(
                                emprendimiento.nombre,
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
                                  // Muestra la hora/fecha ya formateada
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
                                      nombreEmprendimiento: emprendimiento.nombre,
                                      fotoEmprendimiento:
                                          (emprendimiento.imagenes.isNotEmpty)
                                              ? emprendimiento.imagenes.first
                                              : '',
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
            ),
          ),
        ],
      ),
    );
  }
}
