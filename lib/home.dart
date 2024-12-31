import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:localpkg/dialogue.dart';
import 'package:localpkg/online.dart';
import 'package:trafficlightsimulator/mode1.dart';
import 'package:trafficlightsimulator/mode2.dart';
import 'package:trafficlightsimulator/util.dart';
import 'package:http/http.dart' as http;

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final formKey = GlobalKey<FormState>();
  String code = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text("Select a Mode"),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            buttonBlock("Create a Match", () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => GamePage1()),
              );
            }),
            Form(
              key: formKey,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    Flexible(
                      child: TextFormField(
                        decoration: InputDecoration(
                          labelText: 'Join a Match',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty || !isValid(value)) {
                            return 'Enter a valid code.';
                          }
                          return null;
                        },
                        onSaved: (value) {
                          code = value ?? '';
                        },
                      ),
                    ),
                    SizedBox(width: 20),
                    buttonBlock("Join", () async {
                      try {
                        if (formKey.currentState!.validate()) {
                          formKey.currentState!.save();
                          showSnackBar(context, "Finding match...");
                          http.Response response = await getServerResponse("/api/services/trafficlightsimulator/join?id=$code");
                          Map? data = json.decode(response.body);
                          int status = response.statusCode;
                          print("Received response: $response");
                          if (data != null && status == 200) {
                            int port = data["game"]["port"];
                            showSnackBar(context, "Found match!");
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(builder: (context) => GamePage2(code: code, port: port)),
                            );
                          } else {
                            if (data != null) {
                              String error = data["error"];
                              showSnackBar(context, "Error $status: $error");
                            } else {
                              showSnackBar(context, "Error $status");
                            }
                          }
                        }
                      } catch (e) {
                        showSnackBar(context, "Error: $e");
                      }
                    }, width: 150)
                  ],
                ),
              ),
            ),
            buttonBlock("Singleplayer", () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => GamePage1()),
              );
            }),
          ],
        ),
      )
    );
  }

  bool isValid(String input) {
    return input.length == 9 && RegExp(r'^[0-9]+$').hasMatch(input);
  }
}