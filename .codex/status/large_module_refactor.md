# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
ContactAllocation contact-validation extraction.

Status:
Completed and pushed in `6d894840`.

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
- Added
  `OrbitalDynamics.Communications.ContactAllocation.ContactValidation` as the
  owner of contact eligibility, provider inference, status blocking, identity
  and unit-interval validation, and invalid-reason precedence.
- Preserved ContactAllocation and root public APIs as allocation, report, and
  summary delegates.
- Kept row evidence projection in the facade while routing shared status,
  completion, and feedback-factor values through the validation owner.
- `communications/contact_allocation.ex` moved from 1,953 to 1,804 lines; the
  new owner is 205 lines.

Verification:
- Strict focused baseline passed all 70 ContactAllocation tests.
- Exact old/new public parity passed for four deterministic captures: inferred
  provider downlink allocation, invalid-input reason coverage, terminal and
  approval status blocking, and status-blocked allocation summary.
- Post-extraction focused and adjacent verification passed all 86 tests.
- Static checks confirm the detailed validation helper family left the facade
  and is owned by ContactValidation; xref reports only ContactAllocation as a
  runtime caller.
- Strict warning-clean forced compile passed for 3,998 files.
- Formatting and `git diff --check` passed.

Behavior/schema changes:
None intended.

Last completed slice:
ContactAllocation contact-validation extraction, selected in `325980b5` and
implemented in `6d894840`.
`communications/contact_allocation.ex` moved from 1,953 to 1,804 lines; the
dedicated ContactValidation owner is 205 lines.

Next candidate:
Re-rank the live checkout and select the next bounded facade-preserving
extraction. `timeline_feedback.ex` is now the largest ordinary eligible facade
at 1,948 lines, followed by OperationalReadiness and StationCalendar.

Blocked:
No.
