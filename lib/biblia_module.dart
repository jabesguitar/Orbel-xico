import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'content.dart';
import 'ladder_game.dart';
import 'main.dart';
import 'question.dart';

/// Estudo Bíblico: 66 livros canônicos por categoria; cada livro tem o seu quiz.
class BibliaPage extends StatefulWidget {
  const BibliaPage({super.key});
  @override
  State<BibliaPage> createState() => _BibliaPageState();
}

class _BibliaPageState extends State<BibliaPage> {
  Map<String, List<Question>> qs = {};
  List<dynamic> testamentos = [];
  bool ready = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final est = jsonDecode(await rootBundle.loadString('assets/data/biblia_estrutura.json')) as Map<String, dynamic>;
    final data = await loadBiblia();
    if (!mounted) return;
    setState(() {
      testamentos = est['testamentos'] as List;
      qs = data;
      ready = true;
    });
  }

  void _play(String titulo, List<Question> pool) {
    if (pool.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('As perguntas deste livro chegam em breve.')));
      return;
    }
    Navigator.push(context, MaterialPageRoute(builder: (_) => LadderGame(titulo: titulo, categoria: 'biblia', pool: pool)));
  }

  Widget _livro(String nome) {
    final n = qs[nome]?.length ?? 0;
    return ListTile(
      title: Text(nome, style: const TextStyle(fontSize: 16)),
      subtitle: Text(n == 0 ? 'Em breve' : '$n perguntas', style: const TextStyle(color: muted, fontSize: 12)),
      trailing: Icon(n == 0 ? Icons.hourglass_empty : Icons.play_circle_fill, color: n == 0 ? muted : electric),
      onTap: () => _play('Quiz de $nome', qs[nome] ?? <Question>[]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final todas = qs.values.expand((e) => e).toList();
    return Scaffold(
      appBar: AppBar(title: Text('Estudo Bíblico', style: serif(20))),
      body: !ready
          ? const Center(child: CircularProgressIndicator())
          : ListView(padding: const EdgeInsets.all(14), children: [
              Card(
                color: deep,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18), side: const BorderSide(color: line)),
                child: ListTile(
                  leading: const Icon(Icons.auto_stories, color: gold, size: 32),
                  title: Text('Quiz de toda a Bíblia', style: serif(18)),
                  subtitle: Text('${todas.length} perguntas de todos os livros', style: const TextStyle(color: muted)),
                  trailing: const Icon(Icons.play_circle_fill, color: electric, size: 32),
                  onTap: () => _play('Quiz da Bíblia', todas),
                ),
              ),
              for (final t in testamentos) ...[
                Padding(
                  padding: const EdgeInsets.only(top: 18, bottom: 6),
                  child: Text(t['nome'] as String, style: serif(22, c: gold)),
                ),
                for (final c in (t['categorias'] as List))
                  Card(
                    color: deep,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: ExpansionTile(
                      shape: const RoundedRectangleBorder(),
                      collapsedShape: const RoundedRectangleBorder(),
                      iconColor: gold,
                      collapsedIconColor: gold,
                      title: Text(c['nome'] as String, style: serif(17)),
                      subtitle: Text('${(c['livros'] as List).length} ${(c['livros'] as List).length == 1 ? 'livro' : 'livros'}', style: const TextStyle(color: muted, fontSize: 12)),
                      children: [for (final l in (c['livros'] as List)) _livro(l as String)],
                    ),
                  ),
              ],
              const SizedBox(height: 20),
            ]),
    );
  }
}
