# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Station-calendar contact-count message restoration.

Status:
Complete and ready to publish.

Selected slice:
Restore the implicit `must equal N` message in
`StationCalendarContactCountContracts` after its direct-helper collapse.

Why this slice:
Verification exposed a concrete behavior regression: mismatched station-calendar
contact counts now emit a nil message. The pre-collapse Schema `/5` wrapper
synthesized `must equal N`, while the direct primitive `/5` helper does not.

Public facade to preserve:
`OrbitalDynamics.Schema.validate_artifact/2`, station-calendar count/list
consistency, exact paths/messages/order, all report consumers, deterministic
artifacts, and schema exports.

Likely files:
- `lib/orbital_dynamics/schema/station_calendar_contact_count_contracts.ex`
- `.codex/status/large_module_refactor.md`

Likely verification:
- compile with warnings as errors
- focused contact-allocation, contact-intent, and station-calendar tests
- broader schema validation regression
- schema export trio and checked-in export regeneration
- compile-connected xref, format, diff hygiene, and bounded review

Definition of done:
All three count/list mismatch paths again emit their historical `must equal N`
messages; focused, broader, and export checks pass; and bounded review finds no
blocker.

Outcome:
`StationCalendarContactCountContracts` now imports the primitive `/6` helper and
restores the historical private `/5` compatibility clauses. All three count/list
mismatches again emit exact `must equal N` messages, including the previously
failing overlap-count case. Five hundred eleven focused/schema/operator and 24
export tests pass; compile, checked-in regeneration, compile-connected xref
within its existing three-edge threshold, format, and diff hygiene are clean.
Bounded review found no blocker and confirmed exact pre-collapse messages, nil
handling, pair order, paths, and issue ordering.

Verification gaps:
- Full repository suite not run.
- The full 1,345-test campaign/operator/schema batch was not rerun for this
  message-only repair. Its prior run had five known campaign-planner baseline
  failures, previously reproduced on pre-slice commit `6f1f0ac1`.

Last completed slice:
Contact-allocation-handoff domain callback-bag collapse published as `811172aa`:
`schema.ex` fell from 11,309 to 11,300 lines and its owner from 936 to 911.
Priority-override validation became direct, duplicate-evidence validation stayed
explicit, and an inert expiration-summary callback argument disappeared. Three
hundred ninety-one attributable focused, 1,340 attributable broader, and 24
export tests passed; compile, regeneration, xref, format, diff hygiene, and
bounded review were clean.

Blocked:
No.
