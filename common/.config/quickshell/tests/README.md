# Tests

Tests for the bar profile model (`config/BarProfileModel.js`), the pure JS
library behind bar profiles. They run with QtTest outside of `qs`:

```sh
common/.config/quickshell/tests/run.sh
```

- Test files are `tst_*.qml` (QtTest `TestCase`) and import the model with
  `import "../config/BarProfileModel.js" as BarProfileModel`.
- `fixtures/` holds copies of the real `appearance.json` and `monitors.json`;
  load them with the `readFixture` helper in `tst_barProfileModel.qml`.
- The script uses the Qt 6 `qmltestrunner` (`/usr/lib/qt6/bin/qmltestrunner`;
  override with `QMLTESTRUNNER`). Extra arguments go to `qmltestrunner`, e.g.
  `run.sh test_savingUnderANewNameAddsAProfile`.
