class Cliente {
  final String id;
  final String nombre;
  final String email;
  final String codigo;
  final String password;
  final String? fotoPerfil;


  Cliente({required this.id, required this.nombre, required this.email, required this.codigo, required this.password, this.fotoPerfil});

  factory Cliente.fromMap(Map<String, dynamic> map, String id) {
    return Cliente(
      id: id,
      nombre: map['nombre'],
      email: map['email'],
      codigo: map['codigo'],
      password: map['password'],
      fotoPerfil: map['fotoPerfil'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nombre': nombre,
      'email': email,
      'codigo': codigo,
      'password': password,
      'fotoPerfil': fotoPerfil,
    };
  }
}