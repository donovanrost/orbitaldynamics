defmodule OrbitalDynamics.Schema.CampaignPlanProposedContactContracts do
  @moduledoc false

  import OrbitalDynamics.Schema.PrimitiveValidation, only: [error: 2]

  alias OrbitalDynamics.CampaignPlanner.DownlinkActivityNormalization
  alias OrbitalDynamics.Schema.ActivityContracts

  def validate(issues, artifact) when is_map(artifact) do
    candidates = Map.get(artifact, "candidate_activities")
    proposed_contacts = Map.get(artifact, "proposed_contacts")

    if derivable_candidates?(candidates) and map_rows?(proposed_contacts) do
      validate_derived_contacts(
        issues,
        proposed_contacts,
        DownlinkActivityNormalization.proposed_contacts(candidates)
      )
    else
      issues
    end
  end

  defp derivable_candidates?(candidates) when is_list(candidates) do
    Enum.with_index(candidates)
    |> Enum.all?(fn
      {%{} = candidate, index} ->
        ActivityContracts.validate([], "$.candidate_activities[#{index}]", candidate) == []

      {_candidate, _index} ->
        false
    end)
  end

  defp derivable_candidates?(_candidates), do: false

  defp map_rows?(rows) when is_list(rows), do: Enum.all?(rows, &is_map/1)
  defp map_rows?(_rows), do: false

  defp validate_derived_contacts(issues, actual, expected)
       when length(actual) != length(expected) do
    [
      error(
        "$.proposed_contacts",
        "must match candidate-derived proposed contact count"
      )
      | issues
    ]
  end

  defp validate_derived_contacts(issues, actual, expected) do
    actual
    |> Enum.zip(expected)
    |> Enum.with_index()
    |> Enum.reduce(issues, fn {{actual_row, expected_row}, index}, acc ->
      if Map.take(actual_row, Map.keys(expected_row)) == expected_row do
        acc
      else
        [
          error(
            "$.proposed_contacts[#{index}]",
            "must match candidate-derived proposed contact snapshot"
          )
          | acc
        ]
      end
    end)
  end
end
