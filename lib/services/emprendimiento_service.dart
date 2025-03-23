import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:unimarket/models/emprendimiento_model.dart';
import 'package:unimarket/services/favorito_service.dart';
import 'package:unimarket/services/producto_service.dart';

class EmprendimientoService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String collectionPath = 'emprendimientos';
  final ProductoService _productoService = ProductoService();
  final FavoritoService _favoritoService = FavoritoService();

  Future<void> crearEmprendimiento(Emprendimiento emprendimiento) async {
    if (emprendimiento.nombre.isEmpty || emprendimiento.emprendedorId.isEmpty) {
      throw Exception('El emprendimiento debe tener nombre y emprendedor');
    }

    await _db.collection('emprendimientos').doc(emprendimiento.id).set(emprendimiento.toMap());

    // Asociar emprendimiento al emprendedor
    await _db.collection('emprendedores').doc(emprendimiento.emprendedorId).update({
      'emprendimientoIds': FieldValue.arrayUnion([emprendimiento.id])
    });
  }

  Future<void> actualizarEmprendimiento(Emprendimiento emprendimiento) async {
    if (emprendimiento.nombre.isEmpty || emprendimiento.emprendedorId.isEmpty) {
      throw Exception('El emprendimiento debe tener nombre y emprendedor');
    }

    await _db.collection(collectionPath).doc(emprendimiento.id).update(emprendimiento.toMap());
  }

  Future<void> eliminarEmprendimiento(String emprendimientoId) async {
    final productosSnapshot = await _db.collection('productos')
      .where('emprendimientoId', isEqualTo: emprendimientoId).get();

    for (final doc in productosSnapshot.docs) {
      await _productoService.eliminarProducto(doc.id);
    }

    final favoritosSnapshot = await _db.collection('favoritos')
      .where('emprendedorId', isEqualTo: emprendimientoId).get();

    for (final doc in favoritosSnapshot.docs) {
      await _favoritoService.eliminarFavorito(doc.id);
    }

    await _db.collection('emprendimientos').doc(emprendimientoId).delete();
  }

  Stream<List<Emprendimiento>> obtenerTodos() {
    return _db.collection(collectionPath).snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => Emprendimiento.fromMap(doc.data(), doc.id)).toList());
  }

  Future<Emprendimiento?> obtenerPorId(String id) async {
    final doc = await _db.collection(collectionPath).doc(id).get();
    if (doc.exists) {
      return Emprendimiento.fromMap(doc.data()!, doc.id);
    }
    return null;
  }

  Stream<List<Emprendimiento>> obtenerPorEmprendedor(String emprendedorId) {
    return _db
        .collection(collectionPath)
        .where('emprendedorId', isEqualTo: emprendedorId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Emprendimiento.fromMap(doc.data(), doc.id))
            .toList());
  }

  Future<void> actualizarRangoPrecios(String emprendimientoId) async {
    final productosSnapshot = await _db.collection('productos')
      .where('emprendimientoId', isEqualTo: emprendimientoId).get();

    final precios = productosSnapshot.docs.map((doc) => (doc['precio'] as num).toDouble()).toList();

    if (precios.isNotEmpty) {
      final min = precios.reduce((a, b) => a < b ? a : b);
      final max = precios.reduce((a, b) => a > b ? a : b);

      final rango = '\$${min.toStringAsFixed(0)} - \$${max.toStringAsFixed(0)}';

      await _db.collection('emprendimientos').doc(emprendimientoId).update({
        'rangoPrecios': rango,
      });
    }
  }

  Future<void> actualizarRatingEmprendimiento(String emprendimientoId) async {
    final productosSnapshot = await _db.collection('productos')
      .where('emprendimientoId', isEqualTo: emprendimientoId).get();

    final ratings = productosSnapshot.docs
        .map((doc) => (doc.data()['rating'] as num?)?.toDouble())
        .where((r) => r != null && r > 0)
        .toList();

    if (ratings.isNotEmpty) {
      final promedio = ratings.reduce((a, b) => a! + b!)! / ratings.length;
      await _db.collection('emprendimientos').doc(emprendimientoId).update({
        'rating': promedio,
      });
    } else {
      await _db.collection('emprendimientos').doc(emprendimientoId).update({
        'rating': null,
      });
    }
  }

  Future<void> actualizarNombre(String emprendimientoId, String nuevoNombre) async {
    await _db.collection('emprendimientos').doc(emprendimientoId).update({
      'nombre': nuevoNombre,
    });
  }

  Future<void> actualizarDescripcion(String emprendimientoId, String nuevaDescripcion) async {
    await _db.collection('emprendimientos').doc(emprendimientoId).update({
      'descripcion': nuevaDescripcion,
    });
  }

  Future<void> agregarImagenAEmprendimiento(String emprendimientoId, String imageUrl) async {
    await _db.collection('emprendimientos').doc(emprendimientoId).update({
      'imagenes': FieldValue.arrayUnion([imageUrl])
    });
  }

  Future<void> agregarPreguntaFrecuente(String emprendimientoId, String pregunta) async {
    await _db.collection('emprendimientos').doc(emprendimientoId).update({
      'preguntasFrecuentes': FieldValue.arrayUnion([pregunta])
    });
  }

  Future<void> eliminarImagenDeEmprendimiento(String emprendimientoId, String imageUrl) async {
    await _db.collection('emprendimientos').doc(emprendimientoId).update({
      'imagenes': FieldValue.arrayRemove([imageUrl])
    });
  }
}
