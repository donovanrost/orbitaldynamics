# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema communications-summary validation ownership cleanup.

Status:
Completed and verified; publishing.

Selected slice:
Point the link-capacity-summary and relay-data-path-summary contract pipelines
directly at their owner `validate_summary/3` functions. Remove the two pure
facade delegates.

Why this slice:
Both communications summary owners already expose exact `/3` validation
pipelines. Each facade helper only forwards the piped issue list, path, and
artifact, so the contract heads can call their owners directly without changing
required-field ordering or owner behavior.

Public facade to preserve:
All `OrbitalDynamics.Schema` public functions, exact validation issue ordering,
paths and messages, cadence-import behavior, JSON Schema bytes, and aggregate
schema export bytes.

Likely files:
- `lib/orbital_dynamics/schema.ex`
- `.codex/status/large_module_refactor.md`

Likely verification:
- focused cadence-import, readiness, and review-import handoff contract tests
- JSON Schema contract/export tests and full checked-in schema regeneration
- strict compile, format, xref, diff hygiene, and bounded review

Definition of done:
Both contract pipelines call their summary owners directly, the two pure facade
delegates are gone, required-field and summary issue ordering remains exact,
validation and schema exports remain byte-for-byte stable, focused tests pass,
and bounded review finds no blocker.

Verification gaps:
- None for this slice.

Tests run:
- `mix compile --warnings-as-errors`
- 12 focused communications contract and fixture tests
- 182 complete schema-contract and schema-export tests
- full checked-in schema export regeneration; no schema diff
- aggregate schema bundle digest unchanged:
  `757bb20af70443e376085ef2e6f97e5a0a0a8ee97323b5911343e88cd8b9ad15`
- `mix format --check-formatted`
- `git diff --check`
- compile-connected xref check for `schema.ex`
- bounded read-only review: clean, no findings

Outcome:
Both communications summary contract heads now pipe directly to their owner
validators. The two pure facade delegates are gone, required-field ordering
remains exact, and `schema.ex` decreased from 8,093 to 8,077 lines.

Behavior/schema changes:
None.

Last completed slice:
Schema ResourceProjection support callback ownership cleanup published as
`395b7249`: five positions now point directly to their owner contracts, four
pure facade delegates were removed, 182 schema/export tests passed, full export
bytes stayed exact, and bounded review was clean.

Next candidate:
After this boundary, audit the single CandidateDiff source-window-lineage
pipeline and remaining communications report delegates before selecting another
cohesive family.

Blocked:
No.
