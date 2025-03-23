import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/domiciliario_model.dart';

class DomiciliarioService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> crearDomiciliario(Domiciliario domiciliario) async {
    if (domiciliario.nombre.isEmpty || domiciliario.email.isEmpty || domiciliario.codigo.isEmpty) {
      throw Exception('Domiciliario inválido');
    }
    await _db.collection('domiciliarios').doc(domiciliario.id).set(domiciliario.toMap());
  }

  Future<void> actualizarDomiciliario(Domiciliario domiciliario) async {
    if (domiciliario.nombre.isEmpty || domiciliario.email.isEmpty || domiciliario.codigo.isEmpty) {
      throw Exception('Domiciliario inválido');
    }
    await _db.collection('domiciliarios').doc(domiciliario.id).update(domiciliario.toMap());
  }

  Future<void> eliminarDomiciliario(String domiciliarioId) async {
    await _db.collection('domiciliarios').doc(domiciliarioId).delete();
  }

  Stream<List<Domiciliario>> obtenerDomiciliarios() {
    return _db.collection('domiciliarios')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Domiciliario.fromMap(doc.data(), doc.id))
            .toList());
  }

  Stream<List<Domiciliario>> obtenerDomiciliariosDisponibles() {
    return _db.collection('domiciliarios')
        .where('disponible', isEqualTo: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Domiciliario.fromMap(doc.data(), doc.id))
            .toList());
  }

  Future<void> cambiarDisponibilidad(String domiciliarioId) async {
    final doc = await _db.collection('domiciliarios').doc(domiciliarioId).get();
    if (doc.exists) {
      final actual = doc.data()!['disponible'] as bool? ?? false;
      await _db.collection('domiciliarios').doc(domiciliarioId).update({
        'disponible': !actual,
      });
    }
  }

  Future<Domiciliario?> obtenerDomiciliarioPorId(String id) async {
    final doc = await _db.collection('domiciliarios').doc(id).get();
    if (doc.exists) {
      return Domiciliario.fromMap(doc.data()!, doc.id);
    }
    return null;
  }
}
