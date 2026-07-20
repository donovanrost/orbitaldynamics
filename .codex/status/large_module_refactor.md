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
Completed the existing `OrbitalDynamics.Schema.ContactReportValidation`
extraction by routing contract clauses and callback tables directly to that
owner and removing five facade pass-through wrappers.
Preserved all `OrbitalDynamics.Schema` public facades and validation output.

Selection evidence:
- `schema.ex` remains the dominant hotspot at 6,622 lines.
- Contact filter/contention validation already has a focused owner, but the
  facade retains five pure one-hop wrappers referenced by contract clauses and
  campaign/candidate callback tables.
- The selected code has one responsibility: route contact-filter reports and
  optional contention/resolution reports to the existing owner.
- Callback-table composition, contact-allocation validation, other
  artifact-family validation, JSON Schema generation, and all public routing
  remain outside the boundary.
- Exact issue ordering, paths, messages, malformed-input behavior, callback
  wiring, public validation results, and schema exports must remain unchanged.

Implementation:
- Routed the contact-filter contract clause plus campaign-plan, campaign-repair,
  and candidate-refresh callback tables directly to
  `ContactReportValidation`.
- Removed five one-hop private wrappers covering optional contact-filter,
  contention, and contention-resolution reports.
- `schema.ex` moved from 6,622 to 6,612 lines; no new abstraction was added
  because the focused owner already existed.

Verification:
- Pre-change strict focused baseline: 31 campaign/contact contract tests
  passed.
- Post-change strict focused verification: the same 31 tests passed; 12
  broader validation, contention-fixture, and campaign-fixture tests also
  passed.
- Static checks found no migrated contact-report wrappers or local callback
  captures remaining; xref reports `schema.ex` as the runtime caller of
  `ContactReportValidation`.
- No checked-in schema export changed.
- Forced warnings-as-errors compile passed across 4,050 files.
- Formatting and `git diff --check` passed; the worktree was clean after the
  implementation commit.

Behavior/schema changes:
None intended.

Last completed slice:
Schema contact-report validation routing cleanup, selected in `b947a636` and
implemented in `f318e290`.
`schema.ex` moved from 6,622 to 6,612 lines by completing routing to the
existing ContactReportValidation owner.

Next candidate:
Re-rank the remaining schema wrapper clusters. Resource validation retains a
larger set of pure pass-through wrappers around an existing focused owner.

Blocked:
No.
