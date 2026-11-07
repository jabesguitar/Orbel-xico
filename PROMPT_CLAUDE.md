# Orbeléxico — Prompt para o Claude gerar o APK (e o .exe)

## Contexto
Crie do zero o app **Orbeléxico** (pt-BR), "Aprender. Descobrir. Evoluir.", em **Flutter** (um código para Android APK e Windows .exe). Se já existir repositório meu em github.com/jabesguitar, analise a estrutura antes e preserve a lógica existente; se não, crie um novo. Não use dados falsos para simular funcionamento.

## Identidade (arquivos já prontos nesta pasta)
- `ic_launcher_foreground.svg`, `ic_launcher_background.svg`, `ic_launcher_monochrome.svg` → ícone adaptativo Android (zona segura central 66/108), com versão monocromática (Android 13+).
- `ic_launcher_playstore.svg` → ícone 512 px da loja. `splash.svg` → splash. Converta SVG→PNG no build (rsvg-convert) e use `flutter_launcher_icons` (adaptive_icon_foreground/background/monochrome) e `flutter_native_splash`.
- Ícone de notificação: silhueta branca do globo+livro (use o monocromático em 24dp).
- Layout de referência: `layout_orbelexico.html` e a imagem do mockup. Siga fielmente.
- Cores: ink #050E24, deep #0B2A66, electric #1E6BFF, gold #D9B15A, cream #F3E6C4. Tipografia: Playfair Display (títulos/palavras) + Inter (interface), embarcadas em assets (offline). Dark Mode premium, bordas 18–22 dp, sombras suaves, gradientes discretos, toque ≥ 48 dp, SafeArea, indicador da aba selecionada (pílula azul), animações 150–250 ms, ícones vetoriais.

## Módulos
1. **Vocabulário Avançado**: milhares de palavras (sinônimos de palavras comuns, termos sofisticados, e palavras em desuso dos anos 50, 60, 80 e 90). As mais usadas aparecem com mais frequência (repetição espaçada). Cada palavra: classe gramatical, significado, sinônimos, **botão de áudio** ao lado (TTS pt-BR via `flutter_tts`), e **no mínimo 3 frases em contextos diferentes** ao final de cada resposta.
2. **Conhecimento Geral**: Brasil e mundo, somente fatos verificáveis, sem militância ou opinião política.
3. **Bandeiras**: mostra a imagem da bandeira, pergunta o país; ao responder, apresenta história do país e personagens importantes. Bandeiras em SVG de domínio público, embarcadas offline.
4. **Estudo Bíblico**: Bíblia protestante (66 livros), perspectiva pentecostal, **sem apócrifos**. Use versão em domínio público ou com licença confirmada (ex.: Almeida Corrigida de domínio público); registre a fonte de cada texto.
5. **Progresso**: sequência diária, acertos, revisões pendentes. Favoritos, Jogos (quiz, ligar sinônimos, forca de palavras).
Sugestões: palavra do dia com notificação, modo offline, níveis (básico→erudito), "palavras que sumiram" por década, versículo do dia.

## Conteúdo: regra de ouro
Todo conteúdo vem de fontes confiáveis (dicionários como Houaiss/Aulete/Priberam para significado, enciclopédias e almanaques para países, texto bíblico oficial). Sem inventar. Cada item guarda `fonte` no JSON. Conteúdo em `assets/data/*.json`, carregado por repositório único (sem duplicar código).

## Comando de especialistas (use ao gerar e revisar conteúdo e telas)
Atue em conjunto como:
- **Psicólogo cognitivo**: repetição espaçada, prática de recuperação, feedback imediato, gamificação saudável, sem pressão ou culpa.
- **Designer humano sênior**: estética clássica, reverente e premium; nada de aparência genérica de IA; hierarquia, respiro, contraste AA+, microinterações suaves.
- **Professor de Língua Portuguesa**: precisão gramatical, registro correto, exemplos naturais em contextos distintos, etimologia quando útil.
- **Teólogo protestante pentecostal**: fidelidade ao texto bíblico, 66 livros, contexto histórico e linguístico, tom respeitoso, sem sensacionalismo.
Em caso de dúvida factual, marque `revisar: true` em vez de afirmar.

## Entrega
Projeto compilável, `.github/workflows/build.yml` que, ao criar a tag `v*`, gera `app-release.apk` e `Orbeleixico-Setup.exe` e anexa à Release; README com instalação. Package id sugerido: `br.com.jabes.orbelexico` (confirme).
