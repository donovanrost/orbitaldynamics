# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema realized-state-snapshot callback ownership mapping.

Status:
Ready for implementation.

Selected slice:
Point both facade uses of `validate_realized_state_snapshot/3` directly at
`Schema.RealizedStateSnapshotContracts.validate/3`: the standalone final pipe
and campaign-repair callback capture. Remove the pure wrapper.

Why this slice:
`Schema` remains a 7,902-line hotspot. The established owner exposes exact `/3`
behavior, with two bounded runtime uses and one pure wrapper.

Public facade to preserve:
All Schema public APIs, callback key/order, exact issue ordering and messages,
JSON Schema output, checked-in export bytes, and snapshot behavior.

Definition of done:
The standalone pipe retains `require_fields`; the repair callback key remains
between `expect_one_of` and `validate_rows`; both reference the owner; the
wrapper is gone; focused/full tests, exports, and review remain exact.

Verification gaps:
- Implementation and post-change verification pending.

Tests run:
- Source baseline: one standalone final pipe, one repair callback capture, and
  one pure wrapper definition.
- Focused contact-feedback plus repair/strategy baseline: 7 tests passed with
  warnings as errors.
- Generated bundle: 121 schemas, 15,506,740 bytes, digest
  `543dbe11bc75f1397dd15dbd10cabd219ae2e46ac1e16d38b810a99befb8cec3`.
- Checked bundle digest:
  `757bb20af70443e376085ef2e6f97e5a0a0a8ee97323b5911343e88cd8b9ad15`.

Behavior/schema changes:
None.

Outcome:
No realized-state-snapshot implementation has started.

Last completed slice:
Realized-activity cleanup published as `b0eac99e`: `schema.ex` shrank from 7,910
to 7,902 lines, 5 focused and 182 complete tests passed, all 122 exports
byte-matched, and bounded review was clean.

Next candidate:
Implement both direct owner substitutions and remove the wrapper.

Blocked:
No.
