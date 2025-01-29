import 'package:flutter/foundation.dart';

String version = "0.0.0A";
bool beta = true;
bool debug = kDebugMode;

int yellowLightTime = 1000; // milliseconds
int blinkTime = 500; // milliseconds

String description = "Traffic Light Simulator is an app that allows you to simulate traffic lights in an intersection. Why? Because why not.";

String instructions = "You can play Singleplayer, which gives you a control panel and presets. Create a Room is like Singleplayer, but it also makes a server-side room that allows you to use the code at the top of the screen to join from other devices. Inside Create a Room or Singleplayer, you have the three or four stoplights you can control with presets, which are in the controls at the bottom of the screen. There are a ton of built-in presets, but you can also make your own and control each light however you want.";

Map initialData() {
  Map data = {};
  return data;
}