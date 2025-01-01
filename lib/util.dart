import 'package:flutter/material.dart';
import 'package:localpkg/dialogue.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:trafficlightsimulator/main.dart';

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
  if (await showConfirmDialogue(context, "Are you sure?", "Are you sure you want to exit the match?") ?? false) {
    if (server != null) {
      print("closing socket...");
      server.close();
    }
    print("exiting...");
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => HomePage()),
    );
  }
}

String getDesc(String error) {
  switch (error) {
    case 'too many clients':
      return "There are too many players in this session.";
    case 'too many connections':
      return "Too many people are using the service right now.";
    case 'no manager':
      return "The game creator has left the match.";
    default:
      print("unknown error: $error");
      return error;
  }
}

Widget closeButton(BuildContext context, server) {
  return IconButton(
    icon: Icon(Icons.cancel_outlined),
    onPressed: () {closeDialogue(context, server);},
    iconSize: 32,
  );
}

Map initialData() {
  return {
    "items": {
      "1": {
        "leftArrow": true, // never changes
        "rightArrow": true,
        "items": {
          "L1": {
            "show": true,
            "value": 0,
          },
          "L2": {
            "show": true,
            "value": 0,
          },
          "S1": {
            "show": true,
            "value": 0,
          },
          "S2": {
            "show": true,
            "value": 0,
          },
          "S3": {
            "show": true,
            "value": 0,
          },
          "R1": {
            "show": true,
            "value": 0,
          },
        },
      },
      "2": {
        "leftArrow": true, // never changes
        "rightArrow": true,
        "items": {
          "L1": {
            "show": true,
            "value": 0,
          },
          "L2": {
            "show": true,
            "value": 0,
          },
          "S1": {
            "show": true,
            "value": 0,
          },
          "S2": {
            "show": true,
            "value": 0,
          },
          "S3": {
            "show": true,
            "value": 0,
          },
          "R1": {
            "show": true,
            "value": 0,
          },
        },
      },
      "3": {
        "leftArrow": true, // never changes
        "rightArrow": true,
        "items": {
          "L1": {
            "show": true,
            "value": 0,
          },
          "L2": {
            "show": true,
            "value": 0,
          },
          "S1": {
            "show": true,
            "value": 0,
          },
          "S2": {
            "show": true,
            "value": 0,
          },
          "S3": {
            "show": true,
            "value": 0,
          },
          "R1": {
            "show": true,
            "value": 0,
          },
        },
      },
      "4": {
        "leftArrow": true, // never changes
        "rightArrow": true,
        "items": {
          "L1": {
            "show": true,
            "value": 0,
          },
          "L2": {
            "show": true,
            "value": 0,
          },
          "S1": {
            "show": true,
            "value": 0,
          },
          "S2": {
            "show": true,
            "value": 0,
          },
          "S3": {
            "show": true,
            "value": 0,
          },
          "R1": {
            "show": true,
            "value": 0,
          },
        },
      },
    },
  };
}