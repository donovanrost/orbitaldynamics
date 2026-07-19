# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
ContactAllocation contact-validation extraction.

Status:
Selected; strict focused baseline pending.

Selected boundary:
Extract contact eligibility, provider-contact detection, terminal/approval
blocking, stable identity/time/station checks, completion and feedback-factor
unit-interval validation, station-capacity validation, and deterministic
invalid-input reasons into
`OrbitalDynamics.Communications.ContactAllocation.ContactValidation`. Preserve
all ContactAllocation and root public facades.

Selection evidence:
- Excluding the generated/declarative candidate-refresh JSON-schema module,
  live re-ranking places `communications/contact_allocation.ex` at 1,953 lines,
  the largest ordinary eligible facade.
- ContactAllocation already delegates to eight focused owners, including
  ContactIdentity, ContactNormalization, StationCapacityEvidence, and
  ThroughputEvidence, while validation still occupies lines 1,546-1,790.
- The selected block has one responsibility: decide whether a normalized
  contact is eligible, status-blocked, or invalid and explain the exact reason.
- Allocation composition, ground-network filtering, contention resolution,
  row construction, capacity packing, counteroffers, approval policy, summary
  generation, and all capability contracts remain outside the boundary.
- Exact provider-contact inference, precedence of invalid reasons, terminal
  status handling, station-capacity policy, unit-interval semantics, returned
  rows/reports/summaries, and error behavior must remain unchanged.

Implementation:
Pending.

Verification:
Pending strict focused baseline, exact old/new public parity, focused and
adjacent tests, static ownership checks, xref, strict warning-clean compile,
formatting, and diff checks.

Behavior/schema changes:
None intended.

Last completed slice:
ResourceFilter candidate-input extraction, selected in `a2a84802` and
implemented in `a1b248fa`.
`resource_filter.ex` moved from 1,964 to 1,542 lines; the dedicated
CandidateInput owner is 477 lines.

Next candidate:
Complete the selected ContactAllocation contact-validation extraction.

Blocked:
No.
