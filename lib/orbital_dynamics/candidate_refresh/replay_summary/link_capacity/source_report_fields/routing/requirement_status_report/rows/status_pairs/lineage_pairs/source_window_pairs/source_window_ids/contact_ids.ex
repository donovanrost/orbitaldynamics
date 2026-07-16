defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.LinkCapacity.SourceReportFields.Routing.RequirementStatusReport.Rows.StatusPairs.LineagePairs.SourceWindowPairs.SourceWindowIds.ContactIds do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.LinkCapacity.SourceReportFields.Routing.RequirementStatusReport.Rows.StatusPairs.Normalization
  alias __MODULE__.ContactSourceWindowIds

  @selected_contact_object_fields [
    "selected_contacts",
    "selected_contact"
  ]

  @actual_throughput_contact_object_fields [
    "actual_throughput_contacts",
    "actual_throughput_contact"
  ]

  def selected_contact_ids(row), do: row_source_window_ids(row, @selected_contact_object_fields)

  def actual_throughput_contact_ids(row),
    do: row_source_window_ids(row, @actual_throughput_contact_object_fields)

  defp row_source_window_ids(row, fields) do
    fields
    |> Enum.flat_map(fn field -> row |> Map.get(field) |> List.wrap() end)
    |> List.flatten()
    |> Enum.flat_map(&ContactSourceWindowIds.contact_source_window_ids/1)
    |> sorted_non_empty_values()
    |> case do
      nil -> nil
      source_window_ids -> source_window_ids
    end
  end

  defp sorted_non_empty_values(values), do: Normalization.sorted_non_empty_values(values)
end
