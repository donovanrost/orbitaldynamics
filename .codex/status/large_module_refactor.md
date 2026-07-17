# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema contact-contention JSON property-dispatch extraction.

Status:
Published.

Selected slice:
Extract property dispatch for contact-contention report, resolution report,
and resolution summary from `OrbitalDynamics.Schema` into one internal
contact-contention dispatcher.

Why this slice:
The three adjacent clauses duplicate the same contract-sensitive
`ContactContentionJsonSchema` predicate and complete context, and have focused
communications contract coverage. Objective reports and contention runtime
behavior remain out of scope.

Public facade to preserve:
All `OrbitalDynamics.Schema` public functions, exact JSON Schema maps and
validators for the three contact-contention contracts, bundle ordering,
and checked-in schema bytes.

Likely files:
- `lib/orbital_dynamics/schema.ex`
- new contact-contention property-dispatch module
- `.codex/status/large_module_refactor.md`

Likely verification:
- focused communications contract tests
- JSON schema export tests
- schema export task tests
- full checked-in export regeneration and aggregate digest comparison
- compile, format, xref, diff hygiene, and bounded review

Definition of done:
The three facade clauses become one guarded delegate to the internal
dispatcher; runtime schemas, validators, bundle ordering, and checked-in
exports remain exact; focused and export tests pass; and bounded review finds
no blocker.

Outcome:
The three duplicate facade clauses are now one guarded delegate to
`OrbitalDynamics.Schema.ContactContentionPropertyDispatch`. The internal
dispatcher owns the allowed contract set, shared context constants and
assembly, contract-sensitive focused predicate/property builder, and common
fallback. Eager dependency evaluation remains in the facade, preserving prior
timing. The facade is 9,451 lines; the dispatcher is 35 lines. Implementation
published as `f6d5420d`.

Verification gaps:
- `mix compile --warnings-as-errors` passed.
- 30 focused communications, JSON export, schema export, and export-task tests
  passed.
- Full checked-in export regeneration remained byte-identical at aggregate
  digest `95051be82cec8a75634e4e8712dadd102888f59998d2c26ebe7c36065d824d3b`.
- Scoped format, diff hygiene, and xref checks passed; xref reports only the
  expected runtime caller from `OrbitalDynamics.Schema`.
- Initial bounded review's low cohesion finding was resolved by moving contract
  family ownership and context assembly into the dispatcher; follow-up review
  found no remaining issue.
- None for this slice.

Last completed slice:
Schema contact-contention property dispatch published as `f6d5420d`: report,
resolution report, and resolution summary now route through one cohesive
internal dispatcher, 30 focused/export tests passed, full regeneration was
byte-identical, and follow-up review found no blocker.

Next candidate:
Extract the adjacent objective-satisfaction and objective-tradeoff property
clauses into one internal objective-report dispatcher. Preserve
contract-sensitive predicates, exact eager row/model-limit/model context,
common fallback, validators, and exact exports. Leave optimizer-ranking clauses
in the facade.

Blocked:
No.
