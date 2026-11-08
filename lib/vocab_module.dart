import 'dart:math';
import 'main.dart';
import 'question.dart';

/// Gera perguntas do Desafio do Vocabulário a partir de assets/data/words.json.
List<Question> vocabQuestions(List<Word> ws) {
  final r = Random();
  final out = <Question>[];
  for (final w in ws) {
    final others = ws.where((x) => x.palavra != w.palavra).toList();
    final nivel = w.uso == 'em desuso' ? 3 : (w.uso == 'formal' ? 2 : 1);
    final frases = w.frases.asMap().entries.map((e) => '${e.key + 1}. ${e.value}').join('\n');
    final expl = '${w.palavra} (${w.classe}): ${w.significado}\nSinônimos: ${w.sinonimos.join(', ')}\n$frases';

    final okSyn = w.sinonimos[r.nextInt(w.sinonimos.length)];
    final synPool = others.expand((x) => x.sinonimos).where((s) => !w.sinonimos.contains(s)).toSet().toList()..shuffle(r);
    if (synPool.length >= 3) {
      final o = [okSyn, ...synPool.take(3)]..shuffle(r);
      out.add(Question(
        id: 'voc_${w.palavra}_sin',
        categoria: 'portugues',
        texto: 'Qual é um sinônimo de “${w.palavra}”?',
        opcoes: o,
        correta: o.indexOf(okSyn),
        explicacao: expl,
        fonte: w.fonte,
        nivel: nivel,
        dica: 'Classe gramatical: ${w.classe}.',
        falar: w.palavra,
      ));
    }
    final sigPool = (others.map((x) => x.significado).toSet().toList()..shuffle(r));
    if (sigPool.length >= 3) {
      final o = [w.significado, ...sigPool.take(3)]..shuffle(r);
      out.add(Question(
        id: 'voc_${w.palavra}_sig',
        categoria: 'portugues',
        texto: 'O que significa “${w.palavra}”?',
        opcoes: o,
        correta: o.indexOf(w.significado),
        explicacao: expl,
        fonte: w.fonte,
        nivel: nivel,
        dica: 'Classe gramatical: ${w.classe}.',
        falar: w.palavra,
      ));
    }
  }
  return out;
}
