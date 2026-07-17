# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema provider-counteroffer JSON property-dispatch extraction.

Status:
Selected.

Selected slice:
Extract property dispatch for provider-counteroffer report, review summary,
import-readiness summary, and plan-impact summary from
`OrbitalDynamics.Schema` into one internal provider-counteroffer dispatcher.

Why this slice:
The four adjacent clauses share one provider-counteroffer row schema,
StationCalendar capability data, stable identity dependencies, and focused
provider-counteroffer contract coverage. Maneuver recommendation, candidate
rejection, and provider-counteroffer runtime behavior remain out of scope.

Public facade to preserve:
All `OrbitalDynamics.Schema` public functions, exact JSON Schema maps and
validators for the four provider-counteroffer contracts, bundle ordering, and
checked-in schema bytes.

Likely files:
- `lib/orbital_dynamics/schema.ex`
- new provider-counteroffer property-dispatch module
- `.codex/status/large_module_refactor.md`

Likely verification:
- focused provider-counteroffer contract tests
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
Schema model-capability property dispatch published as `84444b3a`: the three
environment/provider/subsystem capability contracts now route through one
cohesive internal dispatcher, 29 focused/export tests passed, full regeneration
was byte-identical, and bounded review found no blocker.

Next candidate:
Audit one adjacent multi-contract report/property family after this slice is
published. Leave single-contract neighbors in the facade unless a broader
cohesive boundary emerges.

Blocked:
No.
