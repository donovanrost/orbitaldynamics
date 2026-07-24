defmodule OrbitalDynamics.CampaignPlanner.RepairContactContentionResolutionPressure do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.{ActivityIdentity, ValueEncoding}

  def group_ids_by_candidate_id(%{"recommendations" => recommendations})
      when is_list(recommendations) do
    recommendations
    |> Enum.filter(&is_map/1)
    |> Enum.map(&ValueEncoding.stringify_keys/1)
    |> Enum.flat_map(&deferred_candidate_group_pairs/1)
    |> Enum.group_by(&elem(&1, 0), &elem(&1, 1))
    |> Map.new(fn {candidate_id, group_ids} ->
      {candidate_id, group_ids |> Enum.uniq() |> Enum.sort()}
    end)
  end

  def group_ids_by_candidate_id(_report), do: %{}

  def selected_count(report, activities) when is_list(activities) do
    selected_ids =
      activities
      |> Enum.filter(&is_map/1)
      |> Enum.map(&ActivityIdentity.activity_id/1)
      |> Enum.reject(&(&1 in [nil, ""]))
      |> MapSet.new()

    report
    |> group_ids_by_candidate_id()
    |> Map.keys()
    |> MapSet.new()
    |> MapSet.intersection(selected_ids)
    |> MapSet.size()
  end

  def selected_count(_report, _activities), do: 0

  defp deferred_candidate_group_pairs(recommendation) do
    group_id = Map.get(recommendation, "group_id")

    if group_id in [nil, ""] do
      []
    else
      recommendation
      |> Map.get("deferred_contact_ids", [])
      |> List.wrap()
      |> Enum.reject(&(&1 in [nil, ""]))
      |> Enum.map(&{&1, group_id})
    end
  end
end
