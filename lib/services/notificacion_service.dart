
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notificacion_model.dart';

class NotificacionService {
  final FirebaseFirestore _db;
  NotificacionService([FirebaseFirestore? firestore]) : _db = firestore ?? FirebaseFirestore.instance;


  Future<void> crearNotificacion(Notificacion notificacion) async {
    if (notificacion.id.isEmpty || notificacion.titulo.isEmpty || notificacion.mensaje.isEmpty) {
      throw Exception('Notificación inválida');
    }
    await _db.collection('notificaciones').doc(notificacion.id).set(notificacion.toMap());
  }

  Future<void> eliminarNotificacion(String notificacionId) async {
    await _db.collection('notificaciones').doc(notificacionId).delete();
  }

  Future<void> marcarComoLeida(String notificacionId) async {
    await _db.collection('notificaciones').doc(notificacionId).update({
      'leida': true,
    });
  }

  Stream<List<Notificacion>> obtenerNotificacionesPorCliente(String clienteId) {
    return _db.collection('notificaciones')
        .where('receptorId', isEqualTo: clienteId)
        .orderBy('fecha', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Notificacion.fromMap(doc.data(), doc.id))
            .toList());
  }
}
