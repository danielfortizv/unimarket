import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/carrito_mercado_model.dart';

class CarritoService {
  final FirebaseFirestore _db;
  CarritoService([FirebaseFirestore? firestore]) : _db = firestore ?? FirebaseFirestore.instance;

  Future<CarritoDeMercado> crearCarrito(CarritoDeMercado carrito) async {
    if (carrito.clienteId.isEmpty || carrito.emprendedorId.isEmpty) {
      throw Exception('El carrito debe tener un cliente y un emprendedor');
    }
    
    // Si el carrito no tiene ID, crear uno nuevo
    DocumentReference docRef;
    if (carrito.id.isEmpty) {
      docRef = _db.collection('carritos').doc();
    } else {
      docRef = _db.collection('carritos').doc(carrito.id);
    }
    
    final carritoConId = CarritoDeMercado(
      id: docRef.id,
      clienteId: carrito.clienteId,
      emprendedorId: carrito.emprendedorId,
      productoIds: carrito.productoIds,
    );
    
    await docRef.set(carritoConId.toMap());
    return carritoConId;
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