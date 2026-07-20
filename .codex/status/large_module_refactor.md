# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Ground-network schema-provider extraction.

Status:
Completed and pushed.

Selected boundary:
Move the contiguous link-capacity, contact-allocation, and contact-contention
schema-builder cluster from the public `Schema` facade into a new
`GroundNetworkSchemaProviders` owner. Merge its six lazy registry providers
into the property context and route the three review-table helper captures to
the new owner.

Selection evidence:
- The public `Schema` facade remains 1,729 lines.
- Ten contiguous helpers form a roughly 130-line communications boundary
  spanning link capacity, allocation, and contention schemas.
- Six are registry providers, three are also captured by the three review-row
  provider tables, and one is internal to the same cluster.
- Approval/policy and station-calendar dependencies can remain lazy through
  explicit callbacks; the three shared helpers can be public owner functions.
- A provider-map owner preserves lazy evaluation and removes both registry
  entries and implementation details from the public facade.

Implementation:
Selected in `721cb8f6` and implemented in `440e5739`.
The new `GroundNetworkSchemaProviders.build/2` returns six lazy provider
closures for link capacity, contact allocation, and contact contention
schemas, owns the internal source-candidate builder, and exposes three focused
helpers shared by the review-row provider tables. `Schema` removes the full
ten-helper cluster, merges the provider map with explicit policy/station
callbacks, and points the three review tables at the new owner.

Verification:
- Strict focused schema/validation baseline and post-change suites both passed:
  359 tests, 0 failures.
- Direct comparison confirmed the extracted provider map has the exact six
  keys and produces outputs exactly equal to the original helper composition;
  all three shared helper outputs also match exactly.
- Xref reports the provider-map edge plus nine expected shared-helper edges
  from `Schema` to the new owner.
- Schema export regenerated 121 schemas plus the bundle with no checked-in
  artifact diff.
- Strict full compile passed for 4,113 files with warnings as errors.
- Formatting, diff checks, and bounded two-file review passed.
- The public `Schema` facade shrank from 1,729 to 1,648 lines; the new focused
  owner is 147 lines.

Behavior/schema changes:
None intended. Parent clause heads/order, dispatch-owner calls, provider
laziness, field-hint fallback, stable-ID decoration, public `Schema`, and
checked-in exports must remain unchanged.

Last completed slice:
Ground-network schema-provider extraction, selected in `721cb8f6` and
implemented in `440e5739`. The public `Schema` facade moved from 1,729 to 1,648
lines.

Next candidate:
Re-rank the remaining public-facade provider clusters.

Blocked:
No.
