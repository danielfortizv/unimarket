import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:unimarket/models/cliente_model.dart';
import 'package:unimarket/services/cliente_service.dart';

void main() {
  group('ClienteService Tests', () {
    late FakeFirebaseFirestore firestore;
    late ClienteService clienteService;

    setUp(() {
      firestore = FakeFirebaseFirestore();
      clienteService = ClienteService(firestore);
    });

    test('crearCliente guarda correctamente un nuevo cliente', () async {
      final cliente = Cliente(
        id: 'cliente1',
        nombre: 'Juan Pérez',
        email: 'juan@correo.com',
        codigo: 'A123',
      );

      await clienteService.crearCliente(cliente);

      final snapshot = await firestore.collection('clientes').doc(cliente.id).get();
      expect(snapshot.exists, true);
      expect(snapshot.data()!['nombre'], 'Juan Pérez');
    });

    test('actualizarCliente modifica los datos del cliente', () async {
      final cliente = Cliente(
        id: 'cliente2',
        nombre: 'Ana Torres',
        email: 'ana@correo.com',
        codigo: 'B456',
      );

      await firestore.collection('clientes').doc(cliente.id).set(cliente.toMap());

      final actualizado = Cliente(
        id: 'cliente2',
        nombre: 'Ana María Torres',
        email: 'ana.maria@correo.com',
        codigo: 'B456',
      );

      await clienteService.actualizarCliente(actualizado);

      final snapshot = await firestore.collection('clientes').doc('cliente2').get();
      expect(snapshot.data()!['nombre'], 'Ana María Torres');
      expect(snapshot.data()!['email'], 'ana.maria@correo.com');
    });

    test('eliminarCliente elimina correctamente el documento', () async {
      final cliente = Cliente(
        id: 'cliente3',
        nombre: 'Carlos Ruiz',
        email: 'carlos@correo.com',
        codigo: 'C789',
      );

      await firestore.collection('clientes').doc(cliente.id).set(cliente.toMap());
      await clienteService.eliminarCliente(cliente.id);

      final snapshot = await firestore.collection('clientes').doc(cliente.id).get();
      expect(snapshot.exists, false);
    });

    test('obtenerClientes retorna todos los clientes existentes', () async {
      final cliente1 = Cliente(id: 'c1', nombre: 'A', email: 'a@mail.com', codigo: '1');
      final cliente2 = Cliente(id: 'c2', nombre: 'B', email: 'b@mail.com', codigo: '2');

      await firestore.collection('clientes').doc(cliente1.id).set(cliente1.toMap());
      await firestore.collection('clientes').doc(cliente2.id).set(cliente2.toMap());

      final stream = clienteService.obtenerClientes();
      final result = await stream.first;

      expect(result.length, 2);
      expect(result.any((c) => c.nombre == 'A'), true);
    });

    test('obtenerClientePorId devuelve el cliente correcto', () async {
      final cliente = Cliente(
        id: 'cliente4',
        nombre: 'Laura Gómez',
        email: 'laura@correo.com',
        codigo: 'D001',
      );

      await firestore.collection('clientes').doc(cliente.id).set(cliente.toMap());

      final result = await clienteService.obtenerClientePorId(cliente.id);

      expect(result, isNotNull);
      expect(result!.nombre, 'Laura Gómez');
    });
  });
}
