// lib/services/firestore_service.dart
import 'package:flutter/foundation.dart'; // Importar para kDebugMode
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:form_app/screens/encuestas/encuesta_1.dart';
import 'package:form_app/screens/encuestas/encuesta_2.dart';
import 'package:form_app/screens/encuestas/encuesta_3.dart';
import 'package:form_app/screens/encuestas/encuesta_4.dart';
import 'package:form_app/screens/encuestas/encuesta_5.dart'; // Para obtener el UID del estudiante

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;


  // --- Datos de ejemplo para las encuestas ---
  // Estos datos deberían ser definidos en un lugar apropiado (ej. un archivo de constantes o modelos)
  // Por simplicidad, los incluyo aquí.
  final List<Map<String, dynamic>> encuesta1 = [
    {'pregunta': '¿Qué tan efectiva fue la dinámica utilizada en clase?', 'tipo': 'escala', 'opciones': ['1', '2', '3', '4', '5']},
    {'pregunta': '¿La dinámica te ayudó a comprender mejor el tema?', 'tipo': 'booleana'},
  ];
  final List<Map<String, dynamic>> encuesta2 = [
    {'pregunta': '¿Qué tan clara fue la explicación del profesor?', 'tipo': 'escala', 'opciones': ['1', '2', '3', '4', '5']},
    {'pregunta': '¿El profesor resolvió tus dudas de manera efectiva?', 'tipo': 'booleana'},
  ];
  final List<Map<String, dynamic>> encuesta3 = [
    {'pregunta': '¿Consideras que el ritmo del curso es adecuado?', 'tipo': 'escala', 'opciones': ['1', '2', '3', '4', '5']},
    {'pregunta': '¿La dificultad de los temas es apropiada?', 'tipo': 'booleana'},
  ];
  final List<Map<String, dynamic>> encuesta4 = [
    {'pregunta': '¿Los recursos y materiales del curso son útiles?', 'tipo': 'escala', 'opciones': ['1', '2', '3', '4', '5']},
    {'pregunta': '¿Hay suficientes materiales complementarios?', 'tipo': 'booleana'},
  ];
  final List<Map<String, dynamic>> encuesta5 = [
    {'pregunta': '¿El contenido del curso es relevante para tus intereses?', 'tipo': 'escala', 'opciones': ['1', '2', '3', '4', '5']},
    {'pregunta': '¿El curso te prepara para desafíos futuros?', 'tipo': 'booleana'},
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
  Stream<List<Map<String, dynamic>>> getMyFormsDuplicate() {
      User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        if (kDebugMode) {
          print("DEBUG: getMyFormsDuplicate - No hay usuario autenticado.");
        }
        return Stream.value([]); // Retorna un stream vacío si no hay usuario
      }
  
      final String currentUserId = currentUser.uid;
      if (kDebugMode) {
        print("DEBUG: getMyFormsDuplicate - UID del usuario actual: $currentUserId");
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
  return FirebaseFirestore.instance
      .collection('encuestas')
      .where('teacherId', isEqualTo: teacherId)
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

  // **** NUEVA FUNCIÓN: Añadir una respuesta a Firestore ****
  Future<String?> addResponseToFirestore({
    required String formId,           // El ID del formulario al que se responde
    required String teacherId,        // El ID del profesor que creó el formulario
    required Map<String, dynamic> responseData, // Las respuestas reales del formulario
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
        "formId": formId,
        "studentId": studentId,
        "teacherId": teacherId, // Necesitamos este para las reglas de seguridad del profesor
        "data": responseData,   // El mapa con las respuestas
        "timestamp": FieldValue.serverTimestamp(), // Fecha y hora de envío de la respuesta
      };

      // Añade el documento a la colección 'responses'
      DocumentReference docRef = await _firestore.collection("responses").add(nuevaRespuestaData);

      print("Documento de respuesta añadido con ID: ${docRef.id}");
      return docRef.id; // Retorna el ID del documento de respuesta
    } catch (e) {
      print("Error al añadir el documento de respuesta: $e");
      return null;
    }
  }

  // Aquí podrías añadir funciones para:
  // - getFormsByTeacherId (para que el profesor vea sus formularios)
  // - getResponsesByFormId (para que el profesor vea las respuestas de un formulario específico)
  // - getMyResponses (para que el estudiante vea sus propias respuestas)
Stream<List<Map<String, dynamic>>> getMyForms() {
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
}