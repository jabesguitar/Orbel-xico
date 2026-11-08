import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'ladder_game.dart';
import 'question.dart';

// Faixas de dificuldade (escolha editorial: países mais conhecidos -> menos conhecidos).
const _n1 = ['BR', 'US', 'FR', 'DE', 'IT', 'ES', 'PT', 'AR', 'JP', 'CN', 'GB', 'CA', 'MX', 'IN', 'RU', 'AU', 'CH', 'SE', 'NO', 'EG', 'ZA', 'KR', 'CL', 'CO', 'UY'];
const _n2 = ['NL', 'BE', 'AT', 'GR', 'TR', 'PL', 'UA', 'IE', 'DK', 'FI', 'PE', 'VE', 'EC', 'BO', 'PY', 'CU', 'NZ', 'SA', 'IL', 'IR', 'IQ', 'TH', 'VN', 'ID', 'PH', 'NG', 'MA', 'DZ', 'KE', 'CZ', 'HU', 'RO', 'HR', 'RS', 'JM', 'PA', 'CR', 'DO', 'HT'];
const _n4 = ['NR', 'TV', 'PW', 'MH', 'FM', 'KI', 'SB', 'VU', 'WS', 'TO', 'BT', 'NP', 'KM', 'ST', 'SC', 'MV', 'MC', 'LI', 'SM', 'VA', 'AD', 'BN', 'TL', 'SZ', 'LS', 'KN', 'LC', 'VC', 'GD', 'AG', 'DM', 'ER', 'DJ', 'SS', 'TM', 'KG', 'TJ', 'UZ', 'MM', 'LA', 'KH', 'GQ', 'CF', 'CD', 'CG'];

int _nivel(String iso) {
  final u = iso.toUpperCase();
  if (_n1.contains(u)) return 1;
  if (_n2.contains(u)) return 2;
  if (_n4.contains(u)) return 4;
  return 3;
}

Future<List<Question>> loadFlagQuestions() async {
  final raw = await rootBundle.loadString('assets/data/flags_index.csv');
  final rows = <List<String>>[];
  for (final l in raw.replaceAll('\uFEFF', '').split(RegExp(r'\r?\n')).skip(1)) {
    if (l.trim().isEmpty) continue;
    final p = l.split(';');
    if (p.length >= 2) rows.add([p[0].trim().toLowerCase(), p[1].trim()]);
  }
  final r = Random();
  final out = <Question>[];
  for (final c in rows) {
    final nv = _nivel(c[0]);
    final others = rows.where((x) => x[0] != c[0]).toList();
    final same = others.where((x) => _nivel(x[0]) == nv).toList()..shuffle(r);
    final rest = others.where((x) => _nivel(x[0]) != nv).toList()..shuffle(r);
    final bad = [...same, ...rest].take(3).map((x) => x[1]).toList();
    final opts = [c[1], ...bad]..shuffle(r);
    out.add(Question(
      id: 'flag_${c[0]}',
      categoria: 'bandeiras',
      texto: 'De qual país é esta bandeira?',
      imagem: 'assets/flags/${c[0]}.png',
      opcoes: opts,
      correta: opts.indexOf(c[1]),
      explicacao: 'Esta é a bandeira de ${c[1]} (código ISO ${c[0].toUpperCase()}).',
      fonte: 'Atlas Mundial de Bandeiras (ISO 3166-1 alfa-2) — conferir antes de publicar',
      dica: 'O nome começa com “${c[1][0]}” e tem ${c[1].length} letras.',
      nivel: nv,
    ));
  }
  return out;
}

Future<void> openFlags(BuildContext context) async {
  final qs = await loadFlagQuestions();
  if (!context.mounted) return;
  await Navigator.push(context, MaterialPageRoute(builder: (_) => LadderGame(titulo: 'Bandeiras do Mundo', categoria: 'bandeiras', pool: qs)));
}
