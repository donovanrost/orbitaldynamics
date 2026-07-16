defmodule OrbitalDynamics.CampaignPlanner.BranchApprovalRequirements do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.{
    ActivityIdentity,
    CandidateDiffMetadata,
    RepairAccumulator,
    StrategicAdditionActivityContext
  }

  def build(repair_result, candidate_plan) do
    repair_requirements = Map.get(repair_result, "approval_requirements", [])
    strategic_requirements = strategic_requirements(candidate_plan)

    (repair_requirements ++ strategic_requirements)
    |> Enum.uniq()
    |> Enum.sort_by(&{&1["activity_id"], &1["action"]})
  end

  defp strategic_requirements(candidate_plan) do
    candidate_plan
    |> Map.get("strategic_additions", [])
    |> Enum.map(fn activity ->
      requirement =
        %{
          "schema_contract" => "approval_requirement.v1",
          "activity_id" => ActivityIdentity.activity_id(activity),
          "activity_type" => activity["type"],
          "requirement_type" =>
            RepairAccumulator.approval_requirement_type("approve_strategic_addition", activity),
          "action" => "approve_strategic_addition",
          "reason" => get_in(activity, ["repair", "reason"]) || "strategic_branch_change",
          "activity_context" => StrategicAdditionActivityContext.build(activity)
        }

      requirement
      |> maybe_put_candidate_diff(
        get_in(activity, ["repair", "candidate_diff"]) ||
          get_in(activity, ["feasibility", "candidate_diff"])
      )
    end)
  end

  defp maybe_put_candidate_diff(metadata, nil), do: metadata

  defp maybe_put_candidate_diff(metadata, row) do
    CandidateDiffMetadata.put(metadata, row)
  end
end
