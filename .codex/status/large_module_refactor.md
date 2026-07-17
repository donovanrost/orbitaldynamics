# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Provider-counteroffer-report callback collapse.

Status:
Selected; implementation pending.

Selected slice:
Make `ProviderCounterofferReportContracts` direct through shared primitive,
stable-ID, collection, and aggregation owners plus local report models/numeric
reducers; leave the larger summary owner's callback boundary unchanged.

Why this slice:
Live inventory leaves `schema.ex` at 11,300 lines. This 272-line report owner
and its two callers route only static/shared work through a 28-entry bag that is
also used by the distinct summary owner. The report can become direct without
expanding or destabilizing that larger summary slice.

Public facade to preserve:
`OrbitalDynamics.Schema.validate_artifact/2`, provider-counteroffer report/row
fields, exact paths/messages/order, derived counts, consumers, deterministic
artifacts, and schema exports.

Likely files:
- `lib/orbital_dynamics/schema.ex`
- `lib/orbital_dynamics/schema/provider_counteroffer_report_contracts.ex`
- `.codex/status/large_module_refactor.md`

Likely verification:
- compile with warnings as errors
- focused provider-counteroffer and schema tests
- broader candidate-refresh/operator-review regression
- schema export trio and checked-in export regeneration
- compile-connected xref, format, diff hygiene, and bounded review

Definition of done:
No callback lookup/apply remains in the report owner; shared ownership and local
aggregation preserve exact behavior; focused, broader, and export checks pass;
and bounded review finds no blocker.

Outcome:
Pending.

Verification gaps:
- Full repository suite not run.
- The 1,345-test broader batch has the same five known campaign-planner baseline
  failures previously reproduced on pre-slice commit `6f1f0ac1`; the
  attributable result is 1,340/1,340.

Last completed slice:
Direct-helper equality-message restoration published as `0bbcd32d`: eleven
owners again emit their historical implicit equality messages while explicit
messages and reachable nil behavior remain unchanged. Five hundred fifty-one
focused, 1,340 attributable broader, and 24 export tests passed; compile,
regeneration, xref, format, diff hygiene, and bounded review were clean.

Blocked:
No.
