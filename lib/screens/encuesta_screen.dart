import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class EncuestaScreen extends StatefulWidget {
  final String id;

  const EncuestaScreen({super.key, required this.id});

  @override
  _EncuestaScreenState createState() => _EncuestaScreenState();
}

class _EncuestaScreenState extends State<EncuestaScreen> {
  Map<String, dynamic> respuestas = {};
  late Future<Map<String, dynamic>?> _futureEncuesta;

  @override
  void initState() {
    super.initState();
    _futureEncuesta = cargarEncuesta();
  }

  Future<Map<String, dynamic>?> cargarEncuesta() async {
    final doc = await FirebaseFirestore.instance
        .collection('encuestas')
        .doc(widget.id)
        .get();
    return doc.data();
  }

  Future<void> registrarRespuestas() async {
    final respuestasRef = FirebaseFirestore.instance
        .collection('encuestas')
        .doc(widget.id)
        .collection('respuestas');

    for (final entrada in respuestas.entries) {
      await respuestasRef.add({
        'pregunta_id': entrada.key,
        'respuesta': entrada.value,
        'timestamp': FieldValue.serverTimestamp(),
      });
    }
  }

  Widget buildPregunta(Map<String, dynamic> pregunta) {
    final tipo = pregunta['tipo'];
    final id = pregunta['id'];

    switch (tipo) {
      case 'escala':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(pregunta['texto'], style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            DropdownButtonFormField<int>(
              decoration: const InputDecoration(border: OutlineInputBorder()),
              value: respuestas[id],
              items: (pregunta['opciones'] as List<dynamic>)
                  .map((e) => DropdownMenuItem<int>(
                        value: e,
                        child: Text(e.toString()),
                      ))
                  .toList(),
              onChanged: (value) => setState(() => respuestas[id] = value),
              validator: (value) => value == null ? 'Requerido' : null,
            ),
            const SizedBox(height: 16),
          ],
        );
      case 'si_no':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(pregunta['texto'], style: const TextStyle(fontSize: 16)),
            Row(
              children: ['Sí', 'No'].map((op) {
                return Expanded(
                  child: RadioListTile<String>(
                    title: Text(op),
                    value: op,
                    groupValue: respuestas[id],
                    onChanged: (val) => setState(() => respuestas[id] = val),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
          ],
        );
      case 'texto':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(pregunta['texto'], style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            TextFormField(
              maxLines: 3,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: "Escribe tu comentario aquí...",
              ),
              onChanged: (val) => respuestas[id] = val,
            ),
            const SizedBox(height: 16),
          ],
        );
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: _futureEncuesta,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final encuesta = snapshot.data;

        if (encuesta == null || encuesta['preguntas'] == null) {
          return const Scaffold(
            body: Center(child: Text('Encuesta no encontrada')),
          );
        }

        final preguntas = encuesta['preguntas'] as List<dynamic>;

        return Scaffold(
          appBar: AppBar(title: Text(encuesta['titulo'] ?? 'Encuesta')),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...preguntas
                    .map((p) => buildPregunta(p as Map<String, dynamic>))
                    .toList(),
                const SizedBox(height: 16),
                Center(
                  child: ElevatedButton(
                    onPressed: () async {
                      // Validación: asegurar que las preguntas obligatorias estén respondidas
                      final preguntas = encuesta['preguntas'] as List<dynamic>;

                      final preguntasIncompletas = preguntas.where((pregunta) {
                        final tipo = pregunta['tipo'];
                        final id = pregunta['id'];
                        final esObligatoria = tipo == 'escala' || tipo == 'si_no';
                        return esObligatoria && (respuestas[id] == null || respuestas[id].toString().isEmpty);
                      }).toList();

                      if (preguntasIncompletas.isNotEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Por favor responde todas las preguntas obligatorias')),
                        );
                        return;
                      }

                      // Todo bien, registrar
                      await registrarRespuestas();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Respuestas enviadas')),
                      );
                      Navigator.pop(context);
                    },
                    child: const Text('Enviar'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
