# Roadmap & Backlog — Copa 2026: do zero ao viral

> **Deadline âncora: publicar na App Store ANTES das Quartas de Final (9–11 de julho de 2026).**
> Hoje é 1º de julho. Review de app novo leva de 2 a 5 dias (com picos de 7+).
> **Isso significa: submeter até 3 de julho.** Tudo neste documento é organizado
> em torno dessa restrição.

## Calendário do torneio (o relógio do projeto)

| Fase | Datas | Janela de produto |
|---|---|---|
| Oitavas (R16) | 4–7 jul | App precisa estar EM REVIEW |
| **Quartas** | **9–11 jul** | **App publicado + primeira onda de compartilhamento** |
| Semifinais | 14–15 jul | v1.1 com loops virais completos |
| Final | 19 jul | Pico absoluto de tráfego — tudo estável |

A Copa é um produto com data de validade: cada dia sem estar na loja é uma
fatia do mercado total que não volta. Por isso o roadmap tem uma regra única:
**nada entra na v1.0 que atrase a submissão.**

---

## 1. O que os apps mais bombados fazem (pesquisa)

### FotMob (20M+ usuários) — retenção por presença
- **Live Activities / Dynamic Island** com placar ao vivo nas cores da seleção —
  o app fica "presente" na tela bloqueada pelos 90 minutos sem nenhum push.
  Braze mede **2,7× mais retenção D30** para apps com touchpoints persistentes
  vs. só notificação.
- Widgets de home screen para fase de grupos e mata-mata (**nós já temos!**).
- Bracket + World Cup Predictor + Lineup Builder — ferramentas que geram
  screenshot compartilhável.

### Apps de bolão brasileiros (Bolão AI: 800 mil palpites; dacopa: 200 mil usuários em 2022) — o loop viral do Brasil
- **Criar bolão em menos de 2 minutos e convidar pelo WhatsApp** (Prodefy).
  O WhatsApp é o canal de distribuição no Brasil — o convite de bolão é o
  mecanismo de K-factor mais eficiente do nicho.
- **Entrar no bolão sem criar conta** (dacopa) — remover fricção do convidado
  é o que faz o loop fechar.
- **Ranking que muda em tempo real, gol a gol** — todo gol vira um motivo de
  abrir o app e provocar os amigos no grupo.
- Mecânicas de jogo: pontos em dobro, "espiar" palpite de rival (Prodefy).

### Wordle (90 → 3 milhões de jogadores em meses) — o share card perfeito
- Compartilhar **status, não link**: a grade de emojis mostra o resultado sem
  spoiler, sinaliza inteligência/participação num ritual coletivo, e desperta
  curiosidade em quem vê. Zero botão de marketing.
- **Ritual diário + streak**: um motivo pequeno e recorrente de voltar.
- Tradução para o nosso app: palpite do dia → card de emojis
  (🇧🇷 2–1 🇫🇷 ✅ / ⚽⚽🟨🟥) compartilhável no WhatsApp/Stories.

### OneFootball / Sofascore — engajamento no jogo
- Fan chat global com reações ao vivo nos grandes jogos.
- Push de gol é o piso da categoria: todo concorrente tem. Sem isso o app é
  "consulta", não "companheiro de jogo".

### Benchmarks de crescimento
- K-factor 0,15–0,25 é bom; 0,4 é ótimo; 0,7+ é viral de verdade. Bolão via
  WhatsApp em época de Copa no Brasil é o cenário raro em que 0,7+ é atingível
  (1 criador de bolão → 5–15 convidados).

---

## 2. Estratégia: 4 loops que se alimentam

```
      AQUISIÇÃO                    RETENÇÃO
┌─────────────────────┐    ┌─────────────────────────┐
│ Loop 1: BOLÃO        │    │ Loop 3: LIVE ACTIVITY    │
│ convite WhatsApp     │───▶│ + widget + push de gol   │
│ (K-factor principal) │    │ (presença nos 90 min)    │
└─────────▲───────────┘    └───────────┬─────────────┘
          │                            │
┌─────────┴───────────┐    ┌───────────▼─────────────┐
│ Loop 2: SHARE CARD   │◀───│ Loop 4: PALPITE DO DIA   │
│ placar/chave/palpite │    │ ritual + streak + rank   │
│ (Wordle-style)       │    │ (motivo de voltar)       │
└─────────────────────┘    └─────────────────────────┘
```

1. **Bolão entre amigos** (Loop 1) é o motor de aquisição — cada usuário
   engajado recruta o grupo do WhatsApp inteiro.
2. **Share cards** (Loop 2) são a superfície de exposição — cada palpite certo,
   cada jogo da chave, vira uma imagem bonita com o nome do app no rodapé.
3. **Live Activities + push de gol** (Loop 3) mantêm o app vivo durante o jogo.
4. **Palpite do dia com streak** (Loop 4) cria o ritual que sustenta os outros
   três entre um jogo e outro.

---

## 3. Roadmap

### 🔴 Fase 0 — "Na loja ou nada" (1–3 jul) → v1.0 SUBMETIDA

O app atual (chave ao vivo + grupos + artilheiros + widget + detalhe de
partida) **já é um produto publicável**. A v1.0 é ele, polido para a loja.

| # | Item | Por quê | Esforço |
|---|---|---|---|
| 0.1 | **Renomear para marca própria sem "FIFA"/"World Cup" no nome** (ex.: "Chave 2026 — Mundial ao vivo"). FIFA é agressiva com trademark e a Apple rejeita por 5.2.1 (direitos de terceiros) — a causa nº 1 de rejeição evitável deste projeto | Aprovação | 2h |
| 0.2 | Ícone + screenshots (6.7" e 6.1") + preview; screenshots com a chave e o widget | Conversão na loja | 4h |
| 0.3 | ASO PT-BR: título ≤30 chars com "copa 2026/chave/tabela", subtítulo, keywords ("bolão, palpite, tabela, jogos, mundial, placar ao vivo") | Descoberta orgânica | 2h |
| 0.4 | Política de privacidade (página estática) + App Privacy no App Store Connect ("não coleta dados" — verdade hoje: zero SDKs) | Obrigatório | 1h |
| 0.5 | Conta paga da API-Football + **cache proxy** (Cloudflare Worker, cache 30–60s por endpoint) — a chave embutida no binário é compartilhada por todos os usuários; o free tier (100 req/dia) morre com ~30 instalações | Sobrevivência | 4h |
| 0.6 | Empty state honesto pré-mata-mata (chave mostra "aguardando classificados" em vez de dado mock quando a API não tem jogos) | Review + confiança | 2h |
| 0.7 | TestFlight interno hoje; build final 2/jul; **submeter 3/jul** marcando associação com evento (elegível a expedited review — pedir só se o review passar de 48h, aprovação não é garantida) | Deadline | — |

**Corte explícito da v1.0**: sem login, sem backend, sem bolão, sem push.
Tudo isso é update (review de update: 12–48h — muito mais rápido).

### 🟠 Fase 1 — Loops de exposição (4–8 jul) → v1.1 no ar até as Quartas

| # | Item | Loop | Esforço |
|---|---|---|---|
| 1.1 | **Share card de partida**: imagem gerada no app (RenderRepaintBoundary → `share_plus`) com bandeiras, placar, fase e rodapé com nome do app. Botão de share no detalhe da partida e no banner ao vivo | 2 | 1 dia |
| 1.2 | **Share card da chave completa** ("minha chave da Copa") — o screenshot que o FotMob e os predictors provam que as pessoas compartilham | 2 | 0,5 dia |
| 1.3 | **Push de gol** (Firebase Messaging + tópicos por seleção: "siga seu time") — piso da categoria, e cada push é uma reabertura | 3 | 1,5 dia |
| 1.4 | **Live Activity do jogo ao vivo** (placar na tela bloqueada/Dynamic Island, cores das seleções — receita FotMob; push-to-start via APNs desde iOS 17.2) | 3 | 2 dias |
| 1.5 | Deep link/universal link para partida (prepara os convites do bolão) | 1 | 0,5 dia |

### 🟡 Fase 2 — O motor viral (9–14 jul) → v1.2 antes das Semis

| # | Item | Loop | Esforço |
|---|---|---|---|
| 2.1 | **Palpite do dia**: escolher placar dos jogos do dia; resultado vira card de emojis estilo Wordle (sem spoiler, com streak 🔥) | 4→2 | 2 dias |
| 2.2 | **Bolão**: criar grupo em <2 min, convite por link de WhatsApp, **entrar sem conta** (Sign in with Apple opcional depois), ranking gol a gol. Backend mínimo: Supabase ou CloudKit público (zero servidor próprio) | 1 | 3–4 dias |
| 2.3 | Ranking do bolão como share card ("tô em 1º no bolão da firma 😎") | 1→2 | 0,5 dia |
| 2.4 | Push de "seus amigos já palpitaram" e "ranking mudou" | 1→3 | 0,5 dia |

### 🟢 Fase 3 — Final e pós-Copa (15–19 jul e além)

- Modo Final: countdown, palpite especial do campeão, card "eu acertei o campeão".
- Load test / rate limits no proxy antes do dia 19 (pico absoluto).
- Decisão pós-Copa: encerrar com dignidade (app vira "álbum da Copa 2026",
  recap compartilhável tipo Spotify Wrapped) **ou** pivotar para Brasileirão/
  Champions reaproveitando o motor. A base instalada de julho é o ativo — o
  recap é a última chance de viralizar com ela.

---

## 4. Riscos (em ordem de probabilidade × impacto)

1. **Review > 5 dias** → submeter 3/jul, metadados impecáveis (conta demo não
   se aplica, sem login), responder rejeição em horas, expedited como plano B.
2. **Trademark FIFA** → item 0.1; nada de logos/mascote/troféu oficial em
   ícone, nome ou screenshots.
3. **Quota da API** → item 0.5; sem o proxy, o app morre no primeiro dia bom.
4. **Backend do bolão atrasar** → bolão é v1.2; o app já viraliza com share
   cards + push na v1.1. Não segurar release por ele.
5. **Só iOS** → aceito para este ciclo (o repo é iOS-first). Android/Play
   (review em horas) entra se sobrar capacidade — não antes da v1.1 iOS.

## 5. Métricas de sucesso

| Métrica | Meta Quartas | Meta Final |
|---|---|---|
| K-factor (convites → instalações) | 0,2 | 0,4+ |
| Shares por usuário ativo/dia | 0,1 | 0,3 |
| D1 retention | 25% | 35% |
| Opt-in de push | 40% | 55% |
| % usuários em ≥1 bolão | — | 30% |

Instrumentação mínima na v1.1: eventos de share, convite, palpite e opt-in
de push (Firebase Analytics — atualizar App Privacy ao adicionar).

## 6. Checklist de submissão (v1.0)

- [ ] Bundle ID + time de assinatura no App Store Connect
- [ ] Nome/subtítulo/keywords sem termos de trademark
- [ ] Screenshots 6.7" + 6.1", ícone 1024px
- [ ] Política de privacidade publicada (URL)
- [ ] App Privacy preenchido ("Data Not Collected")
- [ ] Build com chave da API paga via `--dart-define` no CI (nunca no git)
- [ ] Widget testado em device real (App Group configurado no Xcode)
- [ ] Nota de review explicando a fonte de dados (API-Football licenciada)
- [ ] Categoria: Sports; classificação etária 4+

---

### Fontes da pesquisa

- FotMob: recursos de Copa, Live Activities, widgets — [fotmob.com](https://www.fotmob.com/), [App Store](https://apps.apple.com/us/app/fotmob-soccer-live-scores/id488575683), [Top 7 apps para a Copa 2026](https://top7.hr/en/sport/top-7-apps-follow-world-cup-2026)
- OneFootball fan chat — [App Store](https://apps.apple.com/us/app/onefootball-live-soccer-scores/id382002079)
- Bolões BR: [Prodefy](https://prodefy.co/en), [Bolão AI](https://bolaoai.com.br/), [dacopa](https://www.dacopa.com/), [Bolão Entre Amigos](https://bolaoentreamigos.app.br/)
- Predictors com share de imagem: [WC Predictor](https://wcpredictor.app/), [World Football 26 Predictor](https://apps.apple.com/us/app/world-football-26-predictor/id6762615410), [Superbru](https://www.superbru.com/worldcup_predictor/)
- Wordle e mecânica de share/streak: [MoEngage](https://www.moengage.com/blog/wordle-viral-growth-story/), [Deep dive aakashg.com](https://www.aakashg.com/wordle/)
- K-factor benchmarks: [Growth Unhinged](https://www.growthunhinged.com/p/your-guide-to-product-virality), [FourWeekMBA](https://fourweekmba.com/viral-coefficients-k-factor-the-mathematics-of-exponential-growth/)
- Live Activities e retenção (Braze 2,7× D30): [EngageLab](https://www.engagelab.com/blog/live-activities-examples), [Pushwoosh](https://www.pushwoosh.com/blog/ios-live-activities/)
- Tempos de review da App Store 2026: [lowcode.agency](https://www.lowcode.agency/blog/app-store-review-time), [Runway (tempos ao vivo)](https://www.runway.team/appreviewtimes), [Median — expedited](https://median.co/blog/unlocking-the-app-store-approval-time-speed-up-your-app-review-process)
