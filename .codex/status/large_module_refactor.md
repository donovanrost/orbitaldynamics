# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
CadenceImport import-readiness policy extraction.

Status:
Completed and published.

Selected boundary:
Extract Cadence-import presence detection and adapter import-status resolution
into `OrbitalDynamics.CadenceImport.ImportReadinessPolicy`. Move the
`cadence_import_present?/2` and `adapter_import_status/2` policies plus their
private nonempty-string predicate while preserving the two existing private
callback seams as delegates.

Selection evidence:
- `cadence_import.ex` is now 3,573 lines.
- The selected policy family spans about 23 lines and is passed through the
  facade to contact-intent, operational-timeline, generic-review, and other row
  builders as stable callbacks.
- The family has one responsibility: decide whether Cadence import data is
  present and translate source/approval states into the adapter import status.
- Row construction, activity context, review actions, provider normalization,
  schemas, ordering, and manifest construction remain outside the boundary.

Verification:
- Strict test compile passed with 3,809 files and warnings as errors.
- Three focused readiness tests passed with 69 excluded.
- All combined CadenceImport tests passed: 96 tests.
- CadenceImport schema contracts passed: 4 tests.
- A 16-case direct decision matrix covered explicit boolean presence,
  missing-status precedence, inferred ID/type/map presence, invalid/missing/
  not-applicable states, approval-policy overrides, ready state, and fallback.
- Formatting and diff checks passed, and no temporary proof files remain.
- Static ownership checks confirmed both policies and the string predicate have
  one production implementation behind the preserved facade callback seams.
- Runtime xref confirmed `cadence_import.ex` is the direct consumer of
  `import_readiness_policy.ex`.
- Bounded local review found no callback, clause-precedence, row-shape,
  ordering, or fallback changes.

Behavior/schema changes:
None. This is a facade-preserving production ownership extraction.

Last completed slice:
CadenceImport import-readiness policy extraction, selected in `a5edf9e8` and
implemented in `27cbfdb9`. `cadence_import.ex` moved from 3,573 to 3,554 lines;
the extracted owner is 29 lines.

Next candidate:
Return to the remaining CadenceImport row-building or manifest-routing helpers
after import readiness has one production policy owner.

Blocked:
No.
