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
