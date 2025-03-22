import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:unimarket/models/producto_model.dart';

class ProductoService {
  final CollectionReference productosCollection = FirebaseFirestore.instance.collection('productos');

  Future<void> crearProducto(Producto producto) async {
    if (producto.nombre.isEmpty || producto.precio <= 0 || producto.imagenes.isEmpty || producto.emprendedorId.isEmpty) {
      throw Exception('El producto debe tener nombre, precio, al menos una imagen y emprendedor.');
    }
    await productosCollection.doc(producto.id).set(producto.toMap());
  }

  Future<void> actualizarProducto(Producto producto) async {
    if (producto.nombre.isEmpty || producto.precio <= 0 || producto.imagenes.isEmpty || producto.emprendedorId.isEmpty) {
      throw Exception('El producto debe tener nombre, precio, al menos una imagen y emprendedor.');
    }
    await productosCollection.doc(producto.id).update(producto.toMap());
  }

  Future<void> eliminarProducto(String productoId) async {
    await productosCollection.doc(productoId).delete();
  }

  Stream<List<Producto>> obtenerProductosPorEmprendedor(String emprendedorId) {
    return productosCollection
        .where('emprendedorId', isEqualTo: emprendedorId)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Producto.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList());
  }

  Stream<List<Producto>> obtenerTodosLosProductos() {
    return productosCollection.snapshots().map(
      (snapshot) => snapshot.docs.map((doc) => Producto.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList(),
    );
  }

  Future<Producto?> obtenerProductoPorId(String productoId) async {
    final doc = await productosCollection.doc(productoId).get();
    if (doc.exists) {
      return Producto.fromMap(doc.data() as Map<String, dynamic>, doc.id);
    } else {
      return null;
    }
  }
} 
