import 'package:flutter/material.dart';
import 'package:localpkg/theme.dart';
import 'package:localpkg/dialogue.dart';
import 'package:localpkg/online.dart';
import 'package:trafficlightsimulator/mode1.dart';
import 'package:trafficlightsimulator/mode2.dart';
import 'package:trafficlightsimulator/util.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Traffic Light Simulator',
      theme: brandTheme(
        darkMode: true,
        seedColor: Colors.black,
        iconSize: 12,
      ),
      home: HomePage(),
    );
  }
}

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
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              buttonBlock("Create a Room", () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => GamePage1(mode: 2)),
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
                            labelText: 'Join a Room',
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
                            showSnackBar(context, "Finding room...");
                            http.Response response = await getServerResponse("/api/services/trafficlightsimulator/join?id=$code");
                            Map? data = json.decode(response.body);
                            int status = response.statusCode;
                            print("received response: $response");
                            if (data != null && status == 200) {
                              String path = data["game"]["path"];
                              showSnackBar(context, "Found room!");
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(builder: (context) => GamePage2(code: code, path: path)),
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
                  MaterialPageRoute(builder: (context) => GamePage1(mode: 1)),
                );
              }),
            ],
          ),
        ),
      )
    );
  }

  bool isValid(String input) {
    return input.length == 9 && RegExp(r'^[0-9]+$').hasMatch(input);
  }
}

Map initialData() {
  return {
    "items": [
      {
        "id": 1,
        "items": [
          {
            "direction": -2,
            "active": 6,
            "subactive": 6,
          },
          {
            "direction": -1,
            "active": 6,
            "subactive": 6,
          },
          {
            "direction": 0,
            "active": 6,
            "subactive": 6,
          },
          {
            "direction": 1,
            "active": 6,
            "subactive": 6,
          },
          {
            "direction": 2,
            "active": 6,
            "subactive": 6,
          },
        ],
      },
      {
        "id": 2,
        "items": [
          {
            "direction": -2,
            "active": 6,
            "subactive": 6,
          },
          {
            "direction": -1,
            "active": 6,
            "subactive": 6,
          },
          {
            "direction": 0,
            "active": 6,
            "subactive": 6,
          },
          {
            "direction": 1,
            "active": 6,
            "subactive": 6,
          },
          {
            "direction": 2,
            "active": 6,
            "subactive": 6,
          },
        ],
      },
      {
        "id": 3,
        "items": [
          {
            "direction": -2,
            "active": 6,
            "subactive": 6,
          },
          {
            "direction": -1,
            "active": 6,
            "subactive": 6,
          },
          {
            "direction": 0,
            "active": 6,
            "subactive": 6,
          },
          {
            "direction": 1,
            "active": 6,
            "subactive": 6,
          },
          {
            "direction": 2,
            "active": 6,
            "subactive": 6,
          },
        ],
      },
      {
        "id": 4,
        "items": [
          {
            "direction": -2,
            "active": 6,
            "subactive": 6,
          },
          {
            "direction": -1,
            "active": 6,
            "subactive": 6,
          },
          {
            "direction": 0,
            "active": 6,
            "subactive": 6,
          },
          {
            "direction": 1,
            "active": 6,
            "subactive": 6,
          },
          {
            "direction": 2,
            "active": 6,
            "subactive": 6,
          },
        ],
      },
    ],
  };
}