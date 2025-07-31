import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:form_app/services/auth_service.dart';
import 'package:form_app/screens/auth/login_screen.dart';
import 'package:form_app/screens/teacher/create_form_screen.dart';
import 'package:form_app/screens/teacher/my_forms_screen.dart';
import 'package:form_app/screens/teacher/internal_forms_screen.dart';
import 'package:form_app/screens/teacher/create_intform_screen.dart';
import 'package:form_app/screens/teacher/teacher_survey_results_list_screen.dart';

class TeacherHomeScreen extends StatefulWidget {
  const TeacherHomeScreen({super.key});

  @override
  State<TeacherHomeScreen> createState() => _TeacherHomeScreenState();
}

class _TeacherHomeScreenState extends State<TeacherHomeScreen> {
  final AuthService _authService = AuthService();
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    _currentUser = _authService.getCurrentUser();
  }

  void _logout() async {
    await _authService.signOut();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  Future<String?> _getUserName() async {
    final uid = _currentUser?.uid;
    if (uid == null) return null;

    final doc = await FirebaseFirestore.instance.collection('users').doc(FirebaseAuth.instance.currentUser!.uid).get();
    if (doc.exists) {
      return doc.data()?['name'] as String?;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          'Panel del Profesor',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            letterSpacing: 0.5,
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        elevation: 6,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Cerrar Sesión',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 600;
            final itemWidth = isWide ? (constraints.maxWidth / 2) - 30 : constraints.maxWidth;

            if (isWide) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Panel fijo a la izquierda con bienvenida
                  Expanded(
                    child: Container(
                      width: 300,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE3F2FD),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF0D47A1),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          SizedBox(
                            child: Text(
                              '¡Bienvenido, Profesor!',
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF0D47A1),
                                  ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (_currentUser != null)
                            FutureBuilder<String?>(
                              future: _getUserName(),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState == ConnectionState.waiting) {
                                  return const CircularProgressIndicator();
                                } else if (snapshot.hasError) {
                                  return Text('Error al cargar el nombre: ${snapshot.error}');
                                } else if (snapshot.hasData && snapshot.data != null) {
                                  return Text(
                                    'Has iniciado sesión como: ${snapshot.data}',
                                    style: Theme.of(context).textTheme.bodyMedium,
                                    textAlign: TextAlign.center,
                                  );
                                } else {
                                  return Text(
                                    'Has iniciado sesión como: ${_currentUser!.email}',
                                    style: Theme.of(context).textTheme.bodyMedium,
                                    textAlign: TextAlign.center,
                                  );
                                }
                              },
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 32),
                  // Botones scrollables a la derecha
                  Expanded(
                    child: SingleChildScrollView(
                      child: Wrap(
                        spacing: 20,
                        runSpacing: 20,
                        children: [
                          _buildCard(
                            context,
                            title: 'Crear Formulario',
                            icon: Icons.add_circle_outline,
                            description: 'Añade formularios externos',
                            color: const Color(0xFF42A5F5),
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const CreateFormScreen()),
                            ),
                          ),
                          _buildCard(
                            context,
                            title: 'Mis Formularios',
                            icon: Icons.list_alt,
                            description: 'Visualiza los formularios que hayas exportado',
                            color: const Color(0xFF26C6DA),
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const MyFormsScreen()),
                            ),
                          ),
                          _buildCard(
                            context,
                            title: 'Obtener Formularios',
                            icon: Icons.cloud_download,
                            description: 'Elige formularios que deseas utilizar en tu clase',
                            color: const Color(0xFF66BB6A),
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => UploadInternalSurveysScreen()),
                            ),
                          ),
                          _buildCard(
                            context,
                            title: 'Formularios Internos',
                            icon: Icons.assignment,
                            description: 'Comparte formularios breves con tu clase',
                            color: const Color(0xFFAB47BC),
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const InternalFormsScreen()),
                            ),
                          ),
                          _buildCard(
                            context,
                            title: 'Ver Respuestas',
                            icon: Icons.bar_chart, // Icono más adecuado para gráficos
                            description: 'Visualiza los resultados de tus encuestas', // Descripción actualizada
                            color: const Color(0xFFFF7043),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const TeacherSurveyResultsListScreen()), // 
                              );
                            },
                          ),
                        ].map((card) {
                          return SizedBox(width: itemWidth, child: card);
                        }).toList(),
                      ),
                    ),
                  ),
                ],
              );
            } else {
              // Pantallas pequeñas (columna con scroll)
              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE3F2FD),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF0D47A1),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Text(
                            '¡Bienvenido, Profesor!',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF0D47A1),
                                ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          if (_currentUser != null)
                            FutureBuilder<String?>(
                              future: _getUserName(),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState == ConnectionState.waiting) {
                                  return const CircularProgressIndicator();
                                } else if (snapshot.hasError) {
                                  return Text('Error al cargar el nombre: ${snapshot.error}');
                                } else if (snapshot.hasData && snapshot.data != null) {
                                  return Text(
                                    'Has iniciado sesión como: ${snapshot.data}',
                                    style: Theme.of(context).textTheme.bodyMedium,
                                    textAlign: TextAlign.center,
                                  );
                                } else {
                                  return Text(
                                    'Has iniciado sesión como: ${_currentUser!.email}',
                                    style: Theme.of(context).textTheme.bodyMedium,
                                    textAlign: TextAlign.center,
                                  );
                                }
                              },
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    Wrap(
                      spacing: 20,
                      runSpacing: 20,
                      alignment: WrapAlignment.center,
                      children: [
                        _buildCard(
                          context,
                          title: 'Crear Formulario',
                          icon: Icons.add_circle_outline,
                          description: 'Añade formularios externos',
                          color: const Color(0xFF42A5F5),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const CreateFormScreen()),
                          ),
                        ),
                        _buildCard(
                          context,
                          title: 'Mis Formularios',
                          icon: Icons.list_alt,
                          description: 'Visualiza los formularios que hayas exportado',
                          color: const Color(0xFF26C6DA),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const MyFormsScreen()),
                          ),
                        ),
                        _buildCard(
                          context,
                          title: 'Obtener Formularios',
                          icon: Icons.cloud_download,
                          description: 'Elige formularios que deseas utilizar en tu clase',
                          color: const Color(0xFF66BB6A),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => UploadInternalSurveysScreen()),
                          ),
                        ),
                        _buildCard(
                          context,
                          title: 'Formularios Internos',
                          icon: Icons.assignment,
                          description: 'Comparte formularios breves con tu clase',
                          color: const Color(0xFFAB47BC),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const InternalFormsScreen()),
                          ),
                        ),
                        _buildCard(
                          context,
                          title: 'Ver Respuestas',
                          icon: Icons.bar_chart,
                          description: 'Visualiza los resultados de tus encuestas',
                          color: const Color(0xFFFF7043),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const TeacherSurveyResultsListScreen()), 
                            );
                          },
                        ),
                      ].map((card) {
                        return SizedBox(width: itemWidth, child: card);
                      }).toList(),
                    ),
                  ],
                ),
              );
            }
          },
        ),
      ),
    );
  }

  Widget _buildCard(
      BuildContext context, {
        required String title,
        required IconData icon,
        required Color color,
        required VoidCallback onTap,
        String? description,
      }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Card(
        elevation: 6,
        shadowColor: color.withAlpha(102),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [
                color.withAlpha(230),
                color.withAlpha(180),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 40, color: Colors.white),
              const SizedBox(height: 10),
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
              ),
              if (description != null) ...[
                const SizedBox(height: 6),
                Text(
                  description,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: const Color.fromRGBO(255, 255, 255, 0.85),
                        fontSize: 12,
                      ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}