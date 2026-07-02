# Mundial 2026 — guia para o Claude Code

App iOS em Flutter: chave do mata-mata da Copa 2026 ao vivo,
classificação dos grupos, artilheiros, detalhe de partida e widget de
Home Screen. Código do app em `app/`; proxy de dados em `proxy/`;
material de loja em `store/`.

## Comandos essenciais

```bash
cd app
flutter analyze && flutter test     # sempre antes de commitar
```

## Rodar no device com dados AO VIVO (Copa 2026 real)

A fonte de produção é o football-data.org (free tier — cobre a Copa
2026 inteira). O token vive em `app/.secrets`, que é **gitignored e
nunca deve ser commitado**.

```bash
# 1) Uma única vez por máquina — criar o arquivo de segredo:
echo 'FOOTBALLDATA_TOKEN=token_do_usuario' > app/.secrets

# 2) Rodar no device conectado (o script lê o .secrets):
app/tool/run-live.sh
# args extras passam direto para o flutter run, ex.:
app/tool/run-live.sh -d 00008110-000A2C3E0E38801E --release
```

Se `app/.secrets` não existir, **peça o token ao usuário** (ele obtém um
gratuito em football-data.org/client/register) e crie o arquivo. Nunca
escreva o token em nenhum arquivo rastreado pelo git, em logs de commit
ou em código.

Equivalente manual, sem o script:

```bash
cd app && flutter run --dart-define=FOOTBALLDATA_TOKEN=$(grep -o 'FOOTBALLDATA_TOKEN=.*' .secrets | cut -d= -f2)
```

Sem nenhum `--dart-define`, o app roda com dados de exemplo (mock) —
útil para trabalhar em UI sem rede.

## Builds de release (TestFlight / App Store)

**Nunca** embuta token/chave num build de release — credencial em
binário público é compartilhada por todas as instalações e irrevogável.
Release usa o proxy de cache (Cloudflare Worker em `proxy/`, token como
secret do worker):

```bash
cd app
flutter build ipa --dart-define=FOOTBALLDATA_PROXY=copa2026.SUBDOMINIO.workers.dev
```

Passo a passo completo de submissão: `store/RELEASE_CHECKLIST.md`.

## Testes de integração com dados reais (rodar antes de releases)

```bash
cd app
# Feed de produção (Copa 2026 ao vivo, ~4 requisições):
flutter test test/football_data_integration_test.dart \
  --dart-define=FOOTBALLDATA_TOKEN=$(grep -o 'FOOTBALLDATA_TOKEN=.*' .secrets | cut -d= -f2)
```

## Convenções

- **SemVer** no `pubspec.yaml` (`MAJOR.MINOR.PATCH+BUILD`): o build (+n)
  incrementa a cada envio ao TestFlight; a versão aparece no header do
  app. Ao mudar a versão, atualize também o mock/expect de versão em
  `app/test/widget_test.dart`.
- **Marca**: o app se chama "Mundial 2026" — nunca usar "FIFA",
  "World Cup" ou "Copa do Mundo 2026" como marca em nome, ícone ou
  strings de destaque (marcas da FIFA; rejeição 5.2.1 no App Review).
- **Fontes de dados** (prioridade no bootstrap): football-data.org →
  API-Football (premium opcional) → mock. Detalhes e limitações de cada
  uma: `app/DATA_SOURCE.md`.
- **Widget iOS**: requer configuração única no Xcode (target + App
  Group) — `app/ios/CopaBracketWidget/WIDGET_SETUP.md`.
- Roadmap de produto e backlog de crescimento: `ROADMAP.md`.
