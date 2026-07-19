# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
CadenceImport branch-evidence field catalog extraction.

Status:
Completed and published.

Selected boundary:
Extract the static branch contact-allocation, readiness/quality-gate, and
timeline evidence field catalogs into
`OrbitalDynamics.CadenceImport.BranchEvidenceFields`. Preserve the facade's
three existing zero-arity callback seams as delegates; keep the timeline
activity/publication subcatalog composition private to the new owner.

Selection evidence:
- `cadence_import.ex` is now 3,536 lines.
- The selected contiguous catalog family spans about 115 lines and is shared by
  branch-comparison and strategy-recommendation row builders through stable
  callbacks.
- The family has one responsibility: declare the exact source field allowlists
  copied into branch evidence, including timeline activity plus publication
  composition and order.
- Dispatch, row construction, review actions, provider normalization, schemas,
  ordering outside these lists, and manifest construction remain outside the
  boundary.

Verification:
- Strict test compile passed with 3,811 files and warnings as errors.
- Two focused branch-row tests passed with 70 excluded.
- All combined CadenceImport tests passed: 96 tests.
- CadenceImport schema contracts passed: 4 tests.
- An AST-derived proof against selection commit `d4c737af` confirmed exact
  ordered equality for all catalogs: 9 contact-allocation fields, 24 readiness/
  quality-gate fields, and 61 composed timeline fields.
- Formatting and diff checks passed, and no temporary proof files remain.
- Static ownership checks confirmed the three catalogs and two timeline
  subcatalogs have one production implementation behind preserved facade seams.
- Runtime xref confirmed `cadence_import.ex` is the direct consumer of
  `branch_evidence_fields.ex`.
- Bounded local review found no callback, membership, order, composition,
  row-shape, or schema changes.

Behavior/schema changes:
None. This is a facade-preserving production ownership extraction.

Last completed slice:
CadenceImport branch-evidence field catalog extraction, selected in `d4c737af`
and implemented in `bac4dd7e`. `cadence_import.ex` moved from 3,536 to 3,428
lines; the extracted owner is 121 lines.

Next candidate:
Return to the remaining CadenceImport row-building or manifest-routing helpers
after branch-evidence field selection has one production owner.

Blocked:
No.
