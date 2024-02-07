import 'package:eliza_chat/src/models/decomposition_rule.dart';

class ElizaKey {
  String word;
  int weight;
  List<DecompositionRule> decomps;

  ElizaKey(this.word, this.weight, this.decomps);
}
