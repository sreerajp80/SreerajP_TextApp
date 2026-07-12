# Bundled fonts

All fonts here are open source (SIL Open Font License 1.1, or dual OFL/GPL with
font exception), which satisfies CLAUDE.md §3.1 (open source only). The full
licence text for each family is under `licenses/`.

| Family | File(s) | Script | Licence | Source |
|--------|---------|--------|---------|--------|
| Inter | `Inter-Variable.ttf` | Latin | OFL 1.1 | github.com/google/fonts (ofl/inter) |
| Lora | `Lora-Variable.ttf` | Latin | OFL 1.1 | github.com/google/fonts (ofl/lora) |
| JetBrains Mono | `JetBrainsMono-Variable.ttf` | Latin (mono) | OFL 1.1 | github.com/google/fonts (ofl/jetbrainsmono) |
| Manjari | `Manjari-Regular.ttf`, `Manjari-Bold.ttf` | Malayalam + Latin | OFL 1.1 | github.com/google/fonts (ofl/manjari) |
| Rachana | `Rachana-Regular.ttf`, `Rachana-Bold.ttf` | Malayalam + Latin | OFL 1.1 / GPLv3+FE | github.com/smc/Rachana |
| Noto Sans Malayalam | `NotoSansMalayalam-Variable.ttf` | Malayalam + Latin | OFL 1.1 | github.com/google/fonts (ofl/notosansmalayalam) |

The `-Variable.ttf` files are variable fonts (weight axis); Flutter interpolates
weights, so one file covers regular and bold. The families are declared in
`pubspec.yaml` under `flutter: fonts:`.
