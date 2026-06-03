import 'dart:async';

import 'dart:ui';
import 'package:flutter/material.dart';

import 'package:pharmacy_wms/Models/UserRoleModel.dart';

import 'package:pharmacy_wms/Models/app_localizations.dart';

import 'package:pharmacy_wms/main.dart';

import 'package:pharmacy_wms/views/Mainlayout.dart';

class Loginview extends StatelessWidget {
  const Loginview({
super.key
});
  @override  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: AuthService.sessionChanges,
      builder: (context, sessionTick, child) {
        final authenticated = AuthService.isAuthenticated;
        return authenticated
            ? const MainLayout(initialIndex: 0)
            : const LoginPage();
      },
    );
  }
}
class LoginPage extends StatefulWidget {
  const LoginPage({
super.key
});
  @override  State<LoginPage> createState() => _LoginPageState();

}
class _LoginPageState extends State<LoginPage>    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  late final AnimationController _entranceController;
  late final Animation<Offset> _slideAnim;
  late final Animation<double> _fadeAnim;
  bool _loading = false;
  bool _obscurePassword = true;
  String? _errorText;
  @override  void initState() {
    super.initState();
    _entranceController = AnimationController(      vsync: this,      duration: const Duration(milliseconds: 750),    );
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)        .animate(          CurvedAnimation(            parent: _entranceController,            curve: Curves.easeOutCubic,          ),        );
    _fadeAnim = CurvedAnimation(      parent: _entranceController,      curve: Curves.easeIn,    );
    Timer(      const Duration(milliseconds: 120),      () => _entranceController.forward(),    );
  
}
  @override  void dispose() {
    _entranceController.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  
}


  Future<void> _attemptLogin() async {
    final tr = context.tr;
    setState(() => _errorText = null);
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    final error = await AuthService.login(      _emailCtrl.text.trim(),      _passwordCtrl.text,    );
    if (!mounted) return;
    setState(() {
      _loading = false;
      _errorText = error;
    
});
  
}

  void _openRegisterSheet() {
    showModalBottomSheet(      context: context,      isScrollControlled: true,      shape: const RoundedRectangleBorder(        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),      ),      builder: (_) => const _RegisterSheet(),    );
  
}
  @override  Widget build(BuildContext context) {
    final maxWidth = MediaQuery.of(context).size.width.clamp(400.0, 560.0);
    return Scaffold(      body: Stack(        fit: StackFit.expand,        children: [          Container(            decoration: const BoxDecoration(              gradient: LinearGradient(                colors: [Color(0xFF0A0E21), Color(0xFF1A237E), Color(0xFF0D47A1)],                begin: Alignment.topLeft,                end: Alignment.bottomRight,              ),            ),          ),          Positioned(top: -80, right: -60,              child: _GlowCircle(color: Colors.blueAccent, size: 300)),          Positioned(bottom: -100, left: -80,              child: _GlowCircle(color: Colors.purpleAccent, size: 250)),          Center(            child: SlideTransition(              position: _slideAnim,              child: FadeTransition(                opacity: _fadeAnim,                child: ConstrainedBox(                  constraints: BoxConstraints(                    maxWidth: maxWidth,                    minWidth: 320,                  ),                  child: ClipRRect(                    borderRadius: BorderRadius.circular(20),                    child: BackdropFilter(                      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),                      child: _buildLoginCard(context),                    ),                  ),                ),              ),            ),          ),        ],      ),    );
  
}
  Widget _buildLoginCard(BuildContext context) {
    final tr = context.tr;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(      elevation: 28,      borderRadius: BorderRadius.circular(20),      child: Container(        decoration: BoxDecoration(          color: Colors.white.withOpacity(0.08),          borderRadius: BorderRadius.circular(20),          border: Border.all(color: Colors.white.withOpacity(0.15)),        ),        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 36),        child: Form(          key: _formKey,          child: Column(            mainAxisSize: MainAxisSize.min,            children: [                            Text(
                tr.appTitle,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                  color: Color(0xFF0A4D57),
                ),
              ),              const SizedBox(height: 4),              Text(                tr.appSubtitle,                style: const TextStyle(                  fontSize: 12,                  fontWeight: FontWeight.w600,                  color: Color(0xFF1CA0A5),                ),              ),              const SizedBox(height: 20),              _buildLogoCircle(),              const SizedBox(height: 24),              _buildLabeledField(                label: tr.email,                child: TextFormField(                  controller: _emailCtrl,                  keyboardType: TextInputType.emailAddress,                  decoration: InputDecoration(                    hintText: tr.enterEmail,                    border: InputBorder.none,                    prefixIcon: const Icon(Icons.email_outlined, size: 20),                  ),                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return tr.enterYourEmail;
                    
}                    if (!value.contains('@')) {
                      return tr.invalidEmail;
                    
}                    return null;
                  
},                  textInputAction: TextInputAction.next,                ),              ),              const SizedBox(height: 14),              _buildLabeledField(                label: tr.password,                child: TextFormField(                  controller: _passwordCtrl,                  obscureText: _obscurePassword,                  decoration: InputDecoration(                    hintText: tr.enterPassword,                    border: InputBorder.none,                    prefixIcon: const Icon(Icons.lock_outline, size: 20),                    suffixIcon: IconButton(                      onPressed: () =>                          setState(() => _obscurePassword = !_obscurePassword),                      icon: Icon(                        _obscurePassword                            ? Icons.visibility_off_outlined                            : Icons.visibility_outlined,                        size: 20,                      ),                    ),                  ),                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return tr.required;
                    
}                    return null;
                  
},                  textInputAction: TextInputAction.done,                  onFieldSubmitted: (_) => _attemptLogin(),                ),              ),              const SizedBox(height: 6),              if (_errorText != null) ...[                const SizedBox(height: 10),                Container(                  padding: const EdgeInsets.all(10),                  decoration: BoxDecoration(                    color: Colors.red.withOpacity(0.08),                    borderRadius: BorderRadius.circular(12),                    border: Border.all(color: Colors.red.withOpacity(0.3)),                  ),                  child: Row(                    children: [                      const Icon(Icons.error_outline,                          color: Colors.red, size: 18),                      const SizedBox(width: 8),                      Expanded(                        child: Text(                          _errorText!,                          style: const TextStyle(                              color: Colors.red, fontSize: 13),                        ),                      ),                    ],                  ),                ),              ],              const SizedBox(height: 20),              SizedBox(                width: double.infinity,                height: 46,                child: ElevatedButton(                  onPressed: _loading ? null : _attemptLogin,                  style: ElevatedButton.styleFrom(                    backgroundColor: const Color(0xFF0A6B6E),                    shape: RoundedRectangleBorder(                      borderRadius: BorderRadius.circular(10),                    ),                  ),                  child: _loading                      ? const SizedBox(                          height: 20,                          width: 20,                          child: CircularProgressIndicator(                            strokeWidth: 2,                            color: Colors.white,                          ),                        )                      : Text(                          tr.signIn,                          style: const TextStyle(                            color: Colors.white,                            fontWeight: FontWeight.w700,                          ),                        ),                ),              ),              const SizedBox(height: 16),              TextButton(                onPressed: _openRegisterSheet,                child: Text(tr.registerNewUser),              ),            ],          ),        ),      ),    );
  
}
  Widget _buildLogoCircle() {
    return Container(      width: 80,      height: 80,      decoration: BoxDecoration(        shape: BoxShape.circle,        color: const Color(0xFF0A6B6E).withOpacity(0.1),      ),      child: ClipOval(        child: Image.asset(          'assets/pharmacy faculty logo.png',          fit: BoxFit.cover,          errorBuilder: (_, __, ___) => const Icon(            Icons.local_pharmacy,            size: 40,            color: Color(0xFF0A6B6E),          ),        ),      ),    );
  
}
  Widget _buildLabeledField({
required String label, required Widget child
}) {
    return Column(      crossAxisAlignment: CrossAxisAlignment.start,      children: [        Text(          label,          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),        ),        const SizedBox(height: 6),        Container(          decoration: BoxDecoration(            color: Colors.grey[100],            borderRadius: BorderRadius.circular(12),          ),          child: child,        ),      ],    );
  
}
}
class _GlowCircle extends StatelessWidget {
  final Color color;
  final double size;
  const _GlowCircle({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
            colors: [color.withOpacity(0.18), Colors.transparent]),
      ),
    );
  }
}

class _RegisterSheet extends StatefulWidget {
  const _RegisterSheet();
  @override  State<_RegisterSheet> createState() => _RegisterSheetState();

}
class _RegisterSheetState extends State<_RegisterSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  String _selectedRole = 'user';
  bool _loading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  String? _errorText;
  String? _successText;
  @override  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  
}


  Future<void> _submit() async {
    final tr = context.tr;
    setState(() {
      _errorText = null;
      _successText = null;
    
});
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    final String? error;
    if (_selectedRole == 'admin') {
      error = await AuthService.registerAdmin(        email: _emailCtrl.text.trim(),        password: _passwordCtrl.text,        fullName: _nameCtrl.text.trim(),        phoneNumber: _phoneCtrl.text.trim(),      );
    
} else {
      error = await AuthService.registerUser(        email: _emailCtrl.text.trim(),        password: _passwordCtrl.text,        fullName: _nameCtrl.text.trim(),        phoneNumber: _phoneCtrl.text.trim(),      );
    
}    if (!mounted) return;
    setState(() {
      _loading = false;
      if (error != null) {
        _errorText = error;
      
} else {
        _successText = tr.success;
      
}    
});
  
}
  @override  Widget build(BuildContext context) {
    final tr = context.tr;
    return Padding(      padding: EdgeInsets.only(        left: 24,        right: 24,        top: 24,        bottom: MediaQuery.of(context).viewInsets.bottom + 24,      ),      child: Form(        key: _formKey,        child: SingleChildScrollView(          child: Column(            crossAxisAlignment: CrossAxisAlignment.start,            mainAxisSize: MainAxisSize.min,            children: [              Text(                tr.registerNewUser,                style: const TextStyle(                    fontSize: 20, fontWeight: FontWeight.bold),              ),              const SizedBox(height: 16),              Row(                children: [                  _roleChip(                    label: tr.supervisor,                    value: 'user',                    icon: Icons.person_outline,                    color: Colors.green,                  ),                  const SizedBox(width: 10),                  _roleChip(                    label: tr.manager,                    value: 'admin',                    icon: Icons.admin_panel_settings_outlined,                    color: Colors.blue,                  ),                ],              ),              const SizedBox(height: 12),              _field(                controller: _nameCtrl,                label: tr.fullName,                hint: tr.fullName,                icon: Icons.person_outline,              ),              const SizedBox(height: 12),              _field(                controller: _emailCtrl,                label: tr.email,                hint: tr.enterEmail,                icon: Icons.email_outlined,                keyboardType: TextInputType.emailAddress,                validator: (value) {
                  if (value == null || value.trim().isEmpty) return tr.required;
                  if (!value.contains('@')) return tr.invalidEmail;
                  return null;
                
},              ),              const SizedBox(height: 12),              _field(                controller: _phoneCtrl,                label: tr.phoneNumber,                hint: '+20 123 456 7890',                icon: Icons.phone_outlined,                keyboardType: TextInputType.phone,                validator: (value) {
                  if (value == null || value.trim().isEmpty) return tr.required;
                  if (value.trim().length < 7) return tr.validPhone;
                  return null;
                
},              ),              const SizedBox(height: 12),              _field(                controller: _passwordCtrl,                label: tr.password,                hint: tr.minSixChars,                icon: Icons.lock_outline,                obscure: _obscurePassword,                suffixIcon: IconButton(                  icon: Icon(                    _obscurePassword                        ? Icons.visibility_off_outlined                        : Icons.visibility_outlined,                    size: 20,                  ),                  onPressed: () =>                      setState(() => _obscurePassword = !_obscurePassword),                ),                validator: (value) {
                  if (value == null || value.length < 6) return tr.atLeast6Chars;
                  return null;
                
},              ),              const SizedBox(height: 12),              _field(                controller: _confirmCtrl,                label: tr.confirmPassword,                hint: tr.repeatPassword,                icon: Icons.lock_outline,                obscure: _obscureConfirm,                suffixIcon: IconButton(                  icon: Icon(                    _obscureConfirm                        ? Icons.visibility_off_outlined                        : Icons.visibility_outlined,                    size: 20,                  ),                  onPressed: () =>                      setState(() => _obscureConfirm = !_obscureConfirm),                ),                validator: (value) {
                  if (value != _passwordCtrl.text) return tr.passwordsDoNotMatch;
                  return null;
                
},              ),              const SizedBox(height: 20),              if (_errorText != null)                _banner(                    text: _errorText!,                    color: Colors.red,                    icon: Icons.error_outline),              if (_successText != null)                _banner(                    text: _successText!,                    color: Colors.green,                    icon: Icons.check_circle_outline),              if (_errorText != null || _successText != null)                const SizedBox(height: 12),              SizedBox(                width: double.infinity,                height: 46,                child: ElevatedButton(                  onPressed: _loading || _successText != null ? null : _submit,                  style: ElevatedButton.styleFrom(                    backgroundColor: const Color(0xFF1CA0A5),                    shape: RoundedRectangleBorder(                      borderRadius: BorderRadius.circular(10),                    ),                  ),                  child: _loading                      ? const SizedBox(                          height: 20,                          width: 20,                          child: CircularProgressIndicator(                            strokeWidth: 2,                            color: Colors.white,                          ),                        )                      : Text(                          tr.createAccount,                          style: const TextStyle(                            color: Colors.white,                            fontWeight: FontWeight.w700,                          ),                        ),                ),              ),              if (_successText != null) ...[                const SizedBox(height: 10),                SizedBox(                  width: double.infinity,                  child: TextButton(                    onPressed: () => Navigator.pop(context),                    child: Text(tr.backToLogin),                  ),                ),              ],            ],          ),        ),      ),    );
  
}
  Widget _roleChip({
    required String label,    required String value,    required IconData icon,    required Color color,  
}) {
    final selected = _selectedRole == value;
    return GestureDetector(      onTap: () => setState(() => _selectedRole = value),      child: AnimatedContainer(        duration: const Duration(milliseconds: 200),        padding:            const EdgeInsets.symmetric(horizontal: 14, vertical: 10),        decoration: BoxDecoration(          color: selected ? color.withOpacity(0.12) : Colors.grey[100],          borderRadius: BorderRadius.circular(12),          border: Border.all(            color: selected ? color : Colors.grey[300]!,            width: selected ? 1.5 : 1,          ),        ),        child: Row(          mainAxisSize: MainAxisSize.min,          children: [            Icon(icon, size: 18, color: selected ? color : Colors.grey),            const SizedBox(width: 6),            Text(              label,              style: TextStyle(                fontSize: 13,                fontWeight:                    selected ? FontWeight.w600 : FontWeight.normal,                color: selected ? color : Colors.black54,              ),            ),          ],        ),      ),    );
  
}
  Widget _field({
    required TextEditingController controller,    required String label,    required String hint,    required IconData icon,    bool obscure = false,    Widget? suffixIcon,    TextInputType? keyboardType,    String? Function(String?)? validator,  
}) {
    final tr = context.tr;
    return Column(      crossAxisAlignment: CrossAxisAlignment.start,      children: [        Text(label,            style: const TextStyle(                fontSize: 13, fontWeight: FontWeight.w600)),        const SizedBox(height: 6),        TextFormField(          controller: controller,          obscureText: obscure,          keyboardType: keyboardType,          decoration: InputDecoration(            hintText: hint,            prefixIcon: Icon(icon, size: 20),            suffixIcon: suffixIcon,            border: OutlineInputBorder(                borderRadius: BorderRadius.circular(12)),            contentPadding: const EdgeInsets.symmetric(                horizontal: 12, vertical: 14),          ),          validator: validator ??              (value) {
                if (value == null || value.trim().isEmpty) return tr.required;
                return null;
              
},        ),      ],    );
  
}
  Widget _banner({
    required String text,    required Color color,    required IconData icon,  
}) {
    return Container(      padding: const EdgeInsets.all(10),      decoration: BoxDecoration(        color: color.withOpacity(0.08),        borderRadius: BorderRadius.circular(12),        border: Border.all(color: color.withOpacity(0.3)),      ),      child: Row(        children: [          Icon(icon, color: color, size: 18),          const SizedBox(width: 8),          Expanded(            child: Text(text,                style: TextStyle(color: color, fontSize: 13)),          ),        ],      ),    );
  
}
}