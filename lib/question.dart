import 'dart:math';

/// Pergunta de múltipla escolha, comum a todos os módulos.
/// nivel: 1 = fácil, 2 = intermediário, 3 = difícil, 4 = especialista.
class Question {
  final String id, categoria, texto, explicacao, fonte, dica;
  final String? imagem; // caminho de asset (ex.: bandeira)
  final String? falar; // texto para o botão de áudio (pronúncia)
  final List<String> opcoes;
  final int correta, nivel;
  const Question({
    required this.id,
    required this.categoria,
    required this.texto,
    required this.opcoes,
    required this.correta,
    required this.explicacao,
    required this.fonte,
    required this.nivel,
    this.dica = '',
    this.imagem,
    this.falar,
  });
}

/// Monta a escada de até 15 perguntas, com dificuldade crescente.
List<Question> buildLadder(List<Question> pool, {Random? rnd}) {
  final r = rnd ?? Random();
  const plan = [1, 1, 1, 1, 1, 2, 2, 2, 2, 3, 3, 3, 4, 4, 4];
  final byLevel = <int, List<Question>>{
    for (var n = 1; n <= 4; n++) n: (pool.where((q) => q.nivel == n).toList()..shuffle(r)),
  };
  final used = <String>{};
  final out = <Question>[];
  for (final n in plan) {
    Question? pick;
    for (final d in const [0, 1, -1, 2, -2, 3, -3]) {
      final lvl = n + d;
      if (lvl < 1 || lvl > 4) continue;
      final free = byLevel[lvl]!.where((q) => !used.contains(q.id));
      if (free.isNotEmpty) {
        pick = free.first;
        break;
      }
    }
    if (pick == null) break;
    used.add(pick.id);
    out.add(pick);
  }
  out.sort((a, b) => a.nivel.compareTo(b.nivel));
  return out;
}
