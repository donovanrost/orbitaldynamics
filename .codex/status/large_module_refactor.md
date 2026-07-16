# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Resource-projection-handoff callback-bag collapse.

Status:
Completed and ready to publish.

Selected slice:
Replace the 3-entry callback bag in `ResourceProjectionHandoffContracts` with
direct primitive owners while retaining the downlink-flow-row predicate as the
sole explicit domain boundary for count matching.

Why this slice:
Live inventory leaves `schema.ex` at 11,684 lines. The handoff owner receives
two shared primitive callbacks across three entry points and one genuine
resource-projection predicate used only for downlink counts. Removing the bag
simplifies battery/remaining-field validation without changing other handoff
matching responsibilities.

Public facade to preserve:
`OrbitalDynamics.Schema.validate_artifact/2` and every resource-projection
handoff path, including optional battery/remaining numbers, flow-derived counts
and IDs, downlink classification, exact messages/error order, source-evidence
and Cadence/review consumers, and exports.

Likely files:
- `lib/orbital_dynamics/schema.ex`
- `lib/orbital_dynamics/schema/resource_projection_handoff_contracts.ex`
- `.codex/status/large_module_refactor.md`

Likely verification:
- compile with warnings as errors
- focused readiness/schema/quality-gate replay/operator-review tests
- broader candidate-refresh/operator-review regression
- schema export trio and checked-in export regeneration
- compile-connected xref, format, diff hygiene, and bounded review

Definition of done:
No resource-projection-handoff callback bag or lookup/apply trampolines remain;
direct primitive owners preserve number/equality validation while only the
downlink predicate remains injected; focused, broader, and export checks pass;
and bounded review finds no blocker.

Outcome:
Removed the 3-entry handoff callback bag and all lookup/apply trampolines.
Battery/remaining optional numbers and count equality checks use direct
`PrimitiveValidation`; the downlink-flow-row predicate remains the sole explicit
domain boundary. Other source/own-flow/Cadence matchers and public accessors are
unchanged. `schema.ex` fell from 11,684 to 11,674 lines and the handoff owner
from 371 to 355.

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
Resource-projection-handoff callback-bag collapse; publication commit pending.

Blocked:
No.
