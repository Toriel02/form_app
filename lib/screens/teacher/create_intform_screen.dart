import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:form_app/screens/encuestas/encuesta_1.dart';
import 'package:form_app/screens/encuestas/encuesta_2.dart';
import 'package:form_app/screens/encuestas/encuesta_3.dart';
import 'package:form_app/screens/encuestas/encuesta_4.dart';
import 'package:form_app/screens/encuestas/encuesta_5.dart';
import 'package:form_app/services/firestore_services.dart';
import 'package:firebase_auth/firebase_auth.dart'; 

class UploadInternalSurveysScreen extends StatefulWidget {
  const UploadInternalSurveysScreen({super.key});

  @override
  State<UploadInternalSurveysScreen> createState() => _UploadInternalSurveysScreenState();
}

class _UploadInternalSurveysScreenState extends State<UploadInternalSurveysScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  User? _currentUser;
  Set<String> uploadedTitles = {}; // títulos ya subidos

  
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
        appBar: AppBar(
          title: const Text('Subir Encuestas Internas'),
          backgroundColor: const Color(0xFF1565C0),
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Text('No hay usuario autenticado'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          'Subir Encuestas Internas',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 6,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: encuestasPredefinidas.length,
        itemBuilder: (context, index) {
          final encuesta = encuestasPredefinidas[index];
          final titulo = encuesta['titulo'] as String;
          final preguntas = encuesta['preguntas'] as List<Map<String, dynamic>>;
          final estaSubida = uploadedTitles.contains(titulo);

          return Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 4,
            margin: const EdgeInsets.symmetric(vertical: 10),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text(
                      titulo,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                  onPressed: () {
                    if (!estaSubida) {
                      _subirEncuestaIndividual(titulo, preguntas);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    backgroundColor: estaSubida ? Colors.green : const Color(0xFF1565C0),
                    foregroundColor: Colors.white, // Asegura texto blanco en ambos estados
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 3,
                  ),
                  child: Text(
                    estaSubida ? 'Subida' : 'Subir',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}