import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:unimarket/models/emprendimiento_model.dart';
import 'package:unimarket/services/favorito_service.dart';
import 'package:unimarket/services/emprendimiento_service.dart';
import 'package:unimarket/widgets/emprendimiento_card.dart';

class FavoritosScreen extends StatefulWidget {
  const FavoritosScreen({super.key});

  @override
  State<FavoritosScreen> createState() => _FavoritosScreenState();
}

class _FavoritosScreenState extends State<FavoritosScreen> {
  final _favoritoService = FavoritoService();
  final _emprendimientoService = EmprendimientoService();

  late final String _uid;
  List<Emprendimiento> _favoritos = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _uid = FirebaseAuth.instance.currentUser!.uid;
    _cargarFavoritos();
  }

  Future<void> _cargarFavoritos() async {
    setState(() => _loading = true);
    final ids = await _favoritoService.obtenerIdsFavoritosPorCliente(_uid);
    final resultados = await Future.wait(
      ids.map((id) => _emprendimientoService.obtenerPorId(id))
    );
    _favoritos = resultados.whereType<Emprendimiento>().toList();
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Favoritos', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _favoritos.isEmpty
              ? const Center(child: Text('Aún no has guardado emprendimientos.'))
              : ListView.builder(
                  itemCount: _favoritos.length,
                  itemBuilder: (context, index) {
                    return EmprendimientoCard(
                      emprendimiento: _favoritos[index],
                      onMostrarComentarios: (context, emp) {},
                    );
                  },
                ),
    );
  }
}
