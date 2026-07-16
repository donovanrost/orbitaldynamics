defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.TimelinePreservation.Summary.Counts do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.TimelinePreservation.Summary.RowValues

  def counts(rows) do
    %{
      source_paths: source_paths(rows),
      required_action_counts: field_counts(rows, "required_operator_action"),
      preservation_status_counts: field_counts(rows, "timeline_preservation_status"),
      protection_decision_counts: field_counts(rows, "timeline_preservation_protection_decision"),
      protection_category_counts: field_counts(rows, "timeline_preservation_protection_category"),
      protection_reason_counts: field_counts(rows, "timeline_preservation_protection_reason"),
      source_contract_counts: rows |> Enum.map(&RowValues.source_contract/1) |> count_values(),
      source_model_counts: rows |> Enum.map(&RowValues.source_model/1) |> count_values(),
      activity_id_counts: count_ids(rows, "activity_id"),
      timeline_id_counts: count_ids(rows, "timeline_id")
    }
  end

  defp source_paths(rows) do
    rows
    |> Enum.map(&Map.get(&1, "source"))
    |> RowValues.sorted_string_values()
  end

  defp field_counts(rows, field) do
    rows
    |> Enum.map(&Map.get(&1, field))
    |> count_values()
  end

  defp count_values(values), do: values |> RowValues.count_values() |> empty_map_if_nil()
  defp count_ids(rows, field), do: rows |> RowValues.count_ids(field) |> empty_map_if_nil()

  defp empty_map_if_nil(%{} = map), do: map
  defp empty_map_if_nil(_map), do: %{}
end
