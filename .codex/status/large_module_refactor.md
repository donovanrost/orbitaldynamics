# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Candidate-refresh resource-signal context extraction.

Status:
Complete; publication pending.

Selected slice:
Extract the link-capacity, constraint, resource-projection, and resource-filter
source-report validators behind their existing public context functions.

Why this slice:
These four flows validate the capacity, constraint, projected-pressure, and
filter evidence that drives branch-local resource decisions. They share the
same direct count-map pattern; resource filter adds its invalid input-ID list.
Communications contention/allocation/pressure contexts remain out of scope.

Public facade to preserve:
`validate_link_capacity_context/4`, `validate_constraint_context/4`,
`validate_resource_projection_context/4`, and
`validate_resource_filter_context/4`, including callback-list guards, argument
order, validation order, paths, messages, and all other public signatures.

Extraction target:
`CandidateRefreshResourceSignalContracts`, with four entry points and a private
direct count-map helper.

Files:
- `lib/orbital_dynamics/schema/candidate_refresh_report_contracts.ex`
- `lib/orbital_dynamics/schema/candidate_refresh_resource_signal_contracts.ex`
- `.codex/status/large_module_refactor.md`

Result:
All four public `/4` facades delegate to a 54-line resource-signal owner. The
complete capacity/constraint/projection/filter flows moved, and the report-
contract facade fell from 386 to 364 lines without schema-export changes.

Verification:
- compile with warnings as errors passed
- 19 focused resource-signal replay/build files plus candidate-refresh schema
  and resource-provenance contracts: 100 passed
- broader candidate-refresh suite: 755 passed
- schema export trio: 22 passed
- full schema export reproduced checked-in artifacts with no diff
- deterministic contract/bundle fingerprint remained
  `831840C514054AEAA9C3B2275DBE55B442423DE771C7B41D4E3AF3AF83A7DDC0`
- compile-connected xref roots stayed narrow; format and diff hygiene passed
- bounded read-only review found no issues and independently passed compile,
  the 100 focused tests, facade/API comparison, xref, format, and diff checks

Verification gaps:
- Full repository suite not run.

Last commit:
Published timeline-activity extraction `f3e73b46`; selected this slice in
`85054acd`.

Blocked:
No.
