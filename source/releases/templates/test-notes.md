# How CMF <<FILL: version>> was tested

<!-- Template for dist/<version>/test-notes.md. Copy it to source/releases/<version>/test-notes.md
and fill every <<FILL: ...>> from the final matrix records (probes/<date>-cmf-matrix-<set>/README.md)
and the freeze commit. Rule: a claim appears only where a launch on the probe copy showed it;
anything else goes under "Not tested". Do not copy results from this template or from older
records: nothing here has been tested until the records say so. Remove these comment lines. -->

## Where and how

- **Where:** a separate copy of the game on Windows, <<FILL: store, patch and build, e.g. Steam 5.01 (build 5.0.1048522)>>, DirectX 12, <<FILL: other installed tools such as W3LoadFix and their versions, or "nothing else">>.
- **What was installed:** <<FILL: confirm from the records, e.g. "the files in this release, installed from these exact archives, with each adapted mod at the version named in its adapter's README.txt">>.
- **How:** <<FILL: input used and how a session ended, e.g. "keyboard and mouse; each test set was one game session that ended without saving">>.

## The test sets

<<FILL: one line per final matrix set, in plain words, with the date its record shows it passing on these archives. List only sets whose record says it passed.>>

## Not tested

- Proton / Linux.
- Controllers. <<FILL: keep "Keyboard and mouse only." or name the input that was tested>>
- Installing through a mod manager (Vortex, MO2). <<FILL: how the archives were installed, from the records>>
- Mods not named on the compatibility list.
<<FILL: anything else the matrix did not cover, or remove this line>>

## Known differences

<<FILL: each adapter's "What is different" text from the final compatibility list>>

## Test levels (developer record)

| Level | What | Record |
| --- | --- | --- |
| Static | `tools/cmf.py check --stage 0`; unit tests at the freeze commit, known failures listed and explained | <<FILL: freeze commit, test count, failure count and why they fail>> |
| Offline | panel build movie hash and layout check; adapter packs matching each adapter's `SHA256SUMS` | <<FILL: candidate spec path>> |
| Probe launches | each ability's own launch on the probe copy | <<FILL: date range and records>> |
| Final matrix | every set on the candidate's own bytes | <<FILL: one record per set>> |
| Live acceptance | Kyle's acceptance of the release | <<FILL: his acceptance at the dist commit>> |

Never written as tested: Proton, controllers, mod-manager install, or in-game behaviour of anything only read in code.
