defmodule OrbitalDynamics.CampaignPlanner.RecommendationApproval do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.PlanBranch

  def rows(%PlanBranch{} = recommended) do
    Enum.map(recommended.approval_requirements, fn requirement ->
      %{
        "type" => "approval_driver",
        "activity_id" => requirement["activity_id"],
        "action" => requirement["action"],
        "classification" => requirement["policy_classification"] || recommended.approval_status,
        "reason" => requirement["reason"]
      }
    end)
  end

  def rows(_branch), do: []
end
