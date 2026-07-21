defmodule OrbitalDynamics.Schema.CampaignPlanContactIntentContracts do
  @moduledoc false

  import OrbitalDynamics.Schema.PrimitiveValidation, only: [error: 2]

  alias OrbitalDynamics.Communications.ContactIntent
  alias OrbitalDynamics.Schema.{ActivityContracts, ContactIntentContracts}

  def validate(issues, artifact) when is_map(artifact) do
    candidates = Map.get(artifact, "candidate_activities")
    contact_intents = Map.get(artifact, "contact_intents")

    with true <- derivable_candidates?(candidates),
         true <- valid_intent_rows?(contact_intents),
         {:ok, expected_intents} <- derived_intents(candidates) do
      validate_derived_intents(issues, contact_intents, expected_intents)
    else
      _reason -> issues
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

  defp valid_intent_rows?(rows) when is_list(rows) do
    Enum.with_index(rows)
    |> Enum.all?(fn
      {%{} = intent, index} ->
        ContactIntentContracts.validate([], "$.contact_intents[#{index}]", intent) == []

      {_intent, _index} ->
        false
    end)
  end

  defp valid_intent_rows?(_rows), do: false

  defp derived_intents(candidates) do
    {:ok, ContactIntent.from_activities(candidates)}
  rescue
    ArgumentError -> :error
  end

  defp validate_derived_intents(issues, actual, expected)
       when length(actual) != length(expected) do
    [
      error(
        "$.contact_intents",
        "must match candidate-derived contact intent count"
      )
      | issues
    ]
  end

  defp validate_derived_intents(issues, actual, expected) do
    actual
    |> Enum.zip(expected)
    |> Enum.with_index()
    |> Enum.reduce(issues, fn {{actual_row, expected_row}, index}, acc ->
      if Map.take(actual_row, Map.keys(expected_row)) == expected_row do
        acc
      else
        [
          error(
            "$.contact_intents[#{index}]",
            "must match candidate-derived contact intent base snapshot"
          )
          | acc
        ]
      end
    end)
  end
end
