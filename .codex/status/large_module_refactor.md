# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
ContactAllocation contact identity extraction.

Status:
Selected; implementation not started.

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
Pending.

Behavior/schema changes:
None. This is a facade-preserving production ownership extraction.

Last completed slice:
ContactAllocation contact-normalization extraction, selected in `233ec122` and
implemented in `08172144`. `communications/contact_allocation.ex` moved from
4,522 to 4,296 lines; the dedicated owner is 269 lines.

Next candidate:
Implement and verify the selected ContactAllocation contact identity
extraction.

Blocked:
No.
