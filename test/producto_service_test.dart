import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:unimarket/models/producto_model.dart';
import 'package:unimarket/services/producto_service.dart';

void main() {
  group('ProductoService Tests', () {
    late FakeFirebaseFirestore firestore;
    late ProductoService productoService;

    setUp(() {
      firestore = FakeFirebaseFirestore();
      productoService = ProductoService(firestore);
    });

    test('crearProducto guarda el producto y actualiza el emprendimiento', () async {
      await firestore.collection('emprendimientos').doc('emp1').set({'productoIds': []});

      final producto = Producto(
        id: 'p1',
        nombre: 'Camiseta',
        descripcion: 'Camiseta cool',
        precio: 25000,
        imagenes: ['img1'],
        emprendimientoId: 'emp1',
        rating: 0,
        comentarioIds: [],
      );

      await productoService.crearProducto(producto);

      final doc = await firestore.collection('productos').doc('p1').get();
      expect(doc.exists, true);

      final emp = await firestore.collection('emprendimientos').doc('emp1').get();
      expect(emp.data()!['productoIds'], contains('p1'));
    });

    test('actualizarProducto actualiza datos y rating del emprendimiento', () async {
      await firestore.collection('emprendimientos').doc('emp2').set({'productoIds': []});
      final producto = Producto(
        id: 'p2',
        nombre: 'Sudadera',
        descripcion: 'desc',
        precio: 45000,
        imagenes: ['img2'],
        emprendimientoId: 'emp2',
        rating: 0,
        comentarioIds: [],
      );
      await firestore.collection('productos').doc('p2').set(producto.toMap());

      final actualizado = Producto(
        id: 'p2',
        nombre: 'Sudadera Cool',
        descripcion: 'actualizada',
        precio: 47000,
        imagenes: ['img2'],
        emprendimientoId: 'emp2',
        rating: 0,
        comentarioIds: [],
      );

      await productoService.actualizarProducto(actualizado);

      final doc = await firestore.collection('productos').doc('p2').get();
      expect(doc.data()!['nombre'], 'Sudadera Cool');
    });

    test('eliminarProducto borra comentarios y lo quita de carritos', () async {
      await firestore.collection('productos').doc('p3').set({
        'nombre': 'Producto X',
        'descripcion': '',
        'precio': 1000,
        'imagenes': ['img'],
        'rating': 0,
        'comentarioIds': ['c1', 'c2'],
        'emprendimientoId': 'emp3',
      });

      await firestore.collection('comentarios').doc('c1').set({'productoId': 'p3', 'clienteId': 'a', 'texto': 'x', 'rating': 3, 'fecha': '2024-01-01', 'likes': 0});
      await firestore.collection('comentarios').doc('c2').set({'productoId': 'p3', 'clienteId': 'a', 'texto': 'y', 'rating': 4, 'fecha': '2024-01-01', 'likes': 0});

      await firestore.collection('carritos').doc('car1').set({
        'clienteId': 'cliente1',
        'emprendedorId': 'emp3',
        'productoIds': ['p3'],
      });

      await productoService.eliminarProducto('p3');

      final doc = await firestore.collection('productos').doc('p3').get();
      expect(doc.exists, false);

      final comentarios = await firestore.collection('comentarios').get();
      expect(comentarios.docs.length, 0);

      final carrito = await firestore.collection('carritos').doc('car1').get();
      expect(carrito.data()!['productoIds'], isNot(contains('p3')));
    });

    test('obtenerProductoPorId retorna el producto esperado', () async {
      final producto = Producto(
        id: 'p4',
        nombre: 'Zapato',
        descripcion: 'desc',
        precio: 80000,
        imagenes: ['img'],
        emprendimientoId: 'emp4',
        rating: 0,
        comentarioIds: [],
      );

      await firestore.collection('productos').doc(producto.id).set(producto.toMap());

      final result = await productoService.obtenerProductoPorId(producto.id);
      expect(result, isNotNull);
      expect(result!.nombre, 'Zapato');
    });

    test('agregarImagenAProducto agrega correctamente', () async {
      await firestore.collection('productos').doc('p5').set({
        'imagenes': [],
      });

      await productoService.agregarImagenAProducto('p5', 'nueva.png');

      final doc = await firestore.collection('productos').doc('p5').get();
      expect(doc.data()!['imagenes'], contains('nueva.png'));
    });

    test('eliminarImagenDeProducto elimina correctamente', () async {
      await firestore.collection('productos').doc('p6').set({
        'imagenes': ['a.png', 'b.png'],
      });

      await productoService.eliminarImagenDeProducto('p6', 'a.png');

      final doc = await firestore.collection('productos').doc('p6').get();
      expect(doc.data()!['imagenes'], isNot(contains('a.png')));
    });

    test('actualizarDescripcionProducto cambia la descripción', () async {
      await firestore.collection('productos').doc('p7').set({
        'descripcion': 'desc vieja',
      });

      await productoService.actualizarDescripcionProducto('p7', 'desc nueva');

      final doc = await firestore.collection('productos').doc('p7').get();
      expect(doc.data()!['descripcion'], 'desc nueva');
    });

    test('actualizarPrecioProducto cambia el precio y actualiza emprendimiento', () async {
      await firestore.collection('emprendimientos').doc('emp8').set({});
      await firestore.collection('productos').doc('p8').set({
        'precio': 1000.0,
        'emprendimientoId': 'emp8',
        'imagenes': ['img'],
        'nombre': 'test',
        'descripcion': '',
        'comentarioIds': [],
        'rating': 0.0
      });

      await productoService.actualizarPrecioProducto('p8', 1200);

      final doc = await firestore.collection('productos').doc('p8').get();
      expect(doc.data()!['precio'], 1200);
    });

    test('actualizarRatingProducto calcula el promedio correctamente', () async {
      await firestore.collection('productos').doc('p9').set({'rating': 0.0});

      await firestore.collection('comentarios').add({
        'productoId': 'p9',
        'clienteId': 'a',
        'texto': 'b',
        'rating': 4,
        'fecha': '2024-01-01',
        'likes': 0,
      });
      await firestore.collection('comentarios').add({
        'productoId': 'p9',
        'clienteId': 'a',
        'texto': 'b',
        'rating': 5,
        'fecha': '2024-01-01',
        'likes': 0,
      });

      await productoService.actualizarRatingProducto('p9');

      final doc = await firestore.collection('productos').doc('p9').get();
      expect(doc.data()!['rating'], closeTo(4.5, 0.001));
    });

    test('obtenerProductosPorEmprendimiento devuelve lista correcta', () async {
      await firestore.collection('productos').add({
        'emprendimientoId': 'emp10',
        'nombre': 'Prod',
        'descripcion': '',
        'precio': 1000.0,
        'imagenes': ['img'],
        'rating': 0.0,
        'comentarioIds': []
      });

      final stream = productoService.obtenerProductosPorEmprendimiento('emp10');
      final result = await stream.first;

      expect(result.length, 1);
      expect(result.first.emprendimientoId, 'emp10');
    });

    test('obtenerTodosLosProductos devuelve todos los productos', () async {
      await firestore.collection('productos').add({
        'emprendimientoId': 'emp11',
        'nombre': 'Prod1',
        'descripcion': '',
        'precio': 3000.0,
        'imagenes': ['img'],
        'rating': 0.0,
        'comentarioIds': []
      });

      await firestore.collection('productos').add({
        'emprendimientoId': 'emp11',
        'nombre': 'Prod2',
        'descripcion': '',
        'precio': 4000.0,
        'imagenes': ['img'],
        'rating': 0.0,
        'comentarioIds': []
      });

      final stream = productoService.obtenerTodosLosProductos();
      final result = await stream.first;

      expect(result.length, 2);
    });
  });
}
