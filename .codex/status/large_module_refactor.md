# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Filter-report-count callback-bag collapse.

Status:
Completed; ready to publish.

Selected slice:
Replace the four-entry callback bag in `FilterReportCountContracts` with direct
primitive owners plus a local exact copy of the facade's five-argument equality
message behavior.

Why this slice:
Live inventory shows `schema.ex` remains the dominant production hotspot at
12,226 lines. The 365-line filter-count owner has four callback trampolines;
error construction, explicit equality, and count-map validation already have
shared primitive owners, while five-argument equality requires preserving the
facade's generated `must equal <expected>` message. Focused contact/resource
filter, replay, review, and export coverage is available.

Public facade to preserve:
`OrbitalDynamics.Schema.validate_artifact/2` and all contact/resource filter
count behavior, including invalid inputs, duplicate rows, multiset IDs,
frequency maps, exact messages, deterministic errors, replay consumers, and
exports.

Likely extraction target:
Replace `validate_counts/5` with `validate_counts/4`, remove the schema bag and
owner trampolines, import exact primitive arities, and locally preserve the
facade's nil/default equality-message clauses.

Likely files:
- `lib/orbital_dynamics/schema.ex`
- `lib/orbital_dynamics/schema/filter_report_count_contracts.ex`
- `.codex/status/large_module_refactor.md`

Likely tests:
- compile with warnings as errors
- contact/resource filter schema contracts
- focused candidate-refresh replay and operator-review consumers
- schema export trio and checked-in export/fingerprint verification
- broader communications/candidate-refresh checks, xref, format, and diff hygiene

Definition of done:
No filter-count callback bag or callback trampolines remain; direct owners and
local default-message clauses preserve exact validation order/messages;
focused/broader/export checks pass; and bounded review finds no blocker.

Verification gaps:
- Full repository suite not run.
- Full contact-filter file remains 87/88 due pre-existing nil-message behavior
  in untouched `SuppressedCandidateContracts`; focused filter-count coverage is
  green and bounded review confirmed the failure is unrelated.

Last completed slice:
Filter-report-count callback collapse ready to publish: `schema.ex` fell from
12,226 to 12,216 lines and its owner from 365 to 317. The four-entry bag became
direct primitive owners plus exact local nil/default equality-message clauses;
all callback trampolines were removed. 71 focused, 798 broader, and 22 export
tests passed; compile, xref, format, diff hygiene, and checked-in schema
regeneration were clean. Bounded review found no issues.

Blocked:
No.
