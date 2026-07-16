# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Operational-readiness-gate-summary callback-bag collapse.

Status:
Selected; implementation pending.

Selected slice:
Replace the 20-entry callback bag in
`OperationalReadinessGateSummaryContracts` with direct primitive, stable-ID,
collection, and readiness-classification owners, explicit model-limit data, one
facade-owned gate validator, and exact local default equality-message behavior.

Why this slice:
Live inventory shows `schema.ex` remains the dominant production hotspot at
12,194 lines. The 424-line readiness-gate-summary owner has 20 callback
trampolines; most target shared validators or readiness-classification/count
owners, one is model-limit data, and only nested readiness-gate validation
remains a facade boundary. Focused readiness, replay, review, and export
coverage is available.

Public facade to preserve:
`OrbitalDynamics.Schema.validate_artifact/2` and all readiness-gate summary
behavior, including classification/status derivation, gate totals and maps,
passed/non-passed IDs, assumptions, exact messages, model limits, deterministic
errors, replay consumers, and exports.

Likely extraction target:
Replace the opaque bag with explicit model-limit data plus the gate validator;
remove shared-helper trampolines, call exact shared/readiness owners directly,
and locally preserve the facade's nil/default equality-message clauses.

Likely files:
- `lib/orbital_dynamics/schema.ex`
- `lib/orbital_dynamics/schema/operational_readiness_gate_summary_contracts.ex`
- `.codex/status/large_module_refactor.md`

Likely tests:
- compile with warnings as errors
- operational-readiness and import-eligibility schema contracts
- focused candidate-refresh replay and operator-review consumers
- schema export trio and checked-in export/fingerprint verification
- broader communications/candidate-refresh checks, xref, format, and diff hygiene

Definition of done:
No readiness-gate-summary callback bag or shared-helper trampolines remain; direct
owners, explicit model data, and the gate-validator boundary preserve exact
validation order/messages; focused/broader/export checks pass; and bounded
review finds no blocker.

Verification gaps:
- Full repository suite not run.
- Known baseline: full contact-filter file remains 87/88 due nil-message
  behavior in `SuppressedCandidateContracts`; unrelated to the completed
  filter-count slice.

Last completed slice:
Operational-import-eligibility-summary callback collapse published as
`cd54b505`:
`schema.ex` fell from 12,216 to 12,194 lines and its owner from 259 to 202. The
17-entry bag became direct primitive/stable/collection/readiness owners,
explicit model-limit data, and one gate-validator boundary; all callback
trampolines were removed. 44 focused, 789 broader, and 22 export tests passed;
compile, xref, format, diff hygiene, and checked-in schema regeneration were
clean. Bounded review found no issues.

Blocked:
No.
