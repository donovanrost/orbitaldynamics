# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema timeline-report JSON property-dispatch extraction.

Status:
Selected.

Selected slice:
Extract property dispatch for operational-timeline report, timeline-diff
report, and timeline-diff summary from `OrbitalDynamics.Schema` into one
internal timeline-report dispatcher.

Why this slice:
The three adjacent clauses share timeline model limits, capability and stable
identity dependencies, paired diff row handling, and focused timeline contract
coverage. Candidate rejection, lifecycle state, and timeline runtime behavior
remain out of scope.

Public facade to preserve:
All `OrbitalDynamics.Schema` public functions, exact JSON Schema maps and
validators for the three timeline-report contracts, bundle ordering, and
checked-in schema bytes.

Likely files:
- `lib/orbital_dynamics/schema.ex`
- new timeline-report property-dispatch module
- `.codex/status/large_module_refactor.md`

Likely verification:
- focused operational-timeline, timeline-report, and timeline-summary tests
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
Schema provider-counteroffer property dispatch published as `4693ca67`: the
report, review, import-readiness, and plan-impact contracts now route through
one cohesive internal dispatcher, 23 focused/export tests passed, full
regeneration was byte-identical, and bounded review found no blocker.

Next candidate:
Audit one adjacent multi-contract timeline property family after this slice is
published. Leave single-contract neighbors in the facade unless a broader
cohesive boundary emerges.

Blocked:
No.
