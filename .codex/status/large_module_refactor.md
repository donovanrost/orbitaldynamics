# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema timeline-report JSON property-dispatch extraction.

Status:
Published.

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
The three facade clauses are now one guarded delegate to
`OrbitalDynamics.Schema.TimelineReportPropertyDispatch`. The internal
dispatcher preserves contract-to-module routing, focused-field selection,
operational and diff row callbacks, shared model-limit/capability callbacks,
stable identity dependencies, and the common-property fallback. The facade is
9,615 lines; the new dispatcher is 59 lines. Implementation published as
`39a16f36`.

Verification gaps:
- `mix compile --warnings-as-errors` passed.
- 49 focused operational-timeline, timeline-report, timeline-summary, JSON
  export, schema export, and export-task tests passed.
- Full checked-in export regeneration remained byte-identical at aggregate
  digest `95051be82cec8a75634e4e8712dadd102888f59998d2c26ebe7c36065d824d3b`.
- Scoped format, diff hygiene, and xref checks passed; xref reports only the
  expected runtime caller from `OrbitalDynamics.Schema`.
- Bounded read-only review found no blocker or follow-up finding.
- None for this slice.

Last completed slice:
Schema timeline-report property dispatch published as `39a16f36`: operational
timeline report, timeline-diff report, and timeline-diff summary now route
through one cohesive internal dispatcher, 49 focused/export tests passed, full
regeneration was byte-identical, and bounded review found no blocker.

Next candidate:
Extract the three adjacent station-reservation review, hold, and hold
import-readiness summary property clauses into one internal reservation-summary
dispatcher. Preserve the review/hold shared row callback, import-readiness row
callback, shared calendar model limits/stable identity, common fallback, and
exact exports. Leave station reservation/calendar reports and provider clauses
in the facade.

Blocked:
No.
