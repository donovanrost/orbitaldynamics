# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema strategy artifact property-dispatch extraction.

Status:
Slice selected; selection publication pending.

Selected slice:
Move JSON-property dispatch/context assembly for strategy branch, strategy
recommendation, branch-comparison report, and campaign strategy into an
internal `Schema.StrategyArtifactPropertyDispatch` owner.

Why this slice:
`Schema` is 7,755 lines. These four decision-support artifacts collectively
carry 18 context dependencies but still route directly through the facade.

Current coupling/problem:
The facade owns strategy event/risk/policy contexts, recommendation
tradeoff/explanation contexts, branch-comparison rows/limits, and campaign
strategy component routing across separated clauses.

Public facade to preserve:
All `Schema` APIs; the four JSON Schema documents; checked-in exports,
deterministic ordering, focused fallback behavior, lazy provider order, risk
closure behavior, and all errors.

Likely files:
- `lib/orbital_dynamics/schema.ex`
- `lib/orbital_dynamics/schema/strategy_artifact_property_dispatch.ex`
- `.codex/status/large_module_refactor.md`

Definition of done:
The four clauses pass compact dependencies to the new owner; named contexts and
focused fallback routing move out of `Schema`; focused strategy/optimizer/
policy/export tests pass; strict compile, full byte-clean schema regeneration,
and independent review are clean.

Verification gaps:
- Focused baseline, strict compile, export proof, and independent review remain.

Tests run:
- None yet for this selected slice.

Behavior/schema changes:
None intended.

Last completed slice:
Main candidate-refresh schema dispatch published as implementation `725a1184`
and handoff `692cbdda`: focused 26/26, strict 3,661-file compile, full
byte-clean schema regeneration, and independent review passed.

Next candidate:
After this slice, remap the remaining direct property clauses in `Schema`.

Blocked:
No.
