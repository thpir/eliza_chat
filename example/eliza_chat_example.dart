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
