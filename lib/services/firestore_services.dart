// lib/services/firestore_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Para obtener el UID del estudiante

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Constructor (puede ser vacío si solo tienes métodos estáticos, pero es buena práctica)
  // FirestoreService(); // Si haces los métodos estáticos, no necesitarías instanciar la clase.

  // Función para añadir un nuevo formulario (ya la teníamos)
  Future<String?> addFormToFirestore({
    required String titulo,
    required String urlDeForms,
    String qrCodeUrl = '',
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print("Error: No hay usuario autenticado.");
        return null;
      }
      final teacherId = user.uid; // El UID del profesor actual

      final Map<String, dynamic> nuevoFormularioData = {
        "titulo": titulo,
        "urlDeForms": urlDeForms,
        "qrCodeUrl": qrCodeUrl,
        "teacherId": teacherId,
        "fechaCreacion": FieldValue.serverTimestamp(),
      };

      DocumentReference docRef = await _firestore.collection("forms").add(nuevoFormularioData);
      print("Documento de formulario añadido con ID: ${docRef.id}");
      return docRef.id;
    } catch (e) {
      print("Error al añadir el documento del formulario: $e");
      return null;
    }
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
}