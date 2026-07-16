defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.StationCalendar.SourceReportFields.ProviderContention.Report.IdentityLists do
  @moduledoc false

  import OrbitalDynamics.CandidateRefresh.ReplaySummary.StationCalendar.SourceReportFields.ProviderContention.Report.Rows,
    only: [
      group_provider_entry_ids: 1,
      source_entries: 1,
      stable_id_or_nil: 1,
      stringify_keys: 1
    ]

  def group_ids(reports) do
    reports
    |> Enum.flat_map(fn report ->
      report
      |> Map.get("provider_calendar_contention_groups", [])
      |> Enum.map(fn group ->
        group
        |> stringify_keys()
        |> Map.get("id")
        |> stable_id_or_nil()
      end)
    end)
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
    |> Enum.sort()
  end

  def source_entry_ids(reports) do
    reports
    |> Enum.flat_map(fn report ->
      report
      |> Map.get("provider_calendar_contention_groups", [])
      |> Enum.flat_map(fn group ->
        group
        |> stringify_keys()
        |> source_entries()
        |> Enum.flat_map(fn entry ->
          [
            entry["station_calendar_provider_entry_id"],
            entry["provider_entry_id"],
            entry["station_calendar_entry_id"],
            entry["id"]
          ]
        end)
      end)
    end)
    |> Enum.map(&stable_id_or_nil/1)
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
    |> Enum.sort()
  end

  def provider_entry_ids(reports) do
    reports
    |> Enum.flat_map(fn report ->
      report
      |> Map.get("provider_calendar_contention_groups", [])
      |> Enum.flat_map(&group_provider_entry_ids/1)
    end)
    |> Enum.uniq()
    |> Enum.sort()
  end
end
