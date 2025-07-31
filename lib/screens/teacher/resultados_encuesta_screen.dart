// =============================================================================
// Archivo: lib/screens/teacher/resultados_encuesta_screen.dart
// Este archivo muestra la pantalla de resultados de una encuesta específica.
// =============================================================================
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:form_app/services/firestore_services.dart';
import 'package:form_app/utils/chart_data_processor.dart';
import 'package:form_app/widgets/widgets/bar_chart_sample.dart'; // Importa tu widget de gráfico de barras

class ResultadosEncuestaScreen extends StatefulWidget {
  final String encuestaId;

  const ResultadosEncuestaScreen({super.key, required this.encuestaId});

  @override
  State<ResultadosEncuestaScreen> createState() => _ResultadosEncuestaScreenState();
}

class _ResultadosEncuestaScreenState extends State<ResultadosEncuestaScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final User? _currentUser = FirebaseAuth.instance.currentUser;
  late Future<Map<String, dynamic>?> _futureEncuesta;

  @override
  void initState() {
    super.initState();
    _futureEncuesta = _firestoreService.obtenerEncuestaPorId(widget.encuestaId);
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUser == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Resultados')),
        body: const Center(child: Text('Inicia sesión para ver los resultados.')),
      );
    }
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Resultados de Encuesta', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blue.shade700,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _futureEncuesta,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error al cargar la encuesta: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text('Encuesta no encontrada.'));
          }

          final encuesta = snapshot.data!;
          final tituloEncuesta = encuesta['titulo'] ?? 'Encuesta sin título';
          final preguntas = (encuesta['preguntas'] as List<dynamic>?)
                  ?.map((e) => e as Map<String, dynamic>)
                  .toList() ??
              [];

          if (preguntas.isEmpty) {
            return const Center(child: Text('Esta encuesta no tiene preguntas definidas.'));
          }

          // ==================================================================
          // ESTO ES LO CRUCIAL: El StreamBuilder ahora usa el método corregido
          // ==================================================================
          return StreamBuilder<QuerySnapshot>(
            stream: _firestoreService.obtenerRespuestasDeEncuestaPorProfesor(
              widget.encuestaId,
              _currentUser!.uid,
            ),
            builder: (context, respuestasSnapshot) {
              if (respuestasSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (respuestasSnapshot.hasError) {
                return Center(
                    child: Text('Error al cargar respuestas: ${respuestasSnapshot.error}'));
              }
              if (!respuestasSnapshot.hasData || respuestasSnapshot.data!.docs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('No hay respuestas aún para: "$tituloEncuesta".'),
                      const SizedBox(height: 10),
                      const Text('Comparte el formulario para empezar a recibir respuestas.'),
                    ],
                  ),
                );
              }

              final todasLasRespuestas = respuestasSnapshot.data!.docs
                  .map((doc) => doc.data() as Map<String, dynamic>)
                  .toList();

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Resultados para: "$tituloEncuesta"',
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.blueAccent),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Total de respuestas: ${todasLasRespuestas.length}',
                      style: const TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
                    ),
                    const Divider(height: 30, thickness: 1),
                    ...preguntas.map((pregunta) {
                      final tipo = pregunta['tipo'];
                      final idPregunta = pregunta['id'] as String;
                      final textoPregunta = pregunta['texto'] as String;

                      if (tipo == 'escala') {
                        final opciones = pregunta['opciones'] as List<dynamic>;
                        final dataGrafico = procesarRespuestasEscala(
                            todasLasRespuestas, idPregunta, opciones);
                        return BarChartSample(
                          title: textoPregunta,
                          data: dataGrafico,
                          barColor: Colors.deepPurple.shade300,
                        );
                      } else if (tipo == 'si_no') {
                        final dataGrafico =
                            procesarRespuestasSiNo(todasLasRespuestas, idPregunta);
                        return BarChartSample(
                          title: textoPregunta,
                          data: dataGrafico,
                          barColor: Colors.teal.shade300,
                        );
                      } else if (tipo == 'texto') {
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          elevation: 2,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  textoPregunta,
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 10),
                                const Text('Esta es una pregunta de texto abierto. No se muestra un gráfico de barras.'),
                              ],
                            ),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    }).toList(),
                    const SizedBox(height: 50),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
