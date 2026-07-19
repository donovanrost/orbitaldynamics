# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
CadenceImport source-identifier policy extraction.

Status:
Completed and published.

Selected boundary:
Extract deterministic source and manifest identifier construction into
`OrbitalDynamics.CadenceImport.SourceIdentifierPolicy`. Move the schema
validation, schema-validation batch, execution, result-artifact, and manifest ID
builders while preserving their five existing private call seams as delegates.

Selection evidence:
- `cadence_import.ex` is now 3,604 lines.
- The selected contiguous private family spans about 47 lines and has five
  narrowly typed call sites.
- The family has one responsibility: construct deterministic colon-delimited
  source IDs and the manifest ID wrapper with the current unknown-source
  fallback.
- Option precedence, report parsing, rows, provenance, schemas, ordering, and
  manifest construction remain outside the boundary.

Verification:
- Strict test compile passed with 3,808 files and warnings as errors.
- Four focused schema-validation, execution-report, and result-artifact tests
  passed with 68 excluded.
- All combined CadenceImport tests passed: 96 tests.
- CadenceImport schema contracts passed: 4 tests.
- A 14-case direct identifier matrix covered compacted fields, run-ID
  precedence and fallback, nested result run-ID precedence and fallback, and
  manifest unknown-source behavior.
- Formatting and diff checks passed, and no temporary proof files remain.
- Static ownership checks confirmed the five builders have one production
  implementation behind the preserved facade seams.
- Runtime xref confirmed `cadence_import.ex` is the direct consumer of
  `source_identifier_policy.ex`.
- Bounded local review found no call-site, option-precedence, output-shape,
  ordering, or fallback changes.

Behavior/schema changes:
None. This is a facade-preserving production ownership extraction.

Last completed slice:
CadenceImport source-identifier policy extraction, selected in `94797583` and
implemented in `fa5fad26`. `cadence_import.ex` moved from 3,604 to 3,573 lines;
the extracted owner is 52 lines.

Next candidate:
Inspect the remaining CadenceImport row-building or manifest-routing helpers for
the next cohesive production ownership boundary.

Blocked:
No.
