import 'package:flutter/material.dart';
import 'package:localpkg/dialogue.dart';
import 'package:localpkg/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trafficlightsimulator/var.dart';
import 'package:localpkg/override.dart';

class Settings extends StatefulWidget {
  const Settings({super.key});

  @override
  State<Settings> createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  int yellowTimer = yellowLightTime;
  bool redLightOnRight = false;
  bool extendedStoplights = false;

  Future<void> loadSettings() async {
    print("getting settings...");
    SharedPreferences prefs = await SharedPreferences.getInstance();
    yellowTimer = prefs.getInt("yellowLightTimer") ?? yellowLightTime;
    redLightOnRight = prefs.getBool("rightRed") ?? redLightOnRight;
    extendedStoplights = prefs.getBool("extended") ?? extendedStoplights;
    setState(() {});
  }

  Future<void> setSettingInt(String key, int value) async {
    print("setting setting (int) $key...");
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setInt(key, value);
    setState(() {});
  }

  Future<void> setSettingBool(String key, bool value) async {
    print("setting setting (bool) $key...");
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool(key, value);
    setState(() {});
  }

  Future<void> clearSettings() async {
    print("clearing settings...");
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.clear();
    loadSettings();
    setState(() {});
  }

  Future<void> clearSetting(String key) async {
    print("clearing setting $key...");
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.remove(key);
    setState(() {});
  }

  @override
  void initState() {
    loadSettings();
    super.initState();
  }

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
        child: SingleChildScrollView(
          child: Column(
            children: [
              SettingTitle(title: "General"),
              Setting(
                title: "Yellow Light Timer",
                desc: "How long a yellow light lasts.",
                text: "${yellowTimer / 1000}s",
                action: () {
                  showDialog(
                    context: context,
                    builder: (context) {
                      double amount = (yellowTimer / 1000).toDouble();
                      int spaces = 1;
          
                      return AlertDialog(
                        title: Text('Yellow Light Timer'),
                        content: StatefulBuilder(
                          builder: (BuildContext context, StateSetter setState) {
                            return Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('Value: ${amount.toStringAsFixed(spaces)}s'),
                                Slider(
                                  value: amount,
                                  min: 0.1,
                                  max: 10,
                                  divisions: 99000,
                                  label: "${amount.toStringAsFixed(spaces)}s",
                                  onChanged: (value) {
                                    setState(() {
                                      amount = value;
                                    });
                                  },
                                ),
                              ],
                            );
                          },
                        ),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            child: Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () {
                              int value = (double.parse(amount.toStringAsFixed(spaces)) * 1000).toInt();
                              yellowTimer = value;
                              setSettingInt('yellowLightTimer', value);
                              Navigator.of(context).pop();
                            },
                            child: Text('OK'),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
              Setting(
                title: "Extended Stoplights",
                desc: "Extends straight-right and straight-left stoplights to include red lights.",
                text: extendedStoplights ? "On" : "Off",
                action: () async {
                  bool? result = await showConfirmDialogue(context, "Do you want to enable Extended Stoplights?", "This extends straight-right and straight-left stoplights to include red lights.");
                  if (result == null) {
                    print("action cancelled");
                    return;
                  }
                  extendedStoplights = result;
                  setSettingBool("extended", result);
                },
              ),
              Setting(
                title: "Red Light on Right-Only",
                desc: "Allows the right-only stoplight to show a red light.",
                text: redLightOnRight ? "On" : "Off",
                action: () async {
                  bool? result = await showConfirmDialogue(context, "Do you want to enable Red Light on Right Only?", "This allows the right-only stoplight to show a red light.");
                  if (result == null) {
                    print("action cancelled");
                    return;
                  }
                  redLightOnRight = result;
                  setSettingBool("rightRed", result);
                },
              ),
              SettingTitle(title: "Instructions"),
              Setting(
                title: "How to Use",
                desc: "Shows a dialogue explaining Traffic Light Simulator.",
                action: () {
                  showAlertDialogue(context, "Welcome to Traffic Light Simulator!", "$description\n\n$instructions", false, {"show": false});
                }
              ),
              AboutSettings(context: context, version: version, beta: beta, about: description),
              SettingTitle(title: "Data"),
              Setting(
                title: "Reset 3-Way Custom Presets",
                desc: "Resets all custom presets for 3-way intersection stoplights. This cannot be undone.",
                action: () async {
                  if (await showConfirmDialogue(context, "Are you sure?", "Are you sure you want to reset all custom presets for 3-way intersection stoplights? This cannot be undone.") ?? false) {
                    clearSetting("customPresets3");
                    showSnackBar(context, "Custom presets (3-way intersection) cleared!");
                  }
                },
              ),
              Setting(
                title: "Reset 4-Way Custom Presets",
                desc: "Resets all custom presets for 4-way intersection stoplights. This cannot be undone.",
                action: () async {
                  if (await showConfirmDialogue(context, "Are you sure?", "Are you sure you want to reset all custom presets for 4-way intersection stoplights? This cannot be undone.") ?? false) {
                    clearSetting("customPresets4");
                    showSnackBar(context, "Custom presets (4-way intersection) cleared!");
                  }
                },
              ),
              Setting(
                title: "Reset All Custom Presets",
                desc: "Resets all custom presets for all stoplights. This cannot be undone.",
                action: () async {
                  if (await showConfirmDialogue(context, "Are you sure?", "Are you sure you want to reset all custom presets? This cannot be undone.") ?? false) {
                    clearSetting("customPresets3");
                    clearSetting("customPresets4");
                    showSnackBar(context, "Custom presets cleared!");
                  }
                },
              ),
              Setting(
                title: "Reset All Settings and Data",
                desc: "Resets all settings, data, and custom presets. This cannot be undone.",
                action: () async {
                  if (await showConfirmDialogue(context, "Are you sure?", "Are you sure you want to reset all settings and data? This includes all custom presets. This cannot be undone.") ?? false) {
                    clearSettings();
                    showSnackBar(context, "All settings and data cleared!");
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}