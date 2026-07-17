# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema validation-evidence JSON property-dispatch extraction.

Status:
Selected.

Selected slice:
Extract property dispatch for validation reference fixture reports, validation
reference reports, validation records, and validation checks from
`OrbitalDynamics.Schema` into one internal validation-evidence dispatcher.

Why this slice:
The four adjacent clauses share `ValidationJsonSchema`, stable validation
contracts, and one focused contract-test family. Moving their dispatch and
dependency wiring together creates a real family boundary without mixing model
acceptance, schema reports, migration, or executable validation behavior.

Public facade to preserve:
All `OrbitalDynamics.Schema` public functions, exact JSON Schema maps for the
four validation-evidence contracts, executable validation behavior, bundle
ordering, and checked-in schema bytes.

Likely files:
- `lib/orbital_dynamics/schema.ex`
- new validation-evidence property-dispatch module
- `.codex/status/large_module_refactor.md`

Likely verification:
- focused validation-evidence and JSON export tests
- schema export task tests
- full checked-in export regeneration and aggregate digest comparison
- compile, format, xref, diff hygiene, and bounded review

Definition of done:
The four facade clauses delegate to the internal dispatcher; runtime schemas,
validators, bundle ordering, and checked-in exports remain exact; focused and
export tests pass; and bounded review finds no blocker.

Outcome:
Pending.

Verification gaps:
- Pending.

Last completed slice:
Candidate timeline activity-state replay callback removal published as
`b86fc6a1`: all five paths are one-argument end to end, 36 focused tests
passed, and bounded review found no blocker. No facade callback transport
remains.

Next candidate:
Extend the property-dispatch extraction to one adjacent validation contract
family after this slice is published.

Blocked:
No.
