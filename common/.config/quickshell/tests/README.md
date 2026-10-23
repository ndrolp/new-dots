# Tests

Tests for the pure JS models behind the settings: bar profiles
(`config/BarProfileModel.js`), desktop widgets (`config/DesktopWidgetsModel.js`)
and schema migrations (`config/SchemaMigrations.js`). They run with QtTest
outside of `qs`:

```sh
common/.config/quickshell/tests/run.sh
```

- Test files are `tst_*.qml` (QtTest `TestCase`) and import the models they
  test, e.g. `import "../config/BarProfileModel.js" as BarProfileModel`.
- `fixtures/` holds copies of the real `appearance.json` and `monitors.json`
  (schema version 0, from before bar profiles were reworked). Read them with
  the shared `Fixtures` helper (`Fixtures.qml`): declare
  `Fixtures { id: fixtures }` in the test and call
  `fixtures.read("appearance.json")`. It also gives the fixtures migrated to
  the current schema (`migrated()`), the in-memory bar profile state Quickshell
  starts with (`startedBarState()`), and helpers to apply the changes the
  model returns (`withChanges`, `edited`).
- The script uses the Qt 6 `qmltestrunner` (`/usr/lib/qt6/bin/qmltestrunner`;
  override with `QMLTESTRUNNER`). Extra arguments go to `qmltestrunner`, e.g.
  `run.sh test_savingUnderANewNameAddsAProfile`.
