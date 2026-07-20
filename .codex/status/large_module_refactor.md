# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Execution-state schema-provider extraction.

Status:
Completed and pushed.

Selected boundary:
Move the spacecraft-state-estimate, maneuver-execution-delta, realized
spacecraft-state, and realized-snapshot-metadata provider builders from the
public `Schema` facade into a new `ExecutionStateSchemaProviders` owner. Merge
its lazy provider map into the existing property context.

Selection evidence:
- The public `Schema` facade remains 1,813 lines.
- These four builders are referenced only by the property provider registry.
- They form a cohesive accepted/realized execution-state boundary spanning
  estimate, maneuver delta, realized state, and snapshot metadata schemas.
- They depend only on the stable-ID pattern and common numeric/string-array
  primitives, so no facade callback is required.
- A provider-map owner preserves lazy evaluation and removes both registry
  entries and implementation details from the public facade.

Implementation:
Selected in `ce29ff10` and implemented in `b6901070`.
The new `ExecutionStateSchemaProviders.build/1` returns four lazy provider
closures for spacecraft estimate, maneuver delta, realized spacecraft state,
and snapshot metadata schemas. `Schema` removes the four registry-local
captures and private builders, then merges the focused provider map using only
the stable-ID pattern.

Verification:
- Strict focused schema/validation baseline and post-change suites both passed:
  359 tests, 0 failures.
- Direct comparison confirmed the extracted provider map has the exact four
  keys and produces outputs exactly equal to the original builders.
- Xref reports one runtime edge from `Schema` to the new provider owner.
- Schema export regenerated 121 schemas plus the bundle with no checked-in
  artifact diff.
- Strict full compile passed for 4,111 files with warnings as errors.
- Formatting, diff checks, and bounded two-file review passed.
- The public `Schema` facade shrank from 1,813 to 1,768 lines; the new focused
  owner is 61 lines.

Behavior/schema changes:
None intended. Parent clause heads/order, dispatch-owner calls, provider
laziness, field-hint fallback, stable-ID decoration, public `Schema`, and
checked-in exports must remain unchanged.

Last completed slice:
Execution-state schema-provider extraction, selected in `ce29ff10` and
implemented in `b6901070`. The public `Schema` facade moved from 1,813 to 1,768
lines.

Next candidate:
Re-rank the remaining public-facade provider clusters.

Blocked:
No.
