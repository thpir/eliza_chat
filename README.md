Eliza chat is a dart implementation of the ELIZA chatbot designed by Joseph Weizenbaum, in the sixties. ELIZA was one of the first chatbots that ever existed. This is a tribute to that wonderfull work that was well ahead of its time. The code for this package is based on the python version created by Wade Brainerd (https://github.com/wadetb/eliza)

## Features

Eliza can be used to implement in a fun Dart or Flutter project.

## Getting started

Install the package, import the library and you're good to go.

## Usage

```dart
import 'dart:io';

import 'package:eliza_chat/eliza_chat.dart';

void main() {
  var eliza = Eliza();
  print(eliza.getHeader());
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

- To start using the package, create an instance of the Eliza class

```dart
var eliza = Eliza();
```

- To get the old school header from the original ELIZA, use the getHeader() method. This method returns a String value:

```dart
eliza.getHeader();
```

- To get the introduction text from ELIZA, use the getInitial() method. This method returns a String value:

```dart
eliza.getInitial();
```

- To process the user its question, use the processInput() method. This method returns a String? value:

```dart
eliza.processInput(input);
```

- processInput() CAN return a null value. If the user types "bye", "goodbye" or "quit", Eliza knows you want to terminate the conversation and will return a null value instead. By checking for a null value you can get confirmation that Eliza received the stop command and you get ask for a final sentence. The getFinal method returns a String value:

```dart
eliza.getFinal();
```

![A screenshot of the example code](/screenshot.png)