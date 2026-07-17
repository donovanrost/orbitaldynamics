# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema quality-gate report JSON property-dispatch extraction.

Status:
Selected.

Selected slice:
Extract property dispatch for the operational quality-gate summary and
quality-gate report from `OrbitalDynamics.Schema` into one internal
quality-gate report dispatcher.

Why this slice:
Both contracts share the operational-readiness capability, quality-gate row
schema, stable identity, and contract-specific model-limit dependency shape.
The operational readiness report uses gate/evidence schemas instead and stays
out of scope.

Public facade to preserve:
All `OrbitalDynamics.Schema` public functions, exact JSON Schema maps and
validators for the two quality-gate contracts, bundle ordering, and checked-in
schema bytes.

Likely files:
- `lib/orbital_dynamics/schema.ex`
- new quality-gate report property-dispatch module
- `.codex/status/large_module_refactor.md`

Likely verification:
- focused operational contract tests
- JSON schema export tests
- schema export task tests
- full checked-in export regeneration and aggregate digest comparison
- compile, format, xref, diff hygiene, and bounded review

Definition of done:
The two facade clauses become one guarded delegate to the internal quality-gate
dispatcher; runtime schemas, validators, bundle ordering, and checked-in exports
remain exact; focused and export tests pass; and bounded review finds no
blocker.

Outcome:
Pending.

Verification gaps:
- Pending.

Last completed slice:
Schema operational readiness gate-summary property dispatch published as
`ae307679`: import-eligibility, readiness-gate, and execution-boundary summaries
now route through one cohesive internal dispatcher, 30 focused/export tests
passed, full regeneration was byte-identical, and bounded review found no
finding.

Next candidate:
After this slice, re-audit the remaining facade property clauses and pivot only
to another explicit multi-contract responsibility cluster. Leave the standalone
operational readiness report in the facade.

Blocked:
No.
