import 'dart:math';

final _synonyms = <String, String>{
  'rasm': 'foto',
  'surat': 'foto',
  'фото': 'foto',
  'камера': 'kamera',
  'таймер': 'timer',
  'будильник': 'alarm',
  'wi-fi': 'wifi',
  'вайфай': 'wifi',
  'блютуз': 'bluetooth',
};

String normalizeText(String input) {
  final lower = input.toLowerCase().trim();
  final words = lower.split(RegExp(r'\s+'));
  final normalized = words.map((w) => _synonyms[w] ?? w).toList();
  return normalized.join(' ');
}

Set<String> tokenize(String input) {
  final cleaned = normalizeText(input)
      .replaceAll(RegExp(r'[^a-z0-9а-яё\s]'), ' ')
      .trim();
  return cleaned.isEmpty
      ? <String>{}
      : cleaned.split(RegExp(r'\s+')).toSet();
}

double jaccardSimilarity(Set<String> a, Set<String> b) {
  if (a.isEmpty || b.isEmpty) return 0;
  final intersection = a.intersection(b).length;
  final union = a.union(b).length;
  return intersection / union;
}

double cosineSimilarity(Set<String> a, Set<String> b) {
  if (a.isEmpty || b.isEmpty) return 0;
  final intersection = a.intersection(b).length;
  final denom = sqrt(a.length * b.length);
  return denom == 0 ? 0 : intersection / denom;
}
