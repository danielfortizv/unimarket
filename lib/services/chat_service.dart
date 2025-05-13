import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:unimarket/models/chat_model.dart';
import 'package:unimarket/models/mensaje_model.dart';
import 'package:unimarket/services/mensaje_service.dart';

class ChatService {
  final FirebaseFirestore _firestore;
  final MensajeService _mensajeService;

  ChatService([FirebaseFirestore? firestore, MensajeService? mensajeService])
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _mensajeService = mensajeService ?? MensajeService(firestore);

  Future<Chat> crearChat(Chat chat) async {
    if (chat.clienteId.isEmpty || chat.emprendimientoId.isEmpty) {
      throw Exception("El chat debe tener un cliente y un emprendimiento asociados.");
    }

    final docRef = await _firestore.collection('chats').add(chat.toMap());
    return chat.copyWith(id: docRef.id);
  }

  Future<void> actualizarChat(Chat chat) async {
    if (chat.clienteId.isEmpty || chat.emprendimientoId.isEmpty) {
      throw Exception("El chat debe tener un cliente y un emprendimiento asociados.");
    }

    await _firestore.collection('chats').doc(chat.id).update(chat.toMap());
  }

  Stream<List<Chat>> obtenerChatsPorCliente(String clienteId) {
    return _firestore.collection('chats')
        .where('clienteId', isEqualTo: clienteId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Chat.fromMap(doc.data(), doc.id))
            .toList());
  }

  // Corregido: Obtiene chats por emprendimiento específico
  Stream<List<Chat>> obtenerChatsPorEmprendimiento(String emprendimientoId) {
    return _firestore.collection('chats')
        .where('emprendimientoId', isEqualTo: emprendimientoId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Chat.fromMap(doc.data(), doc.id))
            .toList());
  }

  // Nuevo: Obtiene chats por emprendedor (todos sus emprendimientos)
  Stream<List<Chat>> obtenerChatsPorEmprendedor(String emprendedorId) async* {
    // Primero obtener todos los emprendimientos del emprendedor
    final emprendimientosSnapshot = await _firestore
        .collection('emprendimientos')
        .where('emprendedorId', isEqualTo: emprendedorId)
        .get();
    
    final emprendimientoIds = emprendimientosSnapshot.docs.map((doc) => doc.id).toList();
    
    if (emprendimientoIds.isEmpty) {
      yield [];
      return;
    }
    
    // Luego obtener chats para todos esos emprendimientos
    yield* _firestore.collection('chats')
        .where('emprendimientoId', whereIn: emprendimientoIds)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Chat.fromMap(doc.data(), doc.id))
            .toList());
  }

  Future<Chat?> obtenerChatPorId(String chatId) async {
    final doc = await _firestore.collection('chats').doc(chatId).get();
    if (doc.exists) {
      return Chat.fromMap(doc.data() as Map<String, dynamic>, doc.id);
    }
    return null;
  }

  Future<void> eliminarChat(String chatId) async {
    final mensajesSnapshot = await _firestore.collection('chats').doc(chatId).collection('mensajes').get();
    for (final doc in mensajesSnapshot.docs) {
      await _mensajeService.eliminarMensaje(chatId, doc.id);
    }
    await _firestore.collection('chats').doc(chatId).delete();
  }

  Future<void> agregarMensajeAChat(String chatId, Mensaje mensaje) async {
    await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('mensajes')
        .add(mensaje.toMap());
  }

  Future<Chat?> obtenerChatEntreClienteYEmprendimiento(String clienteId, String emprendimientoId) async {
    final query = await _firestore
        .collection('chats')
        .where('clienteId', isEqualTo: clienteId)
        .where('emprendimientoId', isEqualTo: emprendimientoId)
        .limit(1)
        .get();

    if (query.docs.isNotEmpty) {
      final doc = query.docs.first;
      return Chat.fromMap(doc.data(), doc.id);
    }

    return null;
  }
}