# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Strategy-recommendation callback-bag collapse.

Status:
Selected; implementation pending.

Selected slice:
Replace the 11-entry `StrategyRecommendationContracts` lookup bag with direct
shared owners, local errors, and two explicit Schema-owned domain validators.

Why this slice:
Live inventory leaves `schema.ex` at 11,484 lines. This 264-line owner and its
sole caller route nine shared/static dependencies and only two true composition
hooks through lookup/apply despite having no dynamic dispatch.

Public facade to preserve:
`OrbitalDynamics.Schema.validate_artifact/2`, recommendation fields and
consistency rules, tradeoff/explanation/risk rows, exact paths/messages/order,
campaign-strategy consumers, deterministic artifacts, and schema exports.

Likely files:
- `lib/orbital_dynamics/schema.ex`
- `lib/orbital_dynamics/schema/strategy_recommendation_contracts.ex`
- `.codex/status/large_module_refactor.md`

Likely verification:
- compile with warnings as errors
- focused campaign repair/strategy, recommendation, fixture, and artifact tests
- broader candidate-refresh/operator-review regression
- schema export trio and checked-in export regeneration
- compile-connected xref, format, diff hygiene, and bounded review

Definition of done:
No strategy-recommendation callback bag or lookup/apply trampolines remain;
shared owners and local errors preserve behavior while the two domain hooks are
explicit; focused, broader, and export checks pass; and bounded review finds no
blocker.

Verification gaps:
- Full repository suite not run.
- Known baseline: full contact-filter file remains 87/88 due nil-message
  behavior in `SuppressedCandidateContracts`; unrelated to these slices.
- The broader focused batch was 113/114 because the generated campaign did not
  exactly match its checked-in golden artifact; generation is outside this
  validation-only slice. The attributable batch is 102/102.

Last completed slice:
Campaign-strategy callback-bag collapse published as `bf070e5d`: `schema.ex`
fell from 11,496 to 11,484 lines; six shared validators became direct calls and
six domain hooks became explicit guarded arguments. Eighteen focused, 1,167
broader, and 22 export tests passed; compile, xref, regeneration, format, diff
hygiene, and bounded review were clean.

Blocked:
No.
