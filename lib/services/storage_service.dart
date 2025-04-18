import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  final _storage = FirebaseStorage.instance;

  Future<String> subirArchivo(File archivo, String ruta) async {
    final ref = _storage.ref().child(ruta);
    await ref.putFile(archivo);
    return await ref.getDownloadURL();
  }

  Future<void> eliminarArchivoPorUrl(String url) async {
    try {
      final ref = _storage.refFromURL(url);
      await ref.delete();
    } catch (e) {
      // Si el archivo no existe o ya fue eliminado
      print('Error eliminando archivo: $e');
    }
  }
}
