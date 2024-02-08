import 'package:eliza_chat/eliza_chat.dart';
import 'package:test/test.dart';

void main() {
  group('Eliza Test', () {
    late Eliza eliza;

    setUp(() {
      eliza = Eliza();
    });

    test('Initial and Final Phrases', () {
      String initialPhrase = eliza.getInitial();
      String finalPhrase = eliza.getFinal();

      expect(initialPhrase, isNotNull);
      expect(finalPhrase, isNotNull);
    });

    test('Process Input', () {
      // Test with various inputs
      String input1 = 'Hello';
      String input2 = 'How are you?';
      String input3 = 'Goodbye';
      
      String? response1 = eliza.processInput(input1);
      String? response2 = eliza.processInput(input2);
      String? response3 = eliza.processInput(input3);

      expect(response1, isNotNull);
      expect(response2, isNotNull);
      expect(response3, isNull);

      print('Input: $input1, Response: $response1');
      print('Input: $input2, Response: $response2');
      print('Input: $input3, Response: $response3');
    });
  });
}
