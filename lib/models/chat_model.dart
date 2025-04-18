import 'package:unimarket/models/mensaje_model.dart';

class Chat {
  final String id;
  final String clienteId;
  final String emprendimientoId;
  final List<Mensaje> mensajes;

  Chat({
    required this.id,
    required this.clienteId,
    required this.emprendimientoId,
    required this.mensajes,
  });

  factory Chat.fromMap(Map<String, dynamic> map, String id) {
    return Chat(
      id: id,
      clienteId: map['clienteId'],
      emprendimientoId: map['emprendimientoId'],
      mensajes: map['mensajes'] != null
          ? List<Mensaje>.from(
              map['mensajes'].map((m) => Mensaje.fromMap(m)))
          : [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'clienteId': clienteId,
      'emprendimientoId': emprendimientoId,
      'mensajes': mensajes.map((m) => m.toMap()).toList(),
    };
  }

    Chat copyWith({
      String? id,
      String? clienteId,
      String? emprendedorId,
      List<Mensaje>? mensajes,
    }) {
      return Chat(
        id: id ?? this.id,
        clienteId: clienteId ?? this.clienteId,
        emprendimientoId: emprendimientoId,
        mensajes: mensajes ?? this.mensajes,
      );
    }

}
