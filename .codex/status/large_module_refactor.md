# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema candidate-rejection model-limit ownership.

Status:
Selected; implementation not started.

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
Pending.

Verification:
Pending.

Behavior/schema changes:
None intended.

Last completed slice:
Schema station-reservation model ownership, selected in `d94ecb41` and
implemented in `a94ebd9f`.
`schema.ex` moved from 6,131 to 6,123 lines; the station-reservation report
schema owner moved from 188 to 196 lines.

Next candidate:
Re-rank the remaining non-capability Schema responsibility clusters now that
direct domain capability reads have been removed from the facade.

Blocked:
No.
