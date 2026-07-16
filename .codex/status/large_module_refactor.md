# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Operational-timeline-report callback-bag collapse.

Status:
Selection pending publication of the completed contention-summary slice.

Selected slice:
After publishing the completed contention-summary slice, confirm whether the
15-entry callback bag in `OperationalTimelineReportContracts` is the next
bounded direct-owner target.

Why this slice:
Live inventory shows `schema.ex` remains the dominant production hotspot at
12,307 lines. The 471-line operational-timeline owner contains 15 callback
trampolines; most target shared primitive/collection validators, while timeline
row validation remains a facade boundary. Focused timeline report, replay,
review, export, and broader candidate-refresh coverage is available.

Public facade to preserve:
`OrbitalDynamics.Schema.validate_artifact/2` and all operational-timeline report
behavior, including validation order/messages, optional aggregates, row
validation, timeline model limits, deterministic errors, replay consumers, and
exports.

Likely extraction target:
Confirm a signature accepting explicit timeline model-limit data plus the row
validator. Remove the schema bag and owner trampolines, call shared validators
and collection aggregations directly, and preserve default-message behavior.

Likely files:
- `lib/orbital_dynamics/schema.ex`
- `lib/orbital_dynamics/schema/operational_timeline_report_contracts.ex`
- `.codex/status/large_module_refactor.md`

Likely tests:
- compile with warnings as errors
- timeline-report schema contracts and validation fixtures
- focused candidate-refresh replay and operator-review consumers
- schema export trio and checked-in export/fingerprint verification
- broader communications/candidate-refresh checks, xref, format, and diff hygiene

Definition of done:
Selection is recorded with a verified public facade, bounded ownership change,
focused proof set, and explicit default-message/row-validator review risks.

Verification gaps:
- Full repository suite not run.

Last completed slice:
Contact-contention-resolution-summary callback collapse ready to publish:
`schema.ex` fell from 12,357 to 12,307 lines and its owner from 509 to 421. The
18-entry bag became direct shared owners, explicit model-limit data, and one
policy-validator boundary; four newly dead facade wrappers were removed. 62
focused, 761 broader, and 22 export tests passed; compile, xref, format, diff
hygiene, and checked-in schema regeneration were clean. Bounded review found no
issues; malformed-input ordering was reviewed structurally rather than through
exhaustive differential generation.

Blocked:
No.
