# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Ground-network schema-provider extraction.

Status:
Selected; implementation pending.

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
Pending.

Verification:
Pending.

Behavior/schema changes:
None intended. Parent clause heads/order, dispatch-owner calls, provider
laziness, field-hint fallback, stable-ID decoration, public `Schema`, and
checked-in exports must remain unchanged.

Last completed slice:
Resource-planning schema-provider extraction, selected in `aedaf961` and
implemented in `b981188a`. The public `Schema` facade moved from 1,768 to 1,729
lines.

Next candidate:
Implement and verify the selected ground-network provider extraction, then
re-rank the remaining public-facade provider clusters.

Blocked:
No.
