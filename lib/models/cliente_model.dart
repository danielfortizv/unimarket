class Cliente {
  final String id;
  final String nombre;
  final String email;
  final String codigo;

  Cliente({required this.id, required this.nombre, required this.email, required this.codigo});

  factory Cliente.fromMap(Map<String, dynamic> map, String id) {
    return Cliente(
      id: id,
      nombre: map['nombre'],
      email: map['email'],
      codigo: map['codigo'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nombre': nombre,
      'email': email,
      'codigo': codigo,
    };
  }
}