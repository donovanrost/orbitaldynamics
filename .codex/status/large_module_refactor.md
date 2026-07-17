# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema timeline-transition callback ownership mapping.

Status:
Ready for implementation.

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
- Implementation and post-change verification pending.

Tests run:
- Source baseline: three single-capture pure wrappers at the positions above.
- Focused `timeline_report_contracts_test.exs`: 8 tests passed with warnings as
  errors.
- Generated bundle: 121 schemas, 15,506,740 bytes, digest
  `543dbe11bc75f1397dd15dbd10cabd219ae2e46ac1e16d38b810a99befb8cec3`.
- Checked bundle digest:
  `757bb20af70443e376085ef2e6f97e5a0a0a8ee97323b5911343e88cd8b9ad15`.

Behavior/schema changes:
None.

Outcome:
No timeline-transition callback implementation has started.

Last completed slice:
Timeline-publication-context cleanup published as `b9f2988d`: `schema.ex`
shrank from 7,845 to 7,837 lines, focused 11 and complete 182 tests passed, all
122 exports byte-matched, and review was clean.

Next candidate:
Implement the three direct captures and remove wrappers.

Blocked:
No.
