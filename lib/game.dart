import 'dart:async';
import 'dart:math';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'main.dart';

TextStyle fun(double s, {Color? c}) => GoogleFonts.fredoka(fontSize: s, color: c, fontWeight: FontWeight.w600);
const green = Color(0xFF2ECC71), red = Color(0xFFE74C3C);

class Lvl {
  final String nome;
  final int secs, lives;
  final Color cor;
  final IconData icon;
  const Lvl(this.nome, this.secs, this.lives, this.cor, this.icon);
  String get tempo => '${secs ~/ 60}:${(secs % 60).toString().padLeft(2, '0')}';
}

const lvls = [
  Lvl('Fácil', 90, 3, green, Icons.eco),
  Lvl('Normal', 60, 4, Color(0xFFF5A623), Icons.local_fire_department),
  Lvl('Difícil', 30, 5, red, Icons.bolt),
];

class Sfx {
  static final bg = AudioPlayer(), fx = AudioPlayer();
  static double vol = .5;
  static Future<void> startMusic() async {
    try {
      await bg.setReleaseMode(ReleaseMode.loop);
      await bg.setVolume(vol);
      await bg.play(AssetSource('audio/music${Random().nextInt(3) + 1}.wav'));
    } catch (_) {}
  }
  static Future<void> stopMusic() async {
    try { await bg.stop(); } catch (_) {}
  }
  static void setVol(double v) { vol = v; bg.setVolume(v); }
  static Future<void> play(String f) async {
    try { await fx.setVolume(min(1.0, vol + .3)); await fx.play(AssetSource('audio/$f')); } catch (_) {}
  }
}

void showVol(BuildContext c) => showModalBottomSheet(
    context: c,
    backgroundColor: deep,
    builder: (_) => StatefulBuilder(
        builder: (ctx, set) => Padding(
            padding: const EdgeInsets.all(24),
            child: Row(children: [
              Icon(Sfx.vol == 0 ? Icons.volume_off : Icons.volume_up, color: gold),
              Expanded(child: Slider(value: Sfx.vol, onChanged: (v) { Sfx.setVol(v); set(() {}); })),
              Text('${(Sfx.vol * 100).round()}%'),
            ]))));

Future<void> markErr(String w) async {
  final p = await SharedPreferences.getInstance();
  final l = p.getStringList('errors') ?? [];
  if (!l.contains(w)) { l.add(w); await p.setStringList('errors', l); }
}

Future<void> endGame(BuildContext c, bool win, String msg) async {
  await showDialog(
      context: c,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
            backgroundColor: deep,
            title: Text(win ? 'Parabéns! 🎉' : 'Fim de jogo 💔', style: fun(24)),
            content: Text(msg),
            actions: [FilledButton(onPressed: () => Navigator.pop(ctx), child: const Text('Voltar ao início'))],
          ));
  if (c.mounted) Navigator.pop(c);
}

mixin Clock<T extends StatefulWidget> on State<T> {
  Timer? clock;
  int left = 0;
  void startClock(int s, VoidCallback onEnd) {
    left = s;
    clock?.cancel();
    clock = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (left <= 1) { clock?.cancel(); setState(() => left = 0); onEnd(); } else { setState(() => left--); }
    });
  }
  @override
  void dispose() { clock?.cancel(); super.dispose(); }
}

class Hud extends StatelessWidget {
  final int lives, maxLives, left, secs;
  final Color cor;
  const Hud(this.lives, this.maxLives, this.left, this.secs, this.cor, {super.key});
  @override
  Widget build(BuildContext c) => Column(children: [
        Row(children: [
          IconButton(icon: const Icon(Icons.home_rounded, color: gold), onPressed: () => Navigator.pop(c)),
          for (var i = 0; i < maxLives; i++) Icon(i < lives ? Icons.favorite : Icons.favorite_border, color: const Color(0xFFFF5470), size: 22),
          const Spacer(),
          const Icon(Icons.timer_outlined, color: muted, size: 20),
          const SizedBox(width: 4),
          Text('${left ~/ 60}:${(left % 60).toString().padLeft(2, '0')}', style: fun(20)),
          IconButton(icon: const Icon(Icons.volume_up_rounded, color: gold), onPressed: () => showVol(c)),
        ]),
        ClipRRect(borderRadius: BorderRadius.circular(8), child: LinearProgressIndicator(value: secs == 0 ? 0 : left / secs, minHeight: 8, color: cor, backgroundColor: deep)),
      ]);
}

Widget stage(Widget child) => Scaffold(
    body: Container(
        decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF0E2F70), ink])),
        child: SafeArea(child: Padding(padding: const EdgeInsets.fromLTRB(16, 8, 16, 12), child: child))));

class GamesHome extends StatefulWidget {
  final List<Word> words;
  const GamesHome({super.key, required this.words});
  @override
  State<GamesHome> createState() => _GamesHomeState();
}

class _GamesHomeState extends State<GamesHome> {
  int li = 0;
  Future<void> _go(Widget w) async {
    await Sfx.startMusic();
    if (!mounted) return;
    await Navigator.push(context, MaterialPageRoute(builder: (_) => w));
    await Sfx.stopMusic();
  }
  @override
  Widget build(BuildContext context) {
    final l = lvls[li];
    return ListView(padding: const EdgeInsets.all(18), children: [
      Text('Jogos', style: fun(30, c: gold)),
      const Text('Escolha o nível e divirta-se aprendendo!', style: TextStyle(color: muted)),
      const SizedBox(height: 14),
      Row(children: [
        for (var i = 0; i < 3; i++)
          Expanded(
              child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Material(
              color: Colors.transparent,
              child: Ink(
                decoration: BoxDecoration(
                    color: li == i ? lvls[i].cor.withAlpha(60) : deep,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: li == i ? lvls[i].cor : const Color(0x331E6BFF), width: li == i ? 2.5 : 1)),
                child: InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: () => setState(() => li = i),
                  child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      child: Column(children: [
                        Icon(lvls[i].icon, color: lvls[i].cor, size: 30),
                        Text(lvls[i].nome, style: fun(16)),
                        Text('${lvls[i].tempo} · ${lvls[i].lives} ❤', style: const TextStyle(fontSize: 12, color: muted)),
                      ])),
                ),
              ),
            ),
          )),
      ]),
      const SizedBox(height: 16),
      Material(
        color: Colors.transparent,
        child: Ink(
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(22), gradient: LinearGradient(colors: [l.cor.withAlpha(200), electric])),
          child: InkWell(
            borderRadius: BorderRadius.circular(22),
            onTap: () => _go(QuizGame(words: widget.words, lvl: l)),
            child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(children: [
                  const Icon(Icons.quiz_rounded, size: 44),
                  const SizedBox(width: 14),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('QUIZ', style: fun(26)),
                    const Text('Sinônimos, significados, lacunas e verdadeiro ou falso. Todas as perguntas, em ordem aleatória.', style: TextStyle(fontSize: 13)),
                  ])),
                  const Icon(Icons.play_circle_fill, size: 36),
                ])),
          ),
        ),
      ),
      const SizedBox(height: 12),
      GridView.count(
        crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 1.3,
        children: [
          Tile(Icons.grid_view_rounded, 'Memória', 'Palavra + sinônimo', () => _go(MemoryGame(words: widget.words, lvl: l))),
          Tile(Icons.compare_arrows_rounded, 'Ligue as colunas', 'Relacione as palavras', () => _go(MatchGame(words: widget.words, lvl: l))),
          Tile(Icons.menu_book_rounded, 'Resumo', 'Para estudar e rever', () => Navigator.push(context, MaterialPageRoute(builder: (_) => StudyPage(words: widget.words)))),
        ],
      ),
    ]);
  }
}

class Q {
  final String text, info, hint;
  final List<String> opts;
  final int ans;
  final String word;
  final bool say;
  Q(this.text, this.opts, this.ans, this.info, this.hint, this.word, this.say);
}

List<Q> buildQs(List<Word> ws) {
  final r = Random();
  final qs = <Q>[];
  Q mc(String t, String ok, List<String> bad, Word w, String hint, bool say) {
    final o = [ok, ...bad]..shuffle(r);
    final info = '${w.palavra} (${w.classe}): ${w.significado}\nEx.: ${w.frases.first}${w.uso == 'em desuso' ? '\nPalavra hoje pouco usada.' : ''}';
    return Q(t, o, o.indexOf(ok), info, hint, w.palavra, say);
  }
  for (final w in ws) {
    final others = ws.where((x) => x.palavra != w.palavra).toList();
    final ok = w.sinonimos[r.nextInt(w.sinonimos.length)];
    final pool = others.expand((x) => x.sinonimos).where((s) => !w.sinonimos.contains(s)).toSet().toList()..shuffle(r);
    qs.add(mc('Qual é um sinônimo de “${w.palavra}”?', ok, pool.take(3).toList(), w, 'Começa com “${ok[0]}” e tem ${ok.length} letras.', true));
    final sigs = (others.map((x) => x.significado).toList()..shuffle(r)).take(3).toList();
    qs.add(mc('O que significa “${w.palavra}”?', w.significado, sigs, w, 'É um(a) ${w.classe}.', true));
    final t = r.nextBool();
    final shown = t ? w.significado : others[r.nextInt(others.length)].significado;
    final vf = mc('Verdadeiro ou falso? “${w.palavra}” significa: $shown', 'Verdadeiro', ['Falso'], w, 'Classe da palavra: ${w.classe}.', true);
    qs.add(Q(vf.text, ['Verdadeiro', 'Falso'], t ? 0 : 1, vf.info, vf.hint, w.palavra, true));
    final f = w.frases.firstWhere((x) => x.toLowerCase().contains(w.palavra.toLowerCase()), orElse: () => '');
    if (f.isNotEmpty) {
      final i = f.toLowerCase().indexOf(w.palavra.toLowerCase());
      final names = (others.map((x) => x.palavra).toList()..shuffle(r)).take(3).toList();
      qs.add(mc('Complete: ${f.replaceRange(i, i + w.palavra.length, '_____')}', w.palavra, names, w, 'Significa: ${w.significado}', false));
    }
  }
  return qs..shuffle(r);
}

class QuizGame extends StatefulWidget {
  final List<Word> words;
  final Lvl lvl;
  const QuizGame({super.key, required this.words, required this.lvl});
  @override
  State<QuizGame> createState() => _QuizGameState();
}

class _QuizGameState extends State<QuizGame> with Clock {
  late List<Q> queue;
  late int lives, total;
  int score = 0, fb = 0;
  int? picked;
  bool hint = false;
  Timer? ft;

  @override
  void initState() {
    super.initState();
    queue = buildQs(widget.words);
    total = queue.length;
    lives = widget.lvl.lives;
    _round();
  }
  void _round() { picked = null; hint = false; startClock(widget.lvl.secs, () => _answer(-1)); }
  void _answer(int i) {
    clock?.cancel();
    final q = queue.first;
    final ok = i == q.ans;
    setState(() { picked = i; fb = 6; if (ok) { score++; } else { lives--; } });
    if (!ok) markErr(q.word);
    Sfx.play(ok ? 'ok.wav' : 'err.wav');
    ft?.cancel();
    ft = Timer.periodic(const Duration(seconds: 1), (_) { if (fb <= 1) { _next(); } else { setState(() => fb--); } });
  }
  void _next() {
    ft?.cancel();
    queue.removeAt(0);
    if (lives <= 0) { endGame(context, false, 'Você acertou $score de $total. Tente de novo!'); return; }
    if (queue.isEmpty) { endGame(context, true, 'Você acertou $score de $total perguntas!'); return; }
    setState(_round);
  }
  void _skip() { clock?.cancel(); setState(() { queue.add(queue.removeAt(0)); _round(); }); }
  @override
  void dispose() { ft?.cancel(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final q = queue.first;
    final done = picked != null;
    return stage(Column(children: [
      Hud(lives, widget.lvl.lives, left, widget.lvl.secs, widget.lvl.cor),
      Expanded(child: ListView(children: [
        const SizedBox(height: 10),
        Text('Restam ${queue.length} · Acertos $score', style: const TextStyle(color: muted)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(color: deep, borderRadius: BorderRadius.circular(22), border: Border.all(color: line)),
          child: Row(children: [
            Expanded(child: Text(q.text, style: fun(22))),
            if (q.say) IconButton(icon: const Icon(Icons.volume_up, color: electric), onPressed: () => speak(q.word)),
          ]),
        ),
        const SizedBox(height: 12),
        for (var i = 0; i < q.opts.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: SizedBox(
              height: 56,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  backgroundColor: !done ? deep : (i == q.ans ? green.withAlpha(90) : (i == picked ? red.withAlpha(90) : deep)),
                  side: BorderSide(color: done && i == q.ans ? green : const Color(0x661E6BFF), width: 1.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: done ? null : () => _answer(i),
                child: Text(q.opts[i], textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 15, color: Colors.white)),
              ),
            ),
          ),
        if (hint && !done) Text('💡 ${q.hint}', style: const TextStyle(color: gold, fontSize: 15)),
        if (done)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: const Color(0xFF081B45), borderRadius: BorderRadius.circular(18), border: Border.all(color: picked == q.ans ? green : red)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(picked == q.ans ? '✅ Muito bem!' : (picked == -1 ? '⏰ Tempo esgotado!' : '❌ Quase!'), style: fun(20)),
              const SizedBox(height: 6),
              Text(q.info, style: const TextStyle(height: 1.4)),
              const SizedBox(height: 10),
              Row(children: [
                Text('Próxima em ${fb}s', style: const TextStyle(color: muted)),
                const Spacer(),
                FilledButton(onPressed: _next, child: const Text('Continuar')),
              ]),
            ]),
          ),
      ])),
      Row(children: [
        Expanded(child: OutlinedButton.icon(onPressed: done ? null : () => setState(() => hint = true), icon: const Icon(Icons.lightbulb_outline), label: const Text('Dica'))),
        const SizedBox(width: 10),
        Expanded(child: OutlinedButton.icon(onPressed: done ? null : _skip, icon: const Icon(Icons.skip_next), label: const Text('Pular'))),
      ]),
    ]));
  }
}

class _C { final String t; final int id; _C(this.t, this.id); }

class MemoryGame extends StatefulWidget {
  final List<Word> words;
  final Lvl lvl;
  const MemoryGame({super.key, required this.words, required this.lvl});
  @override
  State<MemoryGame> createState() => _MemoryGameState();
}

class _MemoryGameState extends State<MemoryGame> with Clock {
  late List<_C> cards;
  late int lives;
  List<int> flipped = [];
  final matched = <int>{};
  bool busy = false;

  @override
  void initState() {
    super.initState();
    final ws = ([...widget.words]..shuffle()).take(6).toList();
    cards = [for (var i = 0; i < ws.length; i++) ...[_C(ws[i].palavra, i), _C(ws[i].sinonimos.first, i)]]..shuffle();
    lives = widget.lvl.lives;
    startClock(widget.lvl.secs, () => endGame(context, false, 'O tempo acabou!'));
  }
  void _tap(int i) {
    if (busy || matched.contains(i) || flipped.contains(i)) return;
    setState(() => flipped.add(i));
    if (flipped.length < 2) return;
    if (cards[flipped[0]].id == cards[flipped[1]].id) {
      Sfx.play('ok.wav');
      setState(() { matched.addAll(flipped); flipped = []; });
      if (matched.length == cards.length) { clock?.cancel(); endGame(context, true, 'Todos os pares encontrados!'); }
    } else {
      Sfx.play('err.wav');
      busy = true;
      setState(() => lives--);
      Future.delayed(const Duration(milliseconds: 900), () {
        if (!mounted) return;
        setState(() { flipped = []; busy = false; });
        if (lives <= 0) { clock?.cancel(); endGame(context, false, 'As vidas acabaram.'); }
      });
    }
  }
  @override
  Widget build(BuildContext context) => stage(Column(children: [
        Hud(lives, widget.lvl.lives, left, widget.lvl.secs, widget.lvl.cor),
        const SizedBox(height: 10),
        Text('Encontre cada palavra e o seu sinônimo', style: fun(16, c: gold)),
        const SizedBox(height: 10),
        Expanded(child: GridView.count(
          crossAxisCount: 3, mainAxisSpacing: 8, crossAxisSpacing: 8, childAspectRatio: .95,
          children: [
            for (var i = 0; i < cards.length; i++)
              InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => _tap(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  alignment: Alignment.center,
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                      color: matched.contains(i) ? green.withAlpha(90) : (flipped.contains(i) ? electric : deep),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: gold.withAlpha(120))),
                  child: matched.contains(i) || flipped.contains(i)
                      ? Text(cards[i].t, textAlign: TextAlign.center, style: fun(15))
                      : const Icon(Icons.public, color: gold, size: 32),
                ),
              ),
          ],
        )),
      ]));
}

class MatchGame extends StatefulWidget {
  final List<Word> words;
  final Lvl lvl;
  const MatchGame({super.key, required this.words, required this.lvl});
  @override
  State<MatchGame> createState() => _MatchGameState();
}

class _MatchGameState extends State<MatchGame> with Clock {
  late List<Word> ws;
  late List<int> order;
  late int lives;
  int? sel;
  final done = <int>{};

  @override
  void initState() {
    super.initState();
    ws = ([...widget.words]..shuffle()).take(5).toList();
    order = List.generate(ws.length, (i) => i)..shuffle();
    lives = widget.lvl.lives;
    startClock(widget.lvl.secs, () => endGame(context, false, 'O tempo acabou!'));
  }
  void _right(int j) {
    if (sel == null || done.contains(order[j])) return;
    if (order[j] == sel) {
      Sfx.play('ok.wav');
      setState(() { done.add(sel!); sel = null; });
      if (done.length == ws.length) { clock?.cancel(); endGame(context, true, 'Todas as colunas ligadas!'); }
    } else {
      Sfx.play('err.wav');
      setState(() { lives--; sel = null; });
      if (lives <= 0) { clock?.cancel(); endGame(context, false, 'As vidas acabaram.'); }
    }
  }
  Widget _box(String t, Color c, VoidCallback? f) => Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: SizedBox(height: 56, width: double.infinity, child: FilledButton(
          style: FilledButton.styleFrom(backgroundColor: c, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
          onPressed: f, child: Text(t, textAlign: TextAlign.center, style: fun(15)))));
  @override
  Widget build(BuildContext context) => stage(Column(children: [
        Hud(lives, widget.lvl.lives, left, widget.lvl.secs, widget.lvl.cor),
        const SizedBox(height: 10),
        Text('Toque na palavra e depois no sinônimo', style: fun(16, c: gold)),
        const SizedBox(height: 12),
        Expanded(child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: Column(children: [
            for (var i = 0; i < ws.length; i++) _box(ws[i].palavra, done.contains(i) ? green : (sel == i ? gold.withAlpha(230) : deep), done.contains(i) ? null : () => setState(() => sel = i)),
          ])),
          const SizedBox(width: 10),
          Expanded(child: Column(children: [
            for (var j = 0; j < order.length; j++) _box(ws[order[j]].sinonimos.first, done.contains(order[j]) ? green : electric, done.contains(order[j]) ? null : () => _right(j)),
          ])),
        ])),
      ]));
}

class StudyPage extends StatelessWidget {
  final List<Word> words;
  const StudyPage({super.key, required this.words});
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text('Resumo para estudar', style: fun(20))),
        body: FutureBuilder<SharedPreferences>(
          future: SharedPreferences.getInstance(),
          builder: (c, s) {
            final errs = s.data?.getStringList('errors') ?? [];
            return ListView(padding: const EdgeInsets.all(16), children: [
              if (errs.isNotEmpty) ...[
                Text('Para rever (você errou)', style: fun(18, c: gold)),
                Wrap(spacing: 8, children: [for (final e in errs) Chip(label: Text(e), backgroundColor: red.withAlpha(90))]),
                const SizedBox(height: 14),
              ],
              for (final w in words)
                Card(
                  color: deep,
                  child: ExpansionTile(
                    title: Text(w.palavra, style: serif(20)),
                    subtitle: Text('${w.classe} · ${w.significado}', style: const TextStyle(color: muted, fontSize: 12)),
                    trailing: IconButton(icon: const Icon(Icons.volume_up, color: electric), onPressed: () => speak(w.palavra)),
                    childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                    expandedCrossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Sinônimos: ${w.sinonimos.join(', ')}', style: const TextStyle(color: gold)),
                      const SizedBox(height: 6),
                      for (final f in w.frases) Padding(padding: const EdgeInsets.symmetric(vertical: 3), child: sentence(f, w.palavra)),
                    ],
                  ),
                ),
            ]);
          },
        ),
      );
}
