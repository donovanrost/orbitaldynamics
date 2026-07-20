# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema candidate-rejection model-limit ownership.

Status:
Completed and pushed.

Selected boundary:
Move the candidate-rejection report model-limit values from the Schema facade
into `OrbitalDynamics.Schema.CandidateRejectionReportJsonSchema`.
Route report property dispatch plus required/optional report validation
directly to that owner.
Keep row/source schema construction, validation algorithms, registry context,
and all public facades in their current modules.

Selection evidence:
- `schema.ex` remains the dominant hotspot at 6,123 lines.
- The four-value constant feeds exactly one
  CandidateRejectionReportJsonSchema property callback and two executable
  report-validation paths.
- The report schema already interprets and emits these model limits, making it
  the cohesive shared owner for construction and validation metadata.
- Exact model-limit values and ordering, callback timing, generated JSON
  Schema, validation results, and checked-in exports must remain unchanged.

Implementation:
Moved the four candidate-rejection report model-limit values into
CandidateRejectionReportJsonSchema and routed the property-dispatch callback
plus required/optional report validation directly to that owner.
`schema.ex` moved from 6,123 to 6,114 lines; the report schema owner moved from
274 to 283 lines.

Verification:
- Strict focused candidate-refresh/Cadence-row/export baseline before move:
  27 passed.
- The same strict focused suite after move: 27 passed.
- Strict full schema-export task plus adjacent Cadence-import,
  operator-review, fixture-visibility, and validation coverage: 10 passed.
- `mix xref callers
  OrbitalDynamics.Schema.CandidateRejectionReportJsonSchema` reports the
  expected `schema.ex` and TimelineReportPropertyDispatch callers.
- Static search confirms the facade model-limit function and all three
  indirect consumers are gone.
- `git diff --check` passed; no checked-in schema export changed.
- Strict forced compile passed across 4,065 files.
- Implementation commit `bd871a8c` pushed to `main`.

Behavior/schema changes:
None. Public facades, callback timing, model-limit values and ordering,
generated JSON Schema, validation behavior, and checked-in exports remain
unchanged.

Last completed slice:
Schema candidate-rejection model-limit ownership, selected in `86e3c44c` and
implemented in `bd871a8c`.
`schema.ex` moved from 6,123 to 6,114 lines; the candidate-rejection report
schema owner moved from 274 to 283 lines.

Next candidate:
Re-rank the remaining non-capability Schema responsibility clusters now that
direct domain capability reads have been removed from the facade.

Blocked:
No.
