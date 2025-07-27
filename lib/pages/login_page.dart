import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _pwCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _pwCtrl.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    await AuthService.signInWithEmail(
      email: _emailCtrl.text.trim(),
      password: _pwCtrl.text.trim(),
    );
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    await AuthService.registerWithEmail(
      email: _emailCtrl.text.trim(),
      password: _pwCtrl.text.trim(),
    );
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('로그인 / 회원가입')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _emailCtrl,
                  decoration: const InputDecoration(labelText: '이메일'),
                  validator: (v) {
                    if (v == null || v.isEmpty) return '이메일을 입력하세요';
                    if (!v.contains('@')) return '유효한 이메일을 입력하세요';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _pwCtrl,
                  decoration: const InputDecoration(labelText: '비밀번호'),
                  obscureText: true,
                  validator: (v) {
                    if (v == null || v.isEmpty) return '비밀번호를 입력하세요';
                    if (v.length < 6) return '6자 이상 입력하세요';
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                _loading
                    ? const CircularProgressIndicator()
                    : Column(
                        children: [
                          ElevatedButton(
                            onPressed: _signIn,
                            child: const Text('로그인'),
                          ),
                          const SizedBox(height: 12),
                          OutlinedButton(
                            onPressed: _register,
                            child: const Text('회원가입'),
                          ),
                        ],
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
