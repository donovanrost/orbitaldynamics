# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Operational-readiness-context callback-bag collapse.

Status:
Completed and ready to publish.

Selected slice:
Replace the 7-entry callback bag in `OperationalReadinessContextContracts` with
direct primitive and stable-ID owners plus an exact local non-negative map sum;
update all facade context validators without changing their composition.

Why this slice:
Live inventory leaves `schema.ex` at 11,876 lines. The 355-line readiness-
context owner underlies quality-gate row resource, operator-training, adapter,
and Cadence-import validation. Its bag contains no genuine facade/domain hook:
all entries are shared validators or one pure sum. Removing it simplifies the
remaining row-validator dependency surface without replacing seven genuine row
domain validators with another opaque structure.

Public facade to preserve:
`OrbitalDynamics.Schema.validate_artifact/2` and every readiness resource,
operator-training, adapter-boundary, and Cadence-import context validation path,
including optional fields, reason/count derivation, exact messages/error order,
quality-gate row/report behavior, replay consumers, and exports.

Likely files:
- `lib/orbital_dynamics/schema.ex`
- `lib/orbital_dynamics/schema/operational_readiness_context_contracts.ex`
- `.codex/status/large_module_refactor.md`

Likely verification:
- compile with warnings as errors
- focused readiness/schema/quality-gate replay/operator-review tests
- broader candidate-refresh/operator-review regression
- schema export trio and checked-in export regeneration
- compile-connected xref, format, diff hygiene, and bounded review

Definition of done:
No readiness-context callback bag or helper trampolines remain; direct shared
owners and the exact local sum preserve all validation/error order and messages;
focused/broader/export checks pass; and bounded review finds no blocker.

Outcome:
Removed the 7-entry callback bag and owner callback trampolines. The four
context validators now call `PrimitiveValidation` directly, stable-ID array-map
validation is locally composed from its shared owners, and the exact nonnegative
map sum remains local. `schema.ex` fell from 11,876 to 11,860 lines and the
readiness-context owner from 355 to 293. The public Schema facade and validation
composition remain unchanged.

Verification:
- compile with warnings as errors passed
- 61 focused readiness/schema/replay/operator-review tests passed
- 1,054 broader candidate-refresh/operator-review tests passed
- 22 schema export tests passed
- compile-connected xref showed only primitive/stable-ID dependencies
- checked-in schema regeneration produced no diff
- format and diff hygiene passed
- bounded review found no findings

Verification gaps:
- Full repository suite not run.
- Known baseline: full contact-filter file remains 87/88 due nil-message
  behavior in `SuppressedCandidateContracts`; unrelated to these slices.

Last completed slice:
Operational-readiness-context callback-bag collapse; publication commit pending.

Blocked:
No.
