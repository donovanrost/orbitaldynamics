# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Source-evidence callback-bag collapse.

Status:
Completed and ready to publish.

Selected slice:
Replace the 6-entry callback bag in `SourceEvidenceContracts` with direct
primitive and stable-ID owners while retaining explicit resource-projection
battery field and own-flow match validators.

Why this slice:
Live inventory leaves `schema.ex` at 11,696 lines. The 206-line source-evidence
owner receives four shared primitive/stable-ID callbacks and two real resource-
projection validators. Expressing only those two boundaries directly removes
lookup/apply indirection without broadening the source-evidence responsibility.

Public facade to preserve:
`OrbitalDynamics.Schema.validate_artifact/2` and every source-evidence path,
including nested source maps/lists, stable IDs/lists, probability fields, diff
status, resource-projection battery handoffs, exact messages/error order,
Cadence/review consumers, and exports.

Likely files:
- `lib/orbital_dynamics/schema.ex`
- `lib/orbital_dynamics/schema/source_evidence_contracts.ex`
- `.codex/status/large_module_refactor.md`

Likely verification:
- compile with warnings as errors
- focused readiness/schema/quality-gate replay/operator-review tests
- broader candidate-refresh/operator-review regression
- schema export trio and checked-in export regeneration
- compile-connected xref, format, diff hygiene, and bounded review

Definition of done:
No source-evidence callback bag or lookup/apply trampolines remain; direct shared
owners preserve nested validation while only the two battery-handoff validators
remain injected; focused, broader, and export checks pass; and bounded review
finds no blocker.

Outcome:
Removed the 6-entry source-evidence callback bag and all owner trampolines.
Stable-ID/list, probability, and diff-status validation use direct shared
owners; battery handoff field and own-flow match validators remain explicit.
Nested map/list traversal and public field accessors are unchanged. `schema.ex`
fell from 11,696 to 11,684 lines and the source-evidence owner from 206 to 176.

Verification:
- compile with warnings as errors passed
- 142 focused source-provenance/Cadence/schema tests passed
- 1,168 broader candidate-refresh/operator-review/Cadence tests passed
- 22 schema export tests passed
- compile-connected xref passed
- checked-in schema regeneration produced no diff
- format and diff hygiene passed
- bounded review found no findings

Verification gaps:
- Full repository suite not run.
- Known baseline: full contact-filter file remains 87/88 due nil-message
  behavior in `SuppressedCandidateContracts`; unrelated to these slices.

Last completed slice:
Source-evidence callback-bag collapse; publication commit pending.

Blocked:
No.
