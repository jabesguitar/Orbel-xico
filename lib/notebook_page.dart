import 'package:flutter/material.dart';
import 'main.dart';
import 'game.dart';
import 'progress.dart';

const _catNomes = {'portugues': 'Português', 'bandeiras': 'Bandeiras do Mundo'};

class NotebookPage extends StatefulWidget {
  const NotebookPage({super.key});
  @override
  State<NotebookPage> createState() => _NotebookPageState();
}

class _NotebookPageState extends State<NotebookPage> {
  late Future<List<Map<String, dynamic>>> f = Progress.wrongList();
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text('Caderno de Aprendizagem', style: serif(18))),
        body: FutureBuilder<List<Map<String, dynamic>>>(
          future: f,
          builder: (c, s) {
            final l = s.data ?? [];
            if (!s.hasData) return const Center(child: CircularProgressIndicator());
            if (l.isEmpty) return const Padding(padding: EdgeInsets.all(20), child: Text('Nenhuma pergunta errada ainda. Quando você errar, ela aparece aqui para revisão.', style: TextStyle(color: muted)));
            return ListView(padding: const EdgeInsets.all(14), children: [
              for (final w in l)
                Card(
                  color: deep,
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(_catNomes[w['cat']] ?? '${w['cat']}', style: const TextStyle(color: gold, fontSize: 12)),
                      const SizedBox(height: 4),
                      if (w['img'] != null) Image.asset(w['img'] as String, height: 90, errorBuilder: (_, __, ___) => const SizedBox()),
                      Text('${w['texto']}', style: const TextStyle(fontSize: 16)),
                      const SizedBox(height: 6),
                      Text('Resposta: ${w['resp']}', style: const TextStyle(color: green, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Text('${w['exp']}', style: const TextStyle(height: 1.4)),
                      Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                              onPressed: () async {
                                await Progress.removeWrong('${w['id']}');
                                setState(() => f = Progress.wrongList());
                              },
                              child: const Text('Já aprendi'))),
                    ]),
                  ),
                ),
            ]);
          },
        ),
      );
}

class RecordsPage extends StatelessWidget {
  const RecordsPage({super.key});
  Future<List<List<Object>>> _load() async => [
        for (final k in _catNomes.keys) [_catNomes[k]!, await Progress.best(k), await Progress.games(k)],
      ];
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text('Ranking e Recordes', style: serif(18))),
        body: FutureBuilder<List<List<Object>>>(
          future: _load(),
          builder: (c, s) {
            if (!s.hasData) return const Center(child: CircularProgressIndicator());
            return ListView(padding: const EdgeInsets.all(14), children: [
              for (final r in s.data!)
                Card(
                    color: deep,
                    child: ListTile(
                      leading: const Icon(Icons.emoji_events, color: gold),
                      title: Text('${r[0]}', style: serif(18)),
                      subtitle: Text('Melhor pontuação: ${r[1]} · Partidas: ${r[2]}', style: const TextStyle(color: muted)),
                    )),
            ]);
          },
        ),
      );
}
