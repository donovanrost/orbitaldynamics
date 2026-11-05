defmodule OrbitalDynamics.MissionAnalysis.PlanValidation.Report do
  @moduledoc false
  def markdown(r) do
    [
      "# Independent plan validation\n\nStatus: **#{r["status"]}**. Source: `#{r["source"]}`.\n\n",
      "Checks declared structure and resource accounting without invoking planning or physical evaluators. Orbital, attitude and path feasibility are outside this check.\n\n",
      if(r["status"] == "partial",
        do:
          "Some checks are unsupported or operations are stopped; this is not a complete pass.\n\n",
        else: ""
      ),
      for(
        i <- r["issues"],
        do: "- #{i["severity"]}: #{i["code"]} at `#{i["location"]}` — #{i["message"]}\n"
      ),
      for(s <- r["snapshots"] || [], do: "- #{s["source"]}: #{s["status"]}\n"),
      "\nAbsolute resource-accounting tolerance: 1e-8 in the declared units (Wh for batteries, Nms/Nm for supported wheels, K for supported thermal states); activity times and commitment placements are compared exactly. Full issues and analytic expectations are in validation.json. A pass covers only the stated checks and declared inputs.\n"
    ]
  end
end
