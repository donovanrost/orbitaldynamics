defmodule OrbitalDynamics.Schema.CampaignRepairProducedSurfaceContracts do
  @moduledoc false

  import OrbitalDynamics.Schema.PrimitiveValidation,
    only: [error: 2, validate_non_negative_integer_count_map: 3]

  @preserved_actions ~w(preserved preserved_executed)

  def validate(issues, artifact) do
    issues
    |> validate_change_summary(artifact)
    |> validate_preserved_activities(artifact)
  end

  defp validate_change_summary(issues, artifact) do
    summary = Map.get(artifact, "change_summary")
    deltas = Map.get(artifact, "deltas")

    issues =
      validate_non_negative_integer_count_map(issues, "$.change_summary", summary)

    if is_map(summary) and is_list(deltas) do
      expected =
        deltas
        |> Enum.filter(&is_map/1)
        |> Enum.map(&Map.get(&1, "repair_action"))
        |> Enum.reject(&is_nil/1)
        |> Enum.frequencies()

      if summary == expected do
        issues
      else
        [error("$.change_summary", "must equal row-derived delta repair-action counts") | issues]
      end
    else
      issues
    end
  end

  defp validate_preserved_activities(issues, artifact) do
    preserved = Map.get(artifact, "preserved_activities")
    activities = Map.get(artifact, "activities")

    if is_list(preserved) and is_list(activities) do
      expected =
        Enum.filter(activities, fn activity ->
          is_map(activity) and get_in(activity, ["repair", "action"]) in @preserved_actions
        end)

      if preserved == expected do
        issues
      else
        [
          error(
            "$.preserved_activities",
            "must equal row-derived preserved activities in repaired activity order"
          )
          | issues
        ]
      end
    else
      issues
    end
  end
end
