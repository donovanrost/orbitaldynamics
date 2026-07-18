# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Timeline activity delivery-timing policy extraction.

Status:
Implementation published in `0154cab2`; focused and broad proof is green.

Selected boundary:
Move collection-end, planned/actual delivery, maximum latency, and
explicit-or-derived planned/actual latency selection into
`Timeline.ActivityDeliveryTimingPolicy`. `Timeline` retains six private entry
points; numeric field selection and delta calculation cross the boundary
explicitly.

Why this slice:
The extraction moved six exclusive clauses into a 61-line internal module.
Timeline retains six private entry points and is now 6,366 lines; the two-line
facade increase is the formatting cost of keeping numeric selection and delta
calculation explicit at the boundary. Alias order and explicit/derived
precedence now live together in the delivery-timing policy.

Completed proof:
- Focused numeric-context, latency-diff, and operational handoff examples:
  3 passed.
- Full Timeline suite: 127 passed.
- Timeline schema-contract suites: 36 passed.
- Strict warnings-as-errors compile: 3,753 files.
- Canonical AST equivalence: all six moved clauses after normalizing only
  public/private heads and numeric selector/delta callbacks.
- Format, whitespace, ownership, exactly-six-facade, unchanged Timeline public
  definitions, and xref checks passed; Timeline is the only runtime caller.
- Independent read-only review found no production-code findings.

Behavior/schema changes:
None intended. No schema-generation boundary is selected, so export
regeneration should not be required.

Last completed slice:
Timeline activity delivery-timing policy extraction, selected in `615501f8` and
implemented in `0154cab2`.

Next candidate:
Remap the 6,366-line Timeline facade after this slice, avoiding the wide
activity-to-map coordinator callback surface.

Blocked:
No.
