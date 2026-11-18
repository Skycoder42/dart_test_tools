# Library Version Bump nur bei relevanten Änderungen – Implementierungsplan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Im library-Modus von `renovate-post-upgrade` wird ein Paket nur noch released (Changelog + Patch-Bump), wenn ein SDK-Constraint angehoben wurde oder sich die Upper Bound einer `dependencies`-Dependency geändert hat. Der application-Modus bleibt unverändert.

**Architecture:** Die Entscheidung trifft eine reine Funktion `PostUpgrade.requiresVersionBump`. Sie arbeitet auf den `RenovateUpgrade`-Einträgen eines Pakets, die `_release` heute schon pro Paket filtert. Die Upper Bound wird mit `pub_semver` aus `currentValue` und `newValue` gelesen. Widened-Constraints (`^1.0.0 || ^2.0.0`) laufen über das vorhandene `mergeWidenedConstraint`. Trifft keine Bedingung zu, verlässt `_release` die Funktion, bevor irgendetwas geschrieben wird: kein Changelog-Eintrag, kein Bump.

**Tech Stack:** Dart, `pub_semver` (bereits Dependency), `cider` über `PubWrapper.cider`.

**Spec:** Anforderung aus dem Chat vom 2026-11-18 (kein separates Spec-Dokument):
- Library: Version Bump nur, wenn mindestens eine Bedingung zutrifft:
  1. Die Flutter- oder Dart-Version wurde erhöht.
  2. Die Upper Bound einer Dependency hat sich geändert (Widening, Major-Bump, allgemein: neue Version hat ein anderes Upper Limit als die alte).
- Application: unverändert, immer Bump.
- Ohne Bump wird im library-Modus **kein** Changelog-Eintrag geschrieben (Entscheidung des Users: einfacher, keine Dedup-Logik).
- Nur Einträge unter `dependencies` zählen, `dev_dependencies` lösen keinen Bump aus (Entscheidung des Users).

## Global Constraints

- Keine neuen Dependencies, auch kein direkter Import von `package:change`.
- Changelog-Einträge und Versionen des Repos selbst nur über `dart run bin/cider.dart` (CLAUDE.md).
- Analyse über den Dart-MCP-Server (`mcp__dart__analyze_files`), nicht über `dart analyze`.
- Integrationstests in `post_upgrade_test.dart` brauchen Netzwerk zu pub.dev. Steht die lokale `PUB_HOSTED_URL` auf einem anderen Host, mit `PUB_HOSTED_URL=https://pub.dev` ausführen.
- Wenn sich die Bump-Entscheidung nicht sicher treffen lässt (Werte fehlen, Constraint nicht parsebar, `depType` fehlt), wird **gebumpt**. Lieber ein Release zu viel als ein fehlendes.

## Review Focus

1. **Git-Dependencies:** `currentValue`/`newValue` sind Git-Refs (`main`, Commit-Hash) und nicht parsebar. Erwartung: Bump (konservativ). Test in Task 1: `changesUpperBound('main', 'v2')` ist `true`.
2. **Fehlender `depType`** bei einer Nicht-SDK-Dependency. Erwartung: zählt wie `dependencies`. Test in Task 1.
3. **Gemischte Upgrades in einem Paket:** mehrere Updates ohne Wirkung plus eines mit neuer Upper Bound. Erwartung: Bump, alle Einträge landen im Release. Test in Task 1 (`requiresVersionBump`).
4. **Gleiche Upper Bound in anderer Schreibweise:** `^1.8.0` → `>=1.9.0 <2.0.0`. Erwartung: kein Bump. `pub_semver` normalisiert beide auf `max=2.0.0-0, includeMax=false` (lokal geprüft). Test in Task 1.
5. **application-Modus mit Update ohne Wirkung:** Erwartung: weiterhin Bump. Integrationstest in Task 2.

---

### Task 1: Entscheidungslogik für den Version Bump

**Files:**
- Modify: `lib/src/renovate/post_upgrade.dart` (zwei neue statische Methoden neben `mergeWidenedConstraint`)
- Test: `test/integration/renovate/post_upgrade_test.dart` (neue Gruppen neben `group('mergeWidenedConstraint', …)`)

**Interfaces:**
- Consumes: `PostUpgrade.mergeWidenedConstraint(String) → VersionRange` (vorhanden), `RenovateUpgrade.isSdkUpgrade` (vorhanden)
- Produces:
  - `@visibleForTesting static bool changesUpperBound(String? currentValue, String? newValue)`
  - `@visibleForTesting static bool requiresVersionBump(Iterable<RenovateUpgrade> upgrades)`

- [ ] **Step 1: Failing Tests schreiben**

`group('changesUpperBound', …)` mit einem Test pro Zeile (Name = Beschreibung):

| Beschreibung | current | new | Erwartung |
|---|---|---|---|
| keeps the bound for a caret minor bump | `^1.2.0` | `^1.3.0` | `false` |
| keeps the bound for an equivalent range | `^1.8.0` | `>=1.9.0 <2.0.0` | `false` |
| keeps the bound of a raised lower range bound | `>=1.0.0 <3.0.0` | `>=2.0.0 <3.0.0` | `false` |
| detects a major bump | `^1.2.0` | `^2.0.0` | `true` |
| detects a 0.x minor bump | `^0.14.0` | `^0.15.0` | `true` |
| detects a widened constraint | `^13.3.0` | `^13.3.0 \|\| ^14.0.0` | `true` |
| detects a bounded constraint becoming unbounded | `^1.0.0` | `>=1.0.0` | `true` |
| detects a pinned version bump | `1.2.3` | `1.2.4` | `true` |
| bumps if a value is missing | `null` / `^1.0.0` und `^1.0.0` / `null` | | `true` |
| bumps for unparsable values | `main` | `v2` | `true` |

`group('requiresVersionBump', …)`, kurz `dep(depType, current, next)` für `RenovateUpgrade(manager: 'pub', depName: 'pkg', packageFile: 'pubspec.yaml', …)`:

- `is false without upgrades`: `[]` → `false`
- `is true for sdk upgrades`: `RenovateUpgrade(manager: 'pub', depName: 'dart', packageFile: 'pubspec.yaml', currentValue: '^3.9.0', newValue: '^3.10.0')` → `true`; dasselbe mit `depName: 'flutter'` → `true`
- `is false for dependencies within their bound`: `dep('dependencies', '^1.2.0', '^1.3.0')` → `false`
- `is true for dependencies with a new bound`: `dep('dependencies', '^1.2.0', '^2.0.0')` → `true`
- `ignores dev dependencies`: `dep('dev_dependencies', '^1.2.0', '^2.0.0')` → `false`
- `treats a missing depType as dependency`: `dep(null, '^1.2.0', '^2.0.0')` → `true`
- `is true if any upgrade requires it`: `[dep('dependencies', '^1.2.0', '^1.3.0'), dep('dev_dependencies', '^1.0.0', '^2.0.0'), dep('dependencies', '^0.1.0', '^0.2.0')]` → `true`

- [ ] **Step 2: Tests laufen lassen, sie müssen rot sein**

Run: `dart test test/integration/renovate/post_upgrade_test.dart -N "changesUpperBound|requiresVersionBump"`
Expected: Compile-Fehler, `changesUpperBound` / `requiresVersionBump` ist nicht definiert.

- [ ] **Step 3: `changesUpperBound` und `requiresVersionBump` in `post_upgrade.dart` implementieren**

- `changesUpperBound`: Ist ein Wert `null`, wird `true` zurückgegeben. Jeder Wert wird über einen privaten Helper zu `(Version? max, bool includeMax)?` umgewandelt:
  - enthält er `||`, dann `mergeWidenedConstraint`;
  - sonst `VersionConstraint.parse`: ein `VersionRange` (auch `Version`) liefert direkt `max`/`includeMax`, eine `VersionUnion` liefert die Werte von `ranges.last`;
  - alles andere, auch eine `FormatException`, ergibt `null`.
  
  Ist einer der beiden Helper-Werte `null`, ist das Ergebnis `true`. Sonst: `true`, sobald sich die Records unterscheiden. `pub_semver` normalisiert `<2.0.0` und `^1.x` beide auf `2.0.0-0`, eine eigene Prerelease-Behandlung ist daher nicht nötig.
- `requiresVersionBump`: `true`, sobald ein Upgrade `isSdkUpgrade` ist oder (`depType != 'dev_dependencies'` und `changesUpperBound(currentValue, newValue)`).

- [ ] **Step 4: Tests laufen lassen, sie müssen grün sein**

Run: `dart test test/integration/renovate/post_upgrade_test.dart -N "changesUpperBound|requiresVersionBump|mergeWidenedConstraint"`
Expected: alle PASS. Danach `mcp__dart__analyze_files` → `No errors`.

- [ ] **Step 5: Commit**

```bash
git add lib/src/renovate/post_upgrade.dart test/integration/renovate/post_upgrade_test.dart
git commit -m "feat(renovate): decide whether library upgrades need a version bump"
```

---

### Task 2: Release im library-Modus an die Entscheidung koppeln

**Files:**
- Modify: `lib/src/renovate/post_upgrade.dart` (`_release`)
- Modify: `test/integration/renovate/post_upgrade_test.dart` (bestehende Tests anpassen, neue Integrationstests)
- Modify: `README.md` (Beschreibung des library-Presets)
- Modify: `CHANGELOG.md` **nur über** `dart run bin/cider.dart log …`

**Interfaces:**
- Consumes: `PostUpgrade.requiresVersionBump(Iterable<RenovateUpgrade>) → bool` aus Task 1
- Produces: keine neuen APIs

- [ ] **Step 1: Bestehenden Test anpassen und neue Tests schreiben (rot)**

Fixture wie gehabt: `packages/b` mit `version: 1.0.0`, `CHANGELOG.md` und `path: ^1.9.0`.

Anpassung: In `package with version but without changelog is bumped` wird das `build_runner`-Upgrade ersetzt durch
`RenovateUpgrade(manager: 'pub', depName: 'dart', packageFile: 'packages/a/pubspec.yaml', currentValue: '^3.9.0', newValue: '^3.13.0')`.
Die Erwartung bleibt `2.0.1`. Diesen Test zuerst laufen lassen: er muss auch vor der Implementierung grün sein. Der heutige Fall (Dev-Dependency ohne Werte) wäre nach der Änderung kein Release mehr.

Neue Tests mit `packageFile: 'packages/b/pubspec.yaml'`:

- `library mode does not release upgrades within the upper bound`: `PostUpgradeMode.library`, `RenovateUpgrade(depName: 'path', depType: 'dependencies', currentValue: '^1.8.0', newValue: '^1.9.0')`. Erwartung: `pubspec.yaml` und `CHANGELOG.md` von b sind byte-gleich mit vorher.
- `library mode does not release dev dependencies with a new upper bound`: `depName: 'test', depType: 'dev_dependencies', currentValue: '^1.0.0', newValue: '^2.0.0'`. Erwartung wie oben, alles unverändert.
- `library mode releases dependencies with a new upper bound`: `depName: 'path', depType: 'dependencies', currentValue: '^0.9.0', newValue: '^1.9.0'`. Erwartung: `packageVersion('packages/b') == '1.0.1'`, `changelogLines` enthält `startsWith('## 1.0.1 - ')` und genau einmal `- Updated dependencies`.
- `application mode releases upgrades within the upper bound`: `PostUpgradeMode.application` mit demselben Upgrade wie im ersten Test. Erwartung: `1.0.1`.

- [ ] **Step 2: Tests laufen lassen, die beiden „does not release“-Tests müssen rot sein**

Run: `PUB_HOSTED_URL=https://pub.dev dart test test/integration/renovate/post_upgrade_test.dart -N "does not release|releases"`
Expected: Die beiden `does not release`-Tests schlagen fehl, weil die Version auf 1.0.1 gebumpt wurde. Die beiden `releases`-Tests sind grün, denn das ist das heutige Verhalten.

- [ ] **Step 3: `_release` anpassen**

Direkt nach der Prüfung `packageUpgrades.isEmpty`: Ist `mode == .library` und `!requiresVersionBump(packageUpgrades)`, dann `Github.logInfo('Skipping release of ${info.name}: no SDK update and no dependency with a new upper bound')` und `return`. Alles danach (Changelog-Einträge, `bump patch`, `version-sync`, `release`) bleibt unverändert.

- [ ] **Step 4: Komplette Renovate-Suite laufen lassen, sie muss grün sein**

Run: `PUB_HOSTED_URL=https://pub.dev dart test test/integration/renovate`
Expected: alle PASS. Danach `mcp__dart__analyze_files` → `No errors`.

- [ ] **Step 5: README und Changelog**

- `README.md`, Bullet `library` unter „Add a `renovate.json`“: Satz ergänzen, dass ein Paket nur released wird (Changelog-Eintrag + Patch-Bump), wenn ein SDK-Constraint angehoben wurde oder sich die Upper Bound eines Eintrags unter `dependencies` geändert hat; sonst bleiben Version und Changelog unverändert. Das Bullet `application` bekommt den Hinweis, dass dort jedes Update released wird.
- `dart run bin/cider.dart log changed 'renovate-post-upgrade (library mode): packages are only released (changelog entry and patch bump) if an SDK constraint was raised or the upper bound of a dependency changed; application mode still releases every update'`

- [ ] **Step 6: Commit**

```bash
git add lib/src/renovate/post_upgrade.dart test/integration/renovate/post_upgrade_test.dart README.md CHANGELOG.md
git commit -m "feat(renovate): only release libraries for sdk or upper bound changes"
```
