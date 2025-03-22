
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:unimarket/models/domiciliario_model.dart';

class ClienteService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  Future<void> crearDomiciliario(Domiciliario domiciliario) async {
    if (domiciliario.nombre.isEmpty || domiciliario.email.isEmpty || domiciliario.codigo.isEmpty) {
      throw Exception('El domiciliario debe tener nombre, email y código.');
    }
    await _db.collection('domiciliarios').doc(domiciliario.id).set(domiciliario.toMap());
  }

  Future<void> actualizarDomiciliario(Domiciliario domiciliario) async {
    if (domiciliario.nombre.isEmpty || domiciliario.email.isEmpty || domiciliario.codigo.isEmpty) {
      throw Exception('El domiciliario debe tener nombre, email y código.');
    }
    await _db.collection('domiciliarios').doc(domiciliario.id).update(domiciliario.toMap());
  }

  Future<void> eliminarDomiciliario(String id) async {
    await _db.collection('domiciliarios').doc(id).delete();
  }

  Stream<List<Domiciliario>> obtenerDomiciliarios() {
    return _db.collection('domiciliarios').snapshots().map((snapshot) =>
      snapshot.docs.map((doc) => Domiciliario.fromMap(doc.data(), doc.id)).toList());
  }

  Future<Domiciliario?> obtenerDomiciliarioPorId(String id) async {
    final doc = await _db.collection('domiciliarios').doc(id).get();
    if (doc.exists) {
      return Domiciliario.fromMap(doc.data()!, doc.id);
    }
    return null;
  }
}