# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema timeline-transition callback ownership mapping.

Status:
Ready for publication.

Selected slice:
Directly capture established owners for transition report counts, row identity
collision fields, and timeline diff rows. Remove the three pure facade wrappers.

Why this slice:
`Schema` remains a 7,837-line hotspot. Structural and bare-name mapping confirms
three cohesive exact-signature wrappers, each with one callback capture.

Public facade to preserve:
All Schema APIs, callback argument order, exact issues/messages, JSON Schema and
checked export bytes, and timeline-transition behavior.

Definition of done:
Report counts remain immediately after model limits; identity collision remains
after lifecycle/protection callbacks; diff row remains final after selected
integrity. Each captures its established owner, wrappers are absent, and all
proof/review remains exact.

Verification gaps:
None.

Tests run:
- Source baseline: three single-capture pure wrappers at the positions above.
- Focused `timeline_report_contracts_test.exs`: 8 tests passed with warnings as
  errors.
- Generated bundle: 121 schemas, 15,506,740 bytes, digest
  `543dbe11bc75f1397dd15dbd10cabd219ae2e46ac1e16d38b810a99befb8cec3`.
- Checked bundle digest:
  `757bb20af70443e376085ef2e6f97e5a0a0a8ee97323b5911343e88cd8b9ad15`.
- Source proof against `1a20a40e`: all three callbacks retain their positions,
  reference established owners, and wrappers are absent.
- Focused timeline-report tests: 8 passed; complete schema/export suite: 182
  passed, all with warnings as errors.
- Generated bundle remains exact; export regeneration produced no schema diff
  and checked digest is unchanged.
- Strict compile, format, xref for all three owners, and diff hygiene passed.
- Independent review against `1a20a40e` was clean across all positions,
  focused 8, complete 182, all 122 exports, digests, strict compile, all-owner
  xref, formatting, sizes, ledger, and hygiene.

Behavior/schema changes:
None.

Outcome:
All three callbacks reference established owners and wrappers are gone.
`schema.ex` decreased from 7,837 to 7,813 lines.

Last completed slice:
Timeline-publication-context cleanup published as `b9f2988d`: `schema.ex`
shrank from 7,845 to 7,837 lines, focused 11 and complete 182 tests passed, all
122 exports byte-matched, and review was clean.

Next candidate:
After review and publication, continue the structural exact-wrapper inventory.

Blocked:
No.
