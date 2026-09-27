part of 'memos_providers.dart';

enum _FilterTokenType {
  identifier,
  number,
  string,
  andOp,
  orOp,
  eq,
  gte,
  lte,
  inOp,
  lParen,
  rParen,
  lBracket,
  rBracket,
  comma,
  dot,
}

class _FilterToken {
  const _FilterToken(this.type, this.lexeme);

  final _FilterTokenType type;
  final String lexeme;
}

List<_FilterToken> _tokenizeShortcutFilter(String input) {
  final tokens = <_FilterToken>[];
  var i = 0;
  while (i < input.length) {
    final ch = input[i];
    if (ch.trim().isEmpty) {
      i++;
      continue;
    }
    if (input.startsWith('&&', i)) {
      tokens.add(const _FilterToken(_FilterTokenType.andOp, '&&'));
      i += 2;
      continue;
    }
    if (input.startsWith('||', i)) {
      tokens.add(const _FilterToken(_FilterTokenType.orOp, '||'));
      i += 2;
      continue;
    }
    if (input.startsWith('>=', i)) {
      tokens.add(const _FilterToken(_FilterTokenType.gte, '>='));
      i += 2;
      continue;
    }
    if (input.startsWith('<=', i)) {
      tokens.add(const _FilterToken(_FilterTokenType.lte, '<='));
      i += 2;
      continue;
    }
    if (input.startsWith('==', i)) {
      tokens.add(const _FilterToken(_FilterTokenType.eq, '=='));
      i += 2;
      continue;
    }
    switch (ch) {
      case '(':
        tokens.add(const _FilterToken(_FilterTokenType.lParen, '('));
        i++;
        continue;
      case ')':
        tokens.add(const _FilterToken(_FilterTokenType.rParen, ')'));
        i++;
        continue;
      case '[':
        tokens.add(const _FilterToken(_FilterTokenType.lBracket, '['));
        i++;
        continue;
      case ']':
        tokens.add(const _FilterToken(_FilterTokenType.rBracket, ']'));
        i++;
        continue;
      case ',':
        tokens.add(const _FilterToken(_FilterTokenType.comma, ','));
        i++;
        continue;
      case '.':
        tokens.add(const _FilterToken(_FilterTokenType.dot, '.'));
        i++;
        continue;
      case '"':
      case '\'':
        final quote = ch;
        i++;
        final buffer = StringBuffer();
        while (i < input.length) {
          final c = input[i];
          if (c == '\\' && i + 1 < input.length) {
            buffer.write(input[i + 1]);
            i += 2;
            continue;
          }
          if (c == quote) {
            i++;
            break;
          }
          buffer.write(c);
          i++;
        }
        tokens.add(_FilterToken(_FilterTokenType.string, buffer.toString()));
        continue;
    }

    if (_isDigit(ch)) {
      final start = i;
      while (i < input.length && _isDigit(input[i])) {
        i++;
      }
      tokens.add(
        _FilterToken(_FilterTokenType.number, input.substring(start, i)),
      );
      continue;
    }

    if (_isIdentifierStart(ch)) {
      final start = i;
      i++;
      while (i < input.length && _isIdentifierPart(input[i])) {
        i++;
      }
      final text = input.substring(start, i);
      if (text == 'in') {
        tokens.add(const _FilterToken(_FilterTokenType.inOp, 'in'));
      } else {
        tokens.add(_FilterToken(_FilterTokenType.identifier, text));
      }
      continue;
    }

    throw FormatException('Unexpected filter token: $ch');
  }
  return tokens;
}

bool _isDigit(String ch) => ch.codeUnitAt(0) >= 48 && ch.codeUnitAt(0) <= 57;

bool _isIdentifierStart(String ch) {
  final code = ch.codeUnitAt(0);
  return (code >= 65 && code <= 90) || (code >= 97 && code <= 122) || ch == '_';
}

bool _isIdentifierPart(String ch) {
  return _isIdentifierStart(ch) || _isDigit(ch);
}

class _ShortcutFilterParser {
  _ShortcutFilterParser(this._tokens);

  final List<_FilterToken> _tokens;
  var _pos = 0;

  bool get isAtEnd => _pos >= _tokens.length;

  _MemoPredicate? parse() {
    final expr = _parseOr();
    return expr;
  }

  _MemoPredicate? _parseOr() {
    final first = _parseAnd();
    if (first == null) return null;
    var left = first;
    while (_match(_FilterTokenType.orOp)) {
      final right = _parseAnd();
      if (right == null) return null;
      final prev = left;
      left = (memo) => prev(memo) || right(memo);
    }
    return left;
  }

  _MemoPredicate? _parseAnd() {
    final first = _parsePrimary();
    if (first == null) return null;
    var left = first;
    while (_match(_FilterTokenType.andOp)) {
      final right = _parsePrimary();
      if (right == null) return null;
      final prev = left;
      left = (memo) => prev(memo) && right(memo);
    }
    return left;
  }

  _MemoPredicate? _parsePrimary() {
    if (_match(_FilterTokenType.lParen)) {
      final expr = _parseOr();
      if (expr == null || !_match(_FilterTokenType.rParen)) return null;
      return expr;
    }
    return _parseCondition();
  }

  _MemoPredicate? _parseCondition() {
    final ident = _consume(_FilterTokenType.identifier);
    if (ident == null) return null;
    switch (ident.lexeme) {
      case 'tag':
        if (!_match(_FilterTokenType.inOp)) return null;
        final values = _parseStringList();
        if (values == null) return null;
        final expected = values
            .map(_normalizeFilterTag)
            .where((v) => v.isNotEmpty)
            .toSet();
        return (memo) {
          for (final tag in memo.tags) {
            if (expected.contains(_normalizeFilterTag(tag))) return true;
          }
          return false;
        };
      case 'visibility':
        if (_match(_FilterTokenType.eq)) {
          final value = _consumeString();
          if (value == null) return null;
          final target = value.toUpperCase();
          return (memo) => memo.visibility.toUpperCase() == target;
        }
        if (_match(_FilterTokenType.inOp)) {
          final values = _parseStringList();
          if (values == null) return null;
          final set = values.map((v) => v.toUpperCase()).toSet();
          return (memo) => set.contains(memo.visibility.toUpperCase());
        }
        return null;
      case 'created_ts':
      case 'updated_ts':
        final isCreated = ident.lexeme == 'created_ts';
        if (_match(_FilterTokenType.gte)) {
          final value = _consumeNumber();
          if (value == null) return null;
          return (memo) => _timestampForMemo(memo, isCreated) >= value;
        }
        if (_match(_FilterTokenType.lte)) {
          final value = _consumeNumber();
          if (value == null) return null;
          return (memo) => _timestampForMemo(memo, isCreated) <= value;
        }
        return null;
      case 'content':
        if (!_match(_FilterTokenType.dot)) return null;
        final method = _consume(_FilterTokenType.identifier);
        if (method == null || method.lexeme != 'contains') return null;
        if (!_match(_FilterTokenType.lParen)) return null;
        final value = _consumeString();
        if (value == null || !_match(_FilterTokenType.rParen)) return null;
        return (memo) => memo.content.contains(value);
      case 'pinned':
        if (!_match(_FilterTokenType.eq)) return null;
        final boolValue = _consumeBool();
        if (boolValue == null) return null;
        return (memo) => memo.pinned == boolValue;
      case 'creator_id':
        if (!_match(_FilterTokenType.eq)) return null;
        final value = _consumeNumber();
        if (value == null) return null;
        return (_) => true;
      default:
        return null;
    }
  }

  List<String>? _parseStringList() {
    if (!_match(_FilterTokenType.lBracket)) return null;
    final values = <String>[];
    if (_check(_FilterTokenType.rBracket)) {
      _advance();
      return values;
    }
    while (!isAtEnd) {
      final value = _consumeString();
      if (value == null) return null;
      values.add(value);
      if (_match(_FilterTokenType.comma)) continue;
      if (_match(_FilterTokenType.rBracket)) break;
      return null;
    }
    return values;
  }

  String? _consumeString() {
    final token = _consume(_FilterTokenType.string);
    return token?.lexeme;
  }

  int? _consumeNumber() {
    final token = _consume(_FilterTokenType.number);
    if (token == null) return null;
    return int.tryParse(token.lexeme);
  }

  bool? _consumeBool() {
    if (_match(_FilterTokenType.identifier)) {
      final text = _previous().lexeme.toLowerCase();
      if (text == 'true') return true;
      if (text == 'false') return false;
    }
    if (_match(_FilterTokenType.number)) {
      return _previous().lexeme != '0';
    }
    return null;
  }

  bool _match(_FilterTokenType type) {
    if (_check(type)) {
      _advance();
      return true;
    }
    return false;
  }

  bool _check(_FilterTokenType type) {
    if (isAtEnd) return false;
    return _tokens[_pos].type == type;
  }

  _FilterToken _advance() {
    return _tokens[_pos++];
  }

  _FilterToken? _consume(_FilterTokenType type) {
    if (_check(type)) return _advance();
    return null;
  }

  _FilterToken _previous() => _tokens[_pos - 1];
}

int _timestampForMemo(LocalMemo memo, bool created) {
  final dt = created ? memo.createTime : memo.updateTime;
  return dt.toUtc().millisecondsSinceEpoch ~/ 1000;
}

String _normalizeFilterTag(String raw) {
  return _normalizeTagInput(raw);
}

String _normalizeShortcutFilterForLocal(String raw) {
  final nowSec = DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000;
  return raw.replaceAllMapped(
    RegExp(r'(created_ts|updated_ts)\s*>=\s*now\(\)\s*-\s*(\d+)'),
    (match) {
      final field = match.group(1) ?? '';
      final seconds = int.tryParse(match.group(2) ?? '');
      if (field.isEmpty || seconds == null) return match.group(0) ?? '';
      final start = nowSec - seconds;
      return '$field >= $start';
    },
  );
}
