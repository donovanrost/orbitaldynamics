# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Candidate-refresh communications-pressure context extraction.

Status:
Selected; implementation pending.

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

Likely extraction target:
`CandidateRefreshCommunicationPressureContracts`, with four entry points and a
private direct count-map helper.

Likely files:
- `lib/orbital_dynamics/schema/candidate_refresh_report_contracts.ex`
- `lib/orbital_dynamics/schema/candidate_refresh_communication_pressure_contracts.ex`
- `.codex/status/large_module_refactor.md`

Likely tests:
- compile with warnings as errors
- focused contact-contention/allocation, station-pressure, and contact-filter
  replay/build tests
- candidate-refresh schema/provenance contracts
- broader candidate-refresh, deterministic export/fingerprint, xref, and format

Definition of done:
All four public `/4` contexts are thin delegates with unchanged guards, their
complete flows move without duplication, the facade drops both stable-ID
imports, validation order/paths/errors remain exact, and all checks pass.

Verification gaps:
- Full repository suite not run.

Last completed slice:
Resource-signal context extraction published as `c79310ac`: a 54-line owner
reduced the report-contract facade from 386 to 364 lines; 100 focused, 755
candidate-refresh, and 22 export tests passed; schemas/fingerprint were
unchanged; bounded review found no issues.

Blocked:
No.
