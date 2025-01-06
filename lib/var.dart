String version = "0.0.0A";
bool beta = true;
bool debug = true;

int yellowLightTime = 1000; // milliseconds
int blinkTime = 500; // milliseconds

String description = "Traffic Light Simulator is an app that allows you to simulate traffic lights in an intersection. Why? Because why not.";

String instructions = "You can play Singleplayer, which gives you a control panel and presets. Create a Room is like Singleplayer, but it also makes a server-side room that allows you to use the code at the top of the screen to join from other devices. Inside Create a Room or Singleplayer, you have the three or four stoplights you can control with presets, which are in the controls at the bottom of the screen. There are a ton of built-in presets, but you can also make your own and control each light however you want.";

/* presets
  top-level:    // key
    4           // 4 roads
    3           // 3 roads
    global      // all amounts of roads

  4 roads:      // 4
    1/0+-2      // top light left and straight
    1/0+3/0     // bottom and top lights straight
    1/-2+3/-2   // bottom and top lights left

    2/0+-2      // left light left and straight
    2/0+4/0     // left and right lights straight
    2/-2+4/-2   // left and right lights left

    3/0+-2      // top light left and straight
    4/0+-2      // right light left and straight

    1/0+3/0Y    // 1/0+3/0 with yielding left lights
    2/0+4/0Y    // 2/0+4/0 with yielding left lights

  3 roads:      // 3
    2/0+3/0     // right and left lights straight
    1/-2        // bottom light left
    3/0+-2      // right light left and straight

    2/0+3/0Y    // 2/0+3/0 with yielding left lights

  global:       // global
    off         // all stoplights have no lights
    solidgreen  // solid green
    solidyellow // solid yellow
    solidred    // solid red
    flashgreen  // flashing green
    flashyellow // flashing yellow
    flashred    // flashing red
*/

Map presets = {
  "3": {
    "2/0+3/0": {
      "1": {
        "-1": 1,
        "0": 4,
        "1": 5,
      },
      "2": {
        "-1": 4,
        "0": 3,
        "1": 3,
      },
      "3": {
        "-1": 1,
        "0": 3,
        "1": 4,
      },
    },
    "2/0+3/0Y": {
      "1": {
        "-1": 1,
        "0": 4,
        "1": 5,
      },
      "2": {
        "-1": 4,
        "0": 3,
        "1": 3,
      },
      "3": {
        "-1": 5,
        "0": 3,
        "1": 4,
      },
    },
    "1/-2": {
      "1": {
        "-1": 3,
        "0": 4,
        "1": 3,
      },
      "2": {
        "-1": 4,
        "0": 1,
        "1": 3,
      },
      "3": {
        "-1": 1,
        "0": 1,
        "1": 4,
      },
    },
    "3/0+-2": {
      "1": {
        "-1": 1,
        "0": 4,
        "1": 3,
      },
      "2": {
        "-1": 4,
        "0": 1,
        "1": 5,
      },
      "3": {
        "-1": 3,
        "0": 3,
        "1": 4,
      },
    },
  },
  "4": {
    "1/0+-2": {
      "1": {
        "-1": 3,
        "0": 3,
        "1": 3,
      },
      "2": {
        "-1": 1,
        "0": 1,
        "1": 3,
      },
      "3": {
        "-1": 5,
        "0": 1,
        "1": 5,
      },
      "4": {
        "-1": 1,
        "0": 1,
        "1": 3,
      },
    },
    "1/0+3/0": {
      "1": {
        "-1": 1,
        "0": 3,
        "1": 3,
      },
      "2": {
        "-1": 1,
        "0": 1,
        "1": 5,
      },
      "3": {
        "-1": 1,
        "0": 3,
        "1": 3,
      },
      "4": {
        "-1": 1,
        "0": 1,
        "1": 5,
      },
    },
    "1/0+3/0Y": {
      "1": {
        "-1": 5,
        "0": 3,
        "1": 3,
      },
      "2": {
        "-1": 1,
        "0": 1,
        "1": 5,
      },
      "3": {
        "-1": 5,
        "0": 3,
        "1": 3,
      },
      "4": {
        "-1": 1,
        "0": 1,
        "1": 5,
      },
    },
    "1/-2+3/-2": {
      "1": {
        "-1": 3,
        "0": 1,
        "1": 5,
      },
      "2": {
        "-1": 1,
        "0": 1,
        "1": 3,
      },
      "3": {
        "-1": 3,
        "0": 1,
        "1": 5,
      },
      "4": {
        "-1": 1,
        "0": 1,
        "1": 3,
      },
    },
    "2/0+-2": {
      "1": {
        "-1": 1,
        "0": 1,
        "1": 3,
      },
      "2": {
        "-1": 3,
        "0": 3,
        "1": 3,
      },
      "3": {
        "-1": 1,
        "0": 1,
        "1": 3,
      },
      "4": {
        "-1": 5,
        "0": 1,
        "1": 5,
      },
    },
    "2/0+4/0": {
      "1": {
        "-1": 1,
        "0": 1,
        "1": 5,
      },
      "2": {
        "-1": 1,
        "0": 3,
        "1": 3,
      },
      "3": {
        "-1": 1,
        "0": 1,
        "1": 5,
      },
      "4": {
        "-1": 1,
        "0": 3,
        "1": 3,
      },
    },
    "2/0+4/0Y": {
      "1": {
        "-1": 1,
        "0": 1,
        "1": 5,
      },
      "2": {
        "-1": 5,
        "0": 3,
        "1": 3,
      },
      "3": {
        "-1": 1,
        "0": 1,
        "1": 5,
      },
      "4": {
        "-1": 5,
        "0": 3,
        "1": 3,
      },
    },
    "2/-2+4/-2": {
      "1": {
        "-1": 1,
        "0": 1,
        "1": 3,
      },
      "2": {
        "-1": 3,
        "0": 1,
        "1": 5,
      },
      "3": {
        "-1": 1,
        "0": 1,
        "1": 3,
      },
      "4": {
        "-1": 3,
        "0": 1,
        "1": 5,
      },
    },
    "3/0+-2": {
      "1": {
        "-1": 5,
        "0": 1,
        "1": 5,
      },
      "2": {
        "-1": 1,
        "0": 1,
        "1": 3,
      },
      "3": {
        "-1": 3,
        "0": 3,
        "1": 3,
      },
      "4": {
        "-1": 1,
        "0": 1,
        "1": 3,
      },
    },
    "4/0+-2": {
      "1": {
        "-1": 1,
        "0": 1,
        "1": 3,
      },
      "2": {
        "-1": 5,
        "0": 1,
        "1": 5,
      },
      "3": {
        "-1": 1,
        "0": 1,
        "1": 3,
      },
      "4": {
        "-1": 3,
        "0": 3,
        "1": 3,
      },
    },
  },
  "global": {
    "off": {
      "1": {
        "-1": 0,
        "0": 0,
        "1": 0,
      },
      "2": {
        "-1": 0,
        "0": 0,
        "1": 0,
      },
      "3": {
        "-1": 0,
        "0": 0,
        "1": 0,
      },
      "4": {
        "-1": 0,
        "0": 0,
        "1": 0,
      },
    },
    "solidgreen": {
      "1": {
        "-1": 3,
        "0": 3,
        "1": 3,
      },
      "2": {
        "-1": 3,
        "0": 3,
        "1": 3,
      },
      "3": {
        "-1": 3,
        "0": 3,
        "1": 3,
      },
      "4": {
        "-1": 3,
        "0": 3,
        "1": 3,
      },
    },
    "solidyellow": {
      "1": {
        "-1": 2,
        "0": 2,
        "1": 2,
      },
      "2": {
        "-1": 2,
        "0": 2,
        "1": 2,
      },
      "3": {
        "-1": 2,
        "0": 2,
        "1": 2,
      },
      "4": {
        "-1": 2,
        "0": 2,
        "1": 2,
      },
    },
    "solidred": {
      "1": {
        "-1": 1,
        "0": 1,
        "1": 1,
      },
      "2": {
        "-1": 1,
        "0": 1,
        "1": 1,
      },
      "3": {
        "-1": 1,
        "0": 1,
        "1": 1,
      },
      "4": {
        "-1": 1,
        "0": 1,
        "1": 1,
      },
    },
    "flashgreen": {
      "1": {
        "-1": 6,
        "0": 6,
        "1": 6,
      },
      "2": {
        "-1": 6,
        "0": 6,
        "1": 6,
      },
      "3": {
        "-1": 6,
        "0": 6,
        "1": 6,
      },
      "4": {
        "-1": 6,
        "0": 6,
        "1": 6,
      },
    },
    "flashyellow": {
      "1": {
        "-1": 5,
        "0": 5,
        "1": 5,
      },
      "2": {
        "-1": 5,
        "0": 5,
        "1": 5,
      },
      "3": {
        "-1": 5,
        "0": 5,
        "1": 5,
      },
      "4": {
        "-1": 5,
        "0": 5,
        "1": 5,
      },
    },
    "flashred": {
      "1": {
        "-1": 4,
        "0": 4,
        "1": 4,
      },
      "2": {
        "-1": 4,
        "0": 4,
        "1": 4,
      },
      "3": {
        "-1": 4,
        "0": 4,
        "1": 4,
      },
      "4": {
        "-1": 4,
        "0": 4,
        "1": 4,
      },
    },
  }
};

Map initialData(int key) {
  Map data = {
    "4": {
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
    },
    "3": {
      "items": [
        {
          "id": 1,
          "allowed": [-2,2],
          "dir": [-1,1],
          "items": [
            {
              "direction": -2,
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
          "allowed": [0,1,2],
          "dir": [0,1],
          "items": [
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
          "allowed": [-2,-1,0],
          "dir": [0,-1],
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
          ],
        },
      ],
    },
  };
  return data["$key"];
}