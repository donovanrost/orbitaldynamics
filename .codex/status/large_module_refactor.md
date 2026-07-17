# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema specialized quality-gate-summary JSON property-dispatch extraction.

Status:
Selected.

Selected slice:
Extract property dispatch for operational quality-gate unavailable-resource,
operator-training, schema-validation, and import-readiness summaries from
`OrbitalDynamics.Schema` into one internal specialized quality-gate dispatcher.

Why this slice:
The four adjacent clauses share the same model-limit/stable-identity dependency
shape, retain explicit module/model-limit pairs, and have focused operational
readiness coverage. The general quality-gate summary, execution boundary, and
runtime behavior remain out of scope.

Public facade to preserve:
All `OrbitalDynamics.Schema` public functions, exact JSON Schema maps and
validators for the four specialized quality-gate contracts, bundle ordering,
and checked-in schema bytes.

Likely files:
- `lib/orbital_dynamics/schema.ex`
- new specialized quality-gate-summary property-dispatch module
- `.codex/status/large_module_refactor.md`

Likely verification:
- focused operational/readiness contract tests
- JSON schema export tests
- schema export task tests
- full checked-in export regeneration and aggregate digest comparison
- compile, format, xref, diff hygiene, and bounded review

Definition of done:
The four facade clauses become one guarded delegate to the internal
dispatcher; runtime schemas, validators, bundle ordering, and checked-in
exports remain exact; focused and export tests pass; and bounded review finds
no blocker.

Outcome:
Pending.

Verification gaps:
- Pending.

Last completed slice:
Schema optimizer-report property dispatch published as `3c7967da`: ranking and
Pareto reports now route through one cohesive internal dispatcher, 24
focused/export tests passed, full regeneration was byte-identical, and bounded
review found no blocker.

Next candidate:
Audit one adjacent multi-contract operational/readiness property family after
this slice is published. Leave the general summaries/reports in the facade
unless a broader cohesive boundary emerges.

Blocked:
No.
