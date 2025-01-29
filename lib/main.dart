import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:localpkg/functions.dart';
import 'package:localpkg/theme.dart';
import 'package:localpkg/dialogue.dart';
import 'package:localpkg/online.dart';
import 'package:localpkg/logger.dart';
import 'package:scoreboardsimulator/mode1.dart';
import 'package:scoreboardsimulator/mode2.dart';
import 'package:scoreboardsimulator/util.dart';
import 'package:scoreboardsimulator/var.dart';

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
    serverlaunch(context: context, service: "scoreboardsimulator");
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
                showSnackBar(context, "Finding match...");
                Map data = await getServerData(method: 'POST', endpoint: "/api/services/scoreboardsimulator/new");
                print("data: $data");
                if (data.containsKey("error")) {
                  print("new room issue: ${data["error"]}");
                  showSnackBar(context, "Error: ${data["error"]}");
                  return;
                }
                String path = data["path"];
                String code = data["code"];
                showSnackBar(context, "Found match!");
                navigate(context: context, page: GamePage1(mode: 2, code: code, path: path));
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
                            http.Response response = await getServerResponse(endpoint: "/api/services/scoreboardsimulator/join", body: {"id": code});
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
                navigate(context: context, page: GamePage1(mode: 1));
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