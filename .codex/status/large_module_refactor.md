# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema timeline-publication-context callback ownership mapping.

Status:
Ready for implementation.

Selected slice:
Point all four captures of `validate_timeline_publication_context/3` directly at
`Schema.CandidateRefreshReportContracts.validate_timeline_publication_context/3`
and remove the pure wrapper.

Why this slice:
`Schema` remains a 7,845-line hotspot. Broad mapping confirms four captures and
one exact-signature delegate shared by a cohesive operational-readiness concern.

Public facade to preserve:
All Schema APIs, callback argument positions, exact issues/messages, JSON Schema
and checked export bytes, and readiness/quality-gate publication behavior.

Definition of done:
The owner remains the sole gate callback; second evidence callback after
resource context; final import-readiness callback after model limits; and third
quality-row callback after both handoff matchers. Wrapper is absent and all
proof/review remains exact.

Verification gaps:
- Implementation and post-change verification pending.

Tests run:
- Source baseline: four captures and one pure delegate at the positions above.
- Focused operational plus readiness baseline: 11 tests passed with warnings as
  errors.
- Generated bundle: 121 schemas, 15,506,740 bytes, digest
  `543dbe11bc75f1397dd15dbd10cabd219ae2e46ac1e16d38b810a99befb8cec3`.
- Checked bundle digest:
  `757bb20af70443e376085ef2e6f97e5a0a0a8ee97323b5911343e88cd8b9ad15`.

Behavior/schema changes:
None.

Outcome:
No timeline-publication-context implementation has started.

Last completed slice:
Operational-feedback cleanup published as `10967b5f`: `schema.ex` shrank from
7,853 to 7,845 lines, focused 2 and complete 182 tests passed, all 122 exports
byte-matched, and review was clean.

Next candidate:
Implement all four direct captures and remove the wrapper.

Blocked:
No.
