# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
ContactFilter provider-counteroffer context extraction.

Status:
Completed and pushed in `a24fb6f8`.

Selected boundary:
Extract the provider-counteroffer field contract, depth-limited nested/overlap
evidence lookup, candidate-before-station precedence, presence detection,
context insertion, and explicit/derived timing deltas into
`OrbitalDynamics.Communications.ContactFilter.ProviderCounterofferContext`.
Preserve all ContactFilter and root public facades.

Selection evidence:
- Excluding the generated/declarative candidate-refresh JSON-schema module,
  live re-ranking places `communications/contact_filter.ex` at 2,062 lines,
  the largest ordinary eligible facade.
- ContactFilter currently has one extracted contact-normalization owner; its
  provider-counteroffer contract remains at lines 38-50 and its cohesive
  context/value/delta helper family remains at lines 1,287-1,437.
- The same source-value lookup also drives counteroffer review detection near
  line 810, so the new owner will expose that operation rather than duplicating
  traversal logic.
- Candidate normalization, suppression decisions, station matching and
  reservation evidence, provider contention, approval policy, report
  aggregation, feedback validation, and capacity handling remain outside the
  boundary.
- Exact field order, candidate-before-station precedence, nested source-entry
  and overlap search order, depth limit, unknown-negotiation omission, sparse
  insertion, explicit-delta precedence, numeric coercion, and derived timing
  delta behavior must remain unchanged.

Implementation:
- Added
  `OrbitalDynamics.Communications.ContactFilter.ProviderCounterofferContext`
  as the owner of the ordered field contract, depth-limited nested/overlap
  traversal, evidence precedence and presence rules, sparse context insertion,
  and explicit/derived timing deltas.
- Preserved all ContactFilter and root public APIs; capability metadata,
  counteroffer review detection, and suppressed-row construction now call the
  dedicated owner.
- Removed the field attribute and full counteroffer context helper family from
  the facade.
- `communications/contact_filter.ex` moved from 2,062 to 1,898 lines; the new
  owner is 149 lines.

Verification:
- Strict focused baseline passed all 42 ContactFilter tests.
- Exact old/new public parity passed for five captured cases: ordered fields,
  candidate-over-station precedence, nested overlap traversal, unknown-state
  omission, and the no-context path.
- Focused and communications-contract verification passed 50 tests.
- Static checks confirm the attribute and helper family left the facade; xref
  reports only ContactFilter as a runtime caller of the new owner.
- Strict warning-clean forced compile passed for 3,989 files.
- Formatting and `git diff --check` passed.

Behavior/schema changes:
None intended.

Last completed slice:
ContactFilter provider-counteroffer context extraction, selected in `b1f30133`
and implemented in `a24fb6f8`.
`communications/contact_filter.ex` moved from 2,062 to 1,898 lines; the
dedicated provider-counteroffer context owner is 149 lines.

Next candidate:
Re-rank the live checkout and select the next bounded facade-preserving
extraction. `resource_filter.ex` is now the largest ordinary eligible facade
at 2,059 lines.

Blocked:
No.
