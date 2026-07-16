# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Source-evidence callback-bag collapse.

Status:
Selected; implementation pending.

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

Verification gaps:
- Full repository suite not run.
- Known baseline: full contact-filter file remains 87/88 due nil-message
  behavior in `SuppressedCandidateContracts`; unrelated to these slices.

Last completed slice:
Cadence-import-manifest callback collapse published as `df6d3d0a`: `schema.ex`
fell from 11,719 to 11,696 lines and its owner from 328 to 225. The 18-entry bag
became direct shared/handoff owners and three explicit validator boundaries.
183 focused, 1,167 broader, and 22 export tests passed; compile, xref, format,
diff hygiene, checked-in regeneration, and bounded review were clean.

Blocked:
No.
