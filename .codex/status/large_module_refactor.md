# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Timeline provider-result policy extraction.

Status:
Selection recorded; implementation has not started.

Selected boundary:
Move provider execution failure reasons and the complete provider-result
flattening, failure/success token classification, and artifact serialization
cluster into `Timeline.ProviderResult`. `Timeline` retains three private facade
entry points for failure reason, failure predicate, and artifact value. The
shared ordered provider-result map-key list remains Timeline-owned for
capabilities and is supplied as selection data.

Why this slice:
The reduced Timeline facade is 8,077 lines. This approximately 165-line cluster
has one cohesive provider-evidence responsibility and no behavioral helper
dependencies. Its three facade entry points preserve all existing callers,
while the shared key list remains with the capabilities surface. This is a
cleaner boundary than combining operational action policy with Cadence import
validation.

Planned proof:
- Focused Timeline tests covering contact and command result/success evidence,
  nested provider result maps/lists, operational failure routing, and
  diff-sensitive command evidence.
- Full Timeline and Timeline schema-contract suites.
- Strict warnings-as-errors compile.
- Canonical AST equivalence for every moved clause after normalizing only
  facade entry points and the shared key-list data boundary.
- Format, diff, whitespace, ownership, three-caller, public-definition, and
  xref checks.
- Independent read-only review before publication.

Behavior/schema changes:
None intended. No schema-generation boundary is selected, so export
regeneration should not be required.

Last completed slice:
Timeline diff-row construction extraction, implementation published in
`80f18ab2` and handoff published in `246c7840`.

Next candidate:
Remap the reduced Timeline facade after this slice, emphasizing operational
action classification and transition application.

Blocked:
No.
