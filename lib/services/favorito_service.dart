
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/favorito_model.dart';

class FavoritoService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> agregarFavorito(Favorito favorito) async {
    if (favorito.clienteId.isEmpty || favorito.emprendedorId.isEmpty) {
      throw Exception('Favorito inválido');
    }
    await _db.collection('favoritos').doc(favorito.id).set(favorito.toMap());
  }

  Future<void> eliminarFavorito(String favoritoId) async {
    await _db.collection('favoritos').doc(favoritoId).delete();
  }

  Stream<List<Favorito>> obtenerFavoritosPorCliente(String clienteId) {
    return _db.collection('favoritos')
        .where('clienteId', isEqualTo: clienteId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Favorito.fromMap(doc.data(), doc.id))
            .toList());
  }

  Future<bool> esFavorito(String clienteId, String emprendedorId) async {
    final query = await _db.collection('favoritos')
        .where('clienteId', isEqualTo: clienteId)
        .where('emprendedorId', isEqualTo: emprendedorId)
        .get();

    return query.docs.isNotEmpty;
  }

  Future<Favorito?> obtenerFavorito(String clienteId, String emprendedorId) async {
    final query = await _db.collection('favoritos')
        .where('clienteId', isEqualTo: clienteId)
        .where('emprendedorId', isEqualTo: emprendedorId)
        .get();

    if (query.docs.isNotEmpty) {
      final doc = query.docs.first;
      return Favorito.fromMap(doc.data(), doc.id);
    }
    return null;
  }
}
