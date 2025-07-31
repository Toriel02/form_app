import 'package:flutter/foundation.dart'; // Importar para kDebugMode
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance; // Usar _db consistentemente
  final FirebaseAuth _auth = FirebaseAuth.instance;


  // --- Datos de ejemplo para las encuestas (AHORA CON CAMPO 'id' PARA CADA PREGUNTA) ---
  final List<Map<String, dynamic>> encuesta1 = [
  {
    "id": "p1",
    "texto": "¿Qué tan dinámica te pareció la clase de hoy?",
    "tipo": "escala",
    "opciones": [1, 2, 3, 4, 5]
  },
  {
    "id": "p2",
    "texto": "¿El docente propició la participación del grupo?",
    "tipo": "si_no"
  },
  {
    "id": "p3",
    "texto": "¿Se realizaron actividades prácticas durante la clase?",
    "tipo": "si_no"
  },
  {
    "id": "p4",
    "texto": "¿Consideras que el ritmo fue adecuado para todos?",
    "tipo": "si_no"
  },
  {
    "id": "p5",
    "texto": "¿Qué sugerencias tienes para mejorar la dinámica?",
    "tipo": "texto"
  },
];
final List<Map<String, dynamic>> encuesta2 = [
  {
    "id": "p1",
    "texto": "¿Qué tan clara fue la explicación de los temas?",
    "tipo": "escala",
    "opciones": [1, 2, 3, 4, 5]
  },
  {
    "id": "p2",
    "texto": "¿Se resolvieron tus dudas durante la clase?",
    "tipo": "si_no"
  },
  {
    "id": "p3",
    "texto": "¿El lenguaje utilizado fue adecuado para tu nivel?",
    "tipo": "si_no"
  },
  {
    "id": "p4",
    "texto": "¿Te resultó fácil seguir el hilo de la explicación?",
    "tipo": "escala",
    "opciones": [1, 2, 3, 4, 5]
  },
  {
    "id": "p5",
    "texto": "¿Qué mejorarías en la forma de explicar los temas?",
    "tipo": "texto"
  },
];
final List<Map<String, dynamic>> encuesta3 = [
  {
    "id": "p1",
    "texto": "¿Qué tan difícil te pareció el contenido de la clase?",
    "tipo": "escala",
    "opciones": [1, 2, 3, 4, 5]
  },
  {
    "id": "p2",
    "texto": "¿Te sentiste abrumado por la cantidad de información?",
    "tipo": "si_no"
  },
  {
    "id": "p3",
    "texto": "¿El ritmo fue muy rápido para ti?",
    "tipo": "si_no"
  },
  {
    "id": "p4",
    "texto": "¿Te sentiste cómodo con la dificultad general del curso?",
    "tipo": "escala",
    "opciones": [1, 2, 3, 4, 5]
  },
  {
    "id": "p5",
    "texto": "¿Tienes sugerencias para mejorar el ritmo o dificultad?",
    "tipo": "texto"
  },
];

final List<Map<String, dynamic>> encuesta4 = [
  {
    "id": "p1",
    "texto": "¿Qué tan útil era el material presentado?",
    "tipo": "escala",
    "opciones": [1, 2, 3, 4, 5]
  },
  {
    "id": "p2",
    "texto": "¿Los materiales estaban disponibles con antelación?",
    "tipo": "si_no"
  },
  {
    "id": "p3",
    "texto": "¿Los recursos facilitaron tu aprendizaje?",
    "tipo": "si_no"
  },
  {
    "id": "p4",
    "texto": "¿Consideras que hubo suficiente material complementario?",
    "tipo": "escala",
    "opciones": [1, 2, 3, 4, 5]
  },
  {
    "id": "p5",
    "texto": "¿Qué material adicional te gustaría tener?",
    "tipo": "texto"
  },
];

final List<Map<String, dynamic>> encuesta5 = [
  {
    "id": "p1",
    "texto": "¿Qué tan relevante fue el contenido para tu formación?",
    "tipo": "escala",
    "opciones": [1, 2, 3, 4, 5]
  },
  {
    "id": "p2",
    "texto": "¿Pudiste relacionar lo aprendido con casos reales?",
    "tipo": "si_no"
  },
  {
    "id": "p3",
    "texto": "¿Crees que el contenido será útil en tu vida profesional?",
    "tipo": "si_no"
  },
  {
    "id": "p4",
    "texto": "¿Te pareció actualizada la información presentada?",
    "tipo": "escala",
    "opciones": [1, 2, 3, 4, 5]
  },
  {
    "id": "p5",
    "texto": "¿Qué otro contenido te gustaría que se abordara?",
    "tipo": "texto"
  },
];

  // --- Fin de datos de ejemplo ---


  // --- Funciones para Formularios (existentes) ---

  // Método para añadir un formulario a Firestore
  Future<String?> addFormToFirestore({
    required String titulo,
    required String urlDeForms,
    required String qrCodeUrl, // Ahora se espera la URL del QR
  }) async {
    User? currentUser = _auth.currentUser;
    if (currentUser == null) {
      print("Usuario no autenticado.");
      return null;
    }

    try {
      DocumentReference docRef = await _db.collection('forms').add({
        'titulo': titulo,
        'urlDeForms': urlDeForms,
        'qrCodeUrl': qrCodeUrl, // Se guarda la URL del QR aquí
        'teacherId': currentUser.uid, // Asegúrate de guardar el UID del profesor
        'fechaCreacion': FieldValue.serverTimestamp(), // Para ordenar y saber cuándo se creó
      });
      print("Formulario agregado con ID: ${docRef.id}");
      return docRef.id;
    } catch (e) {
      print("Error al agregar formulario: $e");
      return null;
    }
  }

  // Método para obtener los formularios del profesor actual en tiempo real
  Stream<List<Map<String, dynamic>>> getMyForms() { // Renombrado de getMyFormsDuplicate a getMyForms
    User? currentUser = _auth.currentUser;
    if (currentUser == null) {
      if (kDebugMode) {
        print("DEBUG: getMyForms - No hay usuario autenticado.");
      }
      return Stream.value([]); // Retorna un stream vacío si no hay usuario
    }

    final String currentUserId = currentUser.uid;
    if (kDebugMode) {
      print("DEBUG: getMyForms - UID del usuario actual: $currentUserId");
    }

    return _db
        .collection('forms')
        .where('teacherId', isEqualTo: currentUserId) // Filtra por el ID del profesor actual
        .orderBy('fechaCreacion', descending: true) // Ordena por la fecha de creación (asegúrate que el campo sea 'fechaCreacion')
        .snapshots() // Obtiene un stream de actualizaciones en tiempo real
        .map((snapshot) => snapshot.docs.map((doc) {
              // Convierte cada documento a un mapa, incluyendo el ID del documento
              if (kDebugMode) {
                print("DEBUG: Formulario encontrado - ID: ${doc.id}, teacherId en DB: ${doc.data()['teacherId']}");
              }
              return {'id': doc.id, ...doc.data()};
            }).toList());
  }

  // --- Nuevas Funciones para Encuestas ---

  // Función para añadir una única encuesta a Firestore
  Future<String?> addEncuestaToFirestore({
    required String titulo,
    required List<Map<String, dynamic>> preguntas,
    required String teacherId,
  }) async {
    try {
      final encuestaData = {
        "titulo": titulo,
        "preguntas": preguntas,
        "teacherId": teacherId,
        "fechaCreacion": FieldValue.serverTimestamp(),
      };

      final docRef = await _db.collection('encuestas').add(encuestaData); // Usar _db
      print('Encuesta añadida con ID: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      print('Error al añadir encuesta: $e');
      return null;
    }
  }

  // Función que sube un conjunto predefinido de encuestas para un profesor
  Future<void> subirEncuestasPorProfesor(String teacherId) async {
    // Verifica si ya hay encuestas del profesor para evitar duplicados
    final existing = await _db // Usar _db
        .collection('encuestas')
        .where('teacherId', isEqualTo: teacherId)
        .limit(1) // Solo necesitamos saber si hay al menos una
        .get();

    if (existing.docs.isNotEmpty) {
      print('Ya existen encuestas para este profesor. No se suben duplicados.');
      return;
    }

    // Definición de las encuestas a subir
    final encuestas = [
      {'titulo': 'Dinámica Utilizada', 'preguntas': encuesta1},
      {'titulo': 'Opinión de Explicación', 'preguntas': encuesta2},
      {'titulo': 'Dificultad y Ritmo del Curso', 'preguntas': encuesta3},
      {'titulo': 'Recursos y Materiales del Curso', 'preguntas': encuesta4},
      {'titulo': 'Relevancia del Contenido', 'preguntas': encuesta5},
    ];

    for (var encuesta in encuestas) {
      final id = await addEncuestaToFirestore(
        titulo: encuesta['titulo'] as String,
        preguntas: encuesta['preguntas'] as List<Map<String, dynamic>>,
        teacherId: teacherId,
      );
      print('Encuesta "${encuesta['titulo']}" subida con ID: $id');
    }
  }

  // Función para obtener encuestas por profesor en tiempo real
  Stream<List<Map<String, dynamic>>> obtenerEncuestasPorProfesor(String teacherId) {
    return _db // Usar _db
        .collection('encuestas')
        .where('teacherId', isEqualTo: teacherId)
        .orderBy('fechaCreacion', descending: true) // Añadido orden para consistencia
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              data['id'] = doc.id;
              return data;
            }).toList());
  }

  // Función para obtener encuestas por profesor una sola vez (no en tiempo real)
  Future<List<Map<String, dynamic>>> obtenerEncuestasPorProfesorUnaVez(String teacherId) async {
    final snapshot = await _db // Usar _db
        .collection('encuestas')
        .where('teacherId', isEqualTo: teacherId)
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id; // Añadir el ID del documento al mapa de datos
      return data;
    }).toList();
  }

  // NAVEGACION ESCANER
  Future<Map<String, dynamic>?> obtenerEncuestaPorId(String id) async {
    try {
      final doc = await _db.collection('encuestas').doc(id).get();
      if (doc.exists) {
        // Retorna el mapa de datos y añade el ID del documento
        return {'id': doc.id, ...doc.data() as Map<String, dynamic>};
      } else {
        return null;
      }
    } catch (e) {
      // ¡IMPORTANTE! Relanzar la excepción para que la pantalla que llama pueda manejarla.
      // Esto permite que el bloque `on FirebaseException catch (e)` en QRScannerScreen funcione.
      rethrow; 
    }
  }
  Future<String?> addResponseToFirestore({
    required String encuestaId,           // El ID de la encuesta a la que se responde
    required String teacherId,        // El ID del profesor que creó la encuesta
    required Map<String, dynamic> responseData, // Las respuestas reales de la encuesta
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print("Error: No hay usuario autenticado.");
        return null;
      }
      final studentId = user.uid; // El UID del estudiante actual

      // Datos del documento de respuesta a añadir
      final Map<String, dynamic> nuevaRespuestaData = {
        "encuestaId": encuestaId, // Cambiado de formId a encuestaId
        "studentId": studentId,
        "teacherId": teacherId, // Necesitamos este para las reglas de seguridad del profesor
        "data": responseData,   // El mapa con las respuestas
        "timestamp": FieldValue.serverTimestamp(), // Fecha y hora de envío de la respuesta
      };

      // Añade el documento a la subcolección 'respuestas' dentro de la encuesta
      DocumentReference docRef = await _db // Usar _db aquí
          .collection("encuestas")
          .doc(encuestaId)
          .collection("respuestas")
          .add(nuevaRespuestaData);

      print("Documento de respuesta añadido con ID: ${docRef.id}");
      return docRef.id; // Retorna el ID del documento de respuesta
    } catch (e) {
      print("Error al añadir el documento de respuesta: $e");
      rethrow; // Relanzar la excepción para que la pantalla que llama pueda manejarla
    }
  }
}