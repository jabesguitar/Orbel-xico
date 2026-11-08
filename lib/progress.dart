import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'question.dart';

/// Persistência real: recordes, histórico de partidas e Caderno de Aprendizagem.
class Progress {
  static Future<int> best(String cat) async {
    final p = await SharedPreferences.getInstance();
    return p.getInt('best_$cat') ?? 0;
  }

  /// Salva a partida. Devolve true se for um novo recorde.
  static Future<bool> saveResult(String cat, int score, int hits, int total) async {
    final p = await SharedPreferences.getInstance();
    final record = score > (p.getInt('best_$cat') ?? 0);
    if (record) await p.setInt('best_$cat', score);
    final h = p.getStringList('hist_$cat') ?? [];
    h.add(jsonEncode({'t': DateTime.now().toIso8601String(), 'score': score, 'hits': hits, 'total': total}));
    await p.setStringList('hist_$cat', h.length > 100 ? h.sublist(h.length - 100) : h);
    return record;
  }

  static Future<int> games(String cat) async {
    final p = await SharedPreferences.getInstance();
    return (p.getStringList('hist_$cat') ?? []).length;
  }

  static Future<void> addWrong(Question q) async {
    final p = await SharedPreferences.getInstance();
    final l = p.getStringList('wrong') ?? [];
    final already = l.any((s) => (jsonDecode(s) as Map)['id'] == q.id);
    if (already) return;
    l.add(jsonEncode({
      'id': q.id,
      'cat': q.categoria,
      'texto': q.texto,
      'resp': q.opcoes[q.correta],
      'exp': q.explicacao,
      'fonte': q.fonte,
      'img': q.imagem,
    }));
    await p.setStringList('wrong', l);
  }

  static Future<List<Map<String, dynamic>>> wrongList() async {
    final p = await SharedPreferences.getInstance();
    return (p.getStringList('wrong') ?? []).map((s) => Map<String, dynamic>.from(jsonDecode(s) as Map)).toList();
  }

  static Future<void> removeWrong(String id) async {
    final p = await SharedPreferences.getInstance();
    final l = p.getStringList('wrong') ?? [];
    l.removeWhere((s) => (jsonDecode(s) as Map)['id'] == id);
    await p.setStringList('wrong', l);
  }
}
