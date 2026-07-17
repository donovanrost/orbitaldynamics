# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema station-calendar-provider callback ownership handoff.

Status:
Published as `40c2471f`.

Selected slice:
Point the standalone `station_calendar_provider.v1` contract pipe directly at
`Schema.StationCalendarProviderContracts.validate/3`. Remove the pure facade
delegate while preserving its final pipeline position and issue ordering.

Why this slice:
`Schema` remains a named 7,934-line production hotspot. The established owner
exposes the exact `/3` implementation, and the facade delegate has exactly one
caller.

Current coupling/problem:
Standalone provider validation still routes through a private facade callback
even though `StationCalendarProviderContracts` owns the implementation.

Public facade to preserve:
All `OrbitalDynamics.Schema` public functions, exact validation issue ordering,
paths and messages, JSON Schema output, checked-in export bytes, and station
calendar provider behavior.

Likely extraction target:
Existing `OrbitalDynamics.Schema.StationCalendarProviderContracts.validate/3`.

Likely files:
- `lib/orbital_dynamics/schema.ex`
- `.codex/status/large_module_refactor.md`

Likely verification:
- exact final pipe position, arguments, and delegate-removal proof
- focused station-provider contract tests
- complete schema-contract/export tests and full checked-in export regeneration
- generated and checked-in bundle digests
- strict compile, format, xref, diff hygiene, and bounded review

Definition of done:
The provider pipe retains `require_fields` and calls the established owner in
the same final position, the pure facade delegate is gone, issue ordering and
messages remain exact, schema bytes do not change, focused and complete tests
pass, and bounded review finds no blocker.

Verification gaps:
None.

Tests run:
- Source baseline: `validate_station_calendar_provider/3` appears exactly once
  as the final standalone pipe call after `require_fields` and once as its pure
  facade definition; the owner exposes the exact `validate/3` implementation.
- Focused `station_provider_contracts_test.exs` baseline: 6 tests passed with
  warnings as errors.
- Generated 121-schema bundle JSON byte digest:
  `543dbe11bc75f1397dd15dbd10cabd219ae2e46ac1e16d38b810a99befb8cec3`
  across 15,506,740 bytes.
- Checked-in `schemas/orbital_dynamics.schema_bundle.v1.json` digest:
  `757bb20af70443e376085ef2e6f97e5a0a0a8ee97323b5911343e88cd8b9ad15`.
- Source proof against selection commit `a49f0c4f`: the provider pipe retains
  `require_fields` and now ends at
  `StationCalendarProviderContracts.validate/3`; the private facade delegate is
  absent.
- Focused `station_provider_contracts_test.exs`: 6 tests passed with warnings as
  errors.
- Complete schema-contract and schema-export suite: 182 tests passed with
  warnings as errors.
- Generated bundle remains exactly 121 schemas, 15,506,740 bytes, and digest
  `543dbe11bc75f1397dd15dbd10cabd219ae2e46ac1e16d38b810a99befb8cec3`.
- Full checked-in schema export regeneration completed with no schema diff;
  aggregate bundle digest remains
  `757bb20af70443e376085ef2e6f97e5a0a0a8ee97323b5911343e88cd8b9ad15`.
- Strict test compile, `mix format --check-formatted`, `git diff --check`, and
  xref caller checks passed. An initial focused-test launch raced the forced
  compile; the compile completed cleanly and the focused test passed when
  rerun sequentially.
- Independent bounded review against selection commit `a49f0c4f` was clean:
  exact pipeline arguments and position, unchanged provider owner, delegate
  removal, sequential 6 focused and 182 complete tests, generated and checked
  bundle digests, all 122 exports byte-matched, strict compile, xref,
  formatting, sizes, ledger, and diff hygiene matched the recorded evidence.

Behavior/schema changes:
None.

Outcome:
The provider pipe now references its established owner directly and the pure
facade delegate is gone. `schema.ex` decreased from 7,934 to 7,926 lines.

Last completed slice:
Contact-intent wrapper cleanup published as `6ba7ee63`: one pipe and two
callback bags now point directly at the established owner, `schema.ex` shrank
from 7,942 to 7,934 lines, 11 focused and 182 complete tests passed, all 122
exports byte-matched, and bounded review was clean.

Next candidate:
Map the single-use `validate_candidate_activity/3` facade delegate. Its only
caller is the final stage of the standalone `candidate_activity.v1` pipe after
`require_fields`, and its established owner exposes the exact
`CandidateActivityContracts.validate/3` implementation. Capture focused
candidate-activity behavior and schema-byte baselines before replacing it.

Blocked:
No.
