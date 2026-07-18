# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Timeline activity-observation evidence context extraction.

Status:
Complete and published.

Selected boundary:
Move observation-quality and observation-lighting context construction into
one dedicated evidence module. Keep two private Timeline facades for their
three coordinator consumers and route scalar, numeric, number-or-scalar, and
compaction dependencies directly. Remove the shared
`first_number_or_scalar/2` Timeline facade because strict compile confirmed the
lighting builder owned its only remaining caller.

Selection evidence:
- Quality owns score/status/source plus cloud-cover and blur aliases.
- Lighting owns eclipse fraction/duration, condition/detail/model/detail-model
  aliases, and numeric-or-label confidence.
- Quality has one valid-context consumer; lighting has operational-row and
  valid-context consumers.
- The initial strict compile proved `first_number_or_scalar/2` became unused
  after the move; repo search confirmed no other Timeline caller.
- Direct existing policies satisfy the boundary without Timeline callbacks.
- The extraction should materially reduce the current 5,554-line Timeline.
- Product, orientation, thermal, resource, link, broad context coordination,
  public API, and schema remain outside the boundary.

Verification:
- Selection published in `ca3f14a2`; corrected helper ownership published in
  `ff38e55c`; implementation published in `c290eabc`.
- Focused baseline and post-change observation/lighting coverage: 3 passed.
- Strict warnings-as-errors compile: 3,794 files compiled.
- Full Timeline suite: 127 passed.
- Operational Timeline schema contracts: 36 passed.
- Canonical AST comparison: both extracted builders equivalent.
- Static checks confirmed unchanged public API, exactly two private facades,
  expected one/two consumer counts, Timeline-only module ownership, no
  temporary checker, and clean diff.
- Independent review: clean, with no production-code findings.
- Timeline is 5,512 lines; the extracted module is 69 lines.

Behavior/schema changes:
None intended. No schema-generation boundary is selected, so export
regeneration should not be required.

Last completed slice:
Timeline activity-observation evidence context extraction, selected in
`ca3f14a2`, corrected in `ff38e55c`, and implemented in `c290eabc`.

Next candidate:
Continue remapping the reduced Timeline facade.

Blocked:
No.
