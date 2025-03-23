import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:unimarket/services/producto_service.dart';
import '../models/comentario_model.dart';

class ComentarioService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final ProductoService _productoService = ProductoService();

  Future<void> crearComentario(Comentario comentario) async {
    if (comentario.productoId.isEmpty || comentario.clienteId.isEmpty || comentario.texto.isEmpty || comentario.rating < 0 || comentario.rating > 5) {
      throw Exception('Comentario inválido');
    }

    final docRef = _db.collection('comentarios').doc(comentario.id);
    await docRef.set(comentario.toMap());

    // Actualizar lista de comentarios en el producto
    await _db.collection('productos').doc(comentario.productoId).update({
      'comentarioIds': FieldValue.arrayUnion([comentario.id])
    });

    // Actualizar rating del producto
    await _productoService.actualizarRatingProducto(comentario.productoId);
  }

  Future<void> actualizarComentario(Comentario comentario) async {
    if (comentario.productoId.isEmpty || comentario.clienteId.isEmpty || comentario.texto.isEmpty || comentario.rating < 0 || comentario.rating > 5) {
      throw Exception('Comentario inválido');
    }

    await _db.collection('comentarios').doc(comentario.id).update(comentario.toMap());
    await _productoService.actualizarRatingProducto(comentario.productoId);
  }

  Future<void> eliminarComentario(String comentarioId, String productoId) async {
    await _db.collection('comentarios').doc(comentarioId).delete();

    // Remover el comentario de la lista del producto
    await _db.collection('productos').doc(productoId).update({
      'comentarioIds': FieldValue.arrayRemove([comentarioId])
    });
  }

  Future<Comentario?> obtenerComentarioPorId(String id) async {
    final doc = await _db.collection('comentarios').doc(id).get();
    if (doc.exists) {
      return Comentario.fromMap(doc.data()!, doc.id);
    }
    return null;
  }

  Stream<List<Comentario>> obtenerComentariosDeProducto(String productoId) {
    return _db
        .collection('comentarios')
        .where('productoId', isEqualTo: productoId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Comentario.fromMap(doc.data(), doc.id))
            .toList());
  }

  Future<void> incrementarLikesComentario(String comentarioId) async {
    await _db.collection('comentarios').doc(comentarioId).update({
      'likes': FieldValue.increment(1),
    });
  }

  Future<void> decrementarLikesComentario(String comentarioId) async {
    await _db.collection('comentarios').doc(comentarioId).update({
      'likes': FieldValue.increment(-1),
    });
  }

}