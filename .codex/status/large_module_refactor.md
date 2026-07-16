# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Candidate-refresh communications-pressure context extraction.

Status:
Complete; publication pending.

Selected slice:
Extract the contact-contention, contact-allocation, station-pressure, and
contact-filter source-report validators behind their public context functions.

Why this slice:
These flows validate the contention, provider-reservation routing, station
pressure, and suppression evidence that drives branch-local communications
decisions. Together they own the facade's remaining stable-ID validations and
three of its four remaining direct count-map callers. Candidate rejection stays
out of scope.

Public facade to preserve:
`validate_contact_contention_context/4`,
`validate_contact_allocation_context/4`, `validate_station_pressure_context/4`,
and `validate_contact_filter_context/4`, including callback-list guards,
argument order, validation order, paths, messages, and all other public APIs.

Extraction target:
`CandidateRefreshCommunicationPressureContracts`, with four entry points and a
private direct count-map helper.

Files:
- `lib/orbital_dynamics/schema/candidate_refresh_report_contracts.ex`
- `lib/orbital_dynamics/schema/candidate_refresh_communication_pressure_contracts.ex`
- `.codex/status/large_module_refactor.md`

Result:
All four public `/4` facades delegate to a 71-line communications-pressure
owner. The complete contention/allocation/pressure/filter flows and both stable-
ID imports moved; the report-contract facade fell from 364 to 337 lines without
schema-export changes.

Verification:
- compile with warnings as errors passed
- focused contention/allocation/station-pressure/contact-filter files plus
  candidate-refresh schema and resource-provenance contracts: 116 passed
- broader candidate-refresh suite: 755 passed
- schema export trio: 22 passed
- full schema export reproduced checked-in artifacts with no diff
- deterministic contract/bundle fingerprint remained
  `831840C514054AEAA9C3B2275DBE55B442423DE771C7B41D4E3AF3AF83A7DDC0`
- compile-connected xref roots stayed narrow; format and diff hygiene passed
- bounded read-only review found no issues and independently passed compile,
  the 116 focused tests, facade/API comparison, xref, format, and diff checks

Verification gaps:
- Full repository suite not run.

Last commit:
Published resource-signal extraction `c79310ac`; selected this slice in
`cc164a85`.

Blocked:
No.
