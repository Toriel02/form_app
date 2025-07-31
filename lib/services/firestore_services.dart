import 'package:flutter/foundation.dart'; // Importar para kDebugMode
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance; // Usar _db consistentemente
  final FirebaseAuth _auth = FirebaseAuth.instance;


  // --- Datos de ejemplo para las encuestas (AHORA CON CAMPO 'id' PARA CADA PREGUNTA) ---
  final List<Map<String, dynamic>> encuesta1 = [
    {'id': 'q1_dinamica', 'pregunta': '¿Qué tan efectiva fue la dinámica utilizada en clase?', 'tipo': 'escala', 'opciones': [1, 2, 3, 4, 5]},
    {'id': 'q2_comprension', 'pregunta': '¿La dinámica te ayudó a comprender mejor el tema?', 'tipo': 'booleana'},
  ];
  final List<Map<String, dynamic>> encuesta2 = [
    {'id': 'q3_explicacion', 'pregunta': '¿Qué tan clara fue la explicación del profesor?', 'tipo': 'escala', 'opciones': [1, 2, 3, 4, 5]},
    {'id': 'q4_dudas', 'pregunta': '¿El profesor resolvió tus dudas de manera efectiva?', 'tipo': 'booleana'},
  ];
  final List<Map<String, dynamic>> encuesta3 = [
    {'id': 'q5_ritmo', 'pregunta': '¿Consideras que el ritmo del curso es adecuado?', 'tipo': 'escala', 'opciones': [1, 2, 3, 4, 5]},
    {'id': 'q6_dificultad', 'pregunta': '¿La dificultad de los temas es apropiada?', 'tipo': 'booleana'},
  ];
  final List<Map<String, dynamic>> encuesta4 = [
    {'id': 'q7_recursos', 'pregunta': '¿Los recursos y materiales del curso son útiles?', 'tipo': 'escala', 'opciones': [1, 2, 3, 4, 5]},
    {'id': 'q8_materiales', 'pregunta': '¿Hay suficientes materiales complementarios?', 'tipo': 'booleana'},
  ];
  final List<Map<String, dynamic>> encuesta5 = [
    {'id': 'q9_relevancia', 'pregunta': '¿El contenido del curso es relevante para tus intereses?', 'tipo': 'escala', 'opciones': [1, 2, 3, 4, 5]},
    {'id': 'q10_preparacion', 'pregunta': '¿El curso te prepara para desafíos futuros?', 'tipo': 'booleana'},
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
}
