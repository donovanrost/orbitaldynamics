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
Made `OrbitalDynamics.Schema.SourceEvidenceValidation` authoritative for
freshness/schema-validation status enums, route JSON Schema evidence builders
and callback tables through that owner, and remove six facade helpers.
Preserved all `OrbitalDynamics.Schema` public facades, JSON Schema output, and
validation behavior.

Selection evidence:
- `schema.ex` remains the dominant hotspot at 6,580 lines.
- Source-evidence validation already has a focused owner, but freshness and
  schema-validation enums remain private in the facade while four callback
  wrappers split validation routing across both modules.
- The selected code has one responsibility: own source-evidence status enums
  and validate source fields plus freshness/schema/execution status matches.
- JSON Schema evidence builders continue to receive the exact same enum
  values. Callback-table composition, other
  artifact-family validation, JSON Schema generation, and all public routing
  remain outside the boundary.
- Exact enum ordering, issue ordering, paths, messages, callback wiring,
  public validation results, and schema exports must remain unchanged.

Implementation:
- Added ordered freshness and schema-validation status APIs plus three-argument
  status-validation entry points to `SourceEvidenceValidation`.
- Routed freshness/schema JSON Schema evidence builders and three callback
  tables directly to the owner.
- Removed two facade status-enum helpers and four one-hop validation wrappers.
- `schema.ex` moved from 6,580 to 6,558 lines; the focused owner is 58 lines.

Verification:
- Pre-change strict focused baseline: 22 Cadence/operator-review/JSON-export
  contract tests passed.
- Post-change strict focused verification: the same 22 tests passed; the full
  schema-export task test and 8 broader validation/readiness/resource fixture
  tests also passed.
- Static checks found no migrated source-evidence enum/validation helpers or
  local callback captures remaining; xref reports `schema.ex` as the runtime
  caller of `SourceEvidenceValidation`.
- No checked-in schema export changed.
- Forced warnings-as-errors compile passed across 4,050 files.
- Formatting and `git diff --check` passed; the worktree was clean after the
  implementation commit.

Behavior/schema changes:
None intended.

Last completed slice:
Schema source-evidence validation/status routing cleanup, selected in
`bbb7ebe4` and implemented in `8a124313`.
`schema.ex` moved from 6,580 to 6,558 lines by consolidating status enums and
validation routing in SourceEvidenceValidation.

Next candidate:
Re-rank the remaining schema responsibility clusters while preserving
dependency-injecting adapters.

Blocked:
No.
