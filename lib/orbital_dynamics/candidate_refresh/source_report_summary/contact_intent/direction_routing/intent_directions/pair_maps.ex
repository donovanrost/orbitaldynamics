defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactIntent.DirectionRouting.IntentDirections.PairMaps do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common.EncodedValue

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactIntent.DirectionRouting.IntentDirections.RowValues

  alias __MODULE__.KeyedIds

  def direction_counts(intents) do
    intents
    |> direction_contact_pairs()
    |> KeyedIds.id_counts_by_key()
  end

  def contact_ids_by_direction(intents) do
    intents
    |> direction_contact_pairs()
    |> KeyedIds.ids_by_key()
  end

  def direction_keys(%{} = contact_ids_by_direction) do
    contact_ids_by_direction
    |> Map.keys()
    |> KeyedIds.sorted_non_empty_values()
  end

  defp direction_contact_pairs(intents) do
    intents
    |> Enum.map(&EncodedValue.stringify_keys/1)
    |> Enum.map(fn intent ->
      {RowValues.direction(intent), RowValues.contact_intent_stable_id(intent)}
    end)
    |> Enum.reject(fn {direction, contact_id} ->
      direction in [nil, ""] or contact_id in [nil, ""]
    end)
  end
end
