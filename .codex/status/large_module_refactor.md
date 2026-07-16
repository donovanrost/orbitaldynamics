# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Result-artifact callback-bag collapse.

Status:
Selected; implementation pending.

Selected slice:
Replace the 12-entry callback bag in `ResultArtifactContracts` with direct
shared owners and local error construction while retaining the nested execution
report validator as the sole explicit boundary.

Why this slice:
Live inventory leaves `schema.ex` at 11,513 lines. The 231-line result-artifact
owner and its sole Schema caller route ten shared operations plus error maps
through lookup; only registry-backed execution-report validation is a genuine
Schema composition hook.

Public facade to preserve:
`OrbitalDynamics.Schema.validate_artifact/2`, result artifact top-level fields,
execution-report errors, payload metrics and section counts, ground-track rows,
exact paths/messages/order, consumers, and exports.

Likely files:
- `lib/orbital_dynamics/schema.ex`
- `lib/orbital_dynamics/schema/result_artifact_contracts.ex`
- `.codex/status/large_module_refactor.md`

Likely verification:
- compile with warnings as errors
- focused result-artifact, payload-metrics, schema, and golden-artifact tests
- broader candidate-refresh/operator-review regression
- schema export trio and checked-in export regeneration
- compile-connected xref, format, diff hygiene, and bounded review

Definition of done:
No result-artifact callback bag or lookup/apply trampolines remain; direct
shared owners and local errors preserve validation while execution-report
validation remains an explicit boundary; focused, broader, and export checks
pass; and bounded review finds no blocker.

Verification gaps:
- Full repository suite not run.
- Known baseline: full contact-filter file remains 87/88 due nil-message
  behavior in `SuppressedCandidateContracts`; unrelated to these slices.

Last completed slice:
Resource-projection-report callback-bag collapse published as `38df3c8a`:
`schema.ex` fell from 11,533 to 11,513 lines and its owner from 259 to 172. The
20-entry bag became direct shared owners, explicit model values, and five
domain-validator arguments. 214 focused, 1,167 broader, and 22 export tests
passed; compile, xref, regeneration, format, diff hygiene, and bounded review
were clean.

Blocked:
No.
