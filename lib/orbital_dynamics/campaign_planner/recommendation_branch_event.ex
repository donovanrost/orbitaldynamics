defmodule OrbitalDynamics.CampaignPlanner.RecommendationBranchEvent do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.PlanBranch

  def rows(%PlanBranch{} = recommended, event_fields_fun) when is_function(event_fields_fun, 1) do
    case event_fields_fun.(recommended) do
      %{"branch_event_count" => 0} ->
        []

      %{} = event_fields ->
        [
          event_fields
          |> Map.put("type", "branch_event_summary")
          |> Map.put("recommended_branch_id", recommended.id)
          |> Map.put("reason", "recommended branch includes strategy branch events")
        ]
    end
  end

  def rows(_branch, _event_fields_fun), do: []
end
