import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:unimarket/models/emprendedor.dart';


class EmprendedorService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> crearEmprendedor(Emprendedor emprendedor) async {
    if (emprendedor.nombre.isEmpty || emprendedor.email.isEmpty || emprendedor.codigo.isEmpty) {
      throw Exception('El emprendedor debe tener nombre, email y código.');
    }
    await _db.collection('emprendedores').doc(emprendedor.id).set(emprendedor.toMap());
  }

  Future<void> actualizarEmprendedor(Emprendedor emprendedor) async {
    if (emprendedor.nombre.isEmpty || emprendedor.email.isEmpty || emprendedor.codigo.isEmpty) {
      throw Exception('El emprendedor debe tener nombre, email y código.');
    }
    await _db.collection('emprendedores').doc(emprendedor.id).update(emprendedor.toMap());
  }

  Future<void> eliminarEmprendedor(String id) async {
    await _db.collection('emprendedores').doc(id).delete();
  }

  Stream<List<Emprendedor>> obtenerEmprendedores() {
    return _db.collection('emprendedores').snapshots().map((snapshot) =>
      snapshot.docs.map((doc) => Emprendedor.fromMap(doc.data(), doc.id)).toList());
  }

  Future<Emprendedor?> obtenerEmprendedorPorId(String id) async {
    final doc = await _db.collection('emprendedores').doc(id).get();
    if (doc.exists) {
      return Emprendedor.fromMap(doc.data()!, doc.id);
    }
    return null;
  }
}