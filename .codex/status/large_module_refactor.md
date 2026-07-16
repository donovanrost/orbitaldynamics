# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Suppressed-candidate exact-message restoration.

Status:
Complete and ready to publish.

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

Outcome:
A local five-argument wrapper again delegates with `"must equal #{expected}"`;
all other primitive validation remains direct. Contact-filter passes 42/42 and
resource-filter 37/37, alongside 1,167 broader and 22 export tests. Compile,
xref, checked-in regeneration, format, and diff hygiene are clean. Bounded
review confirmed exact legacy wording, nil no-op behavior, unchanged issue
order, sole-call scope, and unambiguous arity resolution.

Verification gaps:
- Full repository suite not run.
- The broader focused batch was 113/114 because the generated campaign did not
  exactly match its checked-in golden artifact; generation is outside this
  validation-only slice. The attributable batch is 102/102.

Last completed slice:
Suppressed-candidate exact-message restoration, ready to publish: the
ambiguous-entry count again emits its legacy expected-value message. Contact
filter passed 42/42 and resource filter 37/37, with 1,167 broader and 22 export
tests; compile, xref, regeneration, format, diff hygiene, and bounded review
were clean.

Blocked:
No.
