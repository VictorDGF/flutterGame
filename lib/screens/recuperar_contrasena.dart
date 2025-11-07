import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_game/utils/alert_helper.dart';

class RecuperarContrasenaScreen extends StatefulWidget {
  static const String routeName = '/recuperarContrasena';
  const RecuperarContrasenaScreen({super.key});

  @override
  State<RecuperarContrasenaScreen> createState() =>
      _RecuperarContrasenaScreenState();
}

class _RecuperarContrasenaScreenState extends State<RecuperarContrasenaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  bool _cargando = false;

  Future<void> _recuperarContrasena() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _cargando = true);

    try {
      await FirebaseAuth.instance
          .sendPasswordResetEmail(email: _emailController.text.trim());

      if (mounted) {
        AlertHelper.success(
            'Se ha enviado un enlace de recuperación al correo: ${_emailController.text.trim()}');
        Navigator.pop(context);
      }
    } on FirebaseAuthException catch (e) {
      String mensaje = 'Error al enviar el correo de recuperación';
      if (e.code == 'user-not-found') {
        mensaje = 'No existe un usuario con ese correo';
      } else if (e.code == 'invalid-email') {
        mensaje = 'El formato del correo no es válido';
      }

      AlertHelper.error(mensaje);
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recuperar contraseña'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    const Icon(Icons.lock_outline, size: 80, color: Colors.blue),
                    const SizedBox(height: 20),
                    const Text(
                      'Ingresa tu correo electrónico registrado y te enviaremos un enlace para restablecer tu contraseña.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 30),

                    // Campo de correo
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Correo electrónico',
                        prefixIcon: Icon(Icons.email_outlined),
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor, ingresa tu correo';
                        }
                        if (!value.contains('@')) {
                          return 'Correo no válido';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 30),

                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: _cargando
                          ? const Center(child: CircularProgressIndicator())
                          : ElevatedButton.icon(
                              onPressed: _recuperarContrasena,
                              icon: const Icon(Icons.send),
                              label: const Text('Enviar enlace'),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
