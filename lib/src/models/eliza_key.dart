import 'package:eliza_chat/src/models/eliza_decomp.dart';

class ElizaKey {
  String word;
  int weight;
  List<ElizaDecomp> decomps;

  ElizaKey(this.word, this.weight, this.decomps);
}
