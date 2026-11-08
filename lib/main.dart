import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'game.dart';
import 'flags_module.dart';
import 'notebook_page.dart';

const ink = Color(0xFF050E24);
const deep = Color(0xFF0B2A66);
const electric = Color(0xFF1E6BFF);
const gold = Color(0xFFD9B15A);
const muted = Color(0xFF9FB0D6);
const line = Color(0x44D9B15A);

TextStyle serif(double s, {Color? c}) =>
    GoogleFonts.playfairDisplay(fontSize: s, color: c, fontWeight: FontWeight.w600);

final FlutterTts tts = FlutterTts();
Future<void> speak(String t) async {
  await tts.setLanguage('pt-BR');
  await tts.speak(t);
}

class Word {
  final String palavra, classe, significado, uso, fonte;
  final List<String> sinonimos, frases;
  Word.fromJson(Map<String, dynamic> j)
      : palavra = j['palavra'],
        classe = j['classe'],
        significado = j['significado'],
        uso = j['uso'] ?? '',
        fonte = j['fonte'] ?? '',
        sinonimos = List<String>.from(j['sinonimos']),
        frases = List<String>.from(j['frases']);
}

void main() => runApp(const OrbelexicoApp());

class OrbelexicoApp extends StatelessWidget {
  const OrbelexicoApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Orbeléxico',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          brightness: Brightness.dark,
          scaffoldBackgroundColor: ink,
          colorScheme: const ColorScheme.dark(primary: electric, secondary: gold, surface: deep),
          textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
          appBarTheme: const AppBarTheme(backgroundColor: ink, elevation: 0),
          navigationBarTheme: const NavigationBarThemeData(
            backgroundColor: Color(0xFF0A1E4A),
            indicatorColor: Color(0x551E6BFF),
            height: 68,
          ),
        ),
        home: const Shell(),
      );
}

class Shell extends StatefulWidget {
  const Shell({super.key});
  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  List<Word> words = [];
  Set<String> favs = {};
  int tab = 0;
  SharedPreferences? prefs;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final raw = await rootBundle.loadString('assets/data/words.json');
    final list = (jsonDecode(raw) as List).map((e) => Word.fromJson(e as Map<String, dynamic>)).toList();
    prefs = await SharedPreferences.getInstance();
    setState(() {
      words = list;
      favs = (prefs!.getStringList('favs') ?? []).toSet();
    });
  }

  void toggleFav(String w) {
    setState(() => favs.contains(w) ? favs.remove(w) : favs.add(w));
    prefs?.setStringList('favs', favs.toList());
  }

  void openWord(Word w) => Navigator.push(
      context, MaterialPageRoute(builder: (_) => WordPage(word: w, all: words, fav: favs.contains(w.palavra), onFav: () => toggleFav(w.palavra))));

  @override
  Widget build(BuildContext context) {
    if (words.isEmpty) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final pages = [
      HomeTab(words: words, onOpen: openWord, onList: () => Navigator.push(context, MaterialPageRoute(builder: (_) => WordList(words: words, onOpen: openWord)))),
      GamesHome(words: words),
      FavTab(words: words.where((w) => favs.contains(w.palavra)).toList(), onOpen: openWord),
      const MoreTab(),
    ];
    return Scaffold(
      body: SafeArea(bottom: false, child: pages[tab]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: tab,
        onDestinationSelected: (i) => setState(() => tab = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Início'),
          NavigationDestination(icon: Icon(Icons.sports_esports_outlined), selectedIcon: Icon(Icons.sports_esports), label: 'Jogos'),
          NavigationDestination(icon: Icon(Icons.star_border), selectedIcon: Icon(Icons.star), label: 'Favoritos'),
          NavigationDestination(icon: Icon(Icons.menu), label: 'Mais'),
        ],
      ),
    );
  }
}

class Tile extends StatelessWidget {
  final IconData icon;
  final String title, sub;
  final VoidCallback onTap;
  const Tile(this.icon, this.title, this.sub, this.onTap, {super.key});
  @override
  Widget build(BuildContext context) => Material(
        color: Colors.transparent,
        child: Ink(
          decoration: BoxDecoration(
            gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF0F2F6B), Color(0xFF081B45)]),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0x331E6BFF)),
            boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 16, offset: Offset(0, 8))],
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(icon, color: gold, size: 28),
                const SizedBox(height: 8),
                Text(title, style: serif(15)),
                const SizedBox(height: 4),
                Text(sub, style: const TextStyle(fontSize: 12, color: muted)),
              ]),
            ),
          ),
        ),
      );
}

class HomeTab extends StatelessWidget {
  final List<Word> words;
  final void Function(Word) onOpen;
  final VoidCallback onList;
  const HomeTab({super.key, required this.words, required this.onOpen, required this.onList});

  @override
  Widget build(BuildContext context) {
    final w = words[DateTime.now().difference(DateTime(2026, 1, 1)).inDays.abs() % words.length];
    void soon() => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Em breve nas próximas versões.')));
    return ListView(padding: const EdgeInsets.all(18), children: [
      Text('Orbeléxico', style: serif(26, c: gold)),
      const SizedBox(height: 14),
      Text('Olá, Aprendiz!', style: serif(22)),
      const Text('Vamos expandir seu conhecimento hoje?', style: TextStyle(color: muted)),
      const SizedBox(height: 16),
      Material(
        color: Colors.transparent,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: line),
            gradient: const LinearGradient(colors: [Color(0xCC0B2A66), Color(0xAA1A1405)]),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(22),
            onTap: () => onOpen(w),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Palavra do Dia', style: TextStyle(color: gold)),
                const SizedBox(height: 4),
                Text(w.palavra, style: serif(32)),
                Text(w.significado, style: const TextStyle(color: muted)),
                const SizedBox(height: 12),
                const Chip(label: Text('Veja mais →', style: TextStyle(color: Color(0xFF1B1405), fontWeight: FontWeight.w600)), backgroundColor: gold, side: BorderSide.none),
              ]),
            ),
          ),
        ),
      ),
      const SizedBox(height: 14),
      GridView.count(
        crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 1.15,
        children: [
          Tile(Icons.menu_book, 'Vocabulário', '${words.length} palavras', onList),
          Tile(Icons.public, 'Conhecimento Geral', 'Em breve', soon),
          Tile(Icons.flag_outlined, 'Bandeiras', '195 países', () => openFlags(context)),
          Tile(Icons.auto_stories, 'Estudo Bíblico', 'Em breve', soon),
        ],
      ),
    ]);
  }
}

class WordList extends StatelessWidget {
  final List<Word> words;
  final void Function(Word) onOpen;
  const WordList({super.key, required this.words, required this.onOpen});
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text('Vocabulário', style: serif(20))),
        body: ListView(padding: const EdgeInsets.all(14), children: [
          for (final w in words)
            Card(
              color: deep,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: ListTile(
                minVerticalPadding: 12,
                title: Text(w.palavra, style: serif(20)),
                subtitle: Text(w.sinonimos.take(3).join(' · '), style: const TextStyle(color: muted)),
                trailing: IconButton(icon: const Icon(Icons.volume_up, color: electric), onPressed: () => speak(w.palavra)),
                onTap: () => onOpen(w),
              ),
            ),
        ]),
      );
}

Widget sentence(String s, String w) {
  final stem = w.toLowerCase().substring(0, max(4, w.length - 3));
  final i = s.toLowerCase().indexOf(stem);
  if (i < 0) return Text(s, style: const TextStyle(fontSize: 15, height: 1.4));
  var end = i;
  while (end < s.length && RegExp(r'[A-Za-zÀ-ÿ]').hasMatch(s[end])) {
    end++;
  }
  return Text.rich(TextSpan(style: const TextStyle(fontSize: 15, height: 1.4), children: [
    TextSpan(text: s.substring(0, i)),
    TextSpan(text: s.substring(i, end), style: const TextStyle(color: gold, decoration: TextDecoration.underline)),
    TextSpan(text: s.substring(end)),
  ]));
}

class WordPage extends StatefulWidget {
  final Word word;
  final List<Word> all;
  final bool fav;
  final VoidCallback onFav;
  const WordPage({super.key, required this.word, required this.all, required this.fav, required this.onFav});
  @override
  State<WordPage> createState() => _WordPageState();
}

class _WordPageState extends State<WordPage> {
  late bool fav = widget.fav;
  @override
  Widget build(BuildContext context) {
    final w = widget.word;
    return Scaffold(
      appBar: AppBar(title: Text('Vocabulário', style: serif(18)), actions: [
        IconButton(
            icon: Icon(fav ? Icons.star : Icons.star_border, color: gold),
            onPressed: () {
              widget.onFav();
              setState(() => fav = !fav);
            }),
      ]),
      body: ListView(padding: const EdgeInsets.all(20), children: [
        Row(children: [
          Flexible(child: Text(w.palavra, style: serif(42))),
          const SizedBox(width: 12),
          Ink(
            decoration: const BoxDecoration(color: electric, shape: BoxShape.circle),
            child: IconButton(iconSize: 26, icon: const Icon(Icons.volume_up), onPressed: () => speak(w.palavra)),
          ),
        ]),
        Text(w.classe, style: GoogleFonts.playfairDisplay(fontStyle: FontStyle.italic, color: gold, fontSize: 18)),
        const SizedBox(height: 10),
        Text(w.significado, style: const TextStyle(fontSize: 16, height: 1.4)),
        Text('Sinônimos', style: serif(18, c: gold)).withPad(),
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (final s in w.sinonimos)
            Chip(label: Text(s), backgroundColor: deep, side: const BorderSide(color: Color(0x661E6BFF))),
        ]),
        Text('Em frases', style: serif(18, c: gold)).withPad(),
        for (var n = 0; n < w.frases.length; n++)
          Padding(padding: const EdgeInsets.symmetric(vertical: 6), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${n + 1}. '),
            Expanded(child: sentence(w.frases[n], w.palavra)),
          ])),
        const SizedBox(height: 20),
        SizedBox(
          height: 54,
          child: FilledButton.icon(
            icon: const Icon(Icons.play_arrow),
            label: const Text('Praticar Agora', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            style: FilledButton.styleFrom(backgroundColor: electric, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => QuizPage(words: widget.all, only: w))),
          ),
        ),
        const SizedBox(height: 12),
        Text('Fonte: ${w.fonte}', style: const TextStyle(color: muted, fontSize: 11)),
      ]),
    );
  }
}

extension on Widget {
  Widget withPad() => Padding(padding: const EdgeInsets.only(top: 20, bottom: 8), child: this);
}

class QuizPage extends StatefulWidget {
  final List<Word> words;
  final Word? only;
  final bool embedded;
  const QuizPage({super.key, required this.words, this.only, this.embedded = false});
  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
  final rnd = Random();
  late Word w;
  late String correct;
  late List<String> options;
  String? picked;
  int hits = 0, total = 0;

  @override
  void initState() {
    super.initState();
    _next();
  }

  void _next() {
    w = widget.only ?? widget.words[rnd.nextInt(widget.words.length)];
    correct = w.sinonimos[rnd.nextInt(w.sinonimos.length)];
    final pool = widget.words
        .where((x) => x.palavra != w.palavra)
        .expand((x) => x.sinonimos)
        .where((s) => !w.sinonimos.contains(s))
        .toSet()
        .toList()
      ..shuffle(rnd);
    options = [correct, ...pool.take(3)]..shuffle(rnd);
    picked = null;
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: widget.embedded ? null : AppBar(title: Text('Praticar', style: serif(18))),
        body: ListView(padding: const EdgeInsets.all(20), children: [
          if (widget.embedded) Text('Jogos', style: serif(26, c: gold)),
          const SizedBox(height: 12),
          Text('Qual é um sinônimo de', style: const TextStyle(color: muted)),
          Row(children: [
            Flexible(child: Text(w.palavra, style: serif(36))),
            IconButton(icon: const Icon(Icons.volume_up, color: electric), onPressed: () => speak(w.palavra)),
          ]),
          const SizedBox(height: 14),
          for (final o in options)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: SizedBox(
                height: 54,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    backgroundColor: picked == null ? deep : (o == correct ? const Color(0x552E9E5B) : (o == picked ? const Color(0x55C0392B) : deep)),
                    side: BorderSide(color: picked != null && o == correct ? const Color(0xFF2E9E5B) : const Color(0x661E6BFF)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: picked != null
                      ? null
                      : () => setState(() {
                            picked = o;
                            total++;
                            if (o == correct) hits++;
                          }),
                  child: Text(o, style: const TextStyle(fontSize: 16, color: Colors.white)),
                ),
              ),
            ),
          if (picked != null) ...[
            const SizedBox(height: 6),
            Text(picked == correct ? 'Muito bem!' : 'Quase! A resposta era "$correct".', style: const TextStyle(color: gold)),
            const SizedBox(height: 6),
            sentence(w.frases[rnd.nextInt(w.frases.length)], w.palavra),
            const SizedBox(height: 12),
            FilledButton(onPressed: () => setState(_next), child: const Text('Próxima')),
          ],
          const SizedBox(height: 16),
          Text('Acertos: $hits de $total', style: const TextStyle(color: muted)),
        ]),
      );
}

class FavTab extends StatelessWidget {
  final List<Word> words;
  final void Function(Word) onOpen;
  const FavTab({super.key, required this.words, required this.onOpen});
  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(18), children: [
        Text('Favoritos', style: serif(26, c: gold)),
        const SizedBox(height: 12),
        if (words.isEmpty) const Text('Toque na estrela de uma palavra para guardá-la aqui.', style: TextStyle(color: muted)),
        for (final w in words)
          ListTile(title: Text(w.palavra, style: serif(20)), subtitle: Text(w.significado, style: const TextStyle(color: muted)), onTap: () => onOpen(w)),
      ]);
}

class MoreTab extends StatelessWidget {
  const MoreTab({super.key});
  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(18), children: [
        Text('Mais', style: serif(26, c: gold)),
        const SizedBox(height: 12),
        Text('Orbeléxico', style: serif(18)),
        const Text('Aprender. Descobrir. Evoluir.', style: TextStyle(color: muted)),
        const SizedBox(height: 12),
        ListTile(
            leading: const Icon(Icons.auto_stories, color: gold),
            title: const Text('Caderno de Aprendizagem'),
            subtitle: const Text('Revise as perguntas que você errou', style: TextStyle(color: muted)),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotebookPage()))),
        ListTile(
            leading: const Icon(Icons.emoji_events, color: gold),
            title: const Text('Ranking e Recordes'),
            subtitle: const Text('Suas melhores pontuações', style: TextStyle(color: muted)),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RecordsPage()))),
        const SizedBox(height: 12),
        const Text('Próximas versões: Conhecimentos Gerais e Estudo Bíblico. As palavras vêm do arquivo assets/data/words.json, que você pode ampliar sem mexer no código.', style: TextStyle(height: 1.4)),
      ]);
}
