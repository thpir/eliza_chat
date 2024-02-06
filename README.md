Eliza chat is a dart implementation of the ELIZA chatbot designed by Joseph Weizenbaum, in the sixties. ELIZA was one of the first chatbots that ever existed. This is a tribute to that wonderfull work that was well ahead of its time. The code for this package is based on the python version created by Wade Brainerd (https://github.com/wadetb/eliza)

## Features

Elize can be used to implement in a fun Dart or Flutter project.

## Getting started

Install the package, import the library and you're good to go.

## Usage

```dart
import 'dart:io';

import 'package:eliza_chat/eliza_chat.dart';

void main() {
  var eliza = Eliza();
  eliza.init();
  print(eliza.initials);

  while (true) {
    stdout.write("You: ");
    var input = stdin.readLineSync();
    if (input == null) {
      break;
    }
    print("Eliza: ${eliza.processInput(input)}");
  }
}
```

## Additional information

