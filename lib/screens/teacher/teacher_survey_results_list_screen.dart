// lib/screens/teacher/teacher_survey_results_list_screen.dart

import 'package:flutter/material.dart';
import 'package:form_app/services/firestore_services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Necesario para Timestamp si lo usas
import 'package:form_app/screens/teacher/resultados_encuesta_screen.dart';

class TeacherSurveyResultsListScreen extends StatefulWidget {
  const TeacherSurveyResultsListScreen({super.key});

  @override
  State<TeacherSurveyResultsListScreen> createState() => _TeacherSurveyResultsListScreenState();
}

class _TeacherSurveyResultsListScreenState extends State<TeacherSurveyResultsListScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final User? _currentUser = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    if (_currentUser == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Resultados de Encuestas')),
        body: const Center(child: Text('Debes iniciar sesión para ver los resultados de tus encuestas.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Resultados de Encuestas', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blue.shade700,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      // CAMBIO CLAVE AQUÍ: El StreamBuilder ahora espera List<Map<String, dynamic>>
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _firestoreService.obtenerEncuestasPorProfesor(_currentUser!.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error al cargar encuestas: ${snapshot.error}'));
          }
          // snapshot.data ahora es List<Map<String, dynamic>> directamente
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No tienes encuestas creadas para ver resultados.'));
          }

          final encuestas = snapshot.data!; // Ahora 'encuestas' es List<Map<String, dynamic>>

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: encuestas.length,
            itemBuilder: (context, index) {
              final encuestaData = encuestas[index]; // Accede directamente al mapa
              // Asumo que tu mapa ya contiene el 'id' de la encuesta como un campo.
              // Si el ID de la encuesta no está dentro del mapa, necesitarás pasarlo
              // desde tu FirestoreService al hacer el mapeo original.
              // Por ahora, asumiré que el ID está dentro del mapa con la clave 'id'.
              // Si no es así, dime cómo lo manejas en tu FirestoreService.
              final encuestaId = encuestaData['id'] as String; // Asumo que el ID está en el mapa
              final titulo = encuestaData['titulo'] ?? 'Encuesta sin título';
              final fechaCreacion = (encuestaData['fechaCreacion'] is Timestamp)
                  ? (encuestaData['fechaCreacion'] as Timestamp).toDate()
                  : null; // Manejo seguro para Timestamp si viene directo o ya convertido

              return Card(
                elevation: 4,
                margin: const EdgeInsets.symmetric(vertical: 8.0),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ResultadosEncuestaScreen(encuestaId: encuestaId),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          titulo,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.blueAccent,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'ID: $encuestaId',
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        if (fechaCreacion != null)
                          Text(
                            'Creada el: ${fechaCreacion.day}/${fechaCreacion.month}/${fechaCreacion.year}',
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        const SizedBox(height: 12),
                        const Align(
                          alignment: Alignment.bottomRight,
                          child: Icon(Icons.bar_chart, color: Colors.green, size: 30),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}