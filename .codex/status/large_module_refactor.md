# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Quality-gate-handoff callback-bag collapse.

Status:
Selected; implementation pending.

Selected slice:
Replace the 7-entry callback bag in `QualityGateHandoffContracts` with direct
primitive and stable-ID owners plus local composition of optional stable-ID
array-map validation.

Why this slice:
Live inventory leaves `schema.ex` at 11,733 lines. The 212-line handoff owner
receives only shared primitive/stable-ID callbacks; none is a genuine Schema
domain hook. Removing the bag completes direct ownership for quality-gate
handoff summary validation without touching its source-match behavior.

Public facade to preserve:
`OrbitalDynamics.Schema.validate_artifact/2` and every quality-gate handoff
summary path, including optional report identity/readiness fields, gate counts,
count maps, grouped gate/row IDs, status ID lists, exact messages/error order,
source-match consumers, replay consumers, and exports.

Likely files:
- `lib/orbital_dynamics/schema.ex`
- `lib/orbital_dynamics/schema/quality_gate_handoff_contracts.ex`
- `.codex/status/large_module_refactor.md`

Likely verification:
- compile with warnings as errors
- focused readiness/schema/quality-gate replay/operator-review tests
- broader candidate-refresh/operator-review regression
- schema export trio and checked-in export regeneration
- compile-connected xref, format, diff hygiene, and bounded review

Definition of done:
No quality-gate-handoff callback bag or lookup/apply trampolines remain; direct
shared owners preserve summary validation and source-match behavior; focused,
broader, and export checks pass; and bounded review finds no blocker.

Verification gaps:
- Full repository suite not run.
- Known baseline: full contact-filter file remains 87/88 due nil-message
  behavior in `SuppressedCandidateContracts`; unrelated to these slices.

Last completed slice:
Quality-gate-row callback collapse published as `3e6fc7d8`: `schema.ex` fell
from 11,762 to 11,733 lines and its owner from 148 to 96. The 14-entry bag
became direct shared/context owners and three explicit validator boundaries.
61 focused, 1,054 broader, and 22 export tests passed; compile, xref, format,
diff hygiene, checked-in regeneration, and bounded review were clean.

Blocked:
No.
