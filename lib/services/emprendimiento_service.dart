import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:unimarket/models/emprendimiento_model.dart';

class EmprendimientoService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String collectionPath = 'emprendimientos';

  Future<void> crearEmprendimiento(Emprendimiento emprendimiento) async {
    if (emprendimiento.nombre.isEmpty || emprendimiento.emprendedorId.isEmpty) {
      throw Exception('El emprendimiento debe tener nombre y emprendedor');
    }

    await _db.collection(collectionPath).doc(emprendimiento.id).set(emprendimiento.toMap());
  }

  Future<void> actualizarEmprendimiento(Emprendimiento emprendimiento) async {
    if (emprendimiento.nombre.isEmpty || emprendimiento.emprendedorId.isEmpty) {
      throw Exception('El emprendimiento debe tener nombre y emprendedor');
    }

    await _db.collection(collectionPath).doc(emprendimiento.id).update(emprendimiento.toMap());
  }

  Future<void> eliminarEmprendimiento(String id) async {
    await _db.collection(collectionPath).doc(id).delete();
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
}
