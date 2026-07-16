# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Timeline-transition-application-summary callback-bag collapse.

Status:
Completed; ready to publish.

Selected slice:
Replace the 13-entry callback bag in
`TimelineTransitionApplicationSummaryContracts` with direct primitive,
collection, and stable-ID owners, explicit timeline model-limit data, and the
one remaining facade-owned transition-application-row validator function.

Why this slice:
Live inventory shows `schema.ex` remains the dominant production hotspot at
12,375 lines. The 311-line summary owner contains 13 callback trampolines; 11
are direct shared validation helpers, one is pure model-limit data, and only
the nested application-row validator still belongs to the facade's deeper row
contract. Focused summary/report/workflow tests cover all counts, IDs/maps,
integrity types, rows, model limits, fixtures, and handoffs.

Public facade to preserve:
`OrbitalDynamics.Schema.validate_artifact/2` and all timeline transition
application summary behavior, including validation order, exact paths/messages,
model-limit comparison, derived counts/IDs/maps, nested application rows,
deterministic errors, and exports.

Likely extraction target:
Replace `validate/4` with an explicit direct-owner signature accepting timeline
model limits plus the row validator. Remove the schema bag and owner
trampolines while retaining the single intentional nested-validator boundary.

Likely files:
- `lib/orbital_dynamics/schema.ex`
- `lib/orbital_dynamics/schema/timeline_transition_application_summary_contracts.ex`
- `.codex/status/large_module_refactor.md`

Likely tests:
- compile with warnings as errors
- focused timeline summary/report contracts
- transition-application workflows and nested handoff checks
- schema export trio and checked-in export/fingerprint verification
- broader timeline/candidate-refresh checks, xref, format, and diff hygiene

Definition of done:
No summary callback bag or shared-helper trampolines remain; explicit model-limit
data and the one row-validator boundary preserve exact behavior;
focused/broader/export checks pass; and bounded review finds no blocker.

Result:
Removed the 13-entry callback factory and all shared-helper trampolines. The
facade now passes exact timeline model-limit data and its one intentional nested
row validator; the summary owner calls primitive, collection, and stable-ID
owners directly. `schema.ex` fell from 12,375 to 12,357 lines and the summary
owner from 311 to 237 lines.

Verification:
- compile with warnings as errors passed
- 30 focused report, summary, provenance, workflow, and handoff tests passed
- 882 broader timeline/candidate-refresh tests passed
- 22 schema-export tests passed
- checked-in schema export reproduction produced no diff
- format, diff hygiene, scoped callback residue, and compile-connected xref passed
- bounded read-only review found no issues

Verification gaps:
- Full repository suite not run.

Last completed slice:
Timeline-transition-application-summary callback collapse: `schema.ex` fell
from 12,375 to 12,357 lines and its owner from 311 to 237; 30 focused, 882
broader, and 22 export tests passed; checked-in schemas were unchanged; bounded
review found no issues.

Blocked:
No.
