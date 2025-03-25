import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:unimarket/models/domiciliario_model.dart';
import 'package:unimarket/services/domiciliario_service.dart';

void main() {
  group('DomiciliarioService', () {
    late FakeFirebaseFirestore firestore;
    late DomiciliarioService service;

    setUp(() {
      firestore = FakeFirebaseFirestore();
      service = DomiciliarioService(firestore);
    });

    test('crearDomiciliario guarda correctamente el documento', () async {
      final domiciliario = Domiciliario(
        id: 'd1',
        nombre: 'Juan',
        email: 'juan@correo.com',
        codigo: '123',
        disponible: true,
      );

      await service.crearDomiciliario(domiciliario);

      final doc = await firestore.collection('domiciliarios').doc('d1').get();
      expect(doc.exists, true);
      expect(doc.data()!['nombre'], 'Juan');
    });

    test('crearDomiciliario lanza excepción si hay campos vacíos', () async {
      final domiciliario = Domiciliario(
        id: 'd2',
        nombre: '',
        email: 'test@correo.com',
        codigo: '123',
        disponible: true,
      );

      expect(() => service.crearDomiciliario(domiciliario), throwsException);
    });

    test('actualizarDomiciliario modifica los datos correctamente', () async {
      final domiciliario = Domiciliario(
        id: 'd3',
        nombre: 'Luis',
        email: 'luis@correo.com',
        codigo: '321',
        disponible: true,
      );

      await firestore.collection('domiciliarios').doc(domiciliario.id).set(domiciliario.toMap());

      final actualizado = Domiciliario(
        id: 'd3',
        nombre: 'Luis Actualizado',
        email: 'luis@correo.com',
        codigo: '321',
        disponible: false,
      );

      await service.actualizarDomiciliario(actualizado);

      final doc = await firestore.collection('domiciliarios').doc('d3').get();
      expect(doc.data()!['nombre'], 'Luis Actualizado');
      expect(doc.data()!['disponible'], false);
    });

    test('eliminarDomiciliario elimina el documento', () async {
      await firestore.collection('domiciliarios').doc('d4').set({
        'nombre': 'Pedro',
        'email': 'pedro@correo.com',
        'codigo': '000',
        'disponible': true,
      });

      await service.eliminarDomiciliario('d4');

      final doc = await firestore.collection('domiciliarios').doc('d4').get();
      expect(doc.exists, false);
    });

    test('obtenerDomiciliarioPorId retorna el domiciliario correcto', () async {
      await firestore.collection('domiciliarios').doc('d5').set({
        'nombre': 'Ana',
        'email': 'ana@correo.com',
        'codigo': '555',
        'disponible': true,
      });

      final result = await service.obtenerDomiciliarioPorId('d5');
      expect(result, isNotNull);
      expect(result!.nombre, 'Ana');
    });

    test('cambiarDisponibilidad alterna el valor correctamente', () async {
      await firestore.collection('domiciliarios').doc('d6').set({
        'nombre': 'Camilo',
        'email': 'camilo@correo.com',
        'codigo': '987',
        'disponible': true,
      });

      await service.cambiarDisponibilidad('d6');

      final doc = await firestore.collection('domiciliarios').doc('d6').get();
      expect(doc.data()!['disponible'], false);
    });

    test('obtenerDomiciliarios retorna la lista completa', () async {
      await firestore.collection('domiciliarios').add({
        'nombre': 'Domi 1',
        'email': 'd1@correo.com',
        'codigo': '1',
        'disponible': true,
      });

      await firestore.collection('domiciliarios').add({
        'nombre': 'Domi 2',
        'email': 'd2@correo.com',
        'codigo': '2',
        'disponible': false,
      });

      final stream = service.obtenerDomiciliarios();
      final result = await stream.first;
      expect(result.length, 2);
    });

    test('obtenerDomiciliariosDisponibles retorna solo los disponibles', () async {
      await firestore.collection('domiciliarios').add({
        'nombre': 'Domi Disponible',
        'email': 'd3@correo.com',
        'codigo': '3',
        'disponible': true,
      });

      await firestore.collection('domiciliarios').add({
        'nombre': 'Domi No Disponible',
        'email': 'd4@correo.com',
        'codigo': '4',
        'disponible': false,
      });

      final stream = service.obtenerDomiciliariosDisponibles();
      final result = await stream.first;
      expect(result.length, 1);
      expect(result.first.disponible, true);
    });
  });
}
