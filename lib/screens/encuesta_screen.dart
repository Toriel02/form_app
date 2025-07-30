import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class EncuestaScreen extends StatelessWidget {
  final String id;

  const EncuestaScreen({super.key, required this.id});

  Future<Map<String, dynamic>?> cargarEncuesta() async {
    final doc = await FirebaseFirestore.instance.collection('encuestas').doc(id).get();
    return doc.data();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: cargarEncuesta(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final encuesta = snapshot.data;

        if (encuesta == null) {
          return const Scaffold(
            body: Center(child: Text('Encuesta no encontrada')),
          );
        }

        return Scaffold(
          appBar: AppBar(title: Text(encuesta['titulo'] ?? 'Encuesta')),
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  encuesta['pregunta'] ?? 'Sin pregunta',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              ...List.generate(
                (encuesta['opciones'] as List<dynamic>).length,
                (index) {
                  final opcion = encuesta['opciones'][index];
                  return ListTile(
                    title: Text(opcion),
                    leading: const Icon(Icons.circle_outlined),
                    onTap: () {
                      // Aquí va lógica para votar
                    },
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}