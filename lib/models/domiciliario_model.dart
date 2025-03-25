import 'package:unimarket/models/cliente_model.dart';

class Domiciliario extends Cliente {
  final bool disponible;

  Domiciliario({
    required super.id,
    required super.nombre,
    required super.email,
    required super.codigo,
    required super.password,
    super.fotoPerfil,
    this.disponible = true,
  });

  factory Domiciliario.fromMap(Map<String, dynamic> map, String id) {
    return Domiciliario(
      id: id,
      nombre: map['nombre'],
      email: map['email'],
      codigo: map['codigo'],
      password: map['password'],
      fotoPerfil: map['fotoPerfil'],
      disponible: map['disponible'] ?? true,
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
      'disponible': disponible,
    };
  }
}
