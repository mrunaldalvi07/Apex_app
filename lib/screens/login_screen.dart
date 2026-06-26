import 'package:flutter/material.dart';

import 'student_screen.dart';
import 'faculty_screen.dart';
import 'cr_screen.dart';
import 'admin_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  String selectedRole = "student";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Role Selection"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 30),

            const Text(
              "APEX Classroom Scheduler",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 40),

            RadioListTile<String>(
              title: const Text("Student"),
              value: "student",
              groupValue: selectedRole,
              onChanged: (value) {
                setState(() {
                  selectedRole = value!;
                });
              },
            ),

            RadioListTile<String>(
              title: const Text("Faculty"),
              value: "faculty",
              groupValue: selectedRole,
              onChanged: (value) {
                setState(() {
                  selectedRole = value!;
                });
              },
            ),

            RadioListTile<String>(
              title: const Text("CR"),
              value: "cr",
              groupValue: selectedRole,
              onChanged: (value) {
                setState(() {
                  selectedRole = value!;
                });
              },
            ),

            RadioListTile<String>(
              title: const Text("Admin"),
              value: "admin",
              groupValue: selectedRole,
              onChanged: (value) {
                setState(() {
                  selectedRole = value!;
                });
              },
            ),

            const Spacer(),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {

                  Widget nextScreen;

                  switch (selectedRole) {
                    case "student":
                      nextScreen = const StudentScreen();
                      break;

                    case "faculty":
                      nextScreen = const FacultyScreen();
                      break;

                    case "cr":
                      nextScreen = const CrScreen();
                      break;

                    case "admin":
                      nextScreen = const AdminScreen();
                      break;

                    default:
                      nextScreen = const StudentScreen();
                  }

                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => nextScreen,
                    ),
                  );
                },
                child: const Text(
                  "CONTINUE",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}