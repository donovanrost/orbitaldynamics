# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Timeline diff-comparison policy extraction.

Status:
Selection recorded; implementation has not started.

Selected boundary:
Move changed-field calculation, direct/activity-context comparison fallback,
and review-significant field membership into
`Timeline.DiffComparisonPolicy`. `Timeline` retains two private entry points;
the full comparison field list and activity-context comparison subset cross the
boundary explicitly, while comparison-value selection becomes policy-internal.

Why this slice:
The 6,250-line Timeline facade still owns four exclusive clauses that define
diff comparison semantics consumed by diff-row assembly and review decisions.
Moving them together isolates comparison order, explicit nil fallback,
missing-field fallback, direct-field access, and significant-field membership
without extracting diff coordinators.

Planned proof:
- Focused changed command, product/latency, throughput, and resource-assignment
  diff examples.
- Full Timeline and Timeline schema-contract suites.
- Strict warnings-as-errors compile.
- Canonical AST equivalence for all four moved clauses after normalizing only
  public/private heads and the two comparison-field arguments.
- Format, diff, whitespace, ownership, exactly-two-facade, unchanged Timeline
  public-definition, and xref checks.
- Independent read-only review before publication.

Behavior/schema changes:
None intended. No schema-generation boundary is selected, so export
regeneration should not be required.

Last completed slice:
Timeline integrity-ID grouping policy extraction, selected in `7e726f43`,
corrected in `8f39e03a`, implemented in `fcdc3670`, and handed off in
`84ce76db`.

Next candidate:
Continue remapping the reduced Timeline facade after this slice, avoiding wide
report and activity-context map coordinator callback surfaces.

Blocked:
No.
