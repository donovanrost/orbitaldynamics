# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
ResourceProjection station-capacity evidence extraction.

Status:
Completed and pushed in `4ca5f9fb`.

Selected boundary:
Extract station-capacity fraction/percent path contracts, capability metadata,
capacity scaling, source station-calendar capacity selection, and resolved
station-calendar entry/provider identifiers into
`OrbitalDynamics.ResourceProjection.StationCapacityEvidence`. Preserve all
ResourceProjection and root public facades.

Selection evidence:
- Excluding the generated/declarative candidate-refresh JSON-schema module,
  live re-ranking places `resource_projection.ex` at 1,981 lines, the largest
  ordinary eligible facade.
- ResourceProjection already delegates to eight focused owners, but six
  station/source path contracts remain inline at lines 137-215 and their
  resolver family occupies lines 1,766-1,890.
- The resolver has one responsibility: derive contact capacity scaling and
  station-calendar entry/provider identity from direct, allocation, entry, and
  overlap evidence.
- Activity normalization, resource flow arithmetic, delivery evidence,
  approval policy, margins, pressure classification, summaries, and all other
  capability contracts remain outside the boundary.
- Exact path ordering, unit metadata, first-valid-source precedence, percent
  conversion, capacity clamping/defaults, stable-id filtering, flow rows,
  reports, summaries, and error behavior must remain unchanged.

Implementation:
- Added `OrbitalDynamics.ResourceProjection.StationCapacityEvidence` as the
  owner of station/source capacity path contracts, unit metadata, capacity
  scaling, source-calendar selection, and station-calendar identifiers.
- Preserved ResourceProjection and root public APIs as capability and report
  delegates.
- Kept the station-calendar direction helper in the facade because it is shared
  by activity normalization outside the selected capacity boundary.
- `resource_projection.ex` moved from 1,981 to 1,789 lines; the new owner is
  255 lines.

Verification:
- Strict focused baseline passed all 49 ResourceProjection tests.
- Exact old/new public parity passed for four deterministic captures: the six
  capability contracts, direct evidence precedence, source-entry evidence, and
  capacity-bearing source-overlap selection.
- Post-extraction focused and adjacent verification passed all 56 tests.
- Static checks confirm the new owner solely declares all six station/source
  path contracts and owns the resolver family; xref reports only
  ResourceProjection as a runtime caller.
- Strict warning-clean forced compile passed for 3,995 files.
- Formatting and `git diff --check` passed.

Behavior/schema changes:
None intended.

Last completed slice:
ResourceProjection station-capacity evidence extraction, selected in
`438a67a8` and implemented in `4ca5f9fb`.
`resource_projection.ex` moved from 1,981 to 1,789 lines; the dedicated
StationCapacityEvidence owner is 255 lines.

Next candidate:
Re-rank the live checkout and select the next bounded facade-preserving
extraction. `communications/contact_contention.ex` is now the largest ordinary
eligible facade at 1,978 lines, followed by ResourceFilter and
ContactAllocation.

Blocked:
No.
