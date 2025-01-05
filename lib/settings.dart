import 'package:flutter/material.dart';
import 'package:localpkg/dialogue.dart';
import 'package:localpkg/widgets.dart';
import 'package:trafficlightsimulator/var.dart';

class Settings extends StatefulWidget {
  const Settings({super.key});

  @override
  State<Settings> createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text("Settings"),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          iconSize: 32,
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            SettingTitle(title: "Instructions"),
            Setting(
              title: "How to Use",
              desc: "Shows a dialogue explaining Traffic Light Simulator.",
              action: () {
                showAlertDialogue(context, "Welcome to Traffic Light Simulator", "$description\n\n$instructions", false, {"show": false});
              }
            ),
            AboutSettings(context: context, version: version, beta: beta, about: description),
          ],
        ),
      ),
    );
  }
}