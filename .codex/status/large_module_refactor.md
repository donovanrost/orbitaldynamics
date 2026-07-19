# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
CadenceImport branch-evidence field catalog extraction.

Status:
Selected; implementation has not started.

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
Pending: focused branch-row baselines, exact ordered catalog equivalence proof,
strict compile, all combined CadenceImport tests, schema contracts, static
single ownership, runtime xref, and bounded review.

Behavior/schema changes:
None. This is a facade-preserving production ownership extraction.

Last completed slice:
CadenceImport JSON normalization extraction, selected in `b9b31830` and
implemented in `f6ebf3bf`. `cadence_import.ex` moved from 3,554 to 3,536 lines;
the extracted owner is 28 lines.

Next candidate:
Return to the remaining CadenceImport row-building or manifest-routing helpers
after branch-evidence field selection has one production owner.

Blocked:
No.
