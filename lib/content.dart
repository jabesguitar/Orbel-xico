import 'dart:convert';
import 'package:flutter/services.dart';
import 'question.dart';

/// Lista os arquivos .json de uma pasta de assets (sem precisar citar cada nome).
/// Para ampliar o conteúdo, basta soltar um novo .json na pasta.
Future<List<String>> _jsonAssets(String prefix) async {
  final m = await AssetManifest.loadFromAssetBundle(rootBundle);
  final l = m.listAssets().where((p) => p.startsWith(prefix) && p.endsWith('.json')).toList()..sort();
  return l;
}

/// Palavras extras de assets/data/vocab/*.json (mesmo formato de words.json).
Future<List<Map<String, dynamic>>> loadExtraWordMaps() async {
  final out = <Map<String, dynamic>>[];
  for (final p in await _jsonAssets('assets/data/vocab/')) {
    final raw = jsonDecode(await rootBundle.loadString(p));
    if (raw is List) {
      for (final e in raw) {
        out.add(Map<String, dynamic>.from(e as Map));
      }
    }
  }
  return out;
}

Question _fromMap(Map<String, dynamic> m, {required String id, required String cat, required String dica}) => Question(
      id: id,
      categoria: cat,
      texto: m['pergunta'] as String,
      opcoes: List<String>.from(m['opcoes'] as List),
      correta: m['correta'] as int,
      explicacao: (m['explicacao'] as String?) ?? '',
      fonte: (m['fonte'] as String?) ?? '',
      nivel: (m['nivel'] as int?) ?? 2,
      dica: dica,
    );

/// Bíblia: assets/data/biblia/*.json, um arquivo por livro: {"livro": "Gênesis", "perguntas": [...]}.
Future<Map<String, List<Question>>> loadBiblia() async {
  final out = <String, List<Question>>{};
  for (final p in await _jsonAssets('assets/data/biblia/')) {
    final j = jsonDecode(await rootBundle.loadString(p)) as Map<String, dynamic>;
    final livro = j['livro'] as String;
    final list = out.putIfAbsent(livro, () => <Question>[]);
    for (final e in (j['perguntas'] as List)) {
      final m = Map<String, dynamic>.from(e as Map);
      list.add(_fromMap(m, id: 'bib_${livro}_${list.length}', cat: 'biblia', dica: 'Procure em: ${m['fonte'] ?? livro}'));
    }
  }
  return out;
}

/// Conhecimento Geral: assets/data/geral/*.json, {"perguntas": [{"categoria": "...", ...}]}.
/// Devolve as perguntas agrupadas por tema.
Future<Map<String, List<Question>>> loadGeral() async {
  final out = <String, List<Question>>{};
  for (final p in await _jsonAssets('assets/data/geral/')) {
    final j = jsonDecode(await rootBundle.loadString(p)) as Map<String, dynamic>;
    final arq = p.split('/').last;
    final qs = j['perguntas'] as List;
    for (var i = 0; i < qs.length; i++) {
      final m = Map<String, dynamic>.from(qs[i] as Map);
      final tema = (m['categoria'] as String?) ?? 'Geral';
      out.putIfAbsent(tema, () => <Question>[]).add(_fromMap(m, id: 'ger_${arq}_$i', cat: 'geral', dica: 'Tema: $tema.'));
    }
  }
  return out;
}
