import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:localpkg/functions.dart';
import 'package:localpkg/theme.dart';
import 'package:localpkg/dialogue.dart';
import 'package:localpkg/online.dart';
import 'package:localpkg/override.dart';
import 'package:trafficlightsimulator/mode1.dart';
import 'package:trafficlightsimulator/mode2.dart';
import 'package:trafficlightsimulator/util.dart';
import 'package:trafficlightsimulator/var.dart';

import 'package:http/http.dart' as http;
import 'dart:convert';

// ------------- TRAFFIC LIGHT SIMULATOR WIDGET TREE -------------
  // Section - contains controls and stoplights
    // StoplightsContainer - 4 Stoplights
      // Area - contains Stoplights
        // Stoplights - Row of Stoplight
          // Stoplight - Column of Light/ArrowLight
            // Light - Container for Circle
              // Circle - Container for CirclePainter
                // CirclePainter - CustomPainter with Paint
            // ArrowLight - Container for Arrow
              // Arrow - Container for ArrowPainter
                // ArrowPainter - CustomPainter with TextPainter for Icons.arrow_back
    // ControlRow - Row of Control
      // Control - ElevatedButton
// ---------------------------------------------------------------

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
        seedColor: const Color.fromARGB(255, 1, 0, 34),
        useDarkBackground: true,
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
  void initState() {
    super.initState();
    print("beta,debug: $beta,$debug");
    print("fetch info: ${getFetchInfo(debug: debug)}");
    showFirstTimeDialogue(context, "Welcome to Traffic Light Simulator!", "$description\n\n$instructions", false);
    serverlaunch(context: context, service: "TrafficLightSimulator");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text("Select a Mode"),
        leading: settingsButton(context),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              buttonBlock("Create a Room", () async {
                int? roads = await selectRoads(context);
                if (roads == null) {
                  return;
                }
                showSnackBar(context, "Finding match...");
                Map data = await getServerData(endpoint: "/api/services/trafficlightsimulator/new", debug: debug);
                print("data: $data");
                if (data.containsKey("error")) {
                  print("new room issue: ${data["error"]}");
                  showSnackBar(context, "Error: ${data["error"]}");
                  return;
                }
                String path = data["path"];
                String code = data["code"];
                showSnackBar(context, "Found match!");
                navigate(context: context, page: GamePage1(mode: 2, roads: roads, code: code, path: path));
              }),
              Form(
                key: formKey,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: 200,
                          ),
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
                      ),
                      SizedBox(width: 20),
                      buttonBlock("Join", () async {
                        if (await checkDisabled()) {
                          showSnackBar(context, "The server is currently not available. Please try again later.");
                          return;
                        }
                        try {
                          if (formKey.currentState!.validate()) {
                            formKey.currentState!.save();
                            showSnackBar(context, "Finding room...");
                            http.Response response = await getServerResponse(endpoint: "/api/services/trafficlightsimulator/join", body: {"id": code}, debug: debug);
                            Map? data = json.decode(response.body);
                            int status = response.statusCode;
                            print("received response: ${response.runtimeType}[${response.statusCode}]");
                            if (data != null && status == 200) {
                              String path = data["game"]["path"];
                              showSnackBar(context, "Found room!");
                              navigate(context: context, page: GamePage2(code: code, path: path));
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
              buttonBlock("Singleplayer", () async {
                int? roads = await selectRoads(context);
                if (roads == null) {
                  return;
                }
                navigate(context: context, page: GamePage1(mode: 1, roads: roads));
              }),
              if (kDebugMode)
              buttonBlock("Receiver", () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => GamePage2(local: true)),
                );
              })
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

Future<int?> selectRoads(BuildContext context) {
  int? roads = 4;
  return showDialog(
    context: context,
    builder: (BuildContext context) {
      return StatefulBuilder( // Use StatefulBuilder to manage state inside the dialog.
        builder: (BuildContext context, StateSetter setState) {
          return AlertDialog(
            title: const Text("Select Type"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("Choose a stoplight type:"),
                const SizedBox(height: 16),
                DropdownButton<int>(
                  value: roads,
                  isExpanded: true,
                  items: <int>[3, 4]
                      .map((int value) {
                    return DropdownMenuItem<int>(
                      value: value,
                      child: Text(getNameForRoads(value)),
                    );
                  }).toList(),
                  onChanged: (int? newValue) {
                    setState(() {
                      roads = newValue;
                    });
                  },
                  hint: const Text("Select an option"),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close the dialog.
                },
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop(roads); // Close the dialog.
                },
                child: const Text("OK"),
              ),
            ],
          );
        },
      );
    },
  );
}