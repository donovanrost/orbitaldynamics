# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Campaign-strategy callback-bag collapse.

Status:
Selected; implementation pending.

Selected slice:
Replace the 12-entry `CampaignStrategyContracts` lookup bag with direct shared
validation calls and six explicit Schema-owned domain validators.

Why this slice:
Live inventory leaves `schema.ex` at 11,496 lines. This 57-line orchestration
owner and its sole caller still route six shared operations and six genuine
domain hooks through generic lookup/apply despite having no dynamic dispatch.

Public facade to preserve:
`OrbitalDynamics.Schema.validate_artifact/2`, campaign-strategy required fields,
branch/recommendation and optional-report validation, exact paths/messages/order,
consumers, deterministic artifacts, and schema exports.

Likely files:
- `lib/orbital_dynamics/schema.ex`
- `lib/orbital_dynamics/schema/campaign_strategy_contracts.ex`
- `.codex/status/large_module_refactor.md`

Likely verification:
- compile with warnings as errors
- focused campaign repair/strategy, validation-fixture, and artifact tests
- broader candidate-refresh/operator-review regression
- schema export trio and checked-in export regeneration
- compile-connected xref, format, diff hygiene, and bounded review

Definition of done:
No campaign-strategy callback bag or lookup/apply trampolines remain; shared
owners are direct and only Schema-owned domain composition is explicit; focused,
broader, and export checks pass; and bounded review finds no blocker.

Verification gaps:
- Full repository suite not run.
- Known baseline: full contact-filter file remains 87/88 due nil-message
  behavior in `SuppressedCandidateContracts`; unrelated to these slices.
- The broader focused batch was 113/114 because the generated campaign did not
  exactly match its checked-in golden artifact; generation is outside this
  validation-only slice. The attributable batch is 102/102.

Last completed slice:
Freshness-report exact-message restoration published as `daf8f13f`: the two
implicit equality checks again emit their legacy expected-value messages, and
both paths are assertion-covered. The full validation file passed 181/181, with
1,167 broader and 22 export tests; compile, xref, regeneration, format, diff
hygiene, and bounded review were clean.

Blocked:
No.
