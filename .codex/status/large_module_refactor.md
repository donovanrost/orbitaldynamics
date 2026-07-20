# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
No slice selected.

Status:
Slice complete and pushed.

Selected boundary:
Completed the resource-filter portion of the existing
`OrbitalDynamics.Schema.ResourceValidation` extraction by routing contract
clauses and callback tables directly to that owner and removing four facade
pass-through wrappers.
Preserved all `OrbitalDynamics.Schema` public facades and validation output.

Selection evidence:
- `schema.ex` remains the dominant hotspot at 6,612 lines.
- Resource-filter validation already has a focused owner, but the facade
  retains four pure one-hop wrappers referenced by report/summary contract
  clauses and campaign/candidate callback tables.
- The selected code has one responsibility: route optional/resource-filter
  reports, suppressed candidates, and invalid resource inputs to the owner.
- Resource-projection adapters remain in the facade because they inject policy
  and stable-ID callbacks. Callback-table composition, other
  artifact-family validation, JSON Schema generation, and all public routing
  remain outside the boundary.
- Exact issue ordering, paths, messages, malformed-input behavior, callback
  wiring, public validation results, and schema exports must remain unchanged.

Implementation:
- Routed resource-filter report/summary contract clauses plus campaign-plan and
  campaign-repair callback tables directly to `ResourceValidation`.
- Removed four one-hop private wrappers for optional/resource-filter reports,
  suppressed candidates, and invalid resource inputs.
- Preserved the resource-projection adapters that inject policy and stable-ID
  callbacks.
- `schema.ex` moved from 6,612 to 6,602 lines; no new abstraction was added
  because the focused owner already existed.

Verification:
- Pre-change strict focused baseline: 12 campaign/resource contract tests
  passed.
- Post-change strict focused verification: the same 12 tests passed; 10
  broader validation and resource/campaign fixture tests also passed.
- Static checks found no migrated resource-filter wrappers or local callback
  captures remaining; xref reports the expected runtime callers of
  `ResourceValidation`.
- No checked-in schema export changed.
- Forced warnings-as-errors compile passed across 4,050 files.
- Formatting and `git diff --check` passed; the worktree was clean after the
  implementation commit.

Behavior/schema changes:
None intended.

Last completed slice:
Schema resource-filter validation routing cleanup, selected in `6965e3b1` and
implemented in `db4ce31c`.
`schema.ex` moved from 6,612 to 6,602 lines by completing resource-filter
routing to the existing ResourceValidation owner.

Next candidate:
Re-rank the remaining schema wrapper clusters while preserving
dependency-injecting resource-projection adapters.

Blocked:
No.
