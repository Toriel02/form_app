import 'package:flutter/material.dart';
import 'package:form_app/services/firestore_services.dart'; // Asegúrate de que la ruta y el nombre del archivo sean correctos (firestore_service.dart, no firestore_services.dart)
import 'package:firebase_auth/firebase_auth.dart'; // Necesario para obtener el usuario actual

class UploadInternalSurveysScreen extends StatefulWidget {
  const UploadInternalSurveysScreen({super.key});

  @override
  State<UploadInternalSurveysScreen> createState() => _UploadInternalSurveysScreenState();
}

class _UploadInternalSurveysScreenState extends State<UploadInternalSurveysScreen> {
  final FirestoreService _firestoreService = FirestoreService(); // Instancia de tu servicio de Firestore
  bool _isUploading = false; // Estado para controlar si la subida está en curso
  String _message = ''; // Mensaje para mostrar el estado al usuario

  @override
  void initState() {
    super.initState();
    // Inicia la subida de encuestas automáticamente cuando la pantalla se carga.
    // La función `subirEncuestasPorProfesor` en FirestoreService ya tiene una lógica
    // para evitar duplicados si las encuestas ya existen para el profesor.
    _uploadSurveys(); 
  }

  // Función asíncrona para manejar la lógica de subida de encuestas
  Future<void> _uploadSurveys() async {
    final user = FirebaseAuth.instance.currentUser; // Obtiene el usuario autenticado actualmente
    if (user == null) {
      // Si no hay usuario, actualiza el mensaje y detiene la ejecución
      setState(() {
        _message = 'No hay usuario autenticado. Inicia sesión para subir encuestas.';
      });
      return;
    }

    // Muestra el indicador de carga y el mensaje de "subiendo"
    setState(() {
      _isUploading = true;
      _message = 'Subiendo encuestas predefinidas...';
    });

    try {
      // Llama a la función de tu FirestoreService para subir las encuestas
      await _firestoreService.subirEncuestasPorProfesor(user.uid);
      // Si la subida es exitosa, actualiza el mensaje
      setState(() {
        _message = 'Encuestas subidas correctamente (o ya existían).';
      });
    } catch (e) {
      // Si ocurre un error, actualiza el mensaje con el error
      setState(() {
        _message = 'Error al subir encuestas: ${e.toString()}';
      });
      print('Error al subir encuestas en pantalla: $e'); // Imprime el error en la consola para depuración
    } finally {
      // Sin importar el resultado, oculta el indicador de carga
      setState(() {
        _isUploading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Subir Encuestas Internas'),
        backgroundColor: Colors.blue.shade700, // Estilo de la barra de aplicación
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Muestra un CircularProgressIndicator si está subiendo, de lo contrario, el mensaje
              _isUploading
                  ? const CircularProgressIndicator()
                  : const SizedBox.shrink(), // Oculta el indicador si no está subiendo
              
              const SizedBox(height: 20), // Espacio entre el indicador y el mensaje
              
              Text(
                _message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  color: _message.contains('Error') ? Colors.red : Colors.black87, // Color del texto según el mensaje
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              const SizedBox(height: 30),
              
              // Botón para reintentar la subida (útil si hubo un error o para forzar)
              ElevatedButton.icon(
                onPressed: _isUploading ? null : _uploadSurveys, // Deshabilita el botón mientras se sube
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar Subida'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 25),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  backgroundColor: Colors.blue.shade500,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
