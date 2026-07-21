# Autonomous Product Loop Status

Overall maturity target:
Level 6 mature operational-planning platform across library, LEO campaign
planning, and Cadence-facing operational-planning surfaces.

Current slice:
Apply exact resource-unavailable rows from canonical contact-allocation reports
to CandidateRefresh selection.

Status:
Implemented and verified; publish pending.

Why this slice:
`contact_allocation_report.v1` already exposes row-derived resource-blocked
contact IDs with spacecraft scope, but CandidateRefresh only turns
station-specific allocation reasons into ground-network selection state.
Resource-unavailable rows remain provenance/scoring evidence even when they
identify a regenerated contact exactly.

Level 6 pillar:
Refreshed candidates from current mission state and fleet-level contact/resource
behavior.

Behavior/evidence added:
- Canonical contact-allocation rows carrying nonempty
  `source_resource_suppression` evidence now filter regenerated contacts only
  when row-derived contact ID, spacecraft/scenario scope, blocked status, and
  resource blocking dimension are exact.
- Aggregate-only blocked-contact maps, stale allocated rows, and matching IDs
  scoped to another spacecraft do not affect selection.
- Direct and result-artifact-wrapped reports preserve report path/source,
  blocking dimension, spacecraft scope, and report/row/wrapper trust evidence.
- Rejected prior contacts receive
  `dropped_by_contact_allocation_unavailable_resource`; operator-review and
  Cadence-import handoffs remain schema-valid and review-only.
- Public capability metadata and CandidateRefresh docs describe the new
  row-derived selection boundary.

Verification:
- Focused cross-family and review/import handoff tests: 27 passed.
- Full CandidateRefresh suite: 761 passed.
- Capability catalog/schema registry tests: 15 passed.
- Full `mix test --timeout 180000`: 3,475 passed.
- Schema lint: 155 artifacts, zero errors/warnings.
- `mix format --check-formatted` and `git diff --check`: pass.

Parent review:
Complete. The parent verified the reused source resolver, row normalization,
wrapper trust inheritance, checked-in canonical row shape, aggregate-only
non-action, and source-family invalidation precedence. No must-fix findings
remain. Runtime policy disallows subagent delegation, so the parent performed
review and publish prep.

Previous published slice:
- `94b65d65` Add readiness selection challenge fixture (`3474 passed`).

Current publish:
- Commit pending.

Remaining maturity gaps:
- Continue direct resource/contact pressure use only for decision-safe signals.
- Continue branch-local realized-feedback depth and challenge fixtures.
- Continue deeper numerical/backend and resource-model maturity separately.

Blocked:
Not blocked. Runtime policy disallows subagent delegation, so the parent will
perform bounded review and publish handoff.
