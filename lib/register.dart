import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:eureka/api.dart';

class Registration extends StatefulWidget {
  const Registration({super.key});

  @override
  State<Registration> createState() => _RegistrationState();
}

class _RegistrationState extends State<Registration> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController firstname = TextEditingController();
  final TextEditingController lastname = TextEditingController();
  final TextEditingController email = TextEditingController();
  final TextEditingController phonenumber = TextEditingController();
  final TextEditingController password = TextEditingController();
  final TextEditingController confirm = TextEditingController();

  final apire = Api((Dio()));
  bool showPassword = false;
  bool showConfirm = false;
  String country = "BI";

  Future<void> register() async {
    if (!_formKey.currentState!.validate()) return;
    try {
      final response = apire.register(
        firstname.text,
        lastname.text,
        int.parse(phonenumber.text),
        email.text,
        country,
        password.text,
        confirm.text,
      );
      print("$response");
    } catch (e) {
      print("$e");
    }
  }

  @override
  void dispose() {
    firstname.dispose();
    lastname.dispose();
    email.dispose();
    phonenumber.dispose();
    password.dispose();
    confirm.dispose();
    super.dispose();
  }

 
  Widget buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool obscure = false,
    Widget? suffix,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          TextFormField(
            controller: controller,
            obscureText: obscure,
            keyboardType: keyboardType,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: Colors.black),
              prefixIcon: Icon(icon, color: Colors.black),
              suffixIcon: suffix,
              filled: true,
              fillColor: Colors.grey.shade100,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide.none,
              ),
            ),
            validator: validator,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const CircleAvatar(
                    backgroundColor: Color(0xFFF1F1F1),
                    child: Icon(Icons.arrow_back, color: Colors.black),
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  "Create Account",
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                const Text(
                  "Create your account for daily updates",
                  style: TextStyle(color: Colors.black),
                ),
                const SizedBox(height: 10),

                buildField(
                  controller: firstname,
                  label: "First Name",
                  hint: "Enter your first name",
                  icon: Icons.person_outline,
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'please enter name' : null,
                ),
                buildField(
                  controller: lastname,
                  label: "Last Name",
                  hint: "Enter your last name",
                  icon: Icons.person_outline,
                  validator: (v) => (v == null || v.isEmpty)
                      ? 'please enter surname'
                      : null,
                ),
                buildField(
                  controller: email,
                  label: "Email",
                  hint: "Enter your email",
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'please enter email' : null,
                ),
                buildField(
                  controller: phonenumber,
                  label: "Phone Number",
                  hint: "Enter your phone number",
                  icon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                  validator: (v) => (v == null || v.isEmpty)
                      ? 'please enter phone number'
                      : null,
                ),
                buildField(
                  controller: password,
                  label: "Password",
                  hint: "Enter your password",
                  icon: Icons.lock_outline,
                  obscure: !showPassword,
                  suffix: InkWell(
                    onTap: () => setState(() => showPassword = !showPassword),
                    child: Icon(
                      showPassword ? Icons.visibility : Icons.visibility_off,
                      color: Colors.grey,
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'please enter password';
                    if (v.length < 6) return 'password too short';
                    return null;
                  },
                ),
                buildField(
                  controller: confirm,
                  label: "Confirm Password",
                  hint: "Enter your password",
                  icon: Icons.lock_outline,
                  obscure: !showConfirm,
                  suffix: InkWell(
                    onTap: () => setState(() => showConfirm = !showConfirm),
                    child: Icon(
                      showConfirm ? Icons.visibility : Icons.visibility_off,
                      color: Colors.grey,
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'please confirm password';
                    if (v != password.text) return 'passwords do not match';
                    return null;
                  },
                ),

                const SizedBox(height: 10),

                
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    onPressed: register,
                    child: const Text(
                      'Create Account',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                ),
                 
                const SizedBox(height: 15),
              ],
            ),
          ),
        ),
      ),
    );
  }
}