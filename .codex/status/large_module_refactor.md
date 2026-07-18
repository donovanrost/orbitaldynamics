# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Timeline activity feedback context extraction.

Status:
Selected; implementation has not started.

Selected boundary:
Move activity feedback context construction into one dedicated module. Keep a
private Timeline facade for its single valid-context consumer, pass the
existing provider-result map key list explicitly, and route boolean, provider
result, numeric, scalar, and compaction dependencies directly through existing
policies. Remove the shared `first_provider_result_string/2` Timeline facade
because strict compile confirmed the feedback builder owned its only remaining
caller.

Selection evidence:
- The builder owns success, result, success-factor, and factor-source evidence
  for contact, command, observation, and maneuver outcomes plus feedback weight
  and source.
- It has exactly one consumer in valid activity-context assembly.
- Passing the existing provider-result key list preserves one configuration
  owner and avoids duplicating normalization knowledge.
- The initial strict compile proved `first_provider_result_string/2` became
  unused after the move; repo search confirmed no other Timeline caller.
- Direct existing policies satisfy the boundary without Timeline callbacks.
- The extraction should reduce the current 5,496-line Timeline while preserving
  the private coordinator seam.
- Provider outcome validation, diff semantics, command windows, lifecycle
  decisions, broad context coordination, public API, and schema remain outside
  the boundary.

Verification:
Pending: focused baseline, implementation, strict compile, focused/full tests,
contracts, structural/static checks, and independent review.

Behavior/schema changes:
None intended. No schema-generation boundary is selected, so export
regeneration should not be required.

Last completed slice:
Timeline activity command-authority context extraction, selected in
`bb108bcc` and implemented in `7a036142`.

Next candidate:
Continue remapping the reduced Timeline facade.

Blocked:
No.
