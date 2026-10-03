import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const _pluralForms = {'zero', 'one', 'two', 'few', 'many', 'other'};

Map<String, dynamic> _catalog(String locale) =>
    jsonDecode(File('assets/translations/$locale.json').readAsStringSync())
        as Map<String, dynamic>;

bool _isPluralGroup(Object? v) =>
    v is Map && v.isNotEmpty && v.keys.every(_pluralForms.contains);

Map<String, Object?> _flatten(Map<String, dynamic> node, [String prefix = '']) {
  final out = <String, Object?>{};
  node.forEach((k, v) {
    final key = prefix.isEmpty ? k : '$prefix.$k';
    if (v is Map<String, dynamic> && !_isPluralGroup(v)) {
      out.addAll(_flatten(v, key));
    } else {
      out[key] = v;
    }
  });
  return out;
}

List<String> _placeholders(String s) =>
    RegExp(r'\{(\w*)\}').allMatches(s).map((m) => m.group(1)!).toList()
      ..sort();

void main() {
  final ar = _flatten(_catalog('ar'));
  final en = _flatten(_catalog('en'));

  test('ar and en have identical key sets', () {
    expect(
      ar.keys.toSet().difference(en.keys.toSet()),
      isEmpty,
      reason: 'keys only in ar.json',
    );
    expect(
      en.keys.toSet().difference(ar.keys.toSet()),
      isEmpty,
      reason: 'keys only in en.json',
    );
  });

  test('a key is a plural group in both catalogs or in neither', () {
    for (final key in ar.keys.where(en.containsKey)) {
      expect(
        _isPluralGroup(en[key]),
        _isPluralGroup(ar[key]),
        reason: key,
      );
      if (_isPluralGroup(ar[key])) {
        expect((ar[key]! as Map).containsKey('other'), isTrue, reason: key);
        expect((en[key]! as Map).containsKey('other'), isTrue, reason: key);
      }
    }
  });

  test('both translations of a string take the same placeholders', () {
    for (final key in ar.keys.where(en.containsKey)) {
      final a = ar[key], e = en[key];
      if (a is String && e is String) {
        expect(_placeholders(e), _placeholders(a), reason: key);
      }
    }
  });

  test('the hours and gallery subtrees are present (the checks above '
      'are not vacuous for them)', () {
    for (final prefix in [
      'venue.hours.',
      'venue.gallery.',
      'manage_venue.hours_editor.',
      'manage_venue.gallery_manager.',
    ]) {
      expect(ar.keys.where((k) => k.startsWith(prefix)), isNotEmpty,
          reason: prefix);
    }
  });
}
