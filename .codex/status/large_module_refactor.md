# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
ContactContention contact/group identity extraction.

Status:
Selected; implementation pending.

Selected boundary:
Extract contact/spacecraft/stable-ID resolution, contact identity validation,
group station/spacecraft/stable-ID/direction projection, contact-ID failure
behavior, and canonical contact sorting into
`OrbitalDynamics.Communications.ContactContention.ContactIdentity`. Centralize
the advertised stable identity fields with that owner. Preserve all public
ContactContention report, resolution, and summary facades.

Selection evidence:
- Live re-ranking places `communications/contact_contention.ex` at 2,370
  lines, the largest eligible facade behind Schema, Timeline,
  MissionPlan.Activity, and the root public facade.
- The selected helper family spans lines 2,185-2,334 and exclusively owns
  contact identity, group identity, direction, and canonical sort semantics.
- Contention grouping, resolution, validation, capacity-demand, and summary
  construction consume this shared identity layer through private facade
  delegates.
- Candidate eligibility, contact normalization, timing/feedback/station
  context, scoring, approval policy, public clauses, and artifact contracts
  remain outside this boundary.
- Existing spacecraft/satellite/scenario precedence, nested identity
  precedence, ID fallback order, atom/integer normalization, stable-pattern
  validation, `nil` rejection, exact error text, group deduplication/sorting,
  mixed/default direction behavior, numeric-zero sort fallback, full tuple
  order, and capability metadata must remain unchanged.

Implementation:
- Pending.

Verification:
- Pending focused baseline, strict compilation, exact old/new public parity,
  focused and adjacent tests, static ownership checks, and xref review.

Behavior/schema changes:
None intended.

Last completed slice:
OperationalReadiness operator-training evidence extraction, selected in
`0a2611d2` and implemented in `7d28b490`.
`operational_readiness.ex` moved from 2,385 to 2,276 lines; the dedicated
operator-training evidence owner is 131 lines.

Next candidate:
Complete and verify the selected ContactContention contact/group identity
extraction.

Blocked:
No.
