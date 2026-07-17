# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema communications-report validation ownership cleanup.

Status:
Ready for implementation.

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
- Implementation and verification pending.

Tests run:
- Selection only; implementation verification pending.

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
