# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema planning-analysis property-dispatch extraction.

Status:
Slice selected; selection publication pending.

Selected slice:
Move JSON-property dispatch/context assembly for score-term report,
resource-filter summary, and constraint report into an internal
`Schema.PlanningAnalysisPropertyDispatch` owner.

Why this slice:
`Schema` is 7,766 lines. These three adjacent planning-analysis reports still
assemble their focused contexts in the facade, between delegated optimizer and
operational-summary families.

Current coupling/problem:
The facade owns eager score/constraint model, limit, and row construction plus
resource-filter contract/source/pattern and lazy model/row helpers.

Public facade to preserve:
All `Schema` APIs; the three JSON Schema documents; checked-in exports,
deterministic ordering, focused fallback behavior, eager/lazy evaluation order,
and all errors.

Likely files:
- `lib/orbital_dynamics/schema.ex`
- `lib/orbital_dynamics/schema/planning_analysis_property_dispatch.ex`
- `.codex/status/large_module_refactor.md`

Definition of done:
The three clauses pass compact dependencies to the new owner; named contexts
and focused fallback routing move out of `Schema`; focused optimizer/resource/
scoring/export tests pass; strict compile, full byte-clean schema regeneration,
and independent review are clean.

Verification gaps:
- Focused baseline, strict compile, export proof, and independent review remain.

Tests run:
- None yet for this selected slice.

Behavior/schema changes:
None intended.

Last completed slice:
Operational handoff schema dispatch published as implementation `d7a69831` and
handoff `ad557151`: focused 24/24, strict 3,659-file compile, full byte-clean
schema regeneration, and independent review passed.

Next candidate:
After this slice, remap the remaining direct property clauses in `Schema`.

Blocked:
No.
