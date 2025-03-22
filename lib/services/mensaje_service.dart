import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:unimarket/models/mensaje_model.dart';

class MensajeService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

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
}
