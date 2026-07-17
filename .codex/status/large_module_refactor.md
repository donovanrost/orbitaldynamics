# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema contact-contention JSON property-dispatch extraction.

Status:
Selected.

Selected slice:
Extract property dispatch for contact-contention report, resolution report,
and resolution summary from `OrbitalDynamics.Schema` into one internal
contact-contention dispatcher.

Why this slice:
The three adjacent clauses duplicate the same contract-sensitive
`ContactContentionJsonSchema` predicate and complete context, and have focused
communications contract coverage. Objective reports and contention runtime
behavior remain out of scope.

Public facade to preserve:
All `OrbitalDynamics.Schema` public functions, exact JSON Schema maps and
validators for the three contact-contention contracts, bundle ordering,
and checked-in schema bytes.

Likely files:
- `lib/orbital_dynamics/schema.ex`
- new contact-contention property-dispatch module
- `.codex/status/large_module_refactor.md`

Likely verification:
- focused communications contract tests
- JSON schema export tests
- schema export task tests
- full checked-in export regeneration and aggregate digest comparison
- compile, format, xref, diff hygiene, and bounded review

Definition of done:
The three facade clauses become one guarded delegate to the internal
dispatcher; runtime schemas, validators, bundle ordering, and checked-in
exports remain exact; focused and export tests pass; and bounded review finds
no blocker.

Outcome:
Pending.

Verification gaps:
- Pending.

Last completed slice:
Schema resource-projection property dispatch published as `b452fa83`: report
and flow summary now route through one cohesive internal dispatcher, 28
focused/export tests passed, full regeneration was byte-identical, and bounded
review found no blocker.

Next candidate:
Audit one adjacent multi-contract report/property family after this slice is
published. Leave single-contract neighbors in the facade unless a broader
cohesive boundary emerges.

Blocked:
No.
