# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Timeline activity-observation evidence context extraction.

Status:
Selected; implementation has not started.

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
Pending: focused baseline, implementation, strict compile, focused/full tests,
contracts, structural/static checks, and independent review.

Behavior/schema changes:
None intended. No schema-generation boundary is selected, so export
regeneration should not be required.

Last completed slice:
Timeline activity-link context extraction, selected in `a47755aa`, implemented
in `37bd9f8e`, and handed off in `eaa14e36`.

Next candidate:
Continue remapping the reduced Timeline facade.

Blocked:
No.
