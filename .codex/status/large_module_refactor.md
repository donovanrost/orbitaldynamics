# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema priority-field evidence callback ownership cleanup.

Status:
Completed and published.

Selected slice:
Point the contact-allocation and operator-review priority-field evidence
callbacks directly at
`Schema.PriorityOverrideContracts.validate_field_evidence_counts/3`. Remove the
two duplicate private facade clauses.

Why this slice:
The two self-contained clauses validate only priority-field evidence maps and
serve two independent consumers. The existing priority-override owner already
contains the exact guarded and fallback implementation, so direct captures
remove duplicate validation ownership without changing callback shapes.

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
Both callback captures point to the established priority-override owner, the
duplicate facade clauses are gone, map iteration and error ordering remain
exact, validation and schema exports remain byte-for-byte stable, focused tests
pass, and bounded review finds no blocker.

Verification gaps:
- None for this slice.

Tests run:
- `mix compile --warnings-as-errors`
- 10 focused contact-allocation and operator-review tests
- 182 complete schema-contract and schema-export tests
- full checked-in schema export regeneration; no schema diff
- aggregate schema bundle digest unchanged:
  `757bb20af70443e376085ef2e6f97e5a0a0a8ee97323b5911343e88cd8b9ad15`
- `mix format --check-formatted`
- `git diff --check`
- compile-connected xref check for `schema.ex`
- bounded read-only review of the corrected established-owner diff: clean, no
  findings

Outcome:
Both priority-field evidence callbacks now point directly to
`PriorityOverrideContracts`. The duplicate facade clauses are gone, both bag
orders remain exact, no duplicate owner module was added, and `schema.ex`
decreased from 8,043 to 8,028 lines.

Behavior/schema changes:
None.

Last completed slice:
Schema priority-field evidence callback ownership cleanup published as
`4df5f3eb`: both callback bags now reuse the established priority-override
owner, duplicate facade clauses were removed, 182 schema/export tests passed,
full export bytes stayed exact, and bounded review was clean.

Next candidate:
Point the remaining contact-allocation priority-override count callback directly
at `PriorityOverrideContracts.validate_count_matches_ids/5` and remove the pure
guarded facade delegate. Then reassess whether the isolated CandidateDiff
lineage pipe justifies a slice or Schema should yield to another hotspot.

Blocked:
No.
