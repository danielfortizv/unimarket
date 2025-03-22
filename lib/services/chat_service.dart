import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:unimarket/models/chat_model.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late final CollectionReference _chatsRef = _firestore.collection('chats');


  Future<void> crearChat(Chat chat) async {
    if (chat.clienteId.isEmpty || chat.emprendedorId.isEmpty) {
      throw Exception("El chat debe tener un cliente y un emprendedor asociados.");
    }

    await _chatsRef.doc(chat.id).set(chat.toMap());
  }

  Future<void> actualizarChat(Chat chat) async {
    if (chat.clienteId.isEmpty || chat.emprendedorId.isEmpty) {
      throw Exception("El chat debe tener un cliente y un emprendedor asociados.");
    }

    await _chatsRef.doc(chat.id).update(chat.toMap());
  }

  Stream<List<Chat>> obtenerChatsPorCliente(String clienteId) {
    return _chatsRef
        .where('clienteId', isEqualTo: clienteId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Chat.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }

  Stream<List<Chat>> obtenerChatsPorEmprendedor(String emprendedorId) {
    return _chatsRef
        .where('emprendedorId', isEqualTo: emprendedorId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Chat.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }

  Future<Chat?> obtenerChatPorId(String chatId) async {
    final doc = await _chatsRef.doc(chatId).get();
    if (doc.exists) {
      return Chat.fromMap(doc.data() as Map<String, dynamic>, doc.id);
    }
    return null;
  }

  // Nota: No se permite eliminar chats según las reglas de negocio.
}
