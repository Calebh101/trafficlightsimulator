import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:localpkg/dialogue.dart';
import 'package:localpkg/functions.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:trafficlightsimulator/drawer.dart';
import 'package:trafficlightsimulator/main.dart';
import 'package:trafficlightsimulator/settings.dart';

String getNameForState(int state) {
  switch (state) {
    case 0: return "Off";
    case 1: return "Red";
    case 2: return "Yellow";
    case 3: return "Green";
    case 4: return "Flashing red";
    case 5: return "Flashing yellow";
    case 6: return "Flashing green";
    default: return "ERROR: UNKNOWN STATE: $state";
  }
}

String getNameForDirection(int direction) {
  switch (direction) {
    case -1: return "Left";
    case 0: return "Straight";
    case 1: return "Right";
    default: return "ERROR: UNKNOWN DIRECTION: $direction";
  }
}

String getNameForRoads(int roads) {
  switch (roads) {
    case 3 || 4: return "$roads-Way Intersection";
    default: return "ERROR: UNKNOWN ROADS COUNT: $roads";
  }
}

Widget buttonBlock(String text, VoidCallback action, {double width = 250, double height = 75}) {
  return Padding(
    padding: const EdgeInsets.all(12.0),
    child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          minimumSize: Size(width, height),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(10)), // Square edges
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
  if (await showConfirmDialogue(context, "Are you sure?", "Are you sure you want to exit the room?") ?? false) {
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

String getDesc(String error) {
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

Widget Stoplights({required int roads, bool showNumber = true, bool align = true, required double height, required double width, required double size, required Map data, required Map item, required int index, required Animation<double> animation, Widget? underChild, bool rightRed = false, bool extended = false}) {
  List alignments = [Alignment.bottomCenter, Alignment.centerLeft, Alignment.topCenter, Alignment.centerRight];
  if (roads == 3) {
    alignments = [Alignment.bottomCenter, Alignment.centerLeft, Alignment.centerRight];
  }
  return Area(showNumber: showNumber, height: height, width: width, size: size, alignment: align ? alignments[index] : Alignment.center, id: item["id"], children: item["items"].asMap().entries.map<Widget>((entry) {
    Map item = entry.value;
    return Column(
      children: [
        Stoplight(size: size, direction: item["direction"], active: item["active"], subactive: item["subactive"], animation: animation, rightRed: rightRed, extended: extended),
        if (underChild != null)
        underChild,
      ],
    );
  }).toList());
}

Widget Area({required bool showNumber, required double width, required double height, required double size, required int id, required List<Widget> children, required Alignment? alignment}) {
  Widget container = Container(
    width: width,
    height: height,
    child: OverflowBox(
      maxWidth: double.infinity,
      maxHeight: double.infinity,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (showNumber)
              Text("#$id"),
            Row(
              children: children,
            ),
          ],
        ),
      ),
    ),
  );

  if (alignment != null) {
    return Align(
      alignment: alignment, // Center
      child: container,
    );
  } else {
    return container;
  }
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