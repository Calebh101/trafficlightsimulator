String version = "0.0.0A";
bool beta = true;

/* presets
  top-level:
    4           // 4 roads
    3           // 3 roads
    global      // all amounts of roads

  4 roads:
    1/0+-2      // top light left and straight
    1/0+3/0     // top and bottom lights straight
    1/-2+3/-2   // top and bottom lights left

    2/0+-2      // right light left and straight
    2/0+4/0     // right and left lights straight
    2/-2+4/-2   // right and left lights left

    3/0+-2      // bottom light left and straight
    4/0+-2      // left light left and straight

  3 roads:
    // TODO

  global:
    solidgreen  // solid green
    solidyellow // solid yellow
    solidred    // solid red
    flashgreen  // flashing green
    flashyellow // flashing yellow
    flashred    // flashing red
*/

Map presets = {
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
  "3": {}, // TODO
  "global": {
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