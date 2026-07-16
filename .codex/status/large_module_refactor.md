# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Resource-projection-row callback-bag collapse.

Status:
Selected; implementation pending.

Selected slice:
Replace the 20-entry callback bag in `ResourceProjectionRowContracts` with
direct shared owners while retaining explicit approval, policy-rule, source-
window, nested-ID, and flow-row validators.

Why this slice:
Live inventory leaves `schema.ex` at 11,599 lines. The 399-line row owner and
its sole Schema caller route 15 shared operations through lookup; five genuine
Schema composition hooks remain. The just-restored equality policy must be
preserved explicitly for its generic `/5` count checks.

Public facade to preserve:
`OrbitalDynamics.Schema.validate_artifact/2`, all resource-projection row
fields, nested approval/policy/source/flow validation, count paths and exact
messages/order, report consumers, and exports.

Likely files:
- `lib/orbital_dynamics/schema.ex`
- `lib/orbital_dynamics/schema/resource_projection_row_contracts.ex`
- `.codex/status/large_module_refactor.md`

Likely verification:
- compile with warnings as errors
- full resource-projection and focused schema/report/replay/operator-review tests
- broader candidate-refresh/operator-review regression
- schema export trio and checked-in export regeneration
- compile-connected xref, format, diff hygiene, and bounded review

Definition of done:
No resource-projection-row callback bag or lookup/apply trampolines remain;
direct shared owners preserve validation and generic equality messages while
five domain validators remain explicit boundaries; focused, broader, and
export checks pass; and bounded review finds no blocker.

Verification gaps:
- Full repository suite not run.
- Known baseline: full contact-filter file remains 87/88 due nil-message
  behavior in `SuppressedCandidateContracts`; unrelated to these slices.

Last completed slice:
Resource-projection report-count messages restored as `6fa085bf`: all five
generic equality calls again emit the exact legacy message while 13 custom
messages remain unchanged. The formerly red resource-projection file is 49/49,
the focused aggregate is 214/214, and 22 export tests pass; compile, xref,
regeneration, format, diff hygiene, and bounded review were clean.

Blocked:
No.
