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
  final TextEditingController email= TextEditingController();
  final TextEditingController phonenumber = TextEditingController();
  final TextEditingController password = TextEditingController();
  final TextEditingController confirm = TextEditingController();

final apire = Api((Dio()));
String country= "BI";
Future<void> register() async{
  
  try{
final response = apire.register(firstname.text, lastname.text,int.parse(phonenumber.text) , email.text, country, password.text, confirm.text);
print("$response");
  }
  catch(e){
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
  @override
  Widget build(BuildContext context) {
    return Scaffold(
         appBar: AppBar(
        backgroundColor: Colors.pink.shade400,
        elevation: 3,
        title:
            const Text("Registration", style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              colors: [
                Colors.grey,
               Colors.grey.shade100
              ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    TextFormField(
                      controller: firstname,
                      decoration: InputDecoration(
                          labelText: "enter Name",
                          hintStyle: const TextStyle(color: Colors.grey),
                          border: const OutlineInputBorder()),
                      validator: (value) {
                        if (value == null || value.isEmpty)
                          return 'please enter name';
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: TextFormField(
                        controller: lastname,
                        decoration: InputDecoration(
                            labelText: "enter surname",
                            hintStyle: const TextStyle(color: Colors.grey),
                            border: const OutlineInputBorder()),
                        validator: (value) {
                          if (value == null || value.isEmpty)
                            return 'please enter surname';
                          return null;
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: TextFormField(
                        controller: email,
                        decoration: InputDecoration(
                            labelText: "enter email",
                            hintStyle: const TextStyle(color: Colors.grey),
                            border: const OutlineInputBorder()),
                        validator: (value) {
                          if (value == null || value.isEmpty)
                            return 'please enter email';
                          return null;
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: TextFormField(
                        controller: phonenumber,
                        decoration: InputDecoration(
                            labelText: "enter phone number",
                            hintStyle: const TextStyle(color: Colors.grey),
                            border: const OutlineInputBorder()),
                        validator: (value) {
                          if (value == null || value.isEmpty)
                            return 'please enter phone number';
                          return null;
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: TextFormField(
                        controller: password,
                        decoration: InputDecoration(
                            labelText: "enter password",
                            hintStyle: const TextStyle(color: Colors.grey),
                            border: const OutlineInputBorder()),
                        validator: (value) {
                          if (value == null || value.isEmpty)
                            return 'please enter password';
                          if (value.length < 6) return 'password too short';
                          return null;
                        },
                        obscureText: true,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: TextFormField(
                        controller: confirm,
                        decoration: InputDecoration(
                            labelText: "confirm password",
                            hintStyle: const TextStyle(color: Colors.grey),
                            border: const OutlineInputBorder()),
                        validator: (value) {
                          if (value == null || value.isEmpty)
                            return 'please confirm password';
                          if (value != password.text)
                            return 'passwords do not match';
                          return null;
                        },
                        obscureText: true,
                      ),
                    ),
                    ElevatedButton(
                        onPressed: register, child: const Text('Submit'))
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