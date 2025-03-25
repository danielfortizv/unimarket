
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unimarket/models/emprendimiento_model.dart';
import 'package:unimarket/services/emprendimiento_service.dart';

void main() {
  group('EmprendimientoService', () {
    late FakeFirebaseFirestore firestore;
    late EmprendimientoService service;

    setUp(() {
      firestore = FakeFirebaseFirestore();
      service = EmprendimientoService(firestore);
    });

    test('crearEmprendimiento lanza excepción si nombre o emprendedorId están vacíos', () async {
      final emprendimiento = Emprendimiento(
        id: 'e1',
        nombre: '',
        descripcion: 'test',
        productoIds: [],
        rangoPrecios: null,
        rating: null,
        preguntasFrecuentes: {},
        emprendedorId: '',
        imagenes: [],
        hashtags: [],
        info: null,
      );

      expect(() => service.crearEmprendimiento(emprendimiento), throwsException);
    });

    test('crearEmprendimiento agrega el documento correctamente', () async {
      await firestore.collection('emprendedores').doc('emp1').set({'emprendimientoIds': []});

      final emprendimiento = Emprendimiento(
        id: 'e2',
        nombre: 'Tienda A',
        descripcion: 'Ropa cool',
        productoIds: [],
        rangoPrecios: null,
        rating: null,
        preguntasFrecuentes: {},
        emprendedorId: 'emp1',
        imagenes: [],
        hashtags: [],
        info: 'info@tiendaa.com',
      );

      await service.crearEmprendimiento(emprendimiento);

      final doc = await firestore.collection('emprendimientos').doc('e2').get();
      expect(doc.exists, true);
    });

    test('actualizarNombre cambia el nombre correctamente', () async {
      await firestore.collection('emprendimientos').doc('e3').set({
        'nombre': 'Viejo',
        'descripcion': '',
        'productoIds': [],
        'rangoPrecios': null,
        'rating': null,
        'preguntasFrecuentes': {},
        'emprendedorId': 'emp2',
        'imagenes': [],
        'hashtags': [],
        'info': '',
      });

      await service.actualizarNombre('e3', 'Nuevo');

      final doc = await firestore.collection('emprendimientos').doc('e3').get();
      expect(doc['nombre'], 'Nuevo');
    });

    test('agregarPreguntaFrecuenteAEmprendimiento agrega correctamente la pregunta', () async {
      await firestore.collection('emprendimientos').doc('e4').set({
        'nombre': 'Test',
        'descripcion': '',
        'productoIds': [],
        'rangoPrecios': null,
        'rating': null,
        'preguntasFrecuentes': {},
        'emprendedorId': 'emp4',
        'imagenes': [],
        'hashtags': [],
        'info': '',
      });

      await service.agregarPreguntaFrecuenteAEmprendimiento('e4', '¿Hacen envíos?');

      final doc = await firestore.collection('emprendimientos').doc('e4').get();
      final preguntas = doc['preguntasFrecuentes'] as Map;
      expect(preguntas.containsKey('¿Hacen envíos?'), true);
      expect(preguntas['¿Hacen envíos?'], null);
    });

    test('agregarRespuestaAPreguntaFrecuente actualiza la respuesta correctamente', () async {
      await firestore.collection('emprendimientos').doc('e5').set({
        'nombre': 'Test',
        'descripcion': '',
        'productoIds': [],
        'rangoPrecios': null,
        'rating': null,
        'preguntasFrecuentes': {'¿Abren domingos?': null},
        'emprendedorId': 'emp5',
        'imagenes': [],
        'hashtags': [],
        'info': '',
      });

      await service.agregarRespuestaAPreguntaFrecuente('e5', '¿Abren domingos?', 'Sí');

      final doc = await firestore.collection('emprendimientos').doc('e5').get();
      final preguntas = doc['preguntasFrecuentes'] as Map;
      expect(preguntas['¿Abren domingos?'], 'Sí');
    });
  });
}
