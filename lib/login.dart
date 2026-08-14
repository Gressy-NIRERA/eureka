import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

import 'package:eureka/api.dart';
import 'package:eureka/register.dart';
import 'package:eureka/control.dart';
import 'package:eureka/cache_helper.dart';

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

  late SharedPrefService sharedPrefService;

  @override
  void initState() {
    super.initState();

    sharedPrefService = SharedPrefService();

    _checkLoginStatus();

    sharedPrefService.readCache(key: "email").then((cachedEmail) {
      if (cachedEmail != null && mounted) {
        email.text = cachedEmail;
      }
    });
  }

  // Vérifie si l'utilisateur est déjà connecté
  Future<void> _checkLoginStatus() async {
    bool isLoggedIn = await CacheHelper.getLogin();

    if (isLoggedIn && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const Control(),
        ),
      );
    }
  }

  // Connexion
  Future<void> login() async {
    if (email.text.trim().isEmpty || password.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Veuillez remplir tous les champs"),
        ),
      );
      return;
    }

    setState(() {
      loading = true;
    });

    try {
      final response = await api.userlogin(
        email.text.trim(),
        password.text,
      );

      print("LOGIN RESPONSE : $response");

      if (response["status"] == true) {
        // Sauvegarde du token
        if (response["token"] != null) {
          await CacheHelper.saveToken(
            response["token"].toString(),
          );
        }

        // Sauvegarde des informations utilisateur
        if (response["data"] != null) {
          await CacheHelper.saveUserData(
            response["data"],
          );
        }

        // Vérification des données sauvegardées
        print("FIRSTNAME : ${await CacheHelper.getFirstname()}");
        print("LASTNAME : ${await CacheHelper.getLastname()}");
        print("EMAIL : ${await CacheHelper.getEmail()}");
        print("PHONE : ${await CacheHelper.getPhone()}");
        print("COUNTRY : ${await CacheHelper.getCountry()}");

        // Sauvegarde de l'état de connexion
        await CacheHelper.saveLogin(true);

        // Sauvegarde de l'email
        await sharedPrefService.writeCache(
          key: "email",
          value: email.text.trim(),
        );

        if (!mounted) return;

        // Aller vers la page principale
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const Control(),
          ),
        );
      } else {
        final message =
            response["message"]?.toString() ??
            "Email ou mot de passe incorrect";

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
            ),
          );
        }
      }
    } on DioException catch (e) {
      print("DIO ERROR : ${e.response?.data}");

      String message = "Email ou mot de passe incorrect";

      final data = e.response?.data;

      if (data is Map && data["message"] != null) {
        message = data["message"].toString();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
          ),
        );
      }
    } catch (e) {
      print("ERROR : $e");

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
          ),
        );
      }
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
    email.dispose();
    password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 237, 228, 216),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 25),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 15),

              // Bouton retour
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

              // Titre
              Text(
                "Welcome Back",
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange.shade400,
                ),
              ),

              const SizedBox(height: 8),

              // Sous-titre
              Text(
                "Sign in to continue",
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 16,
                ),
              ),

              const SizedBox(height: 35),

              // Email
              const Text(
                "Email",
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: Colors.orange,
                ),
              ),

              const SizedBox(height: 10),

              TextField(
                controller: email,
                keyboardType: TextInputType.emailAddress,

                decoration: InputDecoration(
                  hintText: "Enter your email",

                  prefixIcon: const Icon(
                    Icons.email_outlined,
                  ),

                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),

                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),

                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: const BorderSide(
                      color: Colors.orange,
                      width: 2,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 25),

              // Password
              Text(
                "Password",
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: Colors.orange.shade400,
                ),
              ),

              const SizedBox(height: 10),

              TextField(
                controller: password,
                obscureText: show,

                decoration: InputDecoration(
                  hintText: "Enter your password",

                  prefixIcon: const Icon(
                    Icons.lock_outline,
                  ),

                  suffixIcon: InkWell(
                    onTap: () {
                      setState(() {
                        show = !show;
                      });
                    },

                    child: Icon(
                      show
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                  ),

                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),

                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),

                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: const BorderSide(
                      color: Colors.orange,
                      width: 2,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 15),

              // Mot de passe oublié
              Align(
                alignment: Alignment.centerRight,

                child: TextButton(
                  onPressed: () {
                    // Ajouter ici la récupération du mot de passe
                  },

                  child: Text(
                    "Forgot Password?",
                    style: TextStyle(
                      color: Colors.orange.shade400,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // Bouton Login
              SizedBox(
                width: double.infinity,
                height: 55,

                child: ElevatedButton(
                  onPressed: loading
                      ? null
                      : () {
                          login();
                        },

                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange.shade400,

                    disabledBackgroundColor:
                        Colors.orange.shade400.withOpacity(0.6),

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
                          "Login",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 30),

              // Inscription
              Row(
                mainAxisAlignment: MainAxisAlignment.center,

                children: [
                  const Text(
                    "Tu n'as pas de compte ? ",
                  ),

                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const Registration(),
                        ),
                      );
                    },

                    child: const Text(
                      "S'inscrire",
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
    );
  }
}