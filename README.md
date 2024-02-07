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
  var intro = eliza.init();
  print(intro);
  print(eliza.getInitial());

  while (true) {
    stdout.write("You: ");
    var input = stdin.readLineSync();
    if (input == null) {
      break;
    }
    var output = eliza.processInput(input);
    if (output == null) {
      break;
    }
    print("Eliza: $output");
  }
  print(eliza.getFinal());
}
```

## Additional information

![A screenshot of the example code](/screenshot.png)