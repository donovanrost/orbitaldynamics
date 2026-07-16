defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.LinkCapacity.SourceReportFields.Routing.RequirementStatusReport.Rows.StatusPairs do
  @moduledoc false

  alias __MODULE__.ContactIds
  alias __MODULE__.LineagePairs
  alias __MODULE__.Normalization

  def requirement_status_contact_pairs(row) do
    row = stringify_keys(row)

    [
      {row["downlink_requirement_status"], ContactIds.selected_contact_ids(row)},
      {row["actual_downlink_requirement_status"], ContactIds.actual_throughput_contact_ids(row)}
    ]
    |> Enum.flat_map(fn {status, contact_ids} ->
      status = normalized_token(status)

      contact_ids
      |> List.wrap()
      |> Enum.map(&{status, &1})
    end)
    |> Enum.reject(fn {status, contact_id} -> status in [nil, ""] or contact_id in [nil, ""] end)
    |> Enum.uniq()
  end

  def requirement_status_source_window_pairs(row) do
    LineagePairs.requirement_status_source_window_pairs(row)
  end

  def requirement_status_station_calendar_entry_pairs(row) do
    LineagePairs.requirement_status_station_calendar_entry_pairs(row)
  end

  def requirement_status_station_calendar_provider_entry_pairs(row) do
    LineagePairs.requirement_status_station_calendar_provider_entry_pairs(row)
  end

  defp normalized_token(value), do: Normalization.normalized_token(value)
  defp stringify_keys(value), do: Normalization.stringify_keys(value)
end
