# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
ContactAllocation contact identity extraction.

Status:
Completed and pushed in `ed1e1cbd`.

Selected boundary:
Extract contact ID resolution and validation, spacecraft identity resolution,
declared stable-identity validation, station-calendar identity selection,
stable ID/number list normalization, reservation-expiry selection, and derived
calendar counts into
`OrbitalDynamics.Communications.ContactAllocation.ContactIdentity`. Preserve
the existing private identity/calendar seams in the facade while moving
`@stable_id_pattern` to its single owner.

Selection evidence:
- Live re-ranking places `contact_allocation.ex` at 4,296 lines.
- The selected 3,970-4,210 helper family shares one stable-ID policy across
  scalar contact identity and station-calendar collection forms.
- The advertised stable identity field list remains facade-owned capability
  policy and will be passed only to declared-field validation.
- Generic numeric parsing remains in the facade and is reused for calendar
  number lists and reservation expiry selection.
- Allocation, contact normalization, contention, capacity, reservation,
  summary, and public report APIs remain in their existing owners or facade.

Verification:
- Strict warnings-as-errors compile passed across 3,888 files.
- Focused ContactAllocation coverage passed: 70 tests.
- Adjacent operator-review, schema-contract, and allocation-fixture coverage
  passed: 24 tests.
- Exact old/new public artifact comparison against `452b1c23` passed for 18
  scalar ID, nested spacecraft, provider/calendar ID, mixed ID-list,
  number-list, reservation-expiry, and invalid-identity cases plus 5 aggregate
  summary artifacts.
- Runtime xref found the new owner referenced only by ContactAllocation;
  static review confirmed the stable-ID regex has one owner and numeric parsing
  is callback-reused, and `git diff --check` passed.
- `communications/contact_allocation.ex` moved from 4,296 to 4,127 lines; the
  dedicated owner is 243 lines.

Behavior/schema changes:
None. This is a facade-preserving production ownership extraction.

Last completed slice:
ContactAllocation contact-identity extraction, selected in `452b1c23` and
implemented in `ed1e1cbd`. `communications/contact_allocation.ex` moved from
4,296 to 4,127 lines; the dedicated owner is 243 lines.

Next candidate:
Re-rank all remaining hotspots after the ContactAllocation ingestion and
identity pass.

Blocked:
No.
