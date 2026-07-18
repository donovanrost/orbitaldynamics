# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
CadenceImport strategy-tradeoff manifest-row builder extraction.

Status:
Slice selected; selection publication pending.

Selected slice:
Move `strategy_tradeoff_manifest_row/2` and its exclusively used
`strategy_tradeoff_import_action/1` clauses into internal
`CadenceImport.StrategyTradeoffManifestRow.build/3`. Inject only the six shared
facade helpers for review action, adapter status, three branch field catalogs,
and compact-map cleanup.

Why this slice:
`CadenceImport` is 6,911 lines. The strategy-tradeoff builder is a 233-line
transformation with 184 projected keys, three ordered branch-field merges, and
one facade caller.

Current coupling/problem:
The main artifact adapter embeds a large strategy-tradeoff projection and
branch evidence merge pipeline alongside every other source transformation.

Public facade to preserve:
All `CadenceImport` APIs; all strategy-tradeoff row keys and value expressions;
branch merge order and collision precedence; approval/import defaults, import
status/action, compaction, deterministic output, and artifact contracts.

Likely files:
- `lib/orbital_dynamics/cadence_import.ex`
- `lib/orbital_dynamics/cadence_import/strategy_tradeoff_manifest_row.ex`
- `.codex/status/large_module_refactor.md`

Definition of done:
The internal builder owns the exact 184-key projection, three branch merges,
and exclusive import-action clauses; the facade supplies only six same-purpose
callbacks; focused Cadence-import and schema-contract tests pass; strict
warnings-as-errors compile, projection/pipeline equivalence, public API checks,
and independent review are clean.

Verification gaps:
- Focused baseline, implementation proof, strict compile, and independent
  review remain.

Tests run:
- None yet for this selected slice.

Behavior/schema changes:
None intended.

Last completed slice:
CadenceImport timeline-diff row builder published as implementation `7cde78b9`
and handoff `dad1b910`: focused 100/100, strict 3,676-file compile, exact
182-entry AST comparison, and independent review passed.

Next candidate:
Remap the reduced `CadenceImport` module and select the next source-specific
manifest-row builder.

Blocked:
No.
