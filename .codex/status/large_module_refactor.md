# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
ContactAllocation provider-counteroffer context extraction.

Status:
Completed and pushed in `456360fd`.

Selected boundary:
Extract provider-counteroffer field ownership, nested source discovery,
presence classification, timing-delta derivation, and compact context assembly
into `OrbitalDynamics.Communications.ContactAllocation.ProviderCounteroffer`.
Preserve the existing private context seam and capabilities output in the
ContactAllocation facade.

Selection evidence:
- Live re-ranking places `communications/contact_allocation.ex` at 4,127
  lines.
- The selected field registry and 2,462-2,593 helper family form one cohesive
  recursive provider-counteroffer normalization policy.
- Allocation, contention, capacity packing, reservation review, approval
  decisions, reporting, and public summary APIs remain in the facade.
- The context is consumed only through existing allocation-row and policy-
  context seams; downstream public call sites remain unchanged.

Verification:
- Strict warnings-as-errors compile passed across 3,894 files.
- Focused `communications/contact_allocation_test.exs` passed under
  warnings-as-errors: 70 tests.
- Adjacent operator-review contact-allocation, provider-reservation schema,
  and wrapped provider-counteroffer Cadence coverage passed under
  warnings-as-errors: 14 tests.
- Exact public old/new comparison against `5d597e6c` passed capabilities and 6
  allocations covering direct fields, nested station entries, overlap lists,
  overlap maps, unknown-only state, derived deltas, and explicit deltas.
- `mix xref callers
  OrbitalDynamics.Communications.ContactAllocation.ProviderCounteroffer`
  reports only the ContactAllocation facade as a runtime caller.
- Static ownership review confirms provider-counteroffer field ownership,
  nested discovery, presence rules, timing deltas, and compact context assembly
  live in the new owner.
- `git diff --check` passed.

Behavior/schema changes:
None. This is a facade-preserving production ownership extraction.

Last completed slice:
ContactAllocation provider-counteroffer context extraction, selected in
`5d597e6c` and implemented in `456360fd`.
`communications/contact_allocation.ex` moved from 4,127 to 3,984 lines; the
dedicated owner is 141 lines.

Next candidate:
Re-rank the remaining large modules and select the next cohesive,
facade-preserving responsibility boundary.

Blocked:
No.
