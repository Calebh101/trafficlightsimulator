import 'package:flutter/material.dart';
import 'package:localpkg/dialogue.dart';

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

void closeDialogue(context, server) async {
  if (await showConfirmDialogue(context, "Are you sure?", "Are you sure you want to exit the match?") ?? false) {
    await server.close();
    print("closed socket");
  }
}

String getDesc(String error) {
  switch (error) {
    case 'too many clients':
      return "There are too many players in this session.";
    case 'no manager':
      return "The game creator has left the match.";
    default:
      return error;
  }
}