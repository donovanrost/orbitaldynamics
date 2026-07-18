# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Timeline dependency-impact row policy extraction.

Status:
Selected; implementation has not started.

Selected boundary:
Move dependency-impact row construction, row inclusion, operator-action reason,
row identity, and set intersection from the Timeline facade into one
`DependencyImpactRowPolicy` module. Keep summary orchestration and aggregation
in the public facade.

Selection evidence:
- The selected five-function cluster is used only to build the source and
  replacement rows of `dependency_impact_summary/3`.
- Row construction can call the already extracted collection and compact-map
  policies directly; the facade supplies its existing `sorted_uniq/1` behavior
  for intersection ordering.
- Focused tests cover changed/removed activity dependencies, timeline-ID
  dependencies, combined exclusivity, clear status, facade parity, persisted
  fixtures, and schema validation.
- Timeline is 5,319 lines; the selected cluster spans about 100 lines of
  dependency-impact row policy.
- Public Timeline APIs, source-identity derivation, summary aggregation,
  capability values, report/schema shapes, field ordering, generated exports,
  and other timeline responsibilities remain outside the boundary.

Verification:
Pending: focused baselines, mechanical policy extraction, strict compile,
focused and full Timeline tests, schema contracts, structural/static checks, and
independent review.

Behavior/schema changes:
None intended. Dependency-impact row maps, filtering, ID ordering, report
aggregation, capabilities, and schema exports should remain byte-for-byte
stable.

Last completed slice:
Timeline diff comparison-value policy completion, selected in `4b541c00` and
implemented in `76d88290`.

Next candidate:
Continue remapping the reduced Timeline facade after this row-policy boundary is
owned.

Blocked:
No.
