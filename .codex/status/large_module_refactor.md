# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
ContactAllocation provider-counteroffer context extraction.

Status:
Selected; implementation not started.

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
Pending.

Behavior/schema changes:
None. This is a facade-preserving production ownership extraction.

Last completed slice:
Study.Manifest activity-schema extraction, selected in `73142212` and
implemented in `90b9d08e`. `study/manifest.ex` moved from 4,260 to 4,075
lines; the dedicated owner is 283 lines.

Next candidate:
Implement and verify the selected ContactAllocation provider-counteroffer
context extraction.

Blocked:
No.
