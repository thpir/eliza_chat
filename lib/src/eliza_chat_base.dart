import 'dart:math';

import 'package:eliza_chat/src/data/doctor.dart';
import 'package:eliza_chat/src/models/eliza_decomp.dart';
import 'package:eliza_chat/src/models/eliza_key.dart';

class Eliza {
  late List<String> initials;
  late List<String> finals;
  late List<String> quits;
  late Map<String, List<String>> pres;
  late Map<String, List<String>> posts;
  late Map<String, List<String>> synons;
  late Map<String, ElizaKey> keys;
  late List<List<String>> memory;

  Eliza() {
    initials = [];
    finals = [];
    quits = [];
    pres = {};
    posts = {};
    synons = {};
    keys = {};
    memory = [];
  }

  init() {
    String word = "";
    for (String line in doctor) {
      if (line.trim().isEmpty) {
        continue;
      }

      // Preprocess line
      final parts = line.split(':').map((part) => part.trim()).toList();
      final tag = parts[0];
      final content = parts[1];

      switch (tag) {
        case 'initial':
          initials.add(content);
          break;
        case 'final':
          finals.add(content);
          break;
        case 'quit':
          quits.add(content);
          break;
        case 'pre':
          final preParts = content.split(' ');
          pres[preParts[0]] = preParts.sublist(1);
          break;
        case 'post':
          final postParts = content.split(' ');
          posts[postParts[0]] = postParts.sublist(1);
          break;
        case 'synon':
          final synonParts = content.split(' ');
          synons[synonParts[0]] = synonParts;
          break;
        case 'key':
          final keyParts = content.split(' ');
          word = keyParts[0];
          final weight = keyParts.length > 1 ? int.parse(keyParts[1]) : 1;
          ElizaKey key = ElizaKey(word, weight, []);
          keys[word] = key;
          break;
        case 'decomp':
          final decompParts = content.split(' ');
          var save = false;
          if (decompParts[0] == "\$") {
            save = true;
            decompParts.removeAt(0);
          }
          ElizaDecomp decomp = ElizaDecomp(decompParts, save, []);
          keys[word]!.decomps.add(decomp);
          break;
        case 'reasmb':
          final reasmbParts = content.split(' ');
          keys[word]!.decomps.last.reasmbs.add(reasmbParts);
          break;
      }
    }
  }

  String? _respond(String text) {
    // Check if the input text is a quit command, and if so, return null
    if (quits.contains(text.toLowerCase())) {
      return null;
    }
    // Perform punctuation cleanup in the input text
    text = text.replaceAll(RegExp(r'\s*\.\s*'), ' . ');
    text = text.replaceAll(RegExp(r'\s*,\s*'), ' , ');
    text = text.replaceAll(RegExp(r'\s*;\s*'), ' ; ');
    // Tokenize the input text into a list of words
    List<String> words = text.split(' ').where((w) => w.isNotEmpty).toList();
    // Substitute words based on predefined patterns (pre-substitution)
    words = _sub(words, pres);
    // Find keys (potential trigger words) in the input and sort them by weight
    List<ElizaKey> keyList = [];
    for (String word in words) {
      if (keys.containsKey(word.toLowerCase())) {
        keyList.add(keys[word.toLowerCase()]!);
      }
    }
    keyList.sort((a, b) => b.weight.compareTo(a.weight));
    // Initialize output to an empty list
    List<String>? output;
    // Loop through the sorted keys and try to match the input against each key
    for (ElizaKey key in keyList) {
      output = _matchKey(words, key);
      // If a match is found, break the loop
      if (output != null) {
        break;
      }
    }
    // If no output is generated from the keys, check memory for a stored response
    if (output == null) {
      if (memory.isNotEmpty) {
        int index = Random().nextInt(memory.length);
        output = memory.removeAt(index);
      } else {
        // If still no output, use a default response from xnone key
        output = _nextReasmb(keys['xnone']!.decomps[0]);
      }
    }
    // Join the output words into a string and return the response
    return output.join(' ');
  }

  List<String> _sub(List<String> words, Map<String, List<String>> sub) {
    List<String> output = [];
    for (String word in words) {
      String wordLower = word.toLowerCase();
      if (sub.containsKey(wordLower)) {
        output.addAll(sub[wordLower]!);
      } else {
        output.add(word);
      }
    }
    return output;
  }

  List<String>? _matchKey(List<String> words, ElizaKey key) {
    for (ElizaDecomp decomp in key.decomps) {
      List<List<String>>? results = _matchDecomp(decomp.parts, words);
      if (results == null) {
        continue;
      }
      results = results.map((words) => _sub(words, posts)).toList();
      List<String> reasmb = _nextReasmb(decomp);
      if (reasmb[0] == 'goto') {
        String gotoKey = reasmb[1];
        if (!keys.containsKey(gotoKey)) {
          throw ArgumentError('Invalid goto key $gotoKey');
        }
        return _matchKey(words, keys[gotoKey]!);
      }
      List<String> output = _reassemble(reasmb, results);
      if (decomp.save) {
        memory.add(output);
        continue;
      }
      return output;
    }
    return null;
  }

  List<String> _nextReasmb(ElizaDecomp decomp) {
    int index = decomp.nextReasmbIndex;
    List<String> result = decomp.reasmbs[index % decomp.reasmbs.length];
    decomp.nextReasmbIndex = index + 1;
    return result;
  }

  bool _matchDecompR(
      List<String> parts, List<String> words, List<List<String>> results) {
    if (parts.isEmpty && words.isEmpty) {
      return true;
    }
    if (parts.isEmpty || (words.isEmpty && parts != ['*'])) {
      return false;
    }
    if (parts[0] == '*') {
      for (int index = words.length; index >= 0; index--) {
        results.add(words.sublist(0, index));
        if (_matchDecompR(parts.sublist(1), words.sublist(index), results)) {
          return true;
        }
        results.removeLast();
      }
      return false;
    } else if (parts[0].startsWith('@')) {
      String root = parts[0].substring(1);
      if (!synons.containsKey(root)) {
        throw ArgumentError('Unknown synonym root $root');
      }
      if (!synons[root]!.contains(words[0].toLowerCase())) {
        return false;
      }
      results.add([words[0]]);
      return _matchDecompR(parts.sublist(1), words.sublist(1), results);
    } else if (parts[0].toLowerCase() != words[0].toLowerCase()) {
      return false;
    } else {
      return _matchDecompR(parts.sublist(1), words.sublist(1), results);
    }
  }

  List<List<String>>? _matchDecomp(List<String> parts, List<String> words) {
    List<List<String>> results = [];
    if (_matchDecompR(parts, words, results)) {
      return results;
    }
    return null;
  }

  List<String> _reassemble(List<String> reasmb, List<List<String>> results) {
    List<String> output = [];
    for (String reword in reasmb) {
      if (reword.isEmpty) {
        continue;
      }
      if (reword[0] == '(' && reword[reword.length - 1] == ')') {
        int index = int.parse(reword.substring(1, reword.length - 1));
        if (index < 1 || index > results.length) {
          throw ArgumentError('Invalid result index $index');
        }
        List<String> insert = results[index - 1];
        for (String punct in [',', '.', ';']) {
          if (insert.contains(punct)) {
            insert = insert.sublist(0, insert.indexOf(punct));
          }
        }
        output.addAll(insert);
      } else {
        output.add(reword);
      }
    }
    return output;
  }

  String getInitial() {
    return initials[Random().nextInt(initials.length)];
  }

  String getFinal() {
    return finals[Random().nextInt(finals.length)];
  }

  String? processInput(String input) {
    return _respond(input);
  }
}



