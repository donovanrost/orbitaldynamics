# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Timeline dependency-impact row policy extraction.

Status:
Completed and published.

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
- Focused baseline passed 2 dependency-impact summary tests.
- Strict warnings-as-errors compile passed 3,801 modules.
- Focused dependency-impact summary tests passed 2 tests.
- Full Timeline suite passed 127 tests.
- Four Timeline schema-contract suites passed 36 tests.
- AST conservation proved the selected five-function row policy moved exactly;
  the only intersection change threads the facade's existing sorted-ID callback.
- Static checks confirmed the five private functions left Timeline, the facade
  has exactly two policy calls, the new module owns its six private helpers,
  formatting and diff checks pass, and no temporary checker remains.
- Independent review was clean with no correctness or maintainability findings;
  it confirmed source-then-replacement ordering, wrapper equivalence, public
  defs, capabilities, output structure, schema fields, and ordering are
  unchanged.
- Timeline decreased from 5,319 to 5,227 lines; the extracted policy is 129
  lines.

Behavior/schema changes:
None intended. Dependency-impact row maps, filtering, ID ordering, report
aggregation, capabilities, and schema exports should remain byte-for-byte
stable.

Last completed slice:
Timeline dependency-impact row policy extraction, selected in `bf4f2e94` and
implemented in `ece31812`.

Next candidate:
Continue remapping the reduced Timeline facade after this row-policy boundary is
owned.

Blocked:
No.
