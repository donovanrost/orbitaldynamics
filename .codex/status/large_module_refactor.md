# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Result-artifact callback-bag collapse.

Status:
Complete and ready to publish.

Selected slice:
Replace the 12-entry callback bag in `ResultArtifactContracts` with direct
shared owners and local error construction while retaining the nested execution
report validator as the sole explicit boundary.

Why this slice:
Live inventory leaves `schema.ex` at 11,513 lines. The 231-line result-artifact
owner and its sole Schema caller route ten shared operations plus error maps
through lookup; only registry-backed execution-report validation is a genuine
Schema composition hook.

Public facade to preserve:
`OrbitalDynamics.Schema.validate_artifact/2`, result artifact top-level fields,
execution-report errors, payload metrics and section counts, ground-track rows,
exact paths/messages/order, consumers, and exports.

Likely files:
- `lib/orbital_dynamics/schema.ex`
- `lib/orbital_dynamics/schema/result_artifact_contracts.ex`
- `.codex/status/large_module_refactor.md`

Likely verification:
- compile with warnings as errors
- focused result-artifact, payload-metrics, schema, and golden-artifact tests
- broader candidate-refresh/operator-review regression
- schema export trio and checked-in export regeneration
- compile-connected xref, format, diff hygiene, and bounded review

Definition of done:
No result-artifact callback bag or lookup/apply trampolines remain; direct
shared owners and local errors preserve validation while execution-report
validation remains an explicit boundary; focused, broader, and export checks
pass; and bounded review finds no blocker.

Outcome:
The 12-entry callback bag and all lookup/apply trampolines are gone. Shared
primitive, collection, and stable-ID validators are called directly, local
payload-metrics errors retain their exact maps, and nested execution-report
validation is the sole injected one-argument boundary. `schema.ex` fell from
11,513 to 11,496 lines and the owner from 231 to 187. Compile warnings, xref,
checked-in export regeneration, format, and diff hygiene are clean; 102 focused,
1,167 broader, and 22 export tests pass. Bounded review found no blocker in
validation order, messages, issue concatenation, payload sections, ground-track
rows, caller shape, or callback residue.

Verification gaps:
- Full repository suite not run.
- Known baseline: full contact-filter file remains 87/88 due nil-message
  behavior in `SuppressedCandidateContracts`; unrelated to these slices.
- Full validation-file probing found existing nil messages for `$.status` and
  `$.state_quality_status` in the curated freshness fixture; unrelated to the
  result-artifact owner and a candidate for the next repair slice.
- The broader focused batch was 113/114 because the generated campaign did not
  exactly match its checked-in golden artifact; generation is outside this
  validation-only slice. The attributable batch is 102/102.

Last completed slice:
Result-artifact callback-bag collapse, ready to publish: `schema.ex` fell from
11,513 to 11,496 lines and its owner from 231 to 187. The 12-entry bag became
direct shared validation calls plus one execution-report boundary. 102 focused,
1,167 broader, and 22 export tests passed; compile, xref, regeneration, format,
diff hygiene, and bounded review were clean.

Blocked:
No.
