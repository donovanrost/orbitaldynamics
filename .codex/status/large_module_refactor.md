# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema contact-allocation-summary JSON property-dispatch extraction.

Status:
Published.

Selected slice:
Extract property dispatch for contact-allocation summary,
reservation-conflict summary, station-pressure summary, capacity-pack summary,
and provider-reservation-request summary from `OrbitalDynamics.Schema` into one
internal contact-allocation-summary dispatcher.

Why this slice:
The five adjacent summary clauses share schema-contract identity, stable IDs,
contact-allocation model limits, row semantics, and focused allocation
coverage. The broader contact-allocation report and runtime behavior remain out
of scope.

Public facade to preserve:
All `OrbitalDynamics.Schema` public functions, exact JSON Schema maps and
validators for the five contact-allocation summary contracts, bundle ordering,
and checked-in schema bytes.

Likely files:
- `lib/orbital_dynamics/schema.ex`
- new contact-allocation-summary property-dispatch module
- `.codex/status/large_module_refactor.md`

Likely verification:
- focused contact-allocation contract tests
- JSON schema export tests
- schema export task tests
- full checked-in export regeneration and aggregate digest comparison
- compile, format, xref, diff hygiene, and bounded review

Definition of done:
The five facade clauses become one guarded delegate to the internal
dispatcher; runtime schemas, validators, bundle ordering, and checked-in
exports remain exact; focused and export tests pass; and bounded review finds
no blocker.

Outcome:
The five facade clauses are now one guarded delegate to
`OrbitalDynamics.Schema.ContactAllocationSummaryPropertyDispatch`. The
dispatcher preserves contract-to-module routing, each schema-contract and
assumptions callback, shared model-limit/stable-identity/row dependencies,
base/capacity-pack group callbacks, focused-field selection, and the common
fallback. The facade is 9,517 lines; the new dispatcher is 87 lines.
Implementation published as `9f68e87c`.

Verification gaps:
- `mix compile --warnings-as-errors` passed.
- 31 focused contact-allocation, provider-reservation, JSON export, schema
  export, and export-task tests passed.
- Full checked-in export regeneration remained byte-identical at aggregate
  digest `95051be82cec8a75634e4e8712dadd102888f59998d2c26ebe7c36065d824d3b`.
- Scoped format, diff hygiene, and xref checks passed; xref reports only the
  expected runtime caller from `OrbitalDynamics.Schema`.
- Bounded read-only review found no blocker or follow-up finding.
- None for this slice.

Last completed slice:
Schema contact-allocation-summary property dispatch published as `9f68e87c`:
the five summary contracts now route through one cohesive internal dispatcher,
31 focused/export tests passed, full regeneration was byte-identical, and
bounded review found no blocker.

Next candidate:
Extract the adjacent contact-filter and resource-filter report property clauses
into one internal filter-report dispatcher. Preserve shared stable identity and
suppressed-candidate callbacks, distinct model-limit/assumptions callbacks,
contact-only trust-boundary count schema, common fallback, validators, and
exact exports. Leave allocation summaries and resource-projection clauses in
the facade.

Blocked:
No.
