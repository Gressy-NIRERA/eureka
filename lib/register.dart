
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

  final apire = Api(Dio());

  bool showPassword = false;
  bool showConfirm = false;
  bool loading = false;

  String country = "BI";

  
  static const Color backgroundColor =
      Color.fromARGB(255, 237, 228, 216);

  static const Color primaryColor = Color(0xFFFFB74D);

  static const Color fieldColor = Colors.white;

  Future<void> register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      loading = true;
    });

    try {
      final response = await apire.register(
        firstname.text.trim(),
        lastname.text.trim(),
        phonenumber.text.trim(),
        email.text.trim(),
        country,
        password.text,
        confirm.text,
      );

      print("Réponse API : $response");

      if (response["status"] == true) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Compte créé avec succès"),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.pop(context);
      } else {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              response["message"] ?? "Échec de l'inscription",
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } on DioException catch (e) {
      print("Erreur Dio : ${e.response?.data}");

      if (!mounted) return;

      String message = "Une erreur est survenue";

      if (e.response?.data is Map) {
        final data = e.response!.data;

        message = data["message"]?.toString() ??
            "Erreur lors de l'inscription";

        if (data["errors"]?["phonenumber"] != null) {
          final errors = data["errors"]["phonenumber"];

          if (errors is List && errors.isNotEmpty) {
            message = errors.first.toString();
          }
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      print("Erreur : $e");

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
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
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.orange,
            ),
          ),

          const SizedBox(height: 8),

          TextFormField(
            controller: controller,
            obscureText: obscure,
            keyboardType: keyboardType,

            decoration: InputDecoration(
              hintText: hint,

              hintStyle: TextStyle(
                color: Colors.grey.shade500,
              ),

              prefixIcon: const Icon(
                Icons.person_outline,
                color: Colors.orange,
              ),

              suffixIcon: suffix,

              filled: true,
              fillColor: fieldColor,

              contentPadding: const EdgeInsets.symmetric(
                vertical: 16,
                horizontal: 20,
              ),

              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide.none,
              ),

              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide.none,
              ),

              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: const BorderSide(
                  color: primaryColor,
                  width: 2,
                ),
              ),

              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: const BorderSide(
                  color: Colors.red,
                ),
              ),

              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: const BorderSide(
                  color: Colors.red,
                  width: 2,
                ),
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
      backgroundColor: backgroundColor,

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: 25,
          ),

          child: Form(
            key: _formKey,

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                const SizedBox(height: 15),

               
                CircleAvatar(
                  radius: 22,
                  backgroundColor: Colors.grey.shade100,

                  child: IconButton(
                    icon: const Icon(
                      Icons.arrow_back,
                      color: Colors.orange,
                    ),

                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                ),

                const SizedBox(height: 35),

               
                Text(
                  "Create Account",
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade400,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  "Create your account to continue",
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 16,
                  ),
                ),

                const SizedBox(height: 30),
                buildField(
                  controller: firstname,
                  label: "First Name",
                  hint: "Enter your first name",
                  icon: Icons.person_outline,

                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return "Please enter name";
                    }
                     return null;
                  },
                ),
                buildField(
                  controller: lastname,
                  label: "Last Name",
                  hint: "Enter your last name",
                  icon: Icons.person_outline,

                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return "Please enter surname";
                    }
                   return null;
                  },
                ),
                buildField(
                  controller: email,
                  label: "Email",
                  hint: "Enter your email",
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,

                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return "Please enter email";
                    }

                    if (!v.contains("@")) {
                      return "Please enter a valid email";
                    }

                    return null;
                  },
                ),
                buildField(
                  controller: phonenumber,
                  label: "Phone Number",
                  hint: "Enter your phone number",
                  icon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,

                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return "Please enter phone number";
                    }

                    return null;
                  },
                ),
                buildField(
                  controller: password,
                  label: "Password",
                  hint: "Enter your password",
                  icon: Icons.lock_outline,
                  obscure: !showPassword,

                  suffix: InkWell(
                    onTap: () {
                      setState(() {
                        showPassword = !showPassword;
                      });
                    },

                    child: Icon(
                      showPassword
                          ? Icons.visibility
                          : Icons.visibility_off,
                      color: Colors.orange,
                    ),
                  ),

                  validator: (v) {
                    if (v == null || v.isEmpty) {
                      return "Please enter password";
                    }

                    if (v.length < 6) {
                      return "Password too short";
                    }

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
                    onTap: () {
                      setState(() {
                        showConfirm = !showConfirm;
                      });
                    },

                    child: Icon(
                      showConfirm
                          ? Icons.visibility
                          : Icons.visibility_off,
                      color: Colors.orange,
                    ),
                  ),

                  validator: (v) {
                    if (v == null || v.isEmpty) {
                      return "Please confirm password";
                    }

                    if (v != password.text) {
                      return "Passwords do not match";
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 15),
                SizedBox(
                  width: double.infinity,
                  height: 55,

                  child: ElevatedButton(
                    onPressed: loading ? null : register,

                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange.shade400,

                      disabledBackgroundColor:
                          Colors.orange.shade400.withOpacity(0.6),

                      elevation: 0,

                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),

                    child: loading
                        ? const SizedBox(
                            width: 25,
                            height: 25,

                            child: CircularProgressIndicator(
                              strokeWidth: 2,

                              valueColor:
                                  AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : const Text(
                            "Create Account",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 25),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,

                  children: [
                    const Text(
                      "Already have an account? ",
                      style: TextStyle(
                        color: Colors.black87,
                      ),
                    ),

                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },

                      child: const Text(
                        "Login",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}