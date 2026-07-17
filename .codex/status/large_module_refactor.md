# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema communications-report validation ownership cleanup.

Status:
Completed and verified; publishing.

Selected slice:
Point link-capacity report validation, contact-contention report validation,
contention-resolution report validation, and resolution-policy validation
directly at their owner contracts. Remove four pure facade delegates across six
positions while preserving the optional nil/type fallback clauses.

Why this slice:
The owners already expose exact `/3` validators. The report helpers only
forward arguments from direct contract heads and optional-map clauses, while
the policy helper only forwards the injected callback. Optional nil and invalid
type behavior remains facade-owned and unchanged.

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
All six selected positions call their communications report owners directly,
the four pure facade delegates are gone, optional fallbacks and positional
policy callback ordering remain exact, validation and schema exports remain
byte-for-byte stable, focused tests pass, and bounded review finds no blocker.

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
All six communications report positions now call their owners directly. Four
pure facade delegates were removed, optional nil/type fallbacks remain exact,
and `schema.ex` decreased from 8,077 to 8,051 lines.

Behavior/schema changes:
None.

Last completed slice:
Schema communications-summary validation ownership cleanup published as
`9f22157d`: both contract heads now call their summary owners directly, two pure
facade delegates were removed, 182 schema/export tests passed, full export
bytes stayed exact, and bounded review was clean.

Next candidate:
After this boundary, audit the remaining CandidateDiff source-window-lineage
pipeline and communications deferred-priority callback before selecting another
owner family.

Blocked:
No.
