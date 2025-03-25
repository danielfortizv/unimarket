
import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:unimarket/services/carrito_mercado_service.dart';
import 'package:unimarket/models/carrito_mercado_model.dart';

void main() {
  group('CarritoMercadoService', () {
    late FakeFirebaseFirestore firestore;
    late CarritoService service;

    setUp(() {
      firestore = FakeFirebaseFirestore();
      service = CarritoService(firestore);
    });

    test('crearCarritoDeMercado agrega correctamente el carrito', () async {
      final carrito = CarritoDeMercado(
        id: 'carrito1',
        clienteId: 'cliente1',
        emprendedorId: 'emprendedor1',
        productoIds: ['producto1', 'producto2'],
      );

      await service.crearCarrito(carrito);

      final snapshot = await firestore.collection('carritos').doc(carrito.id).get();

      expect(snapshot.exists, true);
      expect(snapshot.data()!['clienteId'], 'cliente1');
      expect(snapshot.data()!['productoIds'], contains('producto1'));
    });

    test('actualizarCarrito actualiza correctamente los datos del carrito', () async {
      final carrito = CarritoDeMercado(
        id: 'carrito2',
        clienteId: 'cliente2',
        emprendedorId: 'emprendedor2',
        productoIds: ['producto3'],
      );

      await firestore.collection('carritos').doc(carrito.id).set(carrito.toMap());

      final updatedCarrito = CarritoDeMercado(
        id: 'carrito2',
        clienteId: 'cliente2',
        emprendedorId: 'emprendedor2',
        productoIds: ['producto4'],
      );

      await service.actualizarCarrito(updatedCarrito);

      final snapshot = await firestore.collection('carritos').doc(carrito.id).get();
      expect(snapshot.data()!['productoIds'], contains('producto4'));
    });

    test('eliminarCarrito elimina correctamente el documento', () async {
      final carrito = CarritoDeMercado(
        id: 'carrito3',
        clienteId: 'cliente3',
        emprendedorId: 'emprendedor3',
        productoIds: [],
      );

      await firestore.collection('carritos').doc(carrito.id).set(carrito.toMap());

      await service.eliminarCarrito(carrito.id);

      final snapshot = await firestore.collection('carritos').doc(carrito.id).get();
      expect(snapshot.exists, false);
    });

    test('agregarProductoAlCarrito agrega un producto al array', () async {
      final carrito = CarritoDeMercado(
        id: 'carrito4',
        clienteId: 'cliente4',
        emprendedorId: 'emprendedor4',
        productoIds: [],
      );

      await firestore.collection('carritos').doc(carrito.id).set(carrito.toMap());

      await service.agregarProductoAlCarrito(carrito.id, 'producto5');

      final snapshot = await firestore.collection('carritos').doc(carrito.id).get();
      expect(snapshot.data()!['productoIds'], contains('producto5'));
    });

    test('eliminarProductoDelCarritoDeMercado elimina un producto del array', () async {
      final carrito = CarritoDeMercado(
        id: 'carrito5',
        clienteId: 'cliente5',
        emprendedorId: 'emprendedor5',
        productoIds: ['producto6'],
      );

      await firestore.collection('carritos').doc(carrito.id).set(carrito.toMap());

      await service.eliminarProductoDelCarritoDeMercado(carrito.id, 'producto6');

      final snapshot = await firestore.collection('carritos').doc(carrito.id).get();
      expect(snapshot.data()!['productoIds'], isNot(contains('producto6')));
    });

    test('obtenerCarritoPorId devuelve el carrito correcto', () async {
      final carrito = CarritoDeMercado(
        id: 'carrito6',
        clienteId: 'cliente6',
        emprendedorId: 'emprendedor6',
        productoIds: ['producto7'],
      );

      await firestore.collection('carritos').doc(carrito.id).set(carrito.toMap());

      final result = await service.obtenerCarritoPorId(carrito.id);
      expect(result, isNotNull);
      expect(result!.clienteId, 'cliente6');
    });

    test('obtenerCarritosPorCliente devuelve la lista correcta', () async {
      final carrito1 = CarritoDeMercado(
        id: 'carrito7',
        clienteId: 'cliente7',
        emprendedorId: 'emprendedor7',
        productoIds: ['producto8'],
      );

      final carrito2 = CarritoDeMercado(
        id: 'carrito8',
        clienteId: 'cliente7',
        emprendedorId: 'emprendedor8',
        productoIds: ['producto9'],
      );

      await firestore.collection('carritos').doc(carrito1.id).set(carrito1.toMap());
      await firestore.collection('carritos').doc(carrito2.id).set(carrito2.toMap());

      final stream = service.obtenerCarritosPorCliente('cliente7');
      final result = await stream.first;

      expect(result.length, 2);
    });
  });
}
