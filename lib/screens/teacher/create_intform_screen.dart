import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:form_app/screens/encuestas/encuesta_1.dart';
import 'package:form_app/screens/encuestas/encuesta_2.dart';
import 'package:form_app/screens/encuestas/encuesta_3.dart';
import 'package:form_app/screens/encuestas/encuesta_4.dart';
import 'package:form_app/screens/encuestas/encuesta_5.dart';
import 'package:form_app/services/firestore_services.dart'; // Asegúrate de que la ruta y el nombre del archivo sean correctos (firestore_service.dart, no firestore_services.dart)
import 'package:firebase_auth/firebase_auth.dart'; // Necesario para obtener el usuario actual

class UploadInternalSurveysScreen extends StatefulWidget {
  const UploadInternalSurveysScreen({super.key});

  @override
  State<UploadInternalSurveysScreen> createState() => _UploadInternalSurveysScreenState();
}

class _UploadInternalSurveysScreenState extends State<UploadInternalSurveysScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  User? _currentUser;
  Set<String> uploadedTitles = {}; // títulos ya subidos

  // Aquí define tus encuestas predefinidas (ejemplo)
  final List<Map<String, dynamic>> encuestasPredefinidas = [
    {'titulo': 'Dinámica Utilizada', 'preguntas': encuesta1},
    {'titulo': 'Opinión de Explicación', 'preguntas': encuesta2},
    {'titulo': 'Dificultad y Ritmo del Curso', 'preguntas': encuesta3},
    {'titulo': 'Recursos y Materiales del Curso', 'preguntas': encuesta4},
    {'titulo': 'Relevancia del Contenido', 'preguntas': encuesta5},
  ];

  @override
  void initState() {
    super.initState();
    _currentUser = FirebaseAuth.instance.currentUser;
    if (_currentUser != null) {
      _cargarEncuestasSubidas(_currentUser!.uid);
    }
  }

  Future<void> _cargarEncuestasSubidas(String teacherId) async {
    final encuestas = await _firestoreService.obtenerEncuestasPorProfesorUnaVez(teacherId);
    final titulos = encuestas.map((e) => e['titulo'] as String).toSet();

    setState(() {
      uploadedTitles = titulos;
    });
  }

  Future<void> _subirEncuestaIndividual(String titulo, List<Map<String, dynamic>> preguntas) async {
    if (_currentUser == null) return;

    if (uploadedTitles.contains(titulo)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('La encuesta "$titulo" ya fue subida.')),
      );
      return;
    }

    final id = await _firestoreService.addEncuestaToFirestore(
      titulo: titulo,
      preguntas: preguntas,
      teacherId: _currentUser!.uid,
    );

    if (id != null) {
      setState(() {
        uploadedTitles.add(titulo);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Encuesta "$titulo" subida exitosamente')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al subir la encuesta "$titulo". Intenta de nuevo.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUser == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Subir Encuestas Internas')),
        body: const Center(child: Text('No hay usuario autenticado')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Subir Encuestas Internas')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: encuestasPredefinidas.length,
        itemBuilder: (context, index) {
          final encuesta = encuestasPredefinidas[index];
          final titulo = encuesta['titulo'] as String;
          final preguntas = encuesta['preguntas'] as List<Map<String, dynamic>>;
          final estaSubida = uploadedTitles.contains(titulo);

          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: ListTile(
              title: Text(titulo, style: const TextStyle(fontWeight: FontWeight.bold)),
              trailing: ElevatedButton(
                onPressed: estaSubida
                    ? null
                    : () => _subirEncuestaIndividual(titulo, preguntas),
                child: Text(estaSubida ? 'Subida' : 'Subir'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: estaSubida ? Colors.grey : Colors.blue.shade800,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
