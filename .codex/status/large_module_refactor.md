# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Study.Manifest realized-activity input-schema extraction.

Status:
Selected; implementation not started.

Selected boundary:
Extract the complete embedded realized-activity input JSON Schema into
`OrbitalDynamics.Study.Manifest.RealizedActivitySchema`. Preserve the existing
public Manifest schema and loader facade.

Selection evidence:
- Live re-ranking places `study/manifest.ex` at 4,008 lines, ahead of
  ContactAllocation and TimelineFeedback and behind the three larger
  orchestration-heavy facades.
- The selected 175-line builder is one embedded artifact-input contract with
  no runtime parsing or semantic-validation responsibility.
- Its property and embedded-value dependencies now have dedicated owners, so
  the extraction introduces no duplicated schema primitives.
- Public schema/export APIs, operational-feedback composition, and all runtime
  loader behavior remain in the facade.
- Existing public report APIs and artifact row shapes remain unchanged.

Verification:
Pending.

Behavior/schema changes:
None. This is a facade-preserving production ownership extraction.

Last completed slice:
Study.Manifest reusable value-schema ownership extraction, selected in
`b8f1453e` and implemented in `e796c533`.
`study/manifest.ex` moved from 4,039 to 4,008 lines; the dedicated owner is 37
lines.

Next candidate:
Implement and verify the selected Study.Manifest realized-activity
input-schema extraction.

Blocked:
No.
