import 'package:unimarket/models/cliente_model.dart';

class Emprendedor extends Cliente {
  final List<String> emprendimientoIds;

  Emprendedor({
    required super.id,
    required super.nombre,
    required super.email,
    required super.codigo,
    required super.password,
    super.fotoPerfil,
    required this.emprendimientoIds,
  });

  factory Emprendedor.fromMap(Map<String, dynamic> map, String id) {
    return Emprendedor(
      id: id,
      nombre: map['nombre'],
      email: map['email'],
      codigo: map['codigo'],
      password: map['password'],
      fotoPerfil: map['fotoPerfil'],
      emprendimientoIds: List<String>.from(map['emprendimientoIds']),
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'nombre': nombre,
      'email': email,
      'codigo': codigo,
      'password': password,
      'fotoPerfil': fotoPerfil,
      'emprendimientoIds': emprendimientoIds,
    };
  }
}
