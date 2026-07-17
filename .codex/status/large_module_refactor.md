# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema communications-summary validation ownership cleanup.

Status:
Ready for implementation.

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
- Implementation and verification pending.

Tests run:
- Selection only; implementation verification pending.

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
