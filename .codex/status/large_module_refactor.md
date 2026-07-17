# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema contact-allocation-summary JSON property-dispatch extraction.

Status:
Selected.

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
Pending.

Verification gaps:
- Pending.

Last completed slice:
Schema link-capacity property dispatch published as `163560ab`: report and
summary now route through one cohesive internal dispatcher, 34 focused/export
tests passed, full regeneration was byte-identical, and bounded review found no
blocker.

Next candidate:
Audit one adjacent multi-contract report/property family after this slice is
published. Leave the contact-allocation report in the facade unless a broader
cohesive boundary emerges.

Blocked:
No.
