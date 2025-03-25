import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:unimarket/models/notificacion_model.dart';
import 'package:unimarket/services/notificacion_service.dart';

void main() {
  group('NotificacionService Tests', () {
    late FakeFirebaseFirestore firestore;
    late NotificacionService service;

    setUp(() {
      firestore = FakeFirebaseFirestore();
      service = NotificacionService(firestore);
    });

    test('crearNotificacion guarda correctamente la notificación', () async {
      final noti = Notificacion(
        id: 'n1',
        receptorId: 'user1',
        titulo: 'Nuevo pedido',
        mensaje: 'Tienes un pedido nuevo',
        tipo: 'pedido',
        fecha: '2024-03-24',
      );

      await service.crearNotificacion(noti);

      final doc = await firestore.collection('notificaciones').doc('n1').get();
      expect(doc.exists, true);
      expect(doc.data()!['mensaje'], 'Tienes un pedido nuevo');
    });

    test('crearNotificacion lanza excepción si campos están vacíos', () async {
      final noti = Notificacion(
        id: '',
        receptorId: 'user2',
        titulo: '',
        mensaje: '',
        tipo: 'chat',
        fecha: '',
      );

      expect(() => service.crearNotificacion(noti), throwsException);
    });

    test('eliminarNotificacion borra correctamente el documento', () async {
      await firestore.collection('notificaciones').doc('n2').set({
        'receptorId': 'user3',
        'titulo': 'Eliminarme',
        'mensaje': 'Este mensaje será eliminado',
        'tipo': 'alerta',
        'fecha': '2024-03-24',
        'leida': false,
      });

      await service.eliminarNotificacion('n2');

      final doc = await firestore.collection('notificaciones').doc('n2').get();
      expect(doc.exists, false);
    });

    test('marcarComoLeida actualiza el campo leída a true', () async {
      await firestore.collection('notificaciones').doc('n3').set({
        'receptorId': 'user4',
        'titulo': 'Sin leer',
        'mensaje': 'Debes leer esto',
        'tipo': 'chat',
        'fecha': '2024-03-24',
        'leida': false,
      });

      await service.marcarComoLeida('n3');

      final doc = await firestore.collection('notificaciones').doc('n3').get();
      expect(doc.data()!['leida'], true);
    });

    test('obtenerNotificacionesPorCliente devuelve las notificaciones correctas y ordenadas', () async {
      await firestore.collection('notificaciones').add({
        'receptorId': 'c1',
        'titulo': 'Primera',
        'mensaje': 'Mensaje 1',
        'tipo': 'info',
        'fecha': '2024-03-20',
        'leida': false,
      });

      await firestore.collection('notificaciones').add({
        'receptorId': 'c1',
        'titulo': 'Segunda',
        'mensaje': 'Mensaje 2',
        'tipo': 'info',
        'fecha': '2024-03-21',
        'leida': false,
      });

      final stream = service.obtenerNotificacionesPorCliente('c1');
      final result = await stream.first;

      expect(result.length, 2);
      expect(result.first.titulo, 'Segunda'); // porque está ordenado por fecha descendente
    });
  });
}
