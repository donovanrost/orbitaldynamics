# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
ContactAllocation contact normalization extraction.

Status:
Completed and pushed in `08172144`.

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
- Strict warnings-as-errors compile passed across 3,887 files.
- Focused ContactAllocation coverage passed: 70 tests.
- Adjacent operator-review, schema-contract, and allocation-fixture coverage
  passed: 24 tests.
- Exact old/new public artifact comparison against `233ec122` passed for 12
  station alias, source-window location, nested calendar status, time/type
  alias, provider direction, and invalid-shape cases plus 5 aggregate summary
  artifacts.
- Runtime xref found the new owner referenced only by ContactAllocation;
  static review preserved the three summary-facing status/direction seams as
  delegates to the same owner, and `git diff --check` passed.
- `communications/contact_allocation.ex` moved from 4,522 to 4,296 lines; the
  dedicated owner is 269 lines.

Behavior/schema changes:
None. This is a facade-preserving production ownership extraction.

Last completed slice:
ContactAllocation contact-normalization extraction, selected in `233ec122` and
implemented in `08172144`. `communications/contact_allocation.ex` moved from
4,522 to 4,296 lines; the dedicated owner is 269 lines.

Next candidate:
Re-inventory remaining ContactAllocation identity/calendar normalization and
switch focus if no cohesive facade-reducing boundary remains.

Blocked:
No.
