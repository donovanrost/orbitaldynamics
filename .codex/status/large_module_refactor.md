# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
ContactAllocation contact normalization extraction.

Status:
Selected; implementation not started.

Selected boundary:
Extract contact key normalization, station/source-window aliases, nested
station-calendar status canonicalization, contact time normalization, activity
type aliases, and provider direction normalization into
`OrbitalDynamics.Communications.ContactAllocation.ContactNormalization`.
Preserve the existing private `normalize_contact/1` seam and keep advertised
status/direction alias policy in the ContactAllocation facade.

Selection evidence:
- Live re-ranking places `contact_allocation.ex` at 4,522 lines; the larger
  Timeline facade is already dominated by delegates to existing owners.
- The selected 4,211-4,465 helper family is one contact ingestion pipeline
  called through a single private normalization seam.
- Provider direction aliases and unavailable-status aliases remain
  facade-owned capability policy and will be passed as one policy value.
- Allocation, contention, capacity, reservation, summary, and public report
  APIs remain in the facade.

Verification:
Pending.

Behavior/schema changes:
None. This is a facade-preserving production ownership extraction.

Last completed slice:
TimelineFeedback artifact-value extraction, selected in `ea208e1f` and
implemented in `ea349a21`. `timeline_feedback.ex` moved from 4,563 to 4,508
lines; the dedicated owner is 78 lines.

Next candidate:
Implement and verify the selected ContactAllocation contact normalization
extraction.

Blocked:
No.
