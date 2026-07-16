defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.StationCalendar.SourceReportFields.ProviderContention.Report.DirectionMaps do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.StationCalendar.SourceReportFields.ProviderContention.Report.Rows

  import Rows,
    only: [
      count_values: 1,
      directions: 1,
      group_capacity_fractions: 1,
      group_provider_entry_ids: 1,
      group_source_entry_ids: 1,
      numeric_values_by_direction: 2,
      provider_ids: 1,
      stable_id_or_nil: 1,
      stringify_keys: 1,
      values_by_direction: 2
    ]

  def direction_counts(report) do
    report
    |> groups()
    |> Enum.flat_map(&(directions(&1) || []))
    |> count_values()
  end

  def group_ids_by_direction(report) do
    report
    |> groups()
    |> values_by_direction(fn group ->
      group
      |> stringify_keys()
      |> Map.get("id")
      |> stable_id_or_nil()
      |> List.wrap()
      |> Enum.reject(&is_nil/1)
    end)
  end

  def source_entry_ids_by_direction(report) do
    report
    |> groups()
    |> values_by_direction(&group_source_entry_ids/1)
  end

  def provider_entry_ids_by_direction(report) do
    report
    |> groups()
    |> values_by_direction(&group_provider_entry_ids/1)
  end

  def provider_ids_by_direction(report) do
    report
    |> groups()
    |> values_by_direction(fn group ->
      group
      |> stringify_keys()
      |> Map.get("provider_ids")
      |> provider_ids()
    end)
  end

  def capacity_fractions_by_direction(report) do
    report
    |> groups()
    |> numeric_values_by_direction(&group_capacity_fractions/1)
  end

  defp groups(report), do: Map.get(report, "provider_calendar_contention_groups", [])
end
