import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:unimarket/models/producto_model.dart';
import 'package:unimarket/services/comentario_service.dart';
import 'package:unimarket/services/emprendimiento_service.dart';
import 'package:unimarket/services/carrito_mercado_service.dart';

class ProductoService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  late final CollectionReference productosCollection = _db.collection('productos');
  final ComentarioService _comentarioService = ComentarioService();
  final EmprendimientoService _emprendimientoService = EmprendimientoService();
  final CarritoService _carritoService = CarritoService();

  Future<void> crearProducto(Producto producto) async {
    if (producto.nombre.isEmpty || producto.precio <= 0 || producto.imagenes.isEmpty || producto.emprendimientoId.isEmpty) {
      throw Exception('El producto debe tener nombre, precio, al menos una imagen y un emprendimiento.');
    }
    await productosCollection.doc(producto.id).set(producto.toMap());

    // Asociar producto al emprendimiento
    await _db.collection('emprendimientos').doc(producto.emprendimientoId).update({
      'productoIds': FieldValue.arrayUnion([producto.id])
    });
    await _emprendimientoService.actualizarRatingEmprendimiento(producto.emprendimientoId);
    await _emprendimientoService.actualizarRangoPrecios(producto.emprendimientoId);
  }

  Future<void> actualizarProducto(Producto producto) async {
    if (producto.nombre.isEmpty || producto.precio <= 0 || producto.imagenes.isEmpty || producto.emprendimientoId.isEmpty) {
      throw Exception('El producto debe tener nombre, precio, al menos una imagen y un emprendimiento.');
    }
    await productosCollection.doc(producto.id).update(producto.toMap());
    await _emprendimientoService.actualizarRatingEmprendimiento(producto.emprendimientoId);
    await _emprendimientoService.actualizarRangoPrecios(producto.emprendimientoId);
  }

  Future<void> eliminarProducto(String productoId) async {
    final productoDoc = await _db.collection('productos').doc(productoId).get();
    if (!productoDoc.exists) return;

    final productoData = productoDoc.data()!;
    final comentarioIds = List<String>.from(productoData['comentarioIds'] ?? []);

    for (final comentarioId in comentarioIds) {
      await _comentarioService.eliminarComentario(comentarioId, productoId);
    }

    final carritosSnapshot = await _db.collection('carritos').get();
    for (final carritoDoc in carritosSnapshot.docs) {
      final carritoData = carritoDoc.data();
      final productos = List<String>.from(carritoData['productoIds'] ?? []);
      if (productos.contains(productoId)) {
        await _carritoService.eliminarProductoDelCarritoDeMercado(carritoDoc.id, productoId);
      }
    }

    await _db.collection('productos').doc(productoId).delete();
  }


  Stream<List<Producto>> obtenerProductosPorEmprendimiento(String emprendimientoId) {
    return productosCollection
        .where('emprendimientoId', isEqualTo: emprendimientoId)
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

  Future<void> agregarImagenAProducto(String productoId, String nuevaImagenUrl) async {
    await _db.collection('productos').doc(productoId).update({
      'imagenes': FieldValue.arrayUnion([nuevaImagenUrl]),
    });
  }

  Future<void> actualizarDescripcionProducto(String productoId, String nuevaDescripcion) async {
    await _db.collection('productos').doc(productoId).update({
      'descripcion': nuevaDescripcion,
    });
  }

  Future<void> actualizarPrecioProducto(String productoId, double nuevoPrecio) async {
    if (nuevoPrecio <= 0) {
      throw Exception('El precio debe ser mayor a 0');
    }

    await _db.collection('productos').doc(productoId).update({
      'precio': nuevoPrecio,
    });
    final producto = await obtenerProductoPorId(productoId);
    if (producto != null) {
      await _emprendimientoService.actualizarRangoPrecios(producto.emprendimientoId);
    }
  }

  Future<void> actualizarRatingProducto(String productoId) async {
    final comentariosSnapshot = await _db.collection('comentarios')
      .where('productoId', isEqualTo: productoId).get();

    final ratings = comentariosSnapshot.docs.map((doc) => (doc['rating'] as num).toDouble()).toList();

    if (ratings.isNotEmpty) {
      final promedio = ratings.reduce((a, b) => a + b) / ratings.length;
      await _db.collection('productos').doc(productoId).update({
        'rating': promedio,
      });
    }
  }

  Future<void> eliminarImagenDeProducto(String productoId, String imageUrl) async {
    await _db.collection('productos').doc(productoId).update({
      'imagenes': FieldValue.arrayRemove([imageUrl])
    });
  }

} 
