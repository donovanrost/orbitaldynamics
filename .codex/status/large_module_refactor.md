# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema filter-report JSON property-dispatch extraction.

Status:
Review complete; ready to publish.

Selected slice:
Extract property dispatch for contact-filter and resource-filter reports from
`OrbitalDynamics.Schema` into one internal filter-report dispatcher.

Why this slice:
The two adjacent report clauses share stable identity and suppressed-candidate
schema dependencies, retain explicit family-specific assumptions/model limits,
and have focused filter-report coverage. Allocation summaries, resource
projection, and filter runtime behavior remain out of scope.

Public facade to preserve:
All `OrbitalDynamics.Schema` public functions, exact JSON Schema maps and
validators for the two filter-report contracts, bundle ordering,
and checked-in schema bytes.

Likely files:
- `lib/orbital_dynamics/schema.ex`
- new filter-report property-dispatch module
- `.codex/status/large_module_refactor.md`

Likely verification:
- focused filter-report contract tests
- JSON schema export tests
- schema export task tests
- full checked-in export regeneration and aggregate digest comparison
- compile, format, xref, diff hygiene, and bounded review

Definition of done:
The two facade clauses become one guarded delegate to the internal
dispatcher; runtime schemas, validators, bundle ordering, and checked-in
exports remain exact; focused and export tests pass; and bounded review finds
no blocker.

Outcome:
The two facade clauses are now one guarded delegate to
`OrbitalDynamics.Schema.FilterReportPropertyDispatch`. The dispatcher preserves
contract-to-module routing, focused-field selection, shared stable-identity and
suppressed-candidate callbacks, distinct model-limit/assumptions callbacks,
contact-only trust-boundary schema wiring, and the common fallback. The facade
is 9,507 lines; the new dispatcher is 46 lines.

Verification gaps:
- `mix compile --warnings-as-errors` passed.
- 23 focused filter-report, JSON export, schema export, and export-task tests
  passed.
- Full checked-in export regeneration remained byte-identical at aggregate
  digest `95051be82cec8a75634e4e8712dadd102888f59998d2c26ebe7c36065d824d3b`.
- Scoped format, diff hygiene, and xref checks passed; xref reports only the
  expected runtime caller from `OrbitalDynamics.Schema`.
- Bounded read-only review found no blocker or follow-up finding.

Last completed slice:
Schema contact-allocation-summary property dispatch published as `9f68e87c`:
the five summary contracts now route through one cohesive internal dispatcher,
31 focused/export tests passed, full regeneration was byte-identical, and
bounded review found no blocker.

Next candidate:
Audit one adjacent multi-contract report/property family after this slice is
published. Leave single-contract neighbors in the facade unless a broader
cohesive boundary emerges.

Blocked:
No.
