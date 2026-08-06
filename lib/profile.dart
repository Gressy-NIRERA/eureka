import 'package:flutter/material.dart';
import 'package:eureka/cache_helper.dart';


class Profile extends StatefulWidget {
  const Profile({super.key});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  String firstname = "";
  String lastname = "";
  String email = "";
  String phone = "";
  String country = "";

  @override
  void initState() {
    super.initState();
    loadUserData();
  }

  Future<void> loadUserData() async {
    firstname = await CacheHelper.getFirstname();
    lastname = await CacheHelper.getLastname();
    email = await CacheHelper.getEmail();
    phone = await CacheHelper.getPhone();
    country = await CacheHelper.getCountry();

      print(firstname);
      print(lastname);
      print(email);
      print(phone);
      print(country);


    setState(() {});
  }

  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Mon Profil"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 20),

            const CircleAvatar(
              radius: 55,
              backgroundColor: Colors.black,
              child: Icon(
                Icons.person,
                color: Colors.white,
                size: 60,
              ),
            ),

            const SizedBox(height: 20),

            Text(
              "$firstname $lastname",
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 30),

            Card(
              child: ListTile(
                leading: const Icon(Icons.email),
                title: const Text("Email"),
                subtitle: Text(email),
              ),
            ),

            const SizedBox(height: 10),

            Card(
              child: ListTile(
                leading: const Icon(Icons.phone_android_rounded),
                title: const Text("Téléphone"),
                subtitle: Text(phone),
              ),
            ),

            const SizedBox(height: 10),

            Card(
              child: ListTile(
                leading: const Icon(Icons.flag_circle_sharp),
                title: const Text("Pays"),
                subtitle: Text(country),
              ),
            ),

            const Spacer(),

        
          ],
        ),
      ),
    );
  }
}