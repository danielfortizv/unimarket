import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:unimarket/models/mensaje_model.dart';

class MensajeService {
  final FirebaseFirestore _db;
  MensajeService([FirebaseFirestore? firestore]) : _db = firestore ?? FirebaseFirestore.instance;

  Future<void> crearMensaje(Mensaje mensaje, String chatId) async {
    if (mensaje.emisorId.isEmpty || mensaje.hora.isEmpty) {
      throw Exception('El mensaje debe tener un emisor y una hora');
    }

    await _db
        .collection('chats')
        .doc(chatId)
        .collection('mensajes')
        .add(mensaje.toMap());
  }

  Future<void> actualizarMensaje(String chatId, String mensajeId, Mensaje mensaje) async {
    if (mensaje.emisorId.isEmpty || mensaje.hora.isEmpty) {
      throw Exception('El mensaje debe tener un emisor y una hora');
    }

    await _db
        .collection('chats')
        .doc(chatId)
        .collection('mensajes')
        .doc(mensajeId)
        .update(mensaje.toMap());
  }

  Future<void> eliminarMensaje(String chatId, String mensajeId) async {
    await _db
        .collection('chats')
        .doc(chatId)
        .collection('mensajes')
        .doc(mensajeId)
        .delete();
  }

  Stream<List<Mensaje>> obtenerMensajesDeChat(String chatId) {
    return _db
        .collection('chats')
        .doc(chatId)
        .collection('mensajes')
        .orderBy('hora') // asumimos que hora es un String legible o timestamp
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Mensaje.fromMap(doc.data()))
            .toList());
  }

  // Nuevo: Marcar mensajes como leídos
  Future<void> marcarMensajesComoLeidos(String chatId, String userId) async {
    final mensajesSnapshot = await _db
        .collection('chats')
        .doc(chatId)
        .collection('mensajes')
        .where('emisorId', isNotEqualTo: userId)  // Solo mensajes de otros usuarios
        .get();

    for (final doc in mensajesSnapshot.docs) {
      final mensaje = Mensaje.fromMap(doc.data());
      
      // Solo actualizar si el usuario no está ya en la lista de leídos
      if (!mensaje.leidoPor.contains(userId)) {
        await doc.reference.update({
          'leidoPor': FieldValue.arrayUnion([userId])
        });
      }
    }
  }

  // Nuevo: Obtener cantidad de mensajes no leídos en un chat
  Future<int> contarMensajesNoLeidos(String chatId, String userId) async {
    final snapshot = await _db
        .collection('chats')
        .doc(chatId)
        .collection('mensajes')
        .where('emisorId', isNotEqualTo: userId)  // Solo mensajes de otros
        .get();

    int noLeidos = 0;
    for (final doc in snapshot.docs) {
      final mensaje = Mensaje.fromMap(doc.data());
      if (!mensaje.leidoPor.contains(userId)) {
        noLeidos++;
      }
    }
    return noLeidos;
  }
}