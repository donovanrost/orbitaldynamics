# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
ResourceProjection station-capacity evidence extraction.

Status:
Selected; strict focused baseline pending.

Selected boundary:
Extract station-capacity fraction/percent path contracts, capability metadata,
capacity scaling, source station-calendar capacity selection, and resolved
station-calendar entry/provider identifiers into
`OrbitalDynamics.ResourceProjection.StationCapacityEvidence`. Preserve all
ResourceProjection and root public facades.

Selection evidence:
- Excluding the generated/declarative candidate-refresh JSON-schema module,
  live re-ranking places `resource_projection.ex` at 1,981 lines, the largest
  ordinary eligible facade.
- ResourceProjection already delegates to eight focused owners, but six
  station/source path contracts remain inline at lines 137-215 and their
  resolver family occupies lines 1,766-1,890.
- The resolver has one responsibility: derive contact capacity scaling and
  station-calendar entry/provider identity from direct, allocation, entry, and
  overlap evidence.
- Activity normalization, resource flow arithmetic, delivery evidence,
  approval policy, margins, pressure classification, summaries, and all other
  capability contracts remain outside the boundary.
- Exact path ordering, unit metadata, first-valid-source precedence, percent
  conversion, capacity clamping/defaults, stable-id filtering, flow rows,
  reports, summaries, and error behavior must remain unchanged.

Implementation:
Pending.

Verification:
Pending strict focused baseline, exact old/new public parity, focused and
adjacent tests, static ownership checks, xref, strict warning-clean compile,
formatting, and diff checks.

Behavior/schema changes:
None intended.

Last completed slice:
TimelineFeedback station-capacity contract consolidation, selected in
`efa062e9` and implemented in `99d57227`.
`timeline_feedback.ex` moved from 1,993 to 1,948 lines; the existing
StationCalendarContext owner moved from 241 to 269 lines.

Next candidate:
Complete the selected ResourceProjection station-capacity evidence extraction.

Blocked:
No.
