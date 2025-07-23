import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Obtiene el usuario actualmente autenticado.
  User? getCurrentUser() {
    return _auth.currentUser;
  }

  // Registra un nuevo usuario con email, contraseña, rol y nombre.
  Future<User?> signUp(String email, String password, String role, String name) async {
    try {
      // Crea el usuario en Firebase Authentication.
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      // Guarda la información adicional del usuario (rol y nombre) en Firestore.
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'email': email,
        'role': role,
        'name': name,
        'createdAt': FieldValue.serverTimestamp(), // Marca de tiempo de creación
      });
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      // Manejo de errores específicos de Firebase Authentication.
      print('Error de registro: ${e.message}');
      return null;
    } catch (e) {
      // Manejo de otros errores.
      print('Error inesperado durante el registro: $e');
      return null;
    }
  }

  // Inicia sesión con email y contraseña.
  Future<User?> signIn(String email, String password) async {
    try {
      // Intenta iniciar sesión en Firebase Authentication.
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      // Manejo de errores específicos de Firebase Authentication.
      print('Error de inicio de sesión: ${e.message}');
      return null;
    } catch (e) {
      // Manejo de otros errores.
      print('Error inesperado durante el inicio de sesión: $e');
      return null;
    }
  }

  // Cierra la sesión del usuario actual.
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Obtiene el rol de un usuario desde Firestore dado su UID.
  Future<String?> getUserRole(String uid) async {
    try {
      // Busca el documento del usuario en la colección 'users'.
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(uid).get();
      if (userDoc.exists) {
        // Retorna el campo 'role' si existe.
        return userDoc.get('role');
      }
      return null; // Retorna null si el documento no existe o no tiene el campo 'role'.
    } catch (e) {
      print('Error al obtener el rol del usuario: $e');
      return null;
    }
  }
}
