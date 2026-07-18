# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Timeline activity operational-hint context extraction.

Status:
Selected; implementation has not started.

Selected boundary:
Move activity operational-hint context construction and direct-value/template
fallback resolution into one dedicated module. Keep private Timeline facades
for the context builder and the three operational-row value consumers, and
route field lookup, numeric/boolean conversion, template provenance, and
compaction directly through existing policies. Remove the shared
`first_present_value/2` and `boolean_value/1` Timeline facades because strict
compile confirmed the moved fallback logic owned their only remaining callers.

Selection evidence:
- The boundary owns setup/cooldown duration plus telemetry-confirmation
  requirement/status resolution.
- Direct activity or metadata values retain precedence over normalized activity
  template operational hints.
- The context builder has one valid-context consumer; the three value helpers
  also serve the operational-row builder.
- The initial strict compile proved `first_present_value/2` and
  `boolean_value/1` became unused after the move; repo search confirmed no other
  Timeline callers.
- Direct existing policies satisfy the boundary without Timeline callbacks.
- The extraction should materially reduce the current 5,467-line Timeline while
  preserving all four private coordinator seams.
- Activity-template normalization, timing, command windows, lifecycle
  decisions, broad context coordination, public API, and schema remain outside
  the boundary.

Verification:
Pending: focused baseline, implementation, strict compile, focused/full tests,
contracts, structural/static checks, and independent review.

Behavior/schema changes:
None intended. No schema-generation boundary is selected, so export
regeneration should not be required.

Last completed slice:
Timeline activity feedback context extraction, selected in `328db40e`,
corrected in `cf067a38`, and implemented in `615428bf`.

Next candidate:
Continue remapping the reduced Timeline facade.

Blocked:
No.
