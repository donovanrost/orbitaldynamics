# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
TimelineFeedback artifact-value extraction.

Status:
Selected; implementation not started.

Selected boundary:
Extract recursive artifact key/value stringification, scalar stringification,
boolean interpretation, non-empty string checks, nil-map compaction, and
optional artifact-field insertion into
`OrbitalDynamics.TimelineFeedback.ArtifactValue`. Preserve the existing private
normalization and map-assembly seams in the TimelineFeedback facade.

Selection evidence:
- Live re-ranking places `timeline_feedback.ex` at 4,563 lines.
- The selected 4,489 and 4,501-4,562 helper family is module-attribute-free
  artifact value normalization used throughout row and report assembly.
- Identity normalization, numeric/throughput interpretation, success-factor
  policy, and public report APIs remain with their existing owners or facade.
- Keeping compaction and optional insertion together preserves the report's
  nil/empty-list omission semantics in one artifact-value owner.

Verification:
Pending.

Behavior/schema changes:
None. This is a facade-preserving production ownership extraction.

Last completed slice:
TimelineFeedback throughput extraction, selected in `5a8f2b1b` and implemented
in `14cd441c`. `timeline_feedback.ex` moved from 4,766 to 4,563 lines; the
dedicated owner is 221 lines.

Next candidate:
Implement and verify the selected TimelineFeedback artifact-value extraction.

Blocked:
No.
