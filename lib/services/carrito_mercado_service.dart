
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/carrito_mercado_model.dart';

class CarritoService {
  final FirebaseFirestore _db;
  CarritoService([FirebaseFirestore? firestore]) : _db = firestore ?? FirebaseFirestore.instance;

  Future<void> crearCarrito(CarritoDeMercado carrito) async {
    if (carrito.clienteId.isEmpty || carrito.emprendedorId.isEmpty) {
      throw Exception('El carrito debe tener un cliente y un emprendedor');
    }
    await _db.collection('carritos').doc(carrito.id).set(carrito.toMap());
  }

  Future<void> actualizarCarrito(CarritoDeMercado carrito) async {
    if (carrito.clienteId.isEmpty || carrito.emprendedorId.isEmpty) {
      throw Exception('El carrito debe tener un cliente y un emprendedor');
    }
    await _db.collection('carritos').doc(carrito.id).update(carrito.toMap());
  }

  Future<void> eliminarCarrito(String carritoId) async {
    await _db.collection('carritos').doc(carritoId).delete();
  }

  Future<void> eliminarProductoDelCarritoDeMercado(String carritoId, String productoId) async {
    await _db.collection('carritos').doc(carritoId).update({
      'productoIds': FieldValue.arrayRemove([productoId])
    });
  }

  Future<void> agregarProductoAlCarrito(String carritoId, String productoId) async {
    await _db.collection('carritos').doc(carritoId).update({
      'productoIds': FieldValue.arrayUnion([productoId])
    });
  }

  Stream<List<CarritoDeMercado>> obtenerCarritosPorCliente(String clienteId) {
    return _db.collection('carritos')
        .where('clienteId', isEqualTo: clienteId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => CarritoDeMercado.fromMap(doc.data(), doc.id))
            .toList());
  }

  Future<CarritoDeMercado?> obtenerCarritoPorId(String id) async {
    final doc = await _db.collection('carritos').doc(id).get();
    if (doc.exists) {
      return CarritoDeMercado.fromMap(doc.data()!, doc.id);
    }
    return null;
  }
}
