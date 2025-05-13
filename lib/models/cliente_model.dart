class Cliente {
  final String id;
  final String nombre;
  final String email;
  final String codigo;
  final String? password;
  final String? fotoPerfil;

  Cliente({required this.id, required this.nombre, required this.email, required this.codigo, this.password, this.fotoPerfil});

  factory Cliente.fromMap(Map<String, dynamic> map, String id) {
    return Cliente(
      id: id,
      nombre: map['nombre'],
      email: map['email'],
      codigo: map['codigo'],
      password: map['password'],
      fotoPerfil: map['fotoPerfil']?.isEmpty == true ? null : map['fotoPerfil'], // Convertir string vacío a null
    );
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'nombre': nombre,
      'email': email,
      'codigo': codigo,
    };
    
    // Solo agregar password si no es null
    if (password != null) {
      map['password'] = password;
    }
    
    // Solo agregar fotoPerfil si no es null
    if (fotoPerfil != null) {
      map['fotoPerfil'] = fotoPerfil;
    }
    
    return map;
  }
}