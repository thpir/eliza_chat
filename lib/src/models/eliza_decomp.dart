class ElizaDecomp {
  List<String> parts;
  bool save;
  List<List<String>> reasmbs;
  int nextReasmbIndex = 0;

  ElizaDecomp(this.parts, this.save, this.reasmbs, {int? nextReasmbIndex})
      : nextReasmbIndex = nextReasmbIndex ?? 0;
}
