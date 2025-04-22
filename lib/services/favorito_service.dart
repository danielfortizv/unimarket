
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/favorito_model.dart';

class FavoritoService {
  final FirebaseFirestore _db;
  FavoritoService([FirebaseFirestore? firestore]) : _db = firestore ?? FirebaseFirestore.instance;

Future<void> agregarFavorito(Favorito favorito) async {
  if (favorito.clienteId.isEmpty || favorito.emprendimientoId.isEmpty) {
    throw Exception('Favorito inválido');
  }

  final docRef = _db.collection('favoritos').doc(); // 🔧 genera un ID único
  favorito.id = docRef.id; // 🔄 actualiza el modelo antes de guardarlo
  await docRef.set(favorito.toMap());
}


  Future<void> eliminarFavorito(String favoritoId) async {
    await _db.collection('favoritos').doc(favoritoId).delete();
  }

  Future<List<String>> obtenerIdsFavoritosPorCliente(String clienteId) async {
    final query = await _db
        .collection('favoritos')
        .where('clienteId', isEqualTo: clienteId)
        .get();

    return query.docs.map((doc) => doc['emprendimientoId'].toString()).toList();
  }


  Future<bool> esFavorito(String clienteId, String emprendimientoId) async {
    final query = await _db.collection('favoritos')
        .where('clienteId', isEqualTo: clienteId)
        .where('emprendimientoId', isEqualTo: emprendimientoId)
        .get();

    return query.docs.isNotEmpty;
  }

  Future<Favorito?> obtenerFavorito(String clienteId, String emprendimientoId) async {
    final query = await _db.collection('favoritos')
        .where('clienteId', isEqualTo: clienteId)
        .where('emprendimientoId', isEqualTo: emprendimientoId)
        .get();

    if (query.docs.isNotEmpty) {
      final doc = query.docs.first;
      return Favorito.fromMap(doc.data(), doc.id);
    }
    return null;
  }
}
