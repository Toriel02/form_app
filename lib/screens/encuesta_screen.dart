import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Importar FirebaseAuth

class EncuestaScreen extends StatefulWidget {
  final String id; // ID de la encuesta

  const EncuestaScreen({super.key, required this.id});

  @override
  _EncuestaScreenState createState() => _EncuestaScreenState();
}

class _EncuestaScreenState extends State<EncuestaScreen> {
  // Mapa para almacenar las respuestas del usuario, usando el ID de la pregunta como clave
  Map<String, dynamic> respuestas = {};
  // Future para cargar los datos de la encuesta una vez
  late Future<Map<String, dynamic>?> _futureEncuesta;

  @override
  void initState() {
    super.initState();
    _futureEncuesta = cargarEncuesta();
  }

  // Función para cargar los datos de la encuesta desde Firestore
  Future<Map<String, dynamic>?> cargarEncuesta() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('encuestas')
          .doc(widget.id)
          .get();
      if (doc.exists) {
        return {'id': doc.id, ...doc.data() as Map<String, dynamic>};
      }
      return null;
    } catch (e) {
      print('Error al cargar encuesta: $e');
      // Puedes mostrar un SnackBar aquí o dejar que el FutureBuilder lo maneje
      return null;
    }
  }

  // Función para registrar las respuestas en Firestore
  Future<void> registrarRespuestas() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debes iniciar sesión para enviar respuestas.')),
      );
      return;
    }

    // Obtener el ID del profesor de la encuesta para guardarlo con la respuesta
    // Esto es crucial para las reglas de seguridad del profesor en 'respuestas'
    String? teacherId;
    try {
      final encuestaDoc = await FirebaseFirestore.instance.collection('encuestas').doc(widget.id).get();
      teacherId = encuestaDoc.data()?['teacherId'] as String?;
      if (teacherId == null) {
        throw Exception("No se pudo obtener el teacherId de la encuesta.");
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al obtener teacherId de la encuesta: ${e.toString()}')),
      );
      return;
    }


    try {
      // Referencia a la subcolección 'respuestas' dentro del documento de la encuesta
      final respuestasCollectionRef = FirebaseFirestore.instance
          .collection('encuestas')
          .doc(widget.id)
          .collection('respuestas');

      // Crear un mapa único para la respuesta del estudiante
      final Map<String, dynamic> respuestaCompleta = {
        'studentId': user.uid, // ID del estudiante que respondió
        'encuestaId': widget.id, // ID de la encuesta a la que se respondió
        'teacherId': teacherId, // ID del profesor de la encuesta (para reglas de seguridad)
        'fechaEnvio': FieldValue.serverTimestamp(), // Marca de tiempo del envío
        'respuestasDetalle': respuestas, // Todas las respuestas del mapa
      };

      // Añadir un único documento a la subcolección 'respuestas'
      await respuestasCollectionRef.add(respuestaCompleta);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Respuestas enviadas correctamente.')),
      );
      // Navegar de vuelta después de enviar
      Navigator.pop(context);
    } on FirebaseException catch (e) {
      // Capturar errores específicos de Firebase
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error de Firestore al enviar: ${e.message} (${e.code})')),
      );
      print('Error de Firestore al registrar respuestas: $e');
    } catch (e) {
      // Capturar cualquier otra excepción
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error inesperado al enviar respuestas: ${e.toString()}')),
      );
      print('Excepción general al registrar respuestas: $e');
    }
  }

  // Widget para construir cada tipo de pregunta
  Widget buildPregunta(Map<String, dynamic> pregunta) {
    final tipo = pregunta['tipo'];
    final idPregunta = pregunta['id'] as String; // Asegurarse de que 'id' es String

    // Inicializar la respuesta para esta pregunta si aún no existe
    if (!respuestas.containsKey(idPregunta)) {
      respuestas[idPregunta] = null; // O un valor por defecto si aplica
    }

    switch (tipo) {
      case 'escala':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(pregunta['pregunta'], style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            DropdownButtonFormField<int>(
              decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'Selecciona una opción'),
              value: respuestas[idPregunta] as int?, // Castear a int?
              items: (pregunta['opciones'] as List<dynamic>)
                  .map((e) => DropdownMenuItem<int>(
                        value: e as int, // Castear el valor del DropdownMenuItem
                        child: Text(e.toString()),
                      ))
                  .toList(),
              onChanged: (value) => setState(() => respuestas[idPregunta] = value),
              validator: (value) => value == null ? 'Esta pregunta es requerida' : null,
            ),
            const SizedBox(height: 16),
          ],
        );
      case 'booleana': // Cambiado de 'si_no' a 'booleana' para coincidir con tus datos de ejemplo
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(pregunta['pregunta'], style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Row(
              children: ['Sí', 'No'].map((op) {
                return Expanded(
                  child: RadioListTile<String>(
                    title: Text(op),
                    value: op,
                    groupValue: respuestas[idPregunta] as String?, // Castear a String?
                    onChanged: (val) => setState(() => respuestas[idPregunta] = val),
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
            Text(pregunta['pregunta'], style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextFormField(
              maxLines: 3,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: "Escribe tu comentario aquí...",
              ),
              onChanged: (val) => respuestas[idPregunta] = val,
              // No hay validator aquí, ya que el texto es opcional por defecto
            ),
            const SizedBox(height: 16),
          ],
        );
      default:
        return const SizedBox.shrink(); // No muestra nada si el tipo no es reconocido
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

        if (snapshot.hasError) {
          print('Error en FutureBuilder de EncuestaScreen: ${snapshot.error}');
          return Scaffold(
            appBar: AppBar(title: const Text('Error')),
            body: Center(child: Text('Error al cargar la encuesta: ${snapshot.error}')),
          );
        }

        final encuesta = snapshot.data;

        if (encuesta == null || encuesta['preguntas'] == null || (encuesta['preguntas'] as List).isEmpty) {
          return Scaffold(
            appBar: AppBar(title: const Text('Encuesta No Encontrada')),
            body: Center(child: Text('No se encontró la encuesta o no tiene preguntas válidas.')),
          );
        }

        final preguntas = encuesta['preguntas'] as List<dynamic>;

        return Scaffold(
          appBar: AppBar(
            title: Text(encuesta['titulo'] ?? 'Encuesta'),
            backgroundColor: Colors.blue.shade700,
            foregroundColor: Colors.white,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Mapea la lista de preguntas a widgets de pregunta
                ...preguntas
                    .map((p) => buildPregunta(p as Map<String, dynamic>))
                    .toList(),
                const SizedBox(height: 16),
                Center(
                  child: ElevatedButton(
                    onPressed: () async {
                      // Validación: asegurar que las preguntas obligatorias estén respondidas
                      // Las preguntas obligatorias son 'escala' y 'booleana' (antes 'si_no')
                      final preguntasIncompletas = preguntas.where((pregunta) {
                        final tipo = pregunta['tipo'];
                        final idPregunta = pregunta['id'] as String;
                        final esObligatoria = tipo == 'escala' || tipo == 'booleana'; // Tipos obligatorios

                        // Verifica si la respuesta para esta pregunta obligatoria es nula o vacía
                        return esObligatoria && (respuestas[idPregunta] == null || respuestas[idPregunta].toString().isEmpty);
                      }).toList();

                      if (preguntasIncompletas.isNotEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Por favor, responde todas las preguntas obligatorias.')),
                        );
                        return;
                      }

                      // Todo bien, registrar respuestas
                      await registrarRespuestas();
                      // El SnackBar de éxito y el Navigator.pop() ahora están dentro de registrarRespuestas()
                    },
                    child: const Text('Enviar Respuestas'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 30),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      backgroundColor: Colors.green.shade600,
                      foregroundColor: Colors.white,
                      elevation: 5,
                    ),
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
