# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema operational readiness gate-summary JSON property-dispatch extraction.

Status:
Selected.

Selected slice:
Extract property dispatch for operational import-eligibility, readiness-gate,
and execution-boundary summaries from `OrbitalDynamics.Schema` into one
internal operational readiness gate-summary dispatcher.

Why this slice:
The three summary contracts share the operational-readiness capability,
operational gate schema, and contract-specific model-limit dependency core.
Readiness-gate adds stable identity and execution-boundary adds string-array
schema, but both remain explicit contract dependencies. General quality-gate
and report contracts have separate row/evidence responsibilities and stay out
of scope.

Public facade to preserve:
All `OrbitalDynamics.Schema` public functions, exact JSON Schema maps and
validators for the three operational gate-summary contracts, bundle ordering,
and checked-in schema bytes.

Likely files:
- `lib/orbital_dynamics/schema.ex`
- new operational readiness gate-summary property-dispatch module
- `.codex/status/large_module_refactor.md`

Likely verification:
- focused operational contract tests
- JSON schema export tests
- schema export task tests
- full checked-in export regeneration and aggregate digest comparison
- compile, format, xref, diff hygiene, and bounded review

Definition of done:
The three facade clauses become one guarded delegate to the internal gate
summary dispatcher; runtime schemas, validators, bundle ordering, and
checked-in exports remain exact; focused and export tests pass; and bounded
review finds no blocker.

Outcome:
Pending.

Verification gaps:
- Pending.

Last completed slice:
Schema specialized quality-gate-summary property dispatch published as
`89329531`: unavailable-resource, operator-training, schema-validation, and
import-readiness summaries now route through one cohesive internal dispatcher,
33 focused/export tests passed, full regeneration was byte-identical, and
bounded review found no finding.

Next candidate:
After this slice, audit the general operational quality-gate summary,
operational readiness report, and quality-gate report clauses as a possible
row/evidence report family. Keep them separate unless one explicit cohesive
boundary emerges.

Blocked:
No.
