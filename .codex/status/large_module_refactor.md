# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema station-calendar contact-count callback ownership mapping.

Status:
Ready for implementation.

Selected slice:
Point the final `validate_station_calendar_contact_counts` domain callback
directly at `Schema.StationCalendarContactCountContracts.validate/3` and remove
the pure wrapper.

Why this slice:
`Schema` remains a 7,805-line hotspot. Structural mapping confirms one final
callback capture and one pure exact-signature delegate.

Public facade to preserve:
All Schema APIs, contact-allocation callback key/order, exact issues/messages,
JSON Schema and checked exports, and station-calendar count behavior.

Definition of done:
The key remains the final domain callback after priority override count
matching, captures the established owner, wrapper is absent, and all
focused/full/schema proof and review remains exact.

Verification gaps:
- Implementation and post-change verification pending.

Tests run:
- Source baseline: one final domain callback capture and one pure delegate.
- Focused contact-allocation baseline: 8 tests passed with warnings as errors.
- Generated bundle: 121 schemas, 15,506,740 bytes, digest
  `543dbe11bc75f1397dd15dbd10cabd219ae2e46ac1e16d38b810a99befb8cec3`.
- Checked bundle digest:
  `757bb20af70443e376085ef2e6f97e5a0a0a8ee97323b5911343e88cd8b9ad15`.

Behavior/schema changes:
None.

Outcome:
No station-calendar contact-count implementation has started.

Last completed slice:
Timeline-integrity-evidence cleanup published as `4895d94e`: `schema.ex` shrank
from 7,813 to 7,805 lines, focused 10 and complete 182 tests passed, all 122
exports byte-matched, and review was clean.

Next candidate:
Implement the direct capture and remove the wrapper.

Blocked:
No.
