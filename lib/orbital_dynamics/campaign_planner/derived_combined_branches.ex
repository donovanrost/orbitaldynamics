defmodule OrbitalDynamics.CampaignPlanner.DerivedCombinedBranches do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.{
    StrategyBranchEventAliases,
    StrategyBranchNormalization,
    ValueEncoding
  }

  def build(individual_derived, %{"combine_derived_branches" => true}) do
    combined_events =
      individual_derived
      |> Enum.flat_map(&combined_branch_events/1)
      |> StrategyBranchNormalization.normalize_events(strategy_branch_normalization_callbacks())

    combined_branch_ids =
      individual_derived
      |> Enum.map(& &1["id"])
      |> Enum.reject(&(&1 in [nil, ""]))
      |> Enum.sort()

    if length(combined_branch_ids) >= 2 and combined_events != [] do
      [
        %{
          "id" => "derived_combined_mission_state",
          "label" => "Derived combined mission-state future",
          "events" => combined_events,
          "metadata" => %{
            "derived_source" => "branch_generation.combined_derived",
            "combined_branch_ids" => combined_branch_ids
          }
        }
      ]
    else
      []
    end
  end

  def build(_individual_derived, _policy), do: []

  defp strategy_branch_normalization_callbacks,
    do: [
      stringify_keys: &ValueEncoding.stringify_keys/1,
      normalize_branch_event_aliases: &StrategyBranchEventAliases.normalize/1
    ]

  defp combined_branch_events(%{"id" => branch_id} = branch) do
    branch
    |> Map.get("events", [])
    |> Enum.map(fn event ->
      event
      |> Map.put_new("source_branch_id", branch_id)
      |> Map.update("source_branch_ids", [branch_id], fn
        branch_ids when is_list(branch_ids) -> Enum.uniq(branch_ids ++ [branch_id])
        _value -> [branch_id]
      end)
    end)
  end

  defp combined_branch_events(_branch), do: []
end
