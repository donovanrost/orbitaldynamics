# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Timeline-publication-summary callback-bag collapse.

Status:
Complete and ready to publish.

Selected slice:
Replace the 19-entry `TimelinePublicationSummaryContracts` keyword bag with
direct shared owners, internalize its two optional source-summary boundaries,
and remove callback plumbing from timeline-publication handoff validation.

Why this slice:
Live inventory leaves `schema.ex` at 10,686 lines. The 703-line publication
summary routes 19 primitive, stable-ID, source-summary, and capability
dependencies through lookup/apply. Its two source validators already have
extracted owners, and the same bag is unnecessarily threaded through the
timeline-publication handoff boundary.

Public facade to preserve:
`OrbitalDynamics.Schema.validate_artifact/2`, all timeline-publication-summary fields,
exact paths/messages/order, consumers, deterministic artifacts, and schema
exports.

Likely files:
- `lib/orbital_dynamics/schema.ex`
- `lib/orbital_dynamics/schema/timeline_publication_summary_contracts.ex`
- `lib/orbital_dynamics/schema/timeline_handoff_contracts.ex`
- `.codex/status/large_module_refactor.md`

Likely verification:
- compile with warnings as errors
- focused timeline-publication, handoff, and candidate-refresh tests
- broader campaign-planner/operator-review/schema regression
- schema export trio and checked-in export regeneration
- compile-connected xref, format, diff hygiene, and bounded review

Definition of done:
No timeline-publication-summary keyword bag or lookup/apply trampolines remain;
its validators and optional sources are direct, handoff validation no longer
threads callbacks, focused/broader/export checks pass, and bounded review finds
no blocker.

Outcome:
The 19-entry bag and every publication-summary lookup/apply trampoline are gone.
Primitive and stable-ID validators are direct. Optional timeline-diff and
dependency-impact source validation now lives with the publication owner while
preserving nil/map/non-map behavior and timeline model-limit order. Timeline
handoff validates optional publication sources directly through `/3`; the
shared Schema diff wrapper delegates to the owner for remaining consumers, and
the dependency wrapper disappeared as an orphan. `schema.ex` fell from 10,686
to 10,637 lines, the publication owner from 703 to 599, and the handoff owner by
two lines, for a net 155-line reduction. Four hundred ninety-four focused,
1,340 attributable broader, and 24 export tests pass; compile, checked-in
regeneration, compile-connected xref within its existing three-edge threshold,
format, and diff hygiene are clean. Bounded review found no blocker and
confirmed the full pipeline/order/defaults/paths/messages, nested-source
behavior, model-limit order, wrapper retention/orphan removal, handoff arity,
all callers, and cleanup.

Verification gaps:
- Full repository suite not run.
- The 1,345-test broader batch has the same five known campaign-planner baseline
  failures previously reproduced on pre-slice commit `6f1f0ac1`; the
  attributable result is 1,340/1,340.

Last completed slice:
Relay-data-path-summary callback collapse published as `6705f3f0`: `schema.ex`
fell from 10,713 to 10,686 lines and the owner from 439 to 372; the 16-entry
factory and lookup/apply trampolines disappeared while implicit equality-message
compatibility remained exact. Two hundred sixty focused, 1,340 attributable
broader, and 24 export tests passed; compile, regeneration, xref, format, diff
hygiene, and bounded review were clean.

Blocked:
No.
