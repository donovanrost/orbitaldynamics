# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Operational-execution-boundary-summary callback-bag collapse.

Status:
Completed and ready to publish.

Selected slice:
Replace the 18-entry callback bag in
`OperationalExecutionBoundarySummaryContracts` with direct primitive,
stable-ID, and readiness-classification owners, explicit model-limit data, one
facade-owned gate validator, and exact local execution-boundary/count/message
behavior.

Why this slice:
After the readiness-gate-summary cleanup, live inventory leaves `schema.ex` as
the dominant production hotspot at 12,163 lines. The adjacent 332-line
execution-boundary owner has 18 callback trampolines: shared validators and
classification functions can call exact owners, model limits are data, the
gate validator is the only facade dependency, and small boundary/count rules
can remain explicit and cohesive. Focused readiness, replay, review, and export
coverage is available.

Public facade to preserve:
`OrbitalDynamics.Schema.validate_artifact/2` and all execution-boundary summary
behavior, including readiness/status derivation, boundary and authority flags,
analysis-mode consistency, gate totals/IDs, assumptions, exact messages,
model limits, deterministic errors, replay consumers, and exports.

Likely files:
- `lib/orbital_dynamics/schema.ex`
- `lib/orbital_dynamics/schema/operational_execution_boundary_summary_contracts.ex`
- `.codex/status/large_module_refactor.md`

Likely verification:
- compile with warnings as errors
- focused readiness/schema/replay/operator-review tests
- broader candidate-refresh/operator-review regression
- schema export trio and checked-in export regeneration
- compile-connected xref, format, and diff hygiene
- bounded read-only review

Definition of done:
No execution-boundary-summary callback bag or shared-helper trampolines remain;
direct owners, explicit model data, the gate-validator boundary, and local pure
rules preserve exact validation order/messages; focused/broader/export checks
pass; and bounded review finds no blocker.

Completed result:
Removed the 18-entry execution-boundary-summary callback bag and all owner
trampolines. Shared primitive, stable-ID, and readiness-classification behavior
now calls exact owners directly; model limits and the facade gate validator are
explicit inputs; boundary mapping, count summation, and default equality
messages remain exact local behavior. `schema.ex` fell from 12,163 to 12,135
lines and the cohesive owner from 332 to 263.

Verification:
- compile with warnings as errors passed
- 44 focused readiness/schema/replay/review tests passed
- 1,051 broader candidate-refresh/operator-review tests passed
- 22 schema-export tests passed
- compile-connected xref, format, diff hygiene, and checked-in schema
  regeneration were clean
- bounded read-only review found no issues

Verification gaps:
- Full repository suite not run.
- Known baseline: full contact-filter file remains 87/88 due nil-message
  behavior in `SuppressedCandidateContracts`; unrelated to these slices.

Last completed slice:
Operational-readiness-gate-summary callback collapse published as `536c69c2`:
`schema.ex` fell from 12,194 to 12,163 lines and its owner from 424 to 339. The
20-entry bag became direct primitive/stable/collection/readiness owners,
explicit model-limit data, and one gate-validator boundary. 44 focused, 1,051
broader, and 22 export tests passed; compile, xref, format, diff hygiene, and
checked-in schema regeneration were clean. Bounded review found no issues.

Blocked:
No.
