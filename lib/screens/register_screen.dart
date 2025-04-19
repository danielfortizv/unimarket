import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _auth = FirebaseAuth.instance;

  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _codigoController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();

  File? _selectedImage;
  bool _loading = false;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (file != null) {
      setState(() {
        _selectedImage = File(file.path);
      });
    }
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final nombre = _nombreController.text.trim();
    final codigo = _codigoController.text.trim();

    if (!email.endsWith('@uniandes.edu.co')) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El correo debe terminar en @uniandes.edu.co')),
      );
      return;
    }

    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      final userId = userCredential.user!.uid;

      String? fotoUrl;
      if (_selectedImage != null) {
        final ref = firebase_storage.FirebaseStorage.instance.ref().child('fotos_perfil').child('$userId.jpg');
        await ref.putFile(_selectedImage!);
        fotoUrl = await ref.getDownloadURL();
      }

      await FirebaseFirestore.instance.collection('clientes').doc(userId).set({
        'id': userId,
        'nombre': nombre,
        'email': email,
        'codigo': codigo,
        'fotoPerfil': fotoUrl ?? '',
      });

      await userCredential.user!.sendEmailVerification();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Verifica tu correo para completar el registro.')),
        );
        Navigator.pop(context); // ir a login
      }
    } catch (e) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("REGISTRO", style:TextStyle(fontSize: 28, fontFamily: "Poppins", fontWeight: FontWeight.bold))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: CircleAvatar(
                radius: 50,
                backgroundColor: Colors.grey[300],
                backgroundImage: _selectedImage != null ? FileImage(_selectedImage!) : null,
                child: _selectedImage == null ? const Icon(Icons.camera_alt, size: 32) : null,
              ),
            ),
            const SizedBox(height: 20),
            Form(
              key: _formKey,
              child: 
                Column(
                  children: [
                    TextFormField(
                      controller: _nombreController,
                      decoration: InputDecoration(
                        labelText: 'Nombre',
                        prefixIcon: Icon(Icons.person),
                        filled: true,
                        fillColor: Color(0xFFE3F2FD),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        labelText: 'Correo',
                        prefixIcon: Icon(Icons.email),
                        filled: true,
                        fillColor: Color(0xFFE3F2FD),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _codigoController,
                      decoration: InputDecoration(
                        labelText: 'Código',
                        prefixIcon: Icon(Icons.credit_card),
                        filled: true,
                        fillColor: Color(0xFFE3F2FD),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: 'Contraseña',
                        prefixIcon: Icon(Icons.lock_open),
                        filled: true,
                        fillColor: Color(0xFFE3F2FD),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _confirmController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: 'Confirmar contraseña',
                        prefixIcon: Icon(Icons.lock_outline),
                        filled: true,
                        fillColor: Color(0xFFE3F2FD),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ],
                )
            ),
            const SizedBox(height: 24), // Espacio entre campos y el botón

            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _loading ? null : _register,
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: _loading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : const Text(
                        "Registrarse",
                        style: TextStyle(fontSize: 16),
                      ),
              ),
            ),
            const SizedBox(height: 12), // Espacio entre botones

            TextButton(
              onPressed: () {
                Navigator.pop(context); // Vuelve al login
              },
              child: const Text(
                "¿Ya tienes cuenta? Inicia sesión",
                style: TextStyle(fontFamily: 'Poppins'),
              ),
            ),
          ],
        ),
      ),
    );
  }

}
