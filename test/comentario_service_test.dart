import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:unimarket/models/comentario_model.dart';
import 'package:unimarket/services/comentario_service.dart';
import 'package:unimarket/models/producto_model.dart';

void main() {
  group('ComentarioService Tests', () {
    late FakeFirebaseFirestore firestore;
    late ComentarioService comentarioService;

    setUp(() {
      firestore = FakeFirebaseFirestore();
      comentarioService = ComentarioService(firestore);
    });

    test('crearComentario guarda correctamente el comentario y actualiza producto', () async {
      // Setup producto
      final producto = Producto(
        id: 'producto1',
        nombre: 'Producto Test',
        descripcion: 'desc',
        precio: 10000,
        imagenes: ['url'],
        emprendimientoId: 'emprendimiento1',
        rating: 0,
        comentarioIds: [],
      );
      await firestore.collection('productos').doc(producto.id).set(producto.toMap());

      final comentario = Comentario(
        id: 'comentario1',
        productoId: producto.id,
        clienteId: 'cliente1',
        texto: 'Buen producto',
        rating: 5,
      );

      await comentarioService.crearComentario(comentario);

      final doc = await firestore.collection('comentarios').doc(comentario.id).get();
      expect(doc.exists, true);

      final productoActualizado = await firestore.collection('productos').doc(producto.id).get();
      expect(productoActualizado.data()!['comentarioIds'], contains('comentario1'));
    });

    test('actualizarComentario modifica el comentario y actualiza rating del producto', () async {
      final comentario = Comentario(
        id: 'comentario2',
        productoId: 'producto2',
        clienteId: 'cliente2',
        texto: 'Muy bueno',
        rating: 4,
      );
      final producto = Producto(
        id: 'producto2',
        nombre: 'Prod 2',
        descripcion: 'desc',
        precio: 8000,
        imagenes: ['img'],
        emprendimientoId: 'emprendimiento2',
        rating: 0,
        comentarioIds: ['comentario2'],
      );
      await firestore.collection('productos').doc(producto.id).set(producto.toMap());
      await firestore.collection('comentarios').doc(comentario.id).set(comentario.toMap());

      final comentarioActualizado = Comentario(
        id: 'comentario2',
        productoId: 'producto2',
        clienteId: 'cliente2',
        texto: 'Cambió mi opinión',
        rating: 3,
      );

      await comentarioService.actualizarComentario(comentarioActualizado);

      final snapshot = await firestore.collection('comentarios').doc('comentario2').get();
      expect(snapshot.data()!['texto'], 'Cambió mi opinión');
    });

    test('eliminarComentario borra el comentario y lo remueve del producto', () async {
      final comentario = Comentario(
        id: 'comentario3',
        productoId: 'producto3',
        clienteId: 'cliente3',
        texto: 'Eliminarme',
        rating: 2,
      );
      final producto = Producto(
        id: 'producto3',
        nombre: 'Prod 3',
        descripcion: 'desc',
        precio: 5000,
        imagenes: ['img'],
        emprendimientoId: 'emprendimiento3',
        rating: 0,
        comentarioIds: ['comentario3'],
      );
      await firestore.collection('productos').doc(producto.id).set(producto.toMap());
      await firestore.collection('comentarios').doc(comentario.id).set(comentario.toMap());

      await comentarioService.eliminarComentario('comentario3', 'producto3');

      final snapshot = await firestore.collection('comentarios').doc('comentario3').get();
      expect(snapshot.exists, false);

      final productoFinal = await firestore.collection('productos').doc('producto3').get();
      expect(productoFinal.data()!['comentarioIds'], isNot(contains('comentario3')));
    });

    test('obtenerComentarioPorId retorna el comentario correcto', () async {
      final comentario = Comentario(
        id: 'comentario4',
        productoId: 'producto4',
        clienteId: 'cliente4',
        texto: 'Recomendado',
        rating: 5,
      );

      await firestore.collection('comentarios').doc(comentario.id).set(comentario.toMap());

      final result = await comentarioService.obtenerComentarioPorId(comentario.id);
      expect(result, isNotNull);
      expect(result!.texto, 'Recomendado');
    });

    test('obtenerComentariosDeProducto devuelve los comentarios asociados', () async {
      final comentario1 = Comentario(
        id: 'comentario5',
        productoId: 'producto5',
        clienteId: 'cliente5',
        texto: 'Comentario 1',
        rating: 4,
      );
      final comentario2 = Comentario(
        id: 'comentario6',
        productoId: 'producto5',
        clienteId: 'cliente6',
        texto: 'Comentario 2',
        rating: 3,
      );

      await firestore.collection('comentarios').doc(comentario1.id).set(comentario1.toMap());
      await firestore.collection('comentarios').doc(comentario2.id).set(comentario2.toMap());

      final stream = comentarioService.obtenerComentariosDeProducto('producto5');
      final result = await stream.first;

      expect(result.length, 2);
    });

    test('incrementarLikesComentario incrementa en 1 los likes', () async {
      final comentario = Comentario(
        id: 'comentario7',
        productoId: 'producto7',
        clienteId: 'cliente7',
        texto: 'Like',
        rating: 5,
        likes: 2,
      );

      await firestore.collection('comentarios').doc(comentario.id).set(comentario.toMap());

      await comentarioService.incrementarLikesComentario(comentario.id);

      final updated = await firestore.collection('comentarios').doc(comentario.id).get();
      expect(updated.data()!['likes'], 3);
    });

    test('decrementarLikesComentario disminuye en 1 los likes', () async {
      final comentario = Comentario(
        id: 'comentario8',
        productoId: 'producto8',
        clienteId: 'cliente8',
        texto: 'Unlike',
        rating: 2,
        likes: 1,
      );

      await firestore.collection('comentarios').doc(comentario.id).set(comentario.toMap());

      await comentarioService.decrementarLikesComentario(comentario.id);

      final updated = await firestore.collection('comentarios').doc(comentario.id).get();
      expect(updated.data()!['likes'], 0);
    });
  });
}
