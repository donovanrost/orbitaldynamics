# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema resource-summary callback ownership handoff.

Status:
Published as `405b94cd`.

Selected slice:
Point both facade uses of `validate_resource_summary/3` directly at
`Schema.ResourceSummaryContracts.validate/3`: the standalone resource-summary
pipe and campaign-repair callback. Remove the pure wrapper.

Why this slice:
`Schema` remains a 7,895-line hotspot. Strict compile after the initial edit
corrected an incomplete caller search: there is one standalone pipe, one
callback capture, and one pure wrapper. The owner has the exact signature.

Public facade to preserve:
All Schema APIs, callback key/order, issue ordering/messages, JSON Schema and
checked export bytes, and nested repair resource-summary behavior.

Definition of done:
The standalone pipe retains `require_fields`; the callback key remains between
`validate_contact_intent` and optional contact filter; both reference the owner;
the wrapper is absent; tests and schema bytes remain exact.

Verification gaps:
None.

Tests run:
- Corrected source baseline: one standalone pipe, one callback capture, and one
  pure wrapper. The initial narrower search missed the standalone pipe; strict
  compile exposed it before any behavior proof or publication claim.
- Focused repair/strategy baseline: 2 tests passed with warnings as errors.
- Generated bundle: 121 schemas, 15,506,740 bytes, digest
  `543dbe11bc75f1397dd15dbd10cabd219ae2e46ac1e16d38b810a99befb8cec3`.
- Checked bundle digest:
  `757bb20af70443e376085ef2e6f97e5a0a0a8ee97323b5911343e88cd8b9ad15`.
- Source proof against `3ae8cd3d`: the standalone pipe and repair callback
  reference `ResourceSummaryContracts.validate/3` in place; wrapper is absent.
- Corrected focused resource plus repair/strategy set: 8 tests passed; complete
  schema/export suite: 182 passed, all with warnings as errors.
- Generated bundle remains exact; export regeneration produced no schema diff
  and the checked digest is unchanged.
- Strict compile, format, xref, and diff hygiene passed after the compile-caught
  caller correction.
- Independent review against `3ae8cd3d` was clean and confirmed both corrected
  positions, focused 8, complete 182, all 122 exports, digests, strict compile,
  xref, formatting, sizes, ledger accuracy, and correction honesty.

Behavior/schema changes:
None.

Outcome:
Both facade uses reference the owner and the wrapper is gone. `schema.ex`
decreased from 7,895 to 7,887 lines.

Last completed slice:
Realized-state-snapshot cleanup published as `c24e7a3e`: `schema.ex` shrank from
7,902 to 7,895 lines, 7 focused and 182 complete tests passed, all 122 exports
byte-matched, and bounded review was clean.

Next candidate:
Refresh the remaining facade-delegate inventory with both definition-name and
bare-name searches before selecting the next slice. Prefer an exact-signature
owner with bounded standalone/callback uses; do not infer caller count from a
single search shape.

Blocked:
No.
