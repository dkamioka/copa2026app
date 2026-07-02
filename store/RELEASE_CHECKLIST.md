# Checklist de release — v1 na App Store até 3/jul

Itens marcados 🤖 já estão prontos no repositório; itens 👤 exigem ações
suas (conta Apple, Xcode, dispositivo físico).

## 1. Infra de dados (30 min, custo ZERO) 👤

A fonte de produção é o **football-data.org** — o free tier cobre a Copa
2026 inteira (validado por teste de integração contra o feed ao vivo).
Nenhum plano pago é necessário.

- [ ] **Rotacionar o token** do football-data.org (o atual circulou fora
      do cofre, inclusive em chats) — em football-data.org/client,
      regenere e use o novo APENAS como secret do worker.
- [ ] Deploy do proxy de cache (conta Cloudflare gratuita serve):
      ```bash
      cd proxy
      npx wrangler deploy
      npx wrangler secret put FOOTBALLDATA_TOKEN   # cola o token novo
      ```
      Anote a URL (ex.: `copa2026.SEU-SUBDOMINIO.workers.dev`).
- [ ] Teste rápido:
      `curl 'https://copa2026.SEU-SUBDOMINIO.workers.dev/fd/v4/competitions/WC/standings'`
- [ ] (Opcional, pós-launch) API-Football pago como upgrade de dados —
      adiciona timeline de lances, minuto ao vivo e desfalques; o adapter
      já está pronto (`APIFOOTBALL_KEY`/secret no worker).

## 2. Projeto no Xcode (1–2 h) 👤

- [ ] Apple Developer Program ativo (US$ 99/ano — a aprovação de conta
      nova pode levar ~48h; se ainda não tem, **faça isso AGORA**).
- [ ] App Store Connect → My Apps → "+" → New App:
      bundle `com.veogroup.worldcup2026`, nome "Mundial 2026 — Chave ao vivo".
- [ ] No Xcode: selecionar seu Team em Signing & Capabilities (Runner).
- [ ] Widget (opcional para v1 — pode ir num update): seguir
      `app/ios/CopaBracketWidget/WIDGET_SETUP.md` (target + App Group).
      Se NÃO for incluir agora, remova o widget do escopo do build.
- [ ] 🤖 Ícone: já gerado em todos os tamanhos (asset catalog completo).
- [ ] 🤖 Launch screen: já estilizada.
- [ ] 🤖 Display name: "Mundial 2026" (Info.plist).

## 3. Build e TestFlight (1 h) 👤

```bash
cd app
flutter build ipa --dart-define=FOOTBALLDATA_PROXY=copa2026.SEU-SUBDOMINIO.workers.dev
```

- [ ] Upload: Xcode Organizer (ou `xcrun altool`/Transporter).
- [ ] TestFlight interno: instalar no SEU device e validar o roteiro:
  - [ ] Cold start: splash → loading → chave (sem tela branca).
  - [ ] Sem proxy configurado o app cai no mock com banner — com proxy,
        dados reais aparecem (hoje: chave em "Chave em definição" se o
        mata-mata ainda não estiver definido + grupos reais).
  - [ ] Abrir/fechar sheet de partida com drag.
  - [ ] Widget (se incluído): adicionar à home, ver snapshot.
  - [ ] Versão no header confere com o build.

## 4. Metadados e submissão (1 h) 👤

- [ ] Ativar GitHub Pages (Settings → Pages → branch main, pasta `/docs`)
      → confirma a URL da política de privacidade.
- [ ] Preencher a ficha com `store/APP_STORE.md` (nome, subtítulo,
      keywords, descrição, nota de review).
- [ ] Screenshots 6.7" e 6.1" (roteiro no APP_STORE.md).
- [ ] App Privacy: "Data Not Collected".
- [ ] Export compliance: usa apenas HTTPS padrão → "None of the
      algorithms mentioned above" / exempt.
- [ ] Submit for Review com release **manual** (você aperta o botão
      quando aprovar — controle sobre o momento do lançamento).

## 5. Se o review demorar (plano B)

- [ ] >48h sem movimento: App Store Connect → Contact Us → Request
      Expedited Review. Texto sugerido:

      > Our app provides live coverage of the ongoing 2026 tournament in
      > North America. The knockout stage is underway and the
      > quarter-finals begin July 9. The app's core value is
      > time-critical: fans need it during the tournament. We would be
      > grateful for an expedited review.

- [ ] Rejeição: responder no Resolution Center em minutos, não dias.
      Causas prováveis e respostas prontas:
      - 5.2.1 (direitos): apontar que não usamos marcas FIFA; dados
        licenciados da API-Football (nota de review já cobre).
      - 2.1 (crash/dados vazios): verificar se o proxy está no ar; o app
        degrada para dados de exemplo com aviso — demonstrável.

## 6. Pós-aprovação

- [ ] Release manual → publicar.
- [ ] Smoke test da versão de produção baixada da loja.
- [ ] Monitorar consumo upstream no painel do Cloudflare Worker no primeiro dia.
- [ ] Começar a Fase 1 do ROADMAP.md (share cards + push + Live Activity).
