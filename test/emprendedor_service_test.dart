import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:unimarket/models/emprendedor_model.dart';
import 'package:unimarket/services/emprendedor_service.dart';
import 'package:unimarket/services/emprendimiento_service.dart';
import 'package:unimarket/services/chat_service.dart';

void main() {
  group('EmprendedorService', () {
    late FakeFirebaseFirestore firestore;
    late EmprendedorService service;

    setUp(() {
      firestore = FakeFirebaseFirestore();

      final emprendimientoService = EmprendimientoService(firestore);
      final chatService = ChatService(firestore);

      service = EmprendedorService(
        firestore,
        emprendimientoService,
        chatService,
      );
    });

    test('crearEmprendedor guarda correctamente el documento', () async {
      final emprendedor = Emprendedor(
        id: 'emp1',
        nombre: 'Sofía',
        email: 'sofia@uni.com',
        codigo: '12345',
        emprendimientoIds: [],
      );

      await service.crearEmprendedor(emprendedor);

      final doc = await firestore.collection('emprendedores').doc('emp1').get();
      expect(doc.exists, true);
      expect(doc.data()!['nombre'], 'Sofía');
    });

    test('crearEmprendedor lanza excepción si campos obligatorios están vacíos', () {
      final emprendedor = Emprendedor(
        id: 'emp2',
        nombre: '',
        email: '',
        codigo: '',
        emprendimientoIds: [],
      );

      expect(() => service.crearEmprendedor(emprendedor), throwsException);
    });

    test('actualizarEmprendedor actualiza correctamente los datos', () async {
      final emprendedor = Emprendedor(
        id: 'emp3',
        nombre: 'Juan',
        email: 'juan@uni.com',
        codigo: 'abc123',
        emprendimientoIds: [],
      );

      await firestore.collection('emprendedores').doc('emp3').set(emprendedor.toMap());

      final actualizado = Emprendedor(
        id: 'emp3',
        nombre: 'Juan Pérez',
        email: 'juan@uni.com',
        codigo: 'abc123',
        emprendimientoIds: [],
      );

      await service.actualizarEmprendedor(actualizado);

      final doc = await firestore.collection('emprendedores').doc('emp3').get();
      expect(doc.data()!['nombre'], 'Juan Pérez');
    });

    test('eliminarEmprendedor borra emprendimientos, chats y el documento', () async {
      // Emprendimiento asociado
      await firestore.collection('emprendimientos').doc('e1').set({
        'nombre': 'Café Uni',
        'descripcion': '',
        'emprendedorId': 'emp4',
        'productoIds': [],
        'rangoPrecios': '',
        'rating': 0,
        'imagenes': [],
        'preguntasFrecuentes': [],
      });

      // Chat asociado
      await firestore.collection('chats').doc('c1').set({
        'clienteId': 'cliente1',
        'emprendedorId': 'emp4',
        'mensajes': [],
      });

      // Emprendedor a eliminar
      await firestore.collection('emprendedores').doc('emp4').set({
        'nombre': 'Carlos',
        'email': 'carlos@uni.com',
        'codigo': '999',
        'emprendimientoIds': [],
      });

      await service.eliminarEmprendedor('emp4');

      final doc = await firestore.collection('emprendedores').doc('emp4').get();
      final emp = await firestore.collection('emprendimientos').get();
      final chats = await firestore.collection('chats').get();

      expect(doc.exists, false);
      expect(emp.docs.length, 0);
      expect(chats.docs.length, 0);
    });

    test('obtenerEmprendedorPorId devuelve el emprendedor correcto', () async {
      await firestore.collection('emprendedores').doc('emp5').set({
        'nombre': 'Laura',
        'email': 'laura@uni.com',
        'codigo': '777',
        'emprendimientoIds': [],
      });

      final result = await service.obtenerEmprendedorPorId('emp5');
      expect(result, isNotNull);
      expect(result!.nombre, 'Laura');
    });

    test('obtenerEmprendedores devuelve todos los emprendedores', () async {
      await firestore.collection('emprendedores').add({
        'nombre': 'E1',
        'email': 'e1@uni.com',
        'codigo': '1',
        'emprendimientoIds': [],
      });

      await firestore.collection('emprendedores').add({
        'nombre': 'E2',
        'email': 'e2@uni.com',
        'codigo': '2',
        'emprendimientoIds': [],
      });

      final stream = service.obtenerEmprendedores();
      final result = await stream.first;
      expect(result.length, 2);
    });
  });
}
