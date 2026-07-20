# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Validation schema-provider extraction.

Status:
Completed and pushed.

Selected boundary:
Move the validation-record, model-acceptance-row, safety-case-evidence-row,
and validation-reference-report provider builders from the public `Schema`
facade into a new `ValidationSchemaProviders` owner. Merge its lazy provider
map into the existing property context.

Selection evidence:
- The public `Schema` facade remains 1,917 lines.
- These four contiguous private builders are referenced only by the property
  provider registry, apart from model acceptance's local reuse of the
  validation-record builder.
- They form a cohesive validation-schema boundary and depend only on the
  stable-ID pattern plus `ValidationJsonSchema` primitives.
- A provider-map owner preserves lazy evaluation and removes both registry
  entries and implementation details from the public facade.

Implementation:
Selected in `bd0109e1` and implemented in `f5050011`.
The new `ValidationSchemaProviders.build/1` returns four lazy provider closures
for validation record, model acceptance, safety-case evidence, and validation
reference report schemas. `Schema` removes the four registry-local captures
and private builders, then merges the focused provider map after the existing
planning-analysis provider map.

Verification:
- Strict focused schema/validation baseline and post-change suites both passed:
  359 tests, 0 failures.
- Direct comparison confirmed the extracted provider map has the exact four
  keys and produces outputs exactly equal to the original builders.
- Xref reports one runtime edge from `Schema` to the new provider owner.
- Schema export regenerated 121 schemas plus the bundle with no checked-in
  artifact diff.
- Strict full compile passed for 4,109 files with warnings as errors.
- Formatting, diff checks, and bounded two-file review passed.
- The public `Schema` facade shrank from 1,917 to 1,887 lines; the new focused
  owner is 44 lines.

Behavior/schema changes:
None intended. Parent clause heads/order, dispatch-owner calls, provider
laziness, field-hint fallback, stable-ID decoration, public `Schema`, and
checked-in exports must remain unchanged.

Last completed slice:
Validation schema-provider extraction, selected in `bd0109e1` and implemented
in `f5050011`. The public `Schema` facade moved from 1,917 to 1,887 lines.

Next candidate:
Re-rank the remaining public-facade provider clusters.

Blocked:
No.
