# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Quality-gate-handoff callback-bag collapse.

Status:
Completed and ready to publish.

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

Outcome:
Removed the 7-entry handoff callback bag and all owner trampolines. Optional
enum/count/count-map validation now uses `PrimitiveValidation`; optional stable
IDs and stable-ID lists use `StableIdValidation`; optional stable-ID array maps
are composed locally from the same shared type and item validators. Source row
and report matching are unchanged. One now-unused Schema import was removed.
`schema.ex` fell from 11,733 to 11,719 lines and the handoff owner from 212 to
174.

Verification:
- compile with warnings as errors passed
- 183 focused readiness/Cadence/replay/operator-review tests passed
- 1,167 broader candidate-refresh/operator-review/Cadence tests passed
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
Quality-gate-handoff callback-bag collapse; publication commit pending.

Blocked:
No.
