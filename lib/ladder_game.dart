import 'package:flutter/material.dart';
import 'main.dart';
import 'game.dart';
import 'question.dart';
import 'progress.dart';

const stepPoints = [100, 200, 300, 500, 1000, 2000, 3000, 4000, 5000, 10000, 20000, 30000, 50000, 75000, 100000];
const nivelNomes = ['Fácil', 'Intermediário', 'Difícil', 'Especialista'];

/// Escada de até 15 perguntas. Servida por qualquer módulo (pool de perguntas).
class LadderGame extends StatefulWidget {
  final String titulo, categoria;
  final List<Question> pool;
  const LadderGame({super.key, required this.titulo, required this.categoria, required this.pool});
  @override
  State<LadderGame> createState() => _LadderGameState();
}

class _LadderGameState extends State<LadderGame> {
  late final List<Question> steps;
  final used = <String>{};
  final hidden = <int>{};
  int i = 0, score = 0, hits = 0;
  int? picked;
  bool hintOn = false, hintUsed = false, elimUsed = false, skipUsed = false, ended = false;

  @override
  void initState() {
    super.initState();
    steps = buildLadder(widget.pool);
    used.addAll(steps.map((q) => q.id));
    Sfx.startMusic(track: widget.categoria);
  }

  @override
  void dispose() {
    Sfx.stopMusic();
    super.dispose();
  }

  Question get q => steps[i];

  void _reset() {
    picked = null;
    hintOn = false;
    hidden.clear();
  }

  void _answer(int k) {
    final ok = k == q.correta;
    setState(() {
      picked = k;
      if (ok) {
        score += stepPoints[i];
        hits++;
      }
    });
    if (!ok) Progress.addWrong(q);
    Sfx.play(ok ? (hits % 5 == 0 ? 'streak.wav' : 'ok.wav') : 'err.wav');
  }

  void _next() {
    if (picked != q.correta) {
      _finish('Resposta incorreta. Você mantém metade dos pontos.', score ~/ 2);
      return;
    }
    if (i == steps.length - 1) {
      _finish('Você completou toda a escada!', score);
      return;
    }
    Sfx.play('step.wav');
    setState(() {
      i++;
      _reset();
    });
  }

  void _eliminate() {
    Sfx.play('hint.wav');
    final wrong = [for (var k = 0; k < q.opcoes.length; k++) if (k != q.correta) k]..shuffle();
    setState(() {
      elimUsed = true;
      hidden
        ..clear()
        ..addAll(wrong.take(2));
    });
  }

  void _skip() {
    final cands = widget.pool.where((x) => !used.contains(x.id)).toList();
    final same = cands.where((x) => x.nivel == q.nivel).toList();
    final list = same.isNotEmpty ? same : cands;
    if (list.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Não há pergunta reserva disponível.')));
      return;
    }
    list.shuffle();
    Sfx.play('skip.wav');
    final n = list.first;
    setState(() {
      skipUsed = true;
      used.add(n.id);
      steps[i] = n;
      _reset();
    });
  }

  Future<void> _stop() async {
    final ok = await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
              backgroundColor: deep,
              title: Text('Parar e guardar?', style: fun(22)),
              content: Text('Você guarda os $score pontos acumulados.'),
              actions: [
                TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Continuar jogando')),
                FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Parar')),
              ],
            ));
    if (ok == true) _finish('Você parou e guardou a pontuação.', score);
  }

  Future<void> _finish(String msg, int finalScore) async {
    if (ended) return;
    ended = true;
    final record = await Progress.saveResult(widget.categoria, finalScore, hits, steps.length);
    if (!mounted) return;
    Sfx.play(record ? 'record.wav' : (finalScore > 0 ? 'win.wav' : 'lose.wav'));
    await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (c) => AlertDialog(
              backgroundColor: deep,
              title: Text('Resultado', style: fun(24)),
              content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(msg),
                const SizedBox(height: 10),
                Text('Pontuação: $finalScore', style: fun(22, c: gold)),
                Text('Acertos: $hits de ${steps.length}'),
                if (record)
                  const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Row(children: [Icon(Icons.emoji_events, color: gold), SizedBox(width: 6), Text('Novo recorde!', style: TextStyle(color: gold))])),
              ]),
              actions: [FilledButton(onPressed: () => Navigator.pop(c), child: const Text('Voltar ao menu'))],
            ));
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    if (steps.isEmpty) {
      return stage(Column(children: [
        Align(alignment: Alignment.centerLeft, child: IconButton(icon: const Icon(Icons.arrow_back, color: gold), onPressed: () => Navigator.pop(context))),
        const Expanded(child: Center(child: Text('Ainda não há perguntas suficientes neste módulo.'))),
      ]));
    }
    final done = picked != null;
    final lvl = nivelNomes[(q.nivel - 1).clamp(0, 3).toInt()];
    return stage(Column(children: [
      Row(children: [
        IconButton(icon: const Icon(Icons.close, color: gold), onPressed: done ? null : _stop),
        Expanded(child: Text(widget.titulo, style: fun(18, c: gold))),
        Text('$score pts', style: fun(18)),
        IconButton(icon: const Icon(Icons.volume_up_rounded, color: gold), onPressed: () => showVol(context)),
      ]),
      ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(value: i / steps.length, minHeight: 8, color: electric, backgroundColor: deep)),
      Expanded(
          child: ListView(children: [
        const SizedBox(height: 10),
        Text('Pergunta ${i + 1} de ${steps.length} · $lvl · vale ${stepPoints[i]} pts', style: const TextStyle(color: muted)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(color: deep, borderRadius: BorderRadius.circular(22), border: Border.all(color: line)),
          child: Column(children: [
            if (q.imagem != null)
              Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Image.asset(q.imagem!,
                      height: 170, fit: BoxFit.contain, errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, color: muted, size: 48))),
            Row(children: [
              Expanded(child: Text(q.texto, style: fun(21))),
              if (q.falar != null) IconButton(icon: const Icon(Icons.volume_up, color: electric), onPressed: () => speak(q.falar!)),
            ]),
          ]),
        ),
        const SizedBox(height: 12),
        for (var k = 0; k < q.opcoes.length; k++)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Opacity(
              opacity: hidden.contains(k) ? .2 : 1,
              child: SizedBox(
                height: 56,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    backgroundColor: !done ? deep : (k == q.correta ? green.withAlpha(90) : (k == picked ? red.withAlpha(90) : deep)),
                    side: BorderSide(color: done && k == q.correta ? green : const Color(0x661E6BFF), width: 1.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: (done || hidden.contains(k)) ? null : () => _answer(k),
                  child: Text('${String.fromCharCode(65 + k)}  ${q.opcoes[k]}',
                      textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 15, color: Colors.white)),
                ),
              ),
            ),
          ),
        if (hintOn && !done) Text('Dica: ${q.dica}', style: const TextStyle(color: gold, fontSize: 15)),
        if (done)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: const Color(0xFF081B45), borderRadius: BorderRadius.circular(18), border: Border.all(color: picked == q.correta ? green : red)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(picked == q.correta ? 'Correto!' : 'Resposta incorreta', style: fun(20)),
              const SizedBox(height: 6),
              Text('Resposta: ${q.opcoes[q.correta]}', style: const TextStyle(color: gold, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              Text(q.explicacao, style: const TextStyle(height: 1.4)),
              const SizedBox(height: 8),
              Text('Fonte: ${q.fonte}', style: const TextStyle(color: muted, fontSize: 11)),
              const SizedBox(height: 10),
              Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton(onPressed: _next, child: Text(picked == q.correta ? (i == steps.length - 1 ? 'Ver resultado' : 'Continuar') : 'Ver resultado'))),
            ]),
          ),
      ])),
      Row(children: [
        Expanded(child: OutlinedButton(onPressed: (done || hintUsed) ? null : () { Sfx.play('hint.wav'); setState(() { hintOn = true; hintUsed = true; }); }, child: const Text('Dica'))),
        const SizedBox(width: 6),
        Expanded(child: OutlinedButton(onPressed: (done || elimUsed) ? null : _eliminate, child: const Text('Eliminar 2'))),
        const SizedBox(width: 6),
        Expanded(child: OutlinedButton(onPressed: (done || skipUsed) ? null : _skip, child: const Text('Pular'))),
        const SizedBox(width: 6),
        Expanded(child: OutlinedButton(onPressed: done ? null : _stop, child: const Text('Parar'))),
      ]),
    ]));
  }
}
