import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:unimarket/models/mensaje_model.dart';
import 'package:unimarket/services/mensaje_service.dart';

void main() {
  group('MensajeService Tests', () {
    late FakeFirebaseFirestore firestore;
    late MensajeService service;

    setUp(() {
      firestore = FakeFirebaseFirestore();
      service = MensajeService(firestore);
    });

    test('crearMensaje guarda correctamente el mensaje en el chat', () async {
      const chatId = 'chat1';
      final mensaje = Mensaje(
        contenido: 'Hola',
        emisorId: 'user1',
        hora: '10:00',
        tipo: 'texto',
      );

      await firestore.collection('chats').doc(chatId).set({'clienteId': 'user1', 'emprendedorId': 'user2'});

      await service.crearMensaje(mensaje, chatId);

      final snapshot = await firestore.collection('chats').doc(chatId).collection('mensajes').get();
      expect(snapshot.docs.length, 1);
      expect(snapshot.docs.first['contenido'], 'Hola');
    });

    test('crearMensaje lanza excepción si falta emisor u hora', () async {
      final mensaje = Mensaje(
        contenido: 'Error',
        emisorId: '',
        hora: '',
        tipo: 'texto',
      );

      expect(() => service.crearMensaje(mensaje, 'chatX'), throwsException);
    });

    test('actualizarMensaje modifica el contenido correctamente', () async {
      const chatId = 'chat2';

      final docRef = await firestore.collection('chats').doc(chatId).collection('mensajes').add({
        'contenido': 'Mensaje original',
        'emisorId': 'user1',
        'hora': '10:00',
        'tipo': 'texto',
      });

      final mensajeActualizado = Mensaje(
        contenido: 'Mensaje editado',
        emisorId: 'user1',
        hora: '10:00',
        tipo: 'texto',
      );

      await service.actualizarMensaje(chatId, docRef.id, mensajeActualizado);

      final doc = await firestore.collection('chats').doc(chatId).collection('mensajes').doc(docRef.id).get();
      expect(doc.data()!['contenido'], 'Mensaje editado');
    });

    test('actualizarMensaje lanza excepción si falta emisor u hora', () async {
      final mensaje = Mensaje(
        contenido: 'x',
        emisorId: '',
        hora: '',
        tipo: 'texto',
      );

      expect(() => service.actualizarMensaje('chat2', 'msg2', mensaje), throwsException);
    });

    test('eliminarMensaje borra correctamente el documento', () async {
      const chatId = 'chat3';

      final docRef = await firestore.collection('chats').doc(chatId).collection('mensajes').add({
        'contenido': 'Eliminarme',
        'emisorId': 'userX',
        'hora': '12:00',
        'tipo': 'texto',
      });

      await service.eliminarMensaje(chatId, docRef.id);

      final doc = await firestore.collection('chats').doc(chatId).collection('mensajes').doc(docRef.id).get();
      expect(doc.exists, false);
    });

    test('obtenerMensajesDeChat devuelve mensajes en orden', () async {
      const chatId = 'chat4';

      await firestore.collection('chats').doc(chatId).collection('mensajes').add({
        'contenido': 'Primero',
        'emisorId': 'u1',
        'hora': '09:00',
        'tipo': 'texto',
      });

      await firestore.collection('chats').doc(chatId).collection('mensajes').add({
        'contenido': 'Segundo',
        'emisorId': 'u1',
        'hora': '10:00',
        'tipo': 'texto',
      });

      final stream = service.obtenerMensajesDeChat(chatId);
      final result = await stream.first;

      expect(result.length, 2);
      expect(result.first.contenido, 'Primero');
      expect(result.last.contenido, 'Segundo');
    });
  });
}
