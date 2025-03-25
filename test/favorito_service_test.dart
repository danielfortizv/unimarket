import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:unimarket/models/favorito_model.dart';
import 'package:unimarket/services/favorito_service.dart';

void main() {
  group('FavoritoService Tests', () {
    late FakeFirebaseFirestore firestore;
    late FavoritoService service;

    setUp(() {
      firestore = FakeFirebaseFirestore();
      service = FavoritoService(firestore);
    });

    test('agregarFavorito guarda correctamente en la base de datos', () async {
      final favorito = Favorito(
        id: 'fav1',
        clienteId: 'c1',
        emprendimientoId: 'e1',
      );

      await service.agregarFavorito(favorito);

      final doc = await firestore.collection('favoritos').doc('fav1').get();
      expect(doc.exists, true);
      expect(doc.data()!['clienteId'], 'c1');
    });

    test('agregarFavorito lanza excepción si los campos están vacíos', () async {
      final favorito = Favorito(
        id: 'fav2',
        clienteId: '',
        emprendimientoId: '',
      );

      expect(() => service.agregarFavorito(favorito), throwsException);
    });

    test('eliminarFavorito borra correctamente el documento', () async {
      await firestore.collection('favoritos').doc('fav3').set({
        'clienteId': 'c3',
        'emprendimientoId': 'e3',
      });

      await service.eliminarFavorito('fav3');

      final doc = await firestore.collection('favoritos').doc('fav3').get();
      expect(doc.exists, false);
    });

    test('obtenerFavoritosPorCliente devuelve los favoritos del cliente', () async {
      await firestore.collection('favoritos').add({
        'clienteId': 'clienteX',
        'emprendimientoId': 'e1',
      });

      await firestore.collection('favoritos').add({
        'clienteId': 'clienteX',
        'emprendimientoId': 'e2',
      });

      final stream = service.obtenerFavoritosPorCliente('clienteX');
      final result = await stream.first;

      expect(result.length, 2);
    });

    test('esFavorito devuelve true si el favorito existe', () async {
      await firestore.collection('favoritos').add({
        'clienteId': 'c10',
        'emprendimientoId': 'e10',
      });

      final result = await service.esFavorito('c10', 'e10');
      expect(result, true);
    });

    test('esFavorito devuelve false si el favorito no existe', () async {
      final result = await service.esFavorito('cX', 'eX');
      expect(result, false);
    });

    test('obtenerFavorito devuelve el favorito si existe', () async {
      await firestore.collection('favoritos').add({
        'clienteId': 'c20',
        'emprendimientoId': 'e20',
      });

      final favorito = await service.obtenerFavorito('c20', 'e20');
      expect(favorito, isNotNull);
      expect(favorito!.clienteId, 'c20');
    });

    test('obtenerFavorito devuelve null si no existe', () async {
      final favorito = await service.obtenerFavorito('cZ', 'eZ');
      expect(favorito, isNull);
    });
  });
}
