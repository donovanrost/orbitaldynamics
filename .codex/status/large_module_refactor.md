# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema resource-projection JSON property-dispatch extraction.

Status:
Review complete; ready to publish.

Selected slice:
Extract property dispatch for resource-projection report and
resource-projection flow summary from `OrbitalDynamics.Schema` into one
internal resource-projection dispatcher.

Why this slice:
The two adjacent clauses share stable identity, model-limit, and assumptions
dependencies while retaining explicit report/summary row paths and focused
resource contract coverage. Filter reports, contention, and projection runtime
behavior remain out of scope.

Public facade to preserve:
All `OrbitalDynamics.Schema` public functions, exact JSON Schema maps and
validators for the two resource-projection contracts, bundle ordering,
and checked-in schema bytes.

Likely files:
- `lib/orbital_dynamics/schema.ex`
- new resource-projection property-dispatch module
- `.codex/status/large_module_refactor.md`

Likely verification:
- focused resource contract tests
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
`OrbitalDynamics.Schema.ResourceProjectionPropertyDispatch`. The dispatcher
preserves contract-to-module routing, focused-field selection, shared
stable-identity/model-limit/assumptions callbacks, report-only models and
projection-row callbacks, flow-summary-only activity-flow-row callback, and
the common fallback. The facade is 9,499 lines; the new dispatcher is 46 lines.

Verification gaps:
- `mix compile --warnings-as-errors` passed.
- 28 focused resource, JSON export, schema export, and export-task tests passed.
- Full checked-in export regeneration remained byte-identical at aggregate
  digest `95051be82cec8a75634e4e8712dadd102888f59998d2c26ebe7c36065d824d3b`.
- Scoped format, diff hygiene, and xref checks passed; xref reports only the
  expected runtime caller from `OrbitalDynamics.Schema`.
- Bounded read-only review found no blocker or follow-up finding.

Last completed slice:
Schema filter-report property dispatch published as `6646d27e`: contact and
resource filter reports now route through one cohesive internal dispatcher, 23
focused/export tests passed, full regeneration was byte-identical, and bounded
review found no blocker.

Next candidate:
Audit one adjacent multi-contract report/property family after this slice is
published. Leave single-contract neighbors in the facade unless a broader
cohesive boundary emerges.

Blocked:
No.
