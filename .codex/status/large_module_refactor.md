# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
OperationalReadiness adapter-boundary evidence extraction.

Status:
Selected; implementation pending.

Selected boundary:
Extract adapter-shaped context detection, nested trust-boundary collection,
trust-boundary token classification, and declared/missing/untrusted frequency
projection into
`OrbitalDynamics.OperationalReadiness.AdapterBoundaryEvidence`. Preserve all
public OperationalReadiness report and summary facades.

Selection evidence:
- Live re-ranking places `operational_readiness.ex` at 2,500 lines, the largest
  eligible facade behind Schema, Timeline, MissionPlan.Activity, and the root
  public facade.
- The selected helper family spans lines 2,202-2,319 and exclusively derives
  adapter trust-boundary status counts from the source artifact, review rows,
  and import rows.
- Readiness evidence construction is the single consumer of the classifier.
- Adapter gate decisions, generic count projection, other evidence families,
  report/summary construction, public clauses, and artifact contracts remain
  outside this boundary.
- Existing direct and nested adapter-key detection, blank-value rejection,
  trust-boundary precedence, missing/untrusted token matching, substring
  matching, duplicate counting, and empty-map behavior must remain unchanged.

Implementation:
- Pending.

Verification:
- Pending focused baseline, strict compilation, exact old/new public parity,
  focused and adjacent tests, static ownership checks, and xref review.

Behavior/schema changes:
None intended.

Last completed slice:
ResourceProjection pressure-risk projection extraction, selected in
`351c84ce` and implemented in `5dd9dd79`.
`resource_projection.ex` moved from 2,504 to 2,418 lines; the dedicated
pressure-risk owner is 91 lines.

Next candidate:
Complete and verify the selected OperationalReadiness adapter-boundary
evidence extraction.

Blocked:
No.
