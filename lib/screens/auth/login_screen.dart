import 'package:flutter/material.dart';
import 'package:form_app/services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:form_app/services/auth_service.dart'; // Importar User para el tipo de retorno
// No necesitamos importar TeacherHomeScreen o StudentHomeScreen aquí directamente para la navegación,
// ya que main.dart se encargará de la redirección.

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _authService = AuthService(); // Instancia del servicio de autenticación
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController(); // Para el registro
  String _selectedRole = 'student'; // Rol por defecto para el registro
  bool _isLoginMode = true; // true para login, false para registro
  String? _errorMessage; // Para mostrar mensajes de error al usuario
  bool _isLoading = false; // Nuevo estado para controlar el indicador de carga

  // Muestra un diálogo de error al usuario.
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: <Widget>[
          TextButton(
            child: const Text('Ok'),
            onPressed: () {
              Navigator.of(ctx).pop(); // Cierra el diálogo
            },
          )
        ],
      ),
    );
  }

  // Función principal para autenticar (iniciar sesión o registrarse).
  Future<void> _authenticate() async {
    setState(() {
      _errorMessage = null; // Limpia cualquier mensaje de error anterior
      _isLoading = true; // Muestra el indicador de carga
    });

    User? user;
    if (_isLoginMode) {
      // Intenta iniciar sesión.
      user = await _authService.signIn(_emailController.text, _passwordController.text);
    } else {
      // Intenta registrarse.
      user = await _authService.signUp(_emailController.text, _passwordController.text, _selectedRole, _nameController.text);
    }

    setState(() {
      _isLoading = false; // Oculta el indicador de carga
    });

    if (user != null) {
      // Si la autenticación fue exitosa, no hacemos nada aquí.
      // main.dart con su StreamBuilder detectará el cambio de estado de autenticación
      // y se encargará de redirigir al usuario a la pantalla correcta (profesor/estudiante).
      print('Autenticación exitosa. main.dart se encargará de la navegación.');
    } else {
      // Si la autenticación falló, muestra un mensaje de error.
      _showErrorDialog(_isLoginMode ? 'Fallo en el inicio de sesión. Verifique sus credenciales.' : 'Fallo en el registro. Intente de nuevo.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isLoginMode ? 'Iniciar Sesión' : 'Registrarse'),
        centerTitle: true,
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Card(
            elevation: 8,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    _isLoginMode ? 'Bienvenido de nuevo' : 'Crea una cuenta',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 28, color: Colors.blue.shade800),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Correo Electrónico',
                      prefixIcon: Icon(Icons.email, color: Colors.blue),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _passwordController,
                    decoration: const InputDecoration(
                      labelText: 'Contraseña',
                      prefixIcon: Icon(Icons.lock, color: Colors.blue),
                    ),
                    obscureText: true,
                  ),
                  const SizedBox(height: 16),
                  // Campos adicionales para el modo de registro.
                  if (!_isLoginMode) ...[
                    TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nombre Completo',
                        prefixIcon: Icon(Icons.person, color: Colors.blue),
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedRole,
                      decoration: const InputDecoration(
                        labelText: 'Rol',
                        prefixIcon: Icon(Icons.group, color: Colors.blue),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'student', child: Text('Estudiante')),
                        DropdownMenuItem(value: 'teacher', child: Text('Profesor')),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedRole = value!;
                        });
                      },
                    ),
                    const SizedBox(height: 24),
                  ],
                  // Muestra el mensaje de error si existe.
                  if (_errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red, fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _authenticate, // Deshabilita el botón si está cargando
                      child: _isLoading
                          ? const CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            )
                          : Text(_isLoginMode ? 'Iniciar Sesión' : 'Registrarse'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade700,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: _isLoading
                        ? null // Deshabilita el botón si está cargando
                        : () {
                            setState(() {
                              _isLoginMode = !_isLoginMode; // Cambia entre modo login y registro
                              _errorMessage = null; // Limpia el mensaje de error al cambiar de modo
                            });
                          },
                    child: Text(
                      _isLoginMode
                          ? '¿No tienes una cuenta? Regístrate'
                          : '¿Ya tienes una cuenta? Inicia Sesión',
                      style: TextStyle(color: Colors.blue.shade600),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
