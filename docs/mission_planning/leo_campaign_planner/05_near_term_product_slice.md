# Near-Term Product Slice

The first concrete slice should be V1 for a small LEO constellation:

1. Load a manifest with multiple spacecraft, ground stations, targets, and a
   planning horizon.
2. Propagate each spacecraft with explicit backend assumptions.
3. Generate access, eclipse, and target visibility windows.
4. Build candidate activities from those windows.
5. Score and rank simple candidate timelines.
6. Emit a plan artifact with contacts, activities, warnings, assumptions, and
   provenance.
7. Make the artifact shape easy for Cadence to import as proposed scheduled
   contacts and planned activities.

That slice is feature-complete when it can produce a plan that an operator would
reasonably review, adjust, and approve.
