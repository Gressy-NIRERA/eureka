import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:eureka/api.dart';
import 'package:eureka/register.dart';

class LoginWidget extends StatefulWidget {
  const LoginWidget({super.key});

  @override
  State<LoginWidget> createState() => _LoginWidgetState();
}

class _LoginWidgetState extends State<LoginWidget> {
  final TextEditingController email = TextEditingController();
  final TextEditingController password = TextEditingController();

  final Api api = Api(Dio());

  bool loading = false;
  bool show = true;
  Color bgColor = Colors.white;

  Future<void> login() async {
    if (email.text.isEmpty || password.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Veuillez remplir tous les champs")),
      );
      return;
    }

    setState(() {
      loading = true;
      bgColor = Colors.black;
    });

    try {
      final response = await api.userlogin(
        email.text.trim(),
        password.text.trim(),
      );

      print(response);

      setState(() {
        loading = false;
        bgColor = Colors.green;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Connexion réussie"),
          backgroundColor: Colors.green,
        ),
      );

      // Navigator.pushReplacement(
      //   context,
      //   MaterialPageRoute(builder: (context) => const Dashboard()),
      // );
    } on DioException catch (e) {
      setState(() {
        loading = false;
        bgColor = Colors.red;
      });

      print(e.response?.data);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.response?.data.toString() ?? "Erreur de connexion"),
        ),
      );
    } catch (e) {
      setState(() {
        loading = false;
        bgColor = Colors.red;
      });

      print(e);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 25),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 15),

              CircleAvatar(
                radius: 22,
                backgroundColor: Colors.grey.shade100,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.black),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
              ),

              const SizedBox(height: 35),

              const Text(
                "Welcome Back",
                style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 8),

              Text(
                "Sign in to continue",
                style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
              ),

              const SizedBox(height: 35),

              const Text(
                "Email",
                style: TextStyle(fontWeight: FontWeight.w500),
              ),

              const SizedBox(height: 10),

              TextField(
                controller: email,
                decoration: InputDecoration(
                  hintText: "Enter your email",
                  prefixIcon: const Icon(Icons.email_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),

              const SizedBox(height: 25),

              const Text(
                "Password",
                style: TextStyle(fontWeight: FontWeight.w500),
              ),

              const SizedBox(height: 10),

              TextField(
                controller: password,
                obscureText: show,
                decoration: InputDecoration(
                  hintText: "Enter your password",
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: InkWell(
                    onTap: () {
                      setState(() {
                        show = !show;
                      });
                    },
                    child: Icon(show ? Icons.visibility_off : Icons.visibility),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),

              const SizedBox(height: 15),

              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {},
                  child: const Text(
                    "Forgot Password?",
                    style: TextStyle(color: Colors.black),
                  ),
                ),
              ),

              const SizedBox(height: 10),

              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: () {
                    if (email.text.isNotEmpty && password.text.isNotEmpty) {
                      login();
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Veuillez remplir tous les champs"),
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  child: const Text(
                    "Login",
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                ),
              ),

              const SizedBox(height: 30),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("tu n as pas de compte? "),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const Registration(),
                        ),
                      );
                    },
                    child: const Text(
                      "s'Inscrire",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
