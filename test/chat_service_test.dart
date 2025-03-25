import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:unimarket/models/chat_model.dart';
import 'package:unimarket/models/mensaje_model.dart';
import 'package:unimarket/services/chat_service.dart';
import 'package:unimarket/services/mensaje_service.dart';

void main() {
  group('ChatService Tests', () {
    late FakeFirebaseFirestore firestore;
    late ChatService chatService;
    late MensajeService mensajeService;

    setUp(() {
      firestore = FakeFirebaseFirestore();
      mensajeService = MensajeService(firestore); // Inyecta fake firestore
      chatService = ChatService(firestore, mensajeService); // Inyecta ambos
    });


    test('crearChat crea correctamente el documento en Firestore', () async {
      final chat = Chat(
        id: 'chat1',
        clienteId: 'cliente1',
        emprendedorId: 'emprendedor1',
        mensajes: [],
      );

      await chatService.crearChat(chat);

      final doc = await firestore.collection('chats').doc('chat1').get();
      expect(doc.exists, true);
      expect(doc.data()!['clienteId'], equals('cliente1'));
    });

    test('actualizarChat modifica los datos correctamente', () async {
      final chat = Chat(
        id: 'chat2',
        clienteId: 'cliente2',
        emprendedorId: 'emprendedor2',
        mensajes: [],
      );

      await firestore.collection('chats').doc(chat.id).set(chat.toMap());

      final updatedChat = Chat(
        id: 'chat2',
        clienteId: 'cliente2',
        emprendedorId: 'emprendedor2',
        mensajes: [
          Mensaje(
            contenido: 'Hola',
            emisorId: 'cliente2',
            hora: '10:00',
            tipo: 'texto',
          )
        ],
      );

      await chatService.actualizarChat(updatedChat);

      final doc = await firestore.collection('chats').doc(chat.id).get();
      expect(doc.data()!['mensajes'][0]['contenido'], 'Hola');
    });

    test('obtenerChatsPorCliente retorna los chats correctos', () async {
      final chat1 = Chat(id: 'chat3', clienteId: 'clienteX', emprendedorId: 'e1', mensajes: []);
      final chat2 = Chat(id: 'chat4', clienteId: 'clienteX', emprendedorId: 'e2', mensajes: []);

      await firestore.collection('chats').doc(chat1.id).set(chat1.toMap());
      await firestore.collection('chats').doc(chat2.id).set(chat2.toMap());

      final stream = chatService.obtenerChatsPorCliente('clienteX');
      final result = await stream.first;

      expect(result.length, 2);
    });

    test('obtenerChatsPorEmprendedor retorna los chats correctos', () async {
      final chat = Chat(id: 'chat5', clienteId: 'c5', emprendedorId: 'emprendedorX', mensajes: []);
      await firestore.collection('chats').doc(chat.id).set(chat.toMap());

      final stream = chatService.obtenerChatsPorEmprendedor('emprendedorX');
      final result = await stream.first;

      expect(result.length, 1);
      expect(result.first.emprendedorId, 'emprendedorX');
    });

    test('obtenerChatPorId devuelve el chat correcto', () async {
      final chat = Chat(id: 'chat6', clienteId: 'c6', emprendedorId: 'e6', mensajes: []);
      await firestore.collection('chats').doc(chat.id).set(chat.toMap());

      final result = await chatService.obtenerChatPorId(chat.id);
      expect(result, isNotNull);
      expect(result!.clienteId, 'c6');
    });

    test('agregarMensajeAChat guarda correctamente en la subcolección', () async {
      const chatId = 'chat7';

      await firestore.collection('chats').doc(chatId).set({
        'clienteId': 'cliente7',
        'emprendedorId': 'emprendedor7',
        'mensajes': [],
      });

      final mensaje = Mensaje(
        contenido: 'Hola desde test',
        emisorId: 'cliente7',
        hora: '12:00',
        tipo: 'texto',
      );

      await chatService.agregarMensajeAChat(chatId, mensaje);

      final subcollection = await firestore
          .collection('chats')
          .doc(chatId)
          .collection('mensajes')
          .get();

      expect(subcollection.docs.length, 1);
      expect(subcollection.docs.first.data()['contenido'], 'Hola desde test');
    });

    test('eliminarChat borra todos los mensajes y el chat', () async {
      const chatId = 'chat8';

      await firestore.collection('chats').doc(chatId).set({
        'clienteId': 'cliente8',
        'emprendedorId': 'emprendedor8',
        'mensajes': [],
      });

      // Simular mensajes en la subcolección
      await firestore
          .collection('chats')
          .doc(chatId)
          .collection('mensajes')
          .doc('mensaje1')
          .set({
        'contenido': 'Mensaje 1',
        'emisorId': 'cliente8',
        'hora': '13:00',
        'tipo': 'texto',
      });

      await firestore
          .collection('chats')
          .doc(chatId)
          .collection('mensajes')
          .doc('mensaje2')
          .set({
        'contenido': 'Mensaje 2',
        'emisorId': 'cliente8',
        'hora': '13:05',
        'tipo': 'texto',
      });

      // Ejecutar eliminación
      await chatService.eliminarChat(chatId);

      final chatDoc = await firestore.collection('chats').doc(chatId).get();
      expect(chatDoc.exists, false);

      final mensajes = await firestore
          .collection('chats')
          .doc(chatId)
          .collection('mensajes')
          .get();

      expect(mensajes.docs.length, 0);
    });
  });
}
