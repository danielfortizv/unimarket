// Widget helper para mostrar avatares con imagen por defecto
import 'package:flutter/material.dart';

class AvatarConDefault extends StatelessWidget {
  final String? imageUrl;
  final double radius;
  final String? placeholderName;

  const AvatarConDefault({
    super.key,
    this.imageUrl,
    required this.radius,
    this.placeholderName,
  });

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundImage: imageUrl != null && imageUrl!.isNotEmpty
          ? NetworkImage(imageUrl!)
          : null,
      backgroundColor: Colors.grey[300],
      child: imageUrl == null || imageUrl!.isEmpty
          ? ClipOval(
              child: Image.asset(
                'assets/images/usuario.png',
                width: radius * 2,
                height: radius * 2,
                fit: BoxFit.cover,
              ),
            )
          : null,
    );
  }
}