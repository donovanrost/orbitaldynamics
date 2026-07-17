# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema handoff-field callback ownership cleanup.

Status:
Completed and published.

Selected slice:
Point observation-quality, feedback-maneuver, link, completion-fraction,
station-capacity, eclipse-lighting, thermal, and resource-availability callback
captures directly at `Schema.HandoffFieldContracts`. Remove the eight pure
facade delegates across twenty-three callback positions.

Why this slice:
All eight owner APIs already expose the exact three-argument validation
pipelines. Their facade functions only forward arguments, while the twenty-three
captures span three stable callback bags without specialized facade behavior.
The contact-allocation evidence path remains separate because it still depends
on facade-owned domain callbacks.

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
All twenty-three selected captures point directly to `HandoffFieldContracts`,
the eight pure facade delegates are gone, callback list positions and issue
ordering remain exact, validation and schema exports remain byte-for-byte
stable, focused tests pass, and bounded review finds no blocker.

Verification gaps:
- None for this slice.

Tests run:
- `mix compile --warnings-as-errors`
- 107 focused cadence-import, review-import, and operator-review tests
- 182 complete schema-contract and schema-export tests
- full checked-in schema export regeneration; no schema diff
- aggregate schema bundle digest unchanged:
  `757bb20af70443e376085ef2e6f97e5a0a0a8ee97323b5911343e88cd8b9ad15`
- `mix format --check-formatted`
- `git diff --check`
- compile-connected xref check for `schema.ex`
- bounded read-only review: clean, no findings

Outcome:
All twenty-three selected captures now point directly to
`HandoffFieldContracts`. Eight pure facade delegates were removed across the
three callback bags, whose key order remains exact, and `schema.ex` decreased
from 8,210 to 8,166 lines.

Behavior/schema changes:
None.

Last completed slice:
Schema handoff-field callback ownership cleanup published as `0f51bf28`:
twenty-three captures now point directly to `HandoffFieldContracts`, eight pure
facade delegates were removed, 182 schema/export tests passed, full export
bytes stayed exact, and bounded review was clean.

Next candidate:
Point four candidate-diff families directly at `CandidateDiffContracts`:
semantic details (three captures), changed fields (three), optional source
window (five), and optional lineage (three). Remove the four pure facade
delegates while preserving the existing four-argument field callbacks.

Blocked:
No.
