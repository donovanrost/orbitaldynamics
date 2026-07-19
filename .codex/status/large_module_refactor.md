# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Timeline application identity collection policy completion.

Status:
Completed and published.

Selected boundary:
Move transition-application timeline-ID and activity-ID collection from the
Timeline facade into the existing `IdentityGroupingPolicy`. Keep both facade
wrappers and pass the existing `sorted_uniq/1` behavior explicitly.

Selection evidence:
- The two collectors are used only by transition-application summary fields and
  sit immediately beside the grouped timeline-ID wrappers.
- `IdentityGroupingPolicy` now owns the generic grouped-ID algorithms; filtered
  application identity collection is the same responsibility.
- The facade wrappers preserve all five current call sites while the policy
  receives the existing deterministic sorted-ID callback.
- One focused transition-application summary test covers review, applied,
  preserved, selected, and withheld timeline/activity ID sets and schema
  validation.
- Timeline is 5,023 lines; `IdentityGroupingPolicy` is 65 lines.
- Public Timeline APIs, summary maps, predicate callbacks, schema/model
  ownership, capability values, generated exports, and other aggregation
  responsibilities remain outside the boundary.

Verification:
- Focused baseline passed 1 transition-application summary test.
- Strict warnings-as-errors compile passed 3,803 modules.
- Focused transition-application summary test passed 1 test.
- Full Timeline suite passed 127 tests.
- Four Timeline schema-contract suites passed 36 tests.
- AST conservation proved both application identity collectors moved exactly
  after normalizing only the sorted-ID callback invocation.
- Static checks confirmed the facade retains two thin wrappers, the policy owns
  exactly one implementation of each collector, public def count remains 101,
  formatting/diff checks pass, and no temporary checker remains.
- Compile-connected xref remained narrow: Timeline has only the pre-existing
  compile edge to `CandidateRejectionStationPolicy`.
- Bounded local review found no correctness or maintainability issues and
  confirmed predicate filtering, source/replacement activity flattening, nil
  rejection, and deterministic unique ID ordering are unchanged.
- Timeline increased from 5,023 to 5,025 lines because the two wrappers remain
  readable across five call sites; `IdentityGroupingPolicy` increased from 65
  to 81 lines and now owns the behavior.

Behavior/schema changes:
None intended. Predicate filtering, nil rejection, ID ordering, summary fields,
capabilities, and schema exports should remain byte-for-byte stable.

Last completed slice:
Timeline application identity collection policy completion, selected in
`6db5ac0d` and implemented in `2fb91b08`.

Next candidate:
Continue remapping the reduced Timeline facade after application identity
collection ownership is complete.

Blocked:
No.
