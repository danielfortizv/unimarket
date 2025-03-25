import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:unimarket/models/emprendimiento_model.dart';
import 'package:unimarket/services/emprendimiento_service.dart';
import 'package:unimarket/services/producto_service.dart';

void main() {
  group('EmprendimientoService Tests', () {
    late FakeFirebaseFirestore firestore;
    late ProductoService productoService;
    late EmprendimientoService service;

    setUp(() {
      firestore = FakeFirebaseFirestore();
      productoService = ProductoService(firestore);
      service = EmprendimientoService(firestore, productoService);
    });

    test('crearEmprendimiento crea documento y actualiza emprendedor', () async {
      await firestore.collection('emprendedores').doc('emp1').set({'emprendimientoIds': []});

      final emp = Emprendimiento(
        id: 'e1',
        nombre: 'Café U',
        descripcion: 'Café artesanal',
        productoIds: [],
        rangoPrecios: '',
        rating: 0,
        preguntasFrecuentes: [],
        emprendedorId: 'emp1',
        imagenes: [],
      );

      await service.crearEmprendimiento(emp);

      final doc = await firestore.collection('emprendimientos').doc('e1').get();
      expect(doc.exists, true);

      final empDoc = await firestore.collection('emprendedores').doc('emp1').get();
      expect(empDoc.data()!['emprendimientoIds'], contains('e1'));
    });

    test('actualizarEmprendimiento modifica correctamente los datos', () async {
      final emp = Emprendimiento(
        id: 'e2',
        nombre: 'Ropa U',
        descripcion: 'Ropa casual',
        productoIds: [],
        rangoPrecios: '',
        rating: 0,
        preguntasFrecuentes: [],
        emprendedorId: 'emp2',
        imagenes: [],
      );
      await firestore.collection('emprendimientos').doc(emp.id).set(emp.toMap());

      final actualizado = Emprendimiento(
        id: 'e2',
        nombre: 'Ropa Universitaria',
        descripcion: 'Ropa con estilo',
        productoIds: [],
        rangoPrecios: '',
        rating: 0,
        preguntasFrecuentes: [],
        emprendedorId: 'emp2',
        imagenes: [],
      );

      await service.actualizarEmprendimiento(actualizado);

      final snapshot = await firestore.collection('emprendimientos').doc('e2').get();
      expect(snapshot.data()!['nombre'], 'Ropa Universitaria');
    });

    test('eliminarEmprendimiento borra productos, favoritos y el documento', () async {
      await firestore.collection('productos').add({
        'emprendimientoId': 'e3',
        'nombre': 'Producto',
        'descripcion': '',
        'precio': 1000,
        'imagenes': ['img'],
        'rating': 0,
        'comentarioIds': [],
      });

      await firestore.collection('favoritos').add({
        'clienteId': 'c1',
        'emprendimientoId': 'e3',
      });

      await firestore.collection('emprendimientos').doc('e3').set({
        'nombre': 'Test',
        'descripcion': '',
        'productoIds': [],
        'rangoPrecios': '',
        'rating': 0,
        'preguntasFrecuentes': [],
        'emprendedorId': '',
        'imagenes': [],
      });

      await service.eliminarEmprendimiento('e3');
      
      final doc = await firestore.collection('emprendimientos').doc('e3').get();
      expect(doc.exists, false);

      final productos = await firestore.collection('productos').get();
      expect(productos.docs.length, 0);

      final favoritos = await firestore.collection('favoritos').get();
      expect(favoritos.docs.length, 0);
    });

    test('obtenerTodos retorna la lista de emprendimientos', () async {
      await firestore.collection('emprendimientos').doc('e4').set({
        'nombre': 'E1',
        'descripcion': '',
        'productoIds': [],
        'rangoPrecios': '',
        'rating': 0,
        'preguntasFrecuentes': [],
        'emprendedorId': 'emp',
        'imagenes': [],
      });

      final stream = service.obtenerTodos();
      final result = await stream.first;
      expect(result.length, 1);
    });

    test('actualizarRangoPrecios calcula el rango correctamente', () async {
      await firestore.collection('emprendimientos').doc('e5').set({
        'nombre': 'Rango Test',
        'descripcion': '',
        'productoIds': [],
        'rangoPrecios': '',
        'rating': 0,
        'preguntasFrecuentes': [],
        'emprendedorId': 'emp',
        'imagenes': [],
      });

      await firestore.collection('productos').add({
        'emprendimientoId': 'e5',
        'nombre': 'Prod1',
        'descripcion': '',
        'precio': 10000,
        'imagenes': ['img'],
        'rating': 0,
        'comentarioIds': [],
      });

      await firestore.collection('productos').add({
        'emprendimientoId': 'e5',
        'nombre': 'Prod2',
        'descripcion': '',
        'precio': 20000,
        'imagenes': ['img'],
        'rating': 0,
        'comentarioIds': [],
      });

      await service.actualizarRangoPrecios('e5');

      final doc = await firestore.collection('emprendimientos').doc('e5').get();
      expect(doc.data()!['rangoPrecios'], '\$10000 - \$20000');
    });

    test('actualizarRatingEmprendimiento calcula el promedio correctamente', () async {
      await firestore.collection('emprendimientos').doc('e6').set({
        'nombre': 'Rating Test',
        'descripcion': '',
        'productoIds': [],
        'rangoPrecios': '',
        'rating': 0,
        'preguntasFrecuentes': [],
        'emprendedorId': 'emp',
        'imagenes': [],
      });

      await firestore.collection('productos').add({
        'emprendimientoId': 'e6',
        'nombre': 'Prod1',
        'descripcion': '',
        'precio': 0,
        'imagenes': ['img'],
        'rating': 4.0,
        'comentarioIds': [],
      });

      await firestore.collection('productos').add({
        'emprendimientoId': 'e6',
        'nombre': 'Prod2',
        'descripcion': '',
        'precio': 0,
        'imagenes': ['img'],
        'rating': 5.0,
        'comentarioIds': [],
      });

      await service.actualizarRatingEmprendimiento('e6');

      final doc = await firestore.collection('emprendimientos').doc('e6').get();
      expect(doc.data()!['rating'], closeTo(4.5, 0.001));
    });

    test('agregarImagenAEmprendimiento y eliminarImagen funcionan', () async {
      await firestore.collection('emprendimientos').doc('e7').set({
        'nombre': 'Multimedia',
        'descripcion': '',
        'productoIds': [],
        'rangoPrecios': '',
        'rating': 0,
        'preguntasFrecuentes': [],
        'emprendedorId': 'emp',
        'imagenes': [],
      });

      await service.agregarImagenAEmprendimiento('e7', 'img1');
      var doc = await firestore.collection('emprendimientos').doc('e7').get();
      expect(doc.data()!['imagenes'], contains('img1'));

      await service.eliminarImagenDeEmprendimiento('e7', 'img1');
      doc = await firestore.collection('emprendimientos').doc('e7').get();
      expect(doc.data()!['imagenes'], isNot(contains('img1')));
    });

    test('agregarPreguntaFrecuente agrega correctamente una pregunta', () async {
      await firestore.collection('emprendimientos').doc('e8').set({
        'nombre': 'FAQ Test',
        'descripcion': '',
        'productoIds': [],
        'rangoPrecios': '',
        'rating': 0,
        'preguntasFrecuentes': [],
        'emprendedorId': 'emp',
        'imagenes': [],
      });

      await service.agregarPreguntaFrecuente('e8', '¿Aceptan tarjeta?');
      final doc = await firestore.collection('emprendimientos').doc('e8').get();
      expect(doc.data()!['preguntasFrecuentes'], contains('¿Aceptan tarjeta?'));
    });

    test('actualizarNombre y actualizarDescripcion funcionan', () async {
      await firestore.collection('emprendimientos').doc('e9').set({
        'nombre': 'Antiguo',
        'descripcion': 'Viejo desc',
        'productoIds': [],
        'rangoPrecios': '',
        'rating': 0,
        'preguntasFrecuentes': [],
        'emprendedorId': 'emp',
        'imagenes': [],
      });

      await service.actualizarNombre('e9', 'Nuevo Nombre');
      await service.actualizarDescripcion('e9', 'Nueva descripción');

      final doc = await firestore.collection('emprendimientos').doc('e9').get();
      expect(doc.data()!['nombre'], 'Nuevo Nombre');
      expect(doc.data()!['descripcion'], 'Nueva descripción');
    });
  });
}
