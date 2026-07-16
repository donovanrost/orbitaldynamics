# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Resource-projection-handoff callback-bag collapse.

Status:
Selected; implementation pending.

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

Verification gaps:
- Full repository suite not run.
- Known baseline: full contact-filter file remains 87/88 due nil-message
  behavior in `SuppressedCandidateContracts`; unrelated to these slices.

Last completed slice:
Source-evidence callback collapse published as `b67722fa`: `schema.ex` fell
from 11,696 to 11,684 lines and its owner from 206 to 176. The 6-entry bag
became direct primitive/stable-ID owners and two battery validator boundaries.
142 focused, 1,168 broader, and 22 export tests passed; compile, xref, format,
diff hygiene, checked-in regeneration, and bounded review were clean.

Blocked:
No.
