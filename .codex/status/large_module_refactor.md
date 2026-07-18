# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema candidate-refresh family property-dispatch extraction.

Status:
Slice selected; selection publication pending.

Selected slice:
Move JSON-property dispatch/context assembly for candidate-diff report,
candidate-diff row/invalidated-candidate/source-window-lineage, and the four
auxiliary refresh-state reports into an internal
`Schema.CandidateRefreshPropertyDispatch` owner.

Why this slice:
`Schema` is 7,766 lines. Three adjacent clauses route eight cohesive
candidate-refresh artifacts, while the neighboring campaign artifact family
already delegates.

Current coupling/problem:
The facade owns contract-name-sensitive predicates and named lazy contexts for
diff lineage/rows/invalidations, scoped context properties, model limits, and
auxiliary refresh-state reports.

Public facade to preserve:
All `Schema` APIs; all eight JSON Schema documents; checked-in exports,
deterministic ordering, contract-sensitive focused fallback behavior, lazy
evaluation order, and all errors.

Likely files:
- `lib/orbital_dynamics/schema.ex`
- `lib/orbital_dynamics/schema/candidate_refresh_property_dispatch.ex`
- `.codex/status/large_module_refactor.md`

Definition of done:
The three clauses pass compact dependencies to the new owner; named contexts
and focused fallback routing move out of `Schema`; focused candidate-refresh
and export tests pass; strict compile, full byte-clean schema regeneration, and
independent review are clean.

Verification gaps:
- Focused baseline, strict compile, export proof, and independent review remain.

Tests run:
- None yet for this selected slice.

Behavior/schema changes:
None intended.

Last completed slice:
Planning-analysis schema dispatch published as implementation `01f7840e` and
handoff `d4076cca`: focused 29/29, strict 3,660-file compile, full byte-clean
schema regeneration, and independent review passed.

Next candidate:
After this slice, remap the remaining direct property clauses in `Schema`,
including the distant main candidate-refresh contract.

Blocked:
No.
