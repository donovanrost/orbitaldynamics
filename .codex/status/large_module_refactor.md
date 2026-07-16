# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Contact-contention-resolution-summary callback-bag collapse.

Status:
Selected; implementation pending.

Selected slice:
Replace the 18-entry callback bag in
`ContactContentionResolutionSummaryContracts` with direct primitive, stable-ID,
and collection owners, explicit contention model-limit data, and the one
facade-owned resolution-policy validator function.

Why this slice:
Live inventory shows `schema.ex` remains the dominant production hotspot at
12,357 lines. The 509-line resolution-summary owner contains 18 callback
trampolines; most target shared validators or pure aggregations, one is model
data, and only policy validation remains a facade boundary. Focused contention,
communications-contract, reference-fixture, candidate-refresh replay, and
operator-review tests cover the report and its downstream consumers.

Public facade to preserve:
`OrbitalDynamics.Schema.validate_artifact/2` and all contact-contention
resolution-summary behavior, including exact validation order/messages,
policy validation, counts/IDs/maps, capacity totals, row-derived identities,
model limits, deterministic errors, replay consumers, and exports.

Likely extraction target:
Replace `validate/4` with an explicit signature accepting contention model-limit
data plus the policy validator. Remove the schema bag and owner trampolines;
call shared validators directly and keep exact aggregation semantics local or
in their existing owner.

Likely files:
- `lib/orbital_dynamics/schema.ex`
- `lib/orbital_dynamics/schema/contact_contention_resolution_summary_contracts.ex`
- `.codex/status/large_module_refactor.md`

Likely tests:
- compile with warnings as errors
- contact-contention and communications schema contracts
- focused reference fixture and candidate-refresh replay/review consumers
- schema export trio and checked-in export/fingerprint verification
- broader communications/candidate-refresh checks, xref, format, and diff hygiene

Definition of done:
No resolution-summary callback bag or shared-helper trampolines remain; explicit
model data and the one policy-validator boundary preserve exact behavior;
focused/broader/export checks pass; and bounded review finds no blocker.

Verification gaps:
- Full repository suite not run.

Last completed slice:
Timeline-transition-application-summary callback collapse published as
`f67eb721`: `schema.ex` fell from 12,375 to 12,357 lines and its owner from 311
to 237; 30 focused, 882 broader, and 22 export tests passed; checked-in schemas
were unchanged; bounded review found no issues.

Blocked:
No.
