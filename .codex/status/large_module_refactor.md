# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
CadenceImport timeline source-identifier policy extension.

Status:
Completed and published.

Selected boundary:
Move the duplicate timeline activity-state and preservation-status source-ID
fallback chains into the existing
`OrbitalDynamics.CadenceImport.SourceIdentifierPolicy`. Preserve both facade
seams as delegates and resolve the existing option override before entering the
policy owner.

Selection evidence:
- `cadence_import.ex` is now 2,813 lines.
- The selected two helpers are identical ordered fallback chains and belong with
  the existing source/manifest identifier policy.
- The family has one responsibility: choose option, ID, source, timeline,
  activity, then explicit fallback identity in that order.
- Option parsing, manifest dispatch, row building, schemas, and ordering remain
  outside the boundary.

Verification:
- Strict test compile passed with 3,824 files and warnings as errors.
- Two focused timeline state/preservation tests passed with 70 excluded.
- All combined CadenceImport tests passed: 96 tests.
- CadenceImport schema contracts passed: 4 tests.
- A 6-case direct matrix covered exact option, ID, source, timeline, activity,
  and explicit fallback precedence.
- Formatting and diff checks passed, and no temporary proof files remain.
- Static ownership checks confirmed the shared fallback chain has one
  production implementation behind both preserved facade seams.
- Runtime xref confirmed `cadence_import.ex` directly consumes the extended
  `source_identifier_policy.ex`.
- Bounded local review found no option resolution, precedence, identity,
  dispatch, ordering, or schema changes.

Behavior/schema changes:
None. This is a facade-preserving production ownership extraction.

Last completed slice:
CadenceImport timeline source-identifier policy extension, selected in
`cd5e4d8e` and implemented in `d51df814`. `cadence_import.ex` moved from 2,813
to 2,819 lines because the two explicit facade delegates expanded for readable
argument passing; the shared policy owner grew from 52 to 57 lines.

Next candidate:
Return to remaining review-package or row dispatch after timeline identity
fallback has one production owner.

Blocked:
No.
