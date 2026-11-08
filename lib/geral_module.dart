import 'package:flutter/material.dart';
import 'content.dart';
import 'ladder_game.dart';
import 'main.dart';
import 'question.dart';

/// Conhecimento Geral: Brasil e mundo, só fatos verificáveis. Quiz por tema ou geral.
class GeralPage extends StatefulWidget {
  const GeralPage({super.key});
  @override
  State<GeralPage> createState() => _GeralPageState();
}

class _GeralPageState extends State<GeralPage> {
  Map<String, List<Question>> temas = {};
  bool ready = false;

  @override
  void initState() {
    super.initState();
    loadGeral().then((d) {
      if (!mounted) return;
      setState(() {
        temas = d;
        ready = true;
      });
    });
  }

  void _play(String titulo, List<Question> pool) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => LadderGame(titulo: titulo, categoria: 'geral', pool: pool)));

  @override
  Widget build(BuildContext context) {
    final todas = temas.values.expand((e) => e).toList();
    final nomes = temas.keys.toList()..sort();
    return Scaffold(
      appBar: AppBar(title: Text('Conhecimento Geral', style: serif(20))),
      body: !ready
          ? const Center(child: CircularProgressIndicator())
          : ListView(padding: const EdgeInsets.all(14), children: [
              Card(
                color: deep,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18), side: const BorderSide(color: line)),
                child: ListTile(
                  leading: const Icon(Icons.public, color: gold, size: 32),
                  title: Text('Quiz geral', style: serif(18)),
                  subtitle: Text('${todas.length} perguntas, Brasil e mundo', style: const TextStyle(color: muted)),
                  trailing: const Icon(Icons.play_circle_fill, color: electric, size: 32),
                  onTap: () => _play('Conhecimento Geral', todas),
                ),
              ),
              Padding(padding: const EdgeInsets.only(top: 18, bottom: 6), child: Text('Por tema', style: serif(22, c: gold))),
              for (final n in nomes)
                Card(
                  color: deep,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: ListTile(
                    title: Text(n, style: serif(17)),
                    subtitle: Text('${temas[n]!.length} perguntas', style: const TextStyle(color: muted, fontSize: 12)),
                    trailing: const Icon(Icons.play_circle_fill, color: electric),
                    onTap: () => _play('Conhecimento Geral · $n', temas[n]!),
                  ),
                ),
            ]),
    );
  }
}
