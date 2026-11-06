import 'dart:math' as math;
import 'dart:typed_data';

import 'package:sqlite3/sqlite3.dart' show AllowedArgumentCount, Database, SqliteArguments;

/// Fuzzy search over English and Chinese item names. The market search and the fitting pickers
/// (ships, modules, charges) all rank with it: SDE queries through the SQL function that
/// [registerNameSearch] installs, lists already in memory through [rankByName].
///
/// Names and queries are folded before they are compared: lower case, full-width letters and
/// digits made half-width, spaces and punctuation dropped. "co processor", "Co-Processor" and
/// "ＣＯＰＲＯＣＥＳＳＯＲ" are the same query. The query is also cut into tokens at spaces and
/// punctuation and where Chinese meets Latin letters or digits: "1mn加力" is "1mn" and "加力".
///
/// Matches, best first:
/// 1. The whole query is the name, or its start.
/// 2. Every token, in any order, matches the English or the Chinese name:
///    - a whole word;
///    - the start of a word (in Chinese, any part of the name);
///    - word beginnings in order, "lse" or "lar shi ext" for Large Shield Extender. Initials
///      rank above longer pieces, and skipping fewer words ranks higher;
///    - any part of the name, "rifter" in Starifter;
///    - letters in order, each word's share starting with its first letter: "mwd" in
///      Microwarpdrive, "dmgctrl" for Damage Control; in Chinese any characters in order,
///      "加燃" in 加力燃烧器.
///    The weakest token decides the rank. When the tokens also appear together as typed,
///    the name ranks higher.
/// 3. Only when 1 and 2 find fewer than [typoFallbackBelow] items: tokens with typos. One edit
///    is allowed from 4 letters or 3 Chinese characters, two from 8 letters or 6 characters.
///
/// Roman numerals in names also match digits ("dc2" finds Damage Control II). "ab" and "mwd"
/// also look for afterburner and microwarpdrive, which their letters alone would rank low.
class NameQuery {
  factory NameQuery(String text) => NameQuery._(foldWords(text));

  NameQuery._(this.tokens)
      : compact = tokens.join(),
        _options = [
          for (final t in tokens) [t, ...?_aliases[t]],
        ],
        _latin = tokens.any((t) => !_isCjk(t.codeUnitAt(0))),
        _chinese = tokens.any((t) => _isCjk(t.codeUnitAt(0))),
        _digits = tokens.any((t) => t.contains(RegExp('[1-5]')));

  /// Folded tokens of the query.
  final List<String> tokens;

  /// The tokens joined: the query without spaces and punctuation.
  final String compact;

  /// Each token with its aliases.
  final List<List<String>> _options;

  /// Whether the query has Latin (letters, digits) and Chinese tokens.
  final bool _latin;
  final bool _chinese;

  /// Only digits can match the Roman numerals of a name.
  final bool _digits;

  final _names = <_Name>[];

  bool get isEmpty => compact.isEmpty;

  /// Forms the whole query is compared in: itself, plus the aliases of a one-token query.
  List<String> get _wholeForms => _options.length == 1 ? _options.first : [compact];

  static String? _cachedText;
  static NameQuery? _cached;

  /// [text] parsed once and reused while the same query scores row after row.
  static NameQuery cached(String text) {
    if (text != _cachedText || _cached == null) {
      _cached = NameQuery(text);
      _cachedText = text;
    }
    return _cached!;
  }

  static const _exact = 1000;
  static const _prefix = 950;

  /// How well the names match; 0 when they do not. Within one kind of match, shorter names
  /// score higher. With [typos], tokens that match no other way may be a few edits off.
  ///
  /// Latin tokens are compared with the English name only: the Chinese name repeats its Latin
  /// parts ("1MN", "II"). Chinese tokens can only match the Chinese name.
  int score(String? en, String? zh, {bool typos = false}) {
    if (isEmpty) return 0;
    final names = _names..clear();
    if (_latin) _addForms(names, en);
    if (_chinese) _addForms(names, zh);
    if (names.isEmpty) return 0;

    var best = 0;
    var length = 255;
    for (final n in names) {
      for (final q in _wholeForms) {
        final s = n.compact == q ? _exact : (n.compact.startsWith(q) ? _prefix : 0);
        if (s > best || (s == best && s > 0 && n.compact.length < length)) {
          best = s;
          length = n.compact.length;
        }
      }
    }
    if (best > 0) return _final(best, length);

    var weakest = 5;
    var levels = 0;
    var bonus = 0;
    var edits = 0;
    for (var i = 0; i < _options.length; i++) {
      var found = -1;
      for (final n in names) {
        for (final t in _options[i]) {
          final m = _match(t, n);
          if (m > found) found = m;
        }
      }
      if (found < 0 && typos) {
        final t = tokens[i];
        final allowed = _allowedEdits(t);
        var fewest = allowed + 1;
        if (allowed > 0) {
          for (final n in names) {
            final d = _editsToPart(t, n.compact, allowed);
            if (d < fewest) fewest = d;
          }
        }
        if (fewest <= allowed) {
          found = _encode(0, 0);
          edits += fewest;
        }
      }
      if (found < 0) return 0;
      final level = found ~/ 64;
      if (level < weakest) weakest = level;
      levels += level;
      bonus += found % 64 - 32;
    }
    var tier = 100 + 100 * weakest + 10 * levels ~/ tokens.length + math.max<int>(bonus, -50) - 10 * edits;
    if (tokens.length > 1 && _together(names)) tier += 40;
    return _final(math.max(tier, 1), names.first.compact.length);
  }

  static int _final(int tier, int length) => tier * 256 + 255 - math.min(length, 255);

  /// An SQLite condition on `t.name_en` and `t.name_zh` that every row [score] accepts also
  /// passes: the letters of each token appear in the name the token is compared with. With
  /// [typos], as many letters may be missing as edits are allowed. Digits 1 to 5 are not
  /// checked, they may stand for Roman numerals. Rows that fail it never reach Dart, which
  /// keeps a search over the whole SDE cheap.
  String sqlPrefilter({required bool typos}) {
    final terms = <String>[];
    for (final t in tokens) {
      final column = _isCjk(t.codeUnitAt(0)) ? 't.name_zh' : 't.name_en';
      // Folded tokens hold only letters, digits and Chinese characters, so none of them needs
      // escaping in a LIKE pattern. LIKE ignores ASCII case.
      final letters = {
        for (final r in t.runes)
          if (r < 0x31 || r > 0x35) String.fromCharCode(r),
      };
      final need = letters.length - (typos ? _allowedEdits(t) : 0);
      if (need <= 0) continue;
      final checks = [for (final ch in letters) "($column LIKE '%$ch%')"];
      terms.add(need == letters.length ? checks.join(' AND ') : '(${checks.join(' + ')}) >= $need');
    }
    return terms.isEmpty ? '1' : terms.join(' AND ');
  }

  void _addForms(List<_Name> names, String? text) {
    if (text == null) return;
    final n = _fold(text);
    if (n == null) return;
    names.add(n);
    if (_digits) {
      final d = n.withDigits();
      if (d != null) names.add(d);
    }
  }

  /// The tokens appear in the name as typed, from the start of a word.
  bool _together(List<_Name> names) {
    for (final n in names) {
      for (var i = n.compact.indexOf(compact); i >= 0; i = n.compact.indexOf(compact, i + 1)) {
        if (n.startsAt(i)) return true;
      }
    }
    return false;
  }

  static int _encode(int level, int bonus) => level * 64 + bonus + 32;

  /// The best level at which [t] matches [n] with a small bonus or penalty, encoded by
  /// [_encode]; -1 for no match. Levels: 5 a word, 4 the start of a word, 3 word beginnings in
  /// order, 2 a part of the name, 1 letters in order.
  static int _match(String t, _Name n) {
    final c = n.compact;
    // Every kind of match keeps the token's letters in order, which most names fail fast.
    if (!_inOrder(t, c)) return -1;
    if (n.hasWord(t)) return _encode(5, 0);
    if (_isCjk(t.codeUnitAt(0))) return c.contains(t) ? _encode(4, 0) : _encode(1, 0);
    if (n.hasWordStartingWith(t)) return _encode(4, 0);
    if (t.length >= 2) {
      final prefixSkips = _chainSkips(t, n, _prefixPieces);
      if (prefixSkips >= 0) {
        final letterSkips = _chainSkips(t, n, _letterPieces);
        final bonus = math.max(letterSkips >= 0 ? 5 - 2 * letterSkips : -20, -2 * prefixSkips);
        return _encode(3, math.max(bonus, -20));
      }
    }
    if (c.contains(t)) return _encode(2, 0);
    if (t.length >= 2) {
      final skips = _chainSkips(t, n, _gappedPieces);
      if (skips >= 0) return _encode(1, math.max(-2 * skips, -20));
    }
    return -1;
  }

  static int _allowedEdits(String t) {
    if (_isCjk(t.codeUnitAt(0))) return t.length >= 6 ? 2 : (t.length >= 3 ? 1 : 0);
    return t.length >= 8 ? 2 : (t.length >= 4 ? 1 : 0);
  }
}

/// Typo matches are looked for only when the strict match finds fewer items than this.
const typoFallbackBelow = 8;

/// Abbreviations players use that are not the initials of the name. Every letter of an
/// abbreviation must occur in its expansion, or [NameQuery.sqlPrefilter] would drop the rows.
const _aliases = {
  'ab': ['afterburner'],
  'mwd': ['microwarpdrive'],
};

/// Folded words of [text]: lower case and half-width, split at everything that is not a letter
/// or digit, and where Chinese meets other letters.
List<String> foldWords(String text) {
  final n = _fold(text);
  if (n == null) return const [];
  return [for (var w = 0; w < n.words; w++) n.compact.substring(n.starts[w], n.starts[w + 1])];
}

/// A folded name: the words joined, and the offset where each word starts.
class _Name {
  _Name(this.compact, this.starts);

  final String compact;

  /// Start offset of every word in [compact], then its length.
  final Int32List starts;

  int get words => starts.length - 1;

  bool hasWord(String t) {
    for (var w = 0; w < words; w++) {
      if (starts[w + 1] - starts[w] == t.length && compact.startsWith(t, starts[w])) return true;
    }
    return false;
  }

  bool hasWordStartingWith(String t) {
    for (var w = 0; w < words; w++) {
      if (starts[w + 1] - starts[w] >= t.length && compact.startsWith(t, starts[w])) return true;
    }
    return false;
  }

  /// Whether a word starts at [offset]. In Chinese every character counts as one.
  bool startsAt(int offset) {
    if (_isCjk(compact.codeUnitAt(offset))) return true;
    for (var w = 0; w < words; w++) {
      if (starts[w] == offset) return true;
    }
    return false;
  }

  /// 1 to 5 when word [w] is a Roman numeral up to V, else 0.
  int _roman(int w) {
    final at = starts[w];
    return switch (starts[w + 1] - at) {
      1 when compact.startsWith('i', at) => 1,
      1 when compact.startsWith('v', at) => 5,
      2 when compact.startsWith('ii', at) => 2,
      2 when compact.startsWith('iv', at) => 4,
      3 when compact.startsWith('iii', at) => 3,
      _ => 0,
    };
  }

  /// This name with Roman numeral words written as digits, or null when it has none.
  _Name? withDigits() {
    var any = false;
    for (var w = 0; w < words && !any; w++) {
      any = _roman(w) > 0;
    }
    if (!any) return null;
    final out = StringBuffer();
    final outStarts = Int32List(words + 1);
    for (var w = 0; w < words; w++) {
      outStarts[w] = out.length;
      final digit = _roman(w);
      if (digit > 0) {
        out.writeCharCode(0x30 + digit);
      } else {
        out.write(compact.substring(starts[w], starts[w + 1]));
      }
    }
    outStarts[words] = out.length;
    return _Name(out.toString(), outStarts);
  }
}

const _separator = 0;
const _latin = 1;
const _chinese = 2;

var _chars = Uint16List(256);
var _wordStarts = Int32List(257);

/// [text] folded: lower case, half-width, spaces and punctuation dropped, with the offsets
/// where words start. Null when nothing is left.
_Name? _fold(String text) {
  if (_chars.length < text.length) {
    _chars = Uint16List(text.length * 2);
    _wordStarts = Int32List(text.length * 2 + 1);
  }
  var length = 0;
  var words = 0;
  var previous = _separator;
  for (var i = 0; i < text.length; i++) {
    var c = text.codeUnitAt(i);
    int kind;
    if (c >= 0xFF01 && c <= 0xFF5E) c -= 0xFEE0; // full-width forms of ASCII
    if (c < 0x80) {
      if (c >= 0x41 && c <= 0x5A) c += 0x20;
      kind = (c >= 0x61 && c <= 0x7A) || (c >= 0x30 && c <= 0x39) ? _latin : _separator;
    } else if (c >= 0xDC00 && c <= 0xDFFF) {
      kind = previous; // second half of a surrogate pair
    } else {
      kind = _kind(c);
      if (kind == _latin) c = _lower(c);
    }
    if (kind == _separator) {
      previous = kind;
      continue;
    }
    if (kind != previous) _wordStarts[words++] = length;
    previous = kind;
    _chars[length++] = c;
  }
  if (length == 0) return null;
  _wordStarts[words] = length;
  return _Name(String.fromCharCodes(_chars, 0, length), Int32List(words + 1)..setRange(0, words + 1, _wordStarts));
}

int _kind(int c) {
  if (_isCjk(c)) return _chinese;
  final punctuation = c <= 0xBF || // Latin-1 punctuation, the middle dot
      c == 0xD7 ||
      c == 0xF7 ||
      (c >= 0x2000 && c <= 0x2BFF) || // dashes, quotes, symbols
      (c >= 0x3000 && c <= 0x303F) || // CJK punctuation, the ideographic space
      c == 0x30FB ||
      (c >= 0xFE30 && c <= 0xFE6F) ||
      (c >= 0xFF00 && c <= 0xFF65); // full-width punctuation
  return punctuation ? _separator : _latin;
}

int _lower(int c) {
  final s = String.fromCharCode(c).toLowerCase();
  return s.length == 1 ? s.codeUnitAt(0) : c;
}

/// Chinese characters, as a code unit (the first half of a surrogate pair for the extension
/// planes).
bool _isCjk(int c) =>
    (c >= 0x4E00 && c <= 0x9FFF) ||
    (c >= 0x3400 && c <= 0x4DBF) ||
    (c >= 0xF900 && c <= 0xFAFF) ||
    (c >= 0xD840 && c <= 0xD88C);

/// Whether the letters of [t] appear in [c] in order.
bool _inOrder(String t, String c) {
  var i = 0;
  for (var j = 0; j < c.length && i < t.length; j++) {
    if (c.codeUnitAt(j) == t.codeUnitAt(i)) i++;
  }
  return i == t.length;
}

/// Pieces of a token taken from successive words, each starting with the word's first letter.
const _letterPieces = 0; // one letter: initials
const _prefixPieces = 1; // the start of the word
const _gappedPieces = 2; // letters of the word in order

const _never = 1 << 20;
final _memoStamp = Int32List(64 * 64);
final _memoSkips = Int32List(64 * 64);
var _stamp = 0;

/// Fewest words skipped while [t] is made of pieces of successive words (see [_letterPieces]
/// and the others); -1 when it cannot be.
int _chainSkips(String t, _Name n, int pieces) {
  final words = n.words;
  if (t.length > 63 || words > 63) return -1;
  final stamp = ++_stamp;
  final c = n.compact;
  final starts = n.starts;

  int from(int ti, int wi) {
    if (ti == t.length) return 0;
    final key = ti * 64 + wi;
    if (_memoStamp[key] == stamp) return _memoSkips[key];
    var best = _never;
    final first = t.codeUnitAt(ti);
    for (var w = wi; w < words; w++) {
      final skip = w - wi;
      if (skip >= best) break;
      final start = starts[w];
      final end = starts[w + 1];
      if (c.codeUnitAt(start) != first) continue;
      var taken = 1;
      var at = start;
      while (true) {
        final rest = from(ti + taken, w + 1);
        if (skip + rest < best) best = skip + rest;
        if (pieces == _letterPieces || ti + taken == t.length) break;
        final next = t.codeUnitAt(ti + taken);
        if (pieces == _prefixPieces) {
          if (at + 1 >= end || c.codeUnitAt(at + 1) != next) break;
          at++;
        } else {
          var p = at + 1;
          while (p < end && c.codeUnitAt(p) != next) {
            p++;
          }
          if (p >= end) break;
          at = p;
        }
        taken++;
      }
    }
    _memoStamp[key] = stamp;
    _memoSkips[key] = best;
    return best;
  }

  final skips = from(0, 0);
  return skips >= _never ? -1 : skips;
}

final _letterCounts = Int32List(128);

/// An edit loses at most one letter of [t], so with [allowed] edits at most that many of its
/// letters can be missing from [c]. Cheap check before [_editsToPart].
bool _fewMissing(String t, String c, int allowed) {
  for (var j = 0; j < c.length; j++) {
    final u = c.codeUnitAt(j);
    if (u < 128) _letterCounts[u]++;
  }
  var missing = 0;
  for (var i = 0; i < t.length; i++) {
    final u = t.codeUnitAt(i);
    if (u < 128) {
      if (_letterCounts[u] > 0) {
        _letterCounts[u]--;
      } else {
        missing++;
      }
    } else if (!c.contains(t[i])) {
      missing++;
    }
  }
  for (var j = 0; j < c.length; j++) {
    final u = c.codeUnitAt(j);
    if (u < 128) _letterCounts[u] = 0;
  }
  return missing <= allowed;
}

var _rows = List.generate(3, (_) => Int32List(128));

/// Fewest edits (insert, delete, change, swap two neighbours) that turn [t] into some part of
/// [c]; anything above [limit] is returned as limit + 1.
int _editsToPart(String t, String c, int limit) {
  if (!_fewMissing(t, c, limit)) return limit + 1;
  final n = c.length;
  if (_rows[0].length <= n) _rows = List.generate(3, (_) => Int32List(n * 2 + 1));
  var beforePrevious = _rows[0];
  var previous = _rows[1];
  var current = _rows[2];
  for (var j = 0; j <= n; j++) {
    beforePrevious[j] = 0;
    previous[j] = 0;
  }
  for (var i = 1; i <= t.length; i++) {
    final ti = t.codeUnitAt(i - 1);
    final tBefore = i > 1 ? t.codeUnitAt(i - 2) : -1;
    current[0] = i;
    var rowMin = i;
    for (var j = 1; j <= n; j++) {
      final cj = c.codeUnitAt(j - 1);
      var v = previous[j - 1] + (ti == cj ? 0 : 1);
      if (previous[j] + 1 < v) v = previous[j] + 1;
      if (current[j - 1] + 1 < v) v = current[j - 1] + 1;
      if (j > 1 && ti == c.codeUnitAt(j - 2) && tBefore == cj && beforePrevious[j - 2] + 1 < v) {
        v = beforePrevious[j - 2] + 1;
      }
      current[j] = v;
      if (v < rowMin) rowMin = v;
    }
    if (rowMin > limit) return limit + 1;
    final spare = beforePrevious;
    beforePrevious = previous;
    previous = current;
    current = spare;
  }
  var best = limit + 1;
  for (var j = 0; j <= n; j++) {
    if (previous[j] < best) best = previous[j];
  }
  return best;
}

/// Installs `ph_name_score(name_en, name_zh, query, typos)` on an SDE connection: the
/// [NameQuery.score] of the names, 0 when they do not match.
void registerNameSearch(Database db) {
  db.createFunction(
    functionName: 'ph_name_score',
    argumentCount: const AllowedArgumentCount(4),
    deterministic: true,
    function: _sqlScore,
  );
}

Object? _sqlScore(SqliteArguments args) {
  final query = NameQuery.cached(args[2] as String? ?? '');
  // Arguments are decoded on access, so a name the query cannot match is never read.
  return query.score(
    query._latin ? args[0] as String? : null,
    query._chinese ? args[1] as String? : null,
    typos: args[3] == 1,
  );
}

/// The [items] whose names match [query], best first. For lists that are already in memory,
/// such as the charges of a module. An empty query returns [items] as they are.
List<T> rankByName<T>(List<T> items, String query, (String, String?) Function(T item) names) {
  final q = NameQuery(query);
  if (q.isEmpty) return items;
  List<T> rank({required bool typos}) {
    final scored = <(int, int)>[];
    for (var i = 0; i < items.length; i++) {
      final (en, zh) = names(items[i]);
      final s = q.score(en, zh, typos: typos);
      if (s > 0) scored.add((s, i));
    }
    scored.sort((a, b) => a.$1 != b.$1 ? b.$1.compareTo(a.$1) : a.$2.compareTo(b.$2));
    return [for (final (_, i) in scored) items[i]];
  }

  final strict = rank(typos: false);
  return strict.length >= typoFallbackBelow ? strict : rank(typos: true);
}
