import 'package:unimarket/models/cliente_model.dart';

class Emprendedor extends Cliente {
  final List<String> emprendimientoIds;

  Emprendedor({
    required super.id,
    required super.nombre,
    required super.email,
    required super.codigo,
    required this.emprendimientoIds,
  });

  factory Emprendedor.fromMap(Map<String, dynamic> map, String id) {
    return Emprendedor(
      id: id,
      nombre: map['nombre'],
      email: map['email'],
      codigo: map['codigo'],
      emprendimientoIds: List<String>.from(map['emprendimientoIds']),
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'nombre': nombre,
      'email': email,
      'codigo': codigo,
      'emprendimientoIds': emprendimientoIds,
    };
  }
}
