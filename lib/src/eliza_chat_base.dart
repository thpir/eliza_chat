import 'dart:math';

import 'package:eliza_chat/src/data/doctor.dart';
import 'package:eliza_chat/src/models/eliza_decomp.dart';
import 'package:eliza_chat/src/models/eliza_key.dart';

class Eliza {
  late List<String> _initials;
  late List<String> _finals;
  late List<String> _quits;
  late Map<String, List<String>> _pres;
  late Map<String, List<String>> _posts;
  late Map<String, List<String>> _synons;
  late Map<String, ElizaKey> _keys;
  late List<List<String>> _memory;

  /// Constructor for the Eliza class.
  Eliza() {
    _initials = [];
    _finals = [];
    _quits = [];
    _pres = {};
    _posts = {};
    _synons = {};
    _keys = {};
    _memory = [];
  }

  /// Initializes the chatbot by parsing the doctor script and populating 
  /// internal data structures.
  init() {
    String word = "";
    for (String line in doctor) {
      if (line.trim().isEmpty) {
        continue;
      }

      /// Preprocess line
      final parts = line.split(':').map((part) => part.trim()).toList();
      final tag = parts[0];
      final content = parts[1];

      switch (tag) {
        case 'initial':
          _initials.add(content);
          break;
        case 'final':
          _finals.add(content);
          break;
        case 'quit':
          _quits.add(content);
          break;
        case 'pre':
          final preParts = content.split(' ');
          _pres[preParts[0]] = preParts.sublist(1);
          break;
        case 'post':
          final postParts = content.split(' ');
          _posts[postParts[0]] = postParts.sublist(1);
          break;
        case 'synon':
          final synonParts = content.split(' ');
          _synons[synonParts[0]] = synonParts;
          break;
        case 'key':
          final keyParts = content.split(' ');
          word = keyParts[0];
          final weight = keyParts.length > 1 ? int.parse(keyParts[1]) : 1;
          ElizaKey key = ElizaKey(word, weight, []);
          _keys[word] = key;
          break;
        case 'decomp':
          final decompParts = content.split(' ');
          var save = false;
          if (decompParts[0] == "\$") {
            save = true;
            decompParts.removeAt(0);
          }
          ElizaDecomp decomp = ElizaDecomp(decompParts, save, []);
          _keys[word]!.decomps.add(decomp);
          break;
        case 'reasmb':
          final reasmbParts = content.split(' ');
          _keys[word]!.decomps.last.reasmbs.add(reasmbParts);
          break;
      }
    }
  }

  /// Responds to the user input by generating an appropriate ELIZA-like 
  /// response.
  String? _respond(String text) {
    /// Check if the input text is a quit command, and if so, return null
    if (_quits.contains(text.toLowerCase())) {
      return null;
    }
    /// Perform punctuation cleanup in the input text
    text = text.replaceAll(RegExp(r'\s*\.\s*'), ' . ');
    text = text.replaceAll(RegExp(r'\s*,\s*'), ' , ');
    text = text.replaceAll(RegExp(r'\s*;\s*'), ' ; ');
    /// Tokenize the input text into a list of words
    List<String> words = text.split(' ').where((w) => w.isNotEmpty).toList();
    /// Substitute words based on predefined patterns (pre-substitution)
    words = _sub(words, _pres);
    /// Find keys (potential trigger words) in the input and sort them by weight
    List<ElizaKey> keyList = [];
    for (String word in words) {
      if (_keys.containsKey(word.toLowerCase())) {
        keyList.add(_keys[word.toLowerCase()]!);
      }
    }
    keyList.sort((a, b) => b.weight.compareTo(a.weight));
    /// Initialize output to an empty list
    List<String>? output;
    /// Loop through the sorted keys and try to match the input against each key
    for (ElizaKey key in keyList) {
      output = _matchKey(words, key);
      /// If a match is found, break the loop
      if (output != null) {
        break;
      }
    }
    /// If no output is generated from the keys, check memory for a stored 
    /// response
    if (output == null) {
      if (_memory.isNotEmpty) {
        int index = Random().nextInt(_memory.length);
        output = _memory.removeAt(index);
      } else {
        /// If still no output, use a default response from xnone key
        output = _nextReasmb(_keys['xnone']!.decomps[0]);
      }
    }
    /// Join the output words into a string and return the response
    return output.join(' ');
  }

  /// Performs word substitution based on predefined patterns.
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

  /// Matches the user input against a given key (potential trigger word).
  List<String>? _matchKey(List<String> words, ElizaKey key) {
    for (ElizaDecomp decomp in key.decomps) {
      List<List<String>>? results = _matchDecomp(decomp.parts, words);
      if (results == null) {
        continue;
      }
      results = results.map((words) => _sub(words, _posts)).toList();
      List<String> reasmb = _nextReasmb(decomp);
      if (reasmb[0] == 'goto') {
        String gotoKey = reasmb[1];
        if (!_keys.containsKey(gotoKey)) {
          throw ArgumentError('Invalid goto key $gotoKey');
        }
        return _matchKey(words, _keys[gotoKey]!);
      }
      List<String> output = _reassemble(reasmb, results);
      if (decomp.save) {
        _memory.add(output);
        continue;
      }
      return output;
    }
    return null;
  }

  /// Retrieves the next reassembly string from the given decomp structure.
  List<String> _nextReasmb(ElizaDecomp decomp) {
    int index = decomp.nextReasmbIndex;
    List<String> result = decomp.reasmbs[index % decomp.reasmbs.length];
    decomp.nextReasmbIndex = index + 1;
    return result;
  }

  /// Recursively matches decomposition parts with user input and generates 
  /// results.
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
      if (!_synons.containsKey(root)) {
        throw ArgumentError('Unknown synonym root $root');
      }
      if (!_synons[root]!.contains(words[0].toLowerCase())) {
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

  /// Matches decomposition parts with user input and generates results.
  List<List<String>>? _matchDecomp(List<String> parts, List<String> words) {
    List<List<String>> results = [];
    if (_matchDecompR(parts, words, results)) {
      return results;
    }
    return null;
  }

  /// Reassembles the response based on reassembly strings and matched results.
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

  /// Retrieves a random initial greeting.
  String getInitial() {
    return _initials[Random().nextInt(_initials.length)];
  }

  /// Retrieves a random final farewell.
  String getFinal() {
    return _finals[Random().nextInt(_finals.length)];
  }

  /// Processes user input and returns the generated ELIZA-like response.
  String? processInput(String input) {
    return _respond(input);
  }
}



