# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Suppressed-candidate exact-message restoration.

Status:
Selected; implementation pending.

Selected slice:
Restore the implicit `"must equal #{expected}"` message for the suppressed
candidate station-calendar ambiguous-entry count comparison.

Why this slice:
The live contact-filter proof is 41/42 because commit `8ffb3e18` replaced
Schema's message-supplying five-argument equality wrapper with the shared `/5`
helper whose default message is nil. Exactly one owner call uses that arity.

Public facade to preserve:
`OrbitalDynamics.Schema.validate_artifact/2`, suppressed-candidate overlap
counts, exact error path/message/order, filter consumers, and schema exports.

Likely files:
- `lib/orbital_dynamics/schema/suppressed_candidate_contracts.ex`
- `.codex/status/large_module_refactor.md`

Likely verification:
- compile with warnings as errors
- focused contact-filter and resource-filter validation tests
- broader candidate-refresh/operator-review regression
- schema export trio and checked-in export regeneration
- compile-connected xref, format, diff hygiene, and bounded review

Definition of done:
The affected comparison again emits its exact expected-value message without
changing equality semantics or issue order; focused, broader, and export checks
pass; and bounded review finds no blocker.

Verification gaps:
- Full repository suite not run.
- Known baseline: current contact-filter file is 41/42 due nil-message behavior
  in `SuppressedCandidateContracts`; this is the selected repair.
- The broader focused batch was 113/114 because the generated campaign did not
  exactly match its checked-in golden artifact; generation is outside this
  validation-only slice. The attributable batch is 102/102.

Last completed slice:
Strategy-branch callback-bag collapse published as `557a5c4c`: `schema.ex` fell
from 11,460 to 11,444 lines and the owner from 178 to 138. Nine shared
dependencies became direct and four domain hooks explicit. Eighteen focused,
1,167 broader, and 22 export tests passed; compile, xref, regeneration, format,
diff hygiene, and bounded review were clean.

Blocked:
No.
