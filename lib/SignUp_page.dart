// lib/SignUp_page.dart
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:firebase_auth/firebase_auth.dart';

//////////////////////////////////////////////////////////////////////////////
//  SIGN‑UP PAGE  – egg mascot, credentials form, Firebase Auth
//////////////////////////////////////////////////////////////////////////////

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _formKey  = GlobalKey<FormState>();
  final _nameCtl  = TextEditingController();
  final _emailCtl = TextEditingController();
  final _pwdCtl   = TextEditingController();
  final _pwd2Ctl  = TextEditingController();

  bool _obscurePwd1 = true;
  bool _obscurePwd2 = true;
  bool _agreeTerms  = false;
  bool _loading     = false;

  // ────────────────────────────────────────────────────────────────────
  //  HELPERS
  // ────────────────────────────────────────────────────────────────────
  /// Remove stray new‑lines that mobile keyboards sometimes append.
  String _cleanPwd(String raw) => raw.replaceAll('\n', '');

  InputDecoration _decor(String label, IconData icon, {Widget? suffix}) =>
      InputDecoration(
        filled: true,
        fillColor: Colors.white,
        labelText: label,
        prefixIcon: Icon(icon),
        suffixIcon: suffix,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      );

  @override
  void dispose() {
    _nameCtl.dispose();
    _emailCtl.dispose();
    _pwdCtl.dispose();
    _pwd2Ctl.dispose();
    super.dispose();
  }

  // ────────────────────────────────────────────────────────────────────
  //  SIGN‑UP
  // ────────────────────────────────────────────────────────────────────
  Future<void> _onSubmit() async {
    if (!_formKey.currentState!.validate() || !_agreeTerms) return;

    setState(() => _loading = true);

    final email = _emailCtl.text.trim();
    final pwd   = _cleanPwd(_pwdCtl.text);            // NEW
    final name  = _nameCtl.text.trim();

    try {
      final cred = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: pwd);

      print('DEBUG ▸ signup success, uid=${cred.user?.uid}');          // NEW

      await cred.user?.updateDisplayName(name);
      // await cred.user?.sendEmailVerification(); // ← enable if you block sign‑in until verified

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Account created!')),
      );
      Navigator.pushReplacementNamed(context, '/home');
    } on FirebaseAuthException catch (e) {
      print('DEBUG ▸ signup error ${e.code}: ${e.message}');            // NEW
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${e.code}: ${e.message}')),
      );
    } catch (e) {
      print('DEBUG ▸ unexpected signup error $e');                      // NEW
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unexpected error during sign‑up')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ────────────────────────────────────────────────────────────────────
  //  UI
  // ────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    const brandTeal  = Color(0xFF4CAFAD);
    const brandAmber = Color(0xFFFFC866);

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topCenter,
            radius: 1.2,
            colors: [Color(0xFFEAFDF7), Color(0xFFF9FEFD)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(children: [
              const SizedBox(height: 24),

              // mascot
              Lottie.asset('assets/animations/egg_idle.json',
                  width: 120, height: 120, repeat: true, fit: BoxFit.contain),
              const SizedBox(height: 12),

              Text('Hatch your savings journey!',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Colors.teal[900],
                  )),
              const SizedBox(height: 24),

              // ───── FORM ─────
              Form(
                key: _formKey,
                child: Column(children: [
                  TextFormField(
                    controller: _nameCtl,
                    decoration: _decor('Display name', Icons.person_outline),
                    textInputAction: TextInputAction.next,
                    validator: (v) =>
                    (v == null || v.trim().length < 2) ? 'Name too short' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _emailCtl,
                    decoration: _decor('Email address', Icons.mail_outline),
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.email],
                    validator: (v) => (v == null || v.isEmpty)
                        ? 'Enter e‑mail'
                        : (!RegExp(r'.+@.+\..+').hasMatch(v.trim())
                        ? 'Invalid e‑mail'
                        : null),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _pwdCtl,
                    obscureText: _obscurePwd1,
                    decoration: _decor(
                      'Password',
                      Icons.lock_outline,
                      suffix: IconButton(
                        icon: Icon(_obscurePwd1
                            ? Icons.visibility
                            : Icons.visibility_off),
                        onPressed: () =>
                            setState(() => _obscurePwd1 = !_obscurePwd1),
                      ),
                    ),
                    textInputAction: TextInputAction.next,
                    validator: (v) =>
                    (v == null || v.length < 6) ? 'Min 6 chars' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _pwd2Ctl,
                    obscureText: _obscurePwd2,
                    decoration: _decor(
                      'Confirm password',
                      Icons.lock_outline,
                      suffix: IconButton(
                        icon: Icon(_obscurePwd2
                            ? Icons.visibility
                            : Icons.visibility_off),
                        onPressed: () =>
                            setState(() => _obscurePwd2 = !_obscurePwd2),
                      ),
                    ),
                    textInputAction: TextInputAction.done,
                    validator: (v) =>
                    (v != _pwdCtl.text) ? 'Passwords don’t match' : null,
                  ),
                ]),
              ),
              const SizedBox(height: 24),

              // terms checkbox
              Row(children: [
                Checkbox(
                  value: _agreeTerms,
                  onChanged: (v) => setState(() => _agreeTerms = v!),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4)),
                ),
                Expanded(
                  child: Wrap(children: [
                    const Text('I agree to the '),
                    GestureDetector(
                      onTap: _openTerms,
                      child: Text(
                        'Terms & Privacy',
                        style: TextStyle(
                          color: brandTeal,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ]),
                ),
              ]),
              const SizedBox(height: 16),

              // primary CTA
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: (_agreeTerms && !_loading) ? _onSubmit : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: brandTeal,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _loading
                      ? const CircularProgressIndicator(strokeWidth: 2)
                      : const Text('CONTINUE'),
                ),
              ),
              const SizedBox(height: 24),

              // social placeholders
              Row(children: [
                Expanded(child: Divider(color: Colors.teal[200])),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text('or sign up with'),
                ),
                Expanded(child: Divider(color: Colors.teal[200])),
              ]),
              const SizedBox(height: 12),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: const [
                _SocialButton(asset: 'assets/images/google_logo.png'),
                SizedBox(width: 24),
                _SocialButton(asset: 'assets/images/apple_logo.png'),
              ]),
              const SizedBox(height: 24),

              TextButton(
                onPressed: _loading ? null : () => Navigator.pop(context),
                child: const Text('Already have an account? Log in'),
              ),
              const SizedBox(height: 24),
            ]),
          ),
        ),
      ),
    );
  }

  // opens your “Terms & Privacy” modal (unchanged)
  void _openTerms() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        maxChildSize: 0.9,
        builder: (_, controller) => Padding(
          padding: const EdgeInsets.all(24),
          child: ListView(
            controller: controller,
            children: const [
              Text('Terms & Privacy',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              SizedBox(height: 12),
              Text('Put your markdown‑converted terms here…',
                  style: TextStyle(height: 1.4)),
            ],
          ),
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────
//  Reusable social‑login button  (placeholder)
// ────────────────────────────────────────────────────────────────────
class _SocialButton extends StatelessWidget {
  const _SocialButton({required this.asset, this.onTap});
  final String asset;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 56,
      height: 56,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
              offset: Offset(0, 2),
              blurRadius: 6,
              color: Color(0x22000000)),
        ],
      ),
      child: Image.asset(asset, fit: BoxFit.contain),
    ),
  );
}




