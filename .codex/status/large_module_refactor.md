# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Direct-helper equality-message restoration.

Status:
Complete and ready to publish.

Selected slice:
Restore implicit `must equal value` messages in the eleven remaining owners
whose callback collapses replaced Schema's message-synthesizing `/5` wrapper
with the primitive nil-message `/5` helper.

Why this slice:
A post-repair audit found the same exact compatibility hazard in approval,
candidate-diff/rejection, manifest, lint, Pareto, optimizer, realized-state,
policy-decision, migration, and validation-report owners. Their pre-collapse
trampolines all targeted Schema's message-synthesizing `/5` callback.

Public facade to preserve:
`OrbitalDynamics.Schema.validate_artifact/2`, all affected artifact fields,
exact paths/messages/order, consumers, deterministic artifacts, and schema
exports.

Likely files:
- eleven affected `lib/orbital_dynamics/schema/*_contracts.ex` owners
- `.codex/status/large_module_refactor.md`

Likely verification:
- compile with warnings as errors
- focused affected artifact/schema tests
- broader schema validation and operator-review regression
- schema export trio and checked-in export regeneration
- compile-connected xref, format, diff hygiene, and bounded review

Definition of done:
Every affected implicit equality mismatch again emits its historical default
message while explicit-message calls remain unchanged; focused, broader, and
export checks pass; and bounded review finds no blocker.

Outcome:
All eleven owners now import primitive `/6` and restore a private historical
`/5` compatibility shim; the eight owners with reachable nil expectations also
retain the historical nil no-op clause. Explicit custom-message calls are
unchanged. Five hundred fifty-one focused, 1,340 attributable broader, and 24
export tests pass; compile, checked-in regeneration, compile-connected xref
within its existing three-edge threshold, format, and diff hygiene are clean.
Bounded review found no blocker and confirmed every pre-collapse callback
mapping, default/custom message, reachable nil case, path, and issue order.

Verification gaps:
- Full repository suite not run.
- The 1,345-test broader batch has the same five known campaign-planner baseline
  failures previously reproduced on pre-slice commit `6f1f0ac1`; the
  attributable result is 1,340/1,340.

Last completed slice:
Station-calendar contact-count message restoration published as `7e6b3ae4`:
all three count/list mismatches again emit exact `must equal N` messages. Five
hundred eleven focused/schema/operator and 24 export tests passed; compile,
regeneration, xref, format, diff hygiene, and bounded review were clean.

Blocked:
No.
