# Copa do Mundo 2026 — app iOS (Flutter)

Chave do mata-mata ao vivo, classificação dos grupos, artilheiros e widget
de Home Screen. Fonte de dados: mock offline ou API-Football — veja
[DATA_SOURCE.md](DATA_SOURCE.md).

## Rodando

```bash
flutter run                                          # dados de exemplo (mock)
flutter run --dart-define=APIFOOTBALL_KEY=SUA_CHAVE  # dados ao vivo
```

> **Performance**: builds de debug rodam com JIT + asserts e são muito mais
> lentos que o app real. Para avaliar fluidez use `flutter run --profile`
> (ou `--release`) em um **device físico** — nunca o simulador em debug.

## Versionamento (SemVer)

A versão vive no `pubspec.yaml` no formato `MAJOR.MINOR.PATCH+BUILD`
(ex.: `1.1.0+2`) e aparece no cabeçalho do app (ex.: `v1.1.0 (2)`), para
que qualquer feedback/bug report cite o build exato.

| Campo | Quando incrementar |
|---|---|
| `MAJOR` | mudança incompatível de comportamento/dados |
| `MINOR` | nova funcionalidade visível ao usuário |
| `PATCH` | correção sem funcionalidade nova |
| `+BUILD` | **sempre**, a cada build enviado ao TestFlight/App Store |

## Testes

```bash
flutter analyze && flutter test
```
