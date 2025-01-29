import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:localpkg/dialogue.dart';
import 'package:localpkg/functions.dart';
import 'package:localpkg/logger.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:scoreboardsimulator/main.dart';
import 'package:scoreboardsimulator/settings.dart';

Widget buttonBlock(String text, VoidCallback action, {double width = 250, double height = 75}) {
  return Padding(
    padding: const EdgeInsets.all(12.0),
    child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          minimumSize: Size(width, height),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(10)),
          ),
        ),
        onPressed: action,
        child: Text(
          text,
          style: TextStyle(
            fontSize: 20,
          ),
        ),
      ),
  );
}

void closeDialogue(BuildContext context, io.Socket? server) async {
  print("starting close...");
  if (await showConfirmDialogue(context: context, title: "Are you sure?", description: "Are you sure you want to exit the room?") ?? false) {
    if (server != null) {
      print("closing socket...");
      server.send([jsonEncode({"action": "disconnect"})]);
      server.disconnect();
    } else {
      print("not closing socket: server is null: $server");
    }
    print("exiting...");
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => HomePage()),
    );
  } else {
    print("close cancelled");
  }
}

String getDesc(dynamic error) {
  if (error == null || error == "null") {
    return "no error";
  }
  if (error is String) {
    switch (error) {
      case 'too many clients':
        return "There are too many players in this session.";
      case 'too many connections':
        return "Too many people are using the service right now.";
      case 'no manager':
        return "The game creator has left the room.";
      default:
        print("unknown error: $error");
        return error;
    }
  } else if (error is Error) {
    return "${error.runtimeType}: $error";
  } else {
    return 'ManualError: Unknown error type: ${error.runtimeType}: $error';
  }
}

Widget closeButton(BuildContext context, server) {
  return IconButton(
    icon: Icon(Icons.cancel_outlined),
    onPressed: () {
      closeDialogue(context, server);
    },
    iconSize: 32,
  );
}

Widget settingsButton(BuildContext context) {
  return IconButton(
    icon: Icon(Icons.settings),
    onPressed: () {
      navigate(context: context, page: Settings());
    },
    iconSize: 32,
  );
}

Widget ControlRow({required List<Widget> children, String? title}) {
  return Column(
    children: [
      if (title != null)
      Text(
        title,
      ),
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: children,
        ),
      ),
    ],
  );
}

Widget Control({required Widget child, required VoidCallback? function, required BuildContext context, Widget? button}) {
  double screenWidth = MediaQuery.of(context).size.width;
  double screenHeight = MediaQuery.of(context).size.height;
  double width = screenWidth / 3;
  double height = screenHeight / 6;
  
  if (width > 250) { width = 250; }
  if (width < 100) { width = 100; }

  if (height > 100) { height = 100; }
  if (height < 50) { height = 50; }

  return Container(
    height: height,
    width: width,
    padding: EdgeInsets.all(8),
    child: ElevatedButton(
      style: ElevatedButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
      ),
      onPressed: function,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          child,
          if (button != null)
          button,
        ],
      ),
    ),
  );
}

Widget Section({Widget? child}) {
  return Expanded(
    child: Center(
      child: child,
    ),
  );
}

class Scoreboard {
  Map data;
  double size;
  int mode;
  bool showBonus;

  Scoreboard({
    required this.data,
    this.size = 1,
    this.mode = 1,
    this.showBonus = true,
  });

  Widget _typeHandler({required String type}) {
    switch (type) {
      case 'basketball':
        return Basketball();
      default:
        return _typeHandler(type: "basketball");
    }
  }

  Widget build() {
    return IntrinsicHeight(
      child: Container(
        width: 500 * size,
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.all(Radius.circular(15 * size)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Center(
            child: _typeHandler(type: data["type"] ?? "baseball"),
          ),
        ),
      ),
    );
  }

  Widget Basketball() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: BasketballItem(home: true, name: "Panthers", points: 103),
            ),
            Expanded(
              child: Column(
                children: [
                  Text("Period"),
                  TextNumber(2),
                ],
              ),
            ),
            Expanded(
              child: BasketballItem(home: false, name: "Scissors", points: 103),
            ),
          ],
        ),
        Row(
          children: [
            Expanded(
              child: Column(
                children: [
                  Text("Time"),
                  TextTime(2),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget BasketballItem({required String name, required double points, bool home = false, int bonus = 2}) {
    return Padding(
      padding: EdgeInsets.all(8.0 * size),
      child: Column(
        children: [
          Text(name),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextNumber(points, pad: 2),
              SizedBox(width: 10 * size),
              Column(
                children: [
                  Text(showBonus ? (bonus == 1 ? "B" : (bonus == 2 ? "B+" : "")) : ""),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget TextDigit(String text, double fontSize) {
    return Text(text, style: TextStyle(fontSize: fontSize * size, fontFamily: "Digital7"));
  }

  Widget TextNumber(num number, {int pad = 0, double fontSize = 42}) {
    return TextDigit(cleanNumber(number).padLeft(pad, '0'), fontSize);
  }

  Widget TextTime(int ms, {double fontSize = 42}) {
    return TextDigit(formatDuration(ms: ms), fontSize);
  }
}