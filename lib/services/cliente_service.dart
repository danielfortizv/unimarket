import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:unimarket/models/cliente_model.dart';

class ClienteService {
  final FirebaseFirestore _db;
  ClienteService([FirebaseFirestore? firestore]) : _db = firestore ?? FirebaseFirestore.instance;

  Future<void> crearCliente(Cliente cliente) async {
    if (cliente.nombre.isEmpty || cliente.email.isEmpty || cliente.codigo.isEmpty) {
      throw Exception('El cliente debe tener nombre, email y código.');
    }
    await _db.collection('clientes').doc(cliente.id).set(cliente.toMap());
  }

  Future<void> actualizarCliente(Cliente cliente) async {
    if (cliente.nombre.isEmpty || cliente.email.isEmpty || cliente.codigo.isEmpty) {
      throw Exception('El cliente debe tener nombre, email y código.');
    }
    await _db.collection('clientes').doc(cliente.id).update(cliente.toMap());
  }

  Future<void> eliminarCliente(String id) async {
    await _db.collection('clientes').doc(id).delete();
  }

  Stream<List<Cliente>> obtenerClientes() {
    return _db.collection('clientes').snapshots().map((snapshot) =>
      snapshot.docs.map((doc) => Cliente.fromMap(doc.data(), doc.id)).toList());
  }

  Future<Cliente?> obtenerClientePorId(String id) async {
    final doc = await _db.collection('clientes').doc(id).get();
    if (doc.exists) {
      return Cliente.fromMap(doc.data()!, doc.id);
    }
    return null;
  }

}