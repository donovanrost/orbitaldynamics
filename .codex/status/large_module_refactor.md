# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema provider-counteroffer JSON property-dispatch extraction.

Status:
Published.

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
The four facade clauses are now one guarded delegate to
`OrbitalDynamics.Schema.ProviderCounterofferPropertyDispatch`. The internal
dispatcher preserves contract-to-module routing, focused-field selection,
private row/model callbacks, lazy StationCalendar capability lookups, stable
identity dependencies, and the common-property fallback. The facade is 9,636
lines; the new dispatcher is 84 lines. Implementation published as `4693ca67`.

Verification gaps:
- `mix compile --warnings-as-errors` passed.
- 23 focused provider-counteroffer, JSON export, schema export, and export-task
  tests passed.
- Full checked-in export regeneration remained byte-identical at aggregate
  digest `95051be82cec8a75634e4e8712dadd102888f59998d2c26ebe7c36065d824d3b`.
- Scoped format, diff hygiene, and xref checks passed; xref reports only the
  expected runtime caller from `OrbitalDynamics.Schema`.
- Bounded read-only review found no blocker or follow-up finding.
- None for this slice.

Last completed slice:
Schema provider-counteroffer property dispatch published as `4693ca67`: the
report, review, import-readiness, and plan-impact contracts now route through
one cohesive internal dispatcher, 23 focused/export tests passed, full
regeneration was byte-identical, and bounded review found no blocker.

Next candidate:
Extract the three adjacent operational-timeline report, timeline-diff report,
and timeline-diff summary property clauses into one internal timeline-report
dispatcher. Preserve each row schema, shared model-limit/capability callbacks,
stable identity dependency, common fallback, validators, and exact exports.
Leave candidate-rejection and lifecycle-state clauses in the facade.

Blocked:
No.
