defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.StationCalendar.SourceReportFields.ProviderContention.Report do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.StationCalendar.SourceReportFields.ProviderContention.Report.Rows
  alias __MODULE__.DirectionMaps
  alias __MODULE__.IdentityLists

  import OrbitalDynamics.CandidateRefresh.ReplaySummary.StationCalendar.SourceReportFields.ProviderContention.Report.Rows,
    only: [
      capacity_fractions_by_values: 2,
      count_values: 1,
      group_capacity_fractions: 1,
      normalize_number_list: 1,
      provider_entry_ids_by_values: 2,
      provider_ids: 1,
      stringify_keys: 1
    ]

  def provider_counts(report) do
    report
    |> Map.get("provider_calendar_contention_groups", [])
    |> Enum.flat_map(fn group ->
      group
      |> stringify_keys()
      |> Map.get("provider_ids")
      |> provider_ids()
    end)
    |> count_values()
  end

  def ground_station_counts(report) do
    report
    |> Map.get("provider_calendar_contention_groups", [])
    |> Enum.flat_map(&ground_station_ids/1)
    |> count_values()
  end

  def ground_station_ids(group), do: Rows.ground_station_ids(group)

  def group_ids(reports) do
    IdentityLists.group_ids(reports)
  end

  def source_entry_ids(reports) do
    IdentityLists.source_entry_ids(reports)
  end

  def provider_entry_ids(reports) do
    IdentityLists.provider_entry_ids(reports)
  end

  def capacity_fractions(reports) do
    reports
    |> Enum.flat_map(fn report ->
      report
      |> Map.get("provider_calendar_contention_groups", [])
      |> Enum.flat_map(&group_capacity_fractions/1)
    end)
    |> normalize_number_list()
  end

  def capacity_fractions_by_provider(report) do
    report
    |> Map.get("provider_calendar_contention_groups", [])
    |> capacity_fractions_by_values(fn group ->
      group
      |> stringify_keys()
      |> Map.get("provider_ids")
      |> provider_ids()
    end)
  end

  def capacity_fractions_by_ground_station(report) do
    report
    |> Map.get("provider_calendar_contention_groups", [])
    |> capacity_fractions_by_values(&ground_station_ids/1)
  end

  def provider_entry_ids_by_provider(report) do
    report
    |> Map.get("provider_calendar_contention_groups", [])
    |> provider_entry_ids_by_values(fn group ->
      group
      |> stringify_keys()
      |> Map.get("provider_ids")
      |> provider_ids()
    end)
  end

  def provider_entry_ids_by_ground_station(report) do
    report
    |> Map.get("provider_calendar_contention_groups", [])
    |> provider_entry_ids_by_values(&ground_station_ids/1)
  end

  def direction_counts(report) do
    DirectionMaps.direction_counts(report)
  end

  def group_ids_by_direction(report) do
    DirectionMaps.group_ids_by_direction(report)
  end

  def source_entry_ids_by_direction(report) do
    DirectionMaps.source_entry_ids_by_direction(report)
  end

  def provider_entry_ids_by_direction(report) do
    DirectionMaps.provider_entry_ids_by_direction(report)
  end

  def provider_ids_by_direction(report) do
    DirectionMaps.provider_ids_by_direction(report)
  end

  def capacity_fractions_by_direction(report) do
    DirectionMaps.capacity_fractions_by_direction(report)
  end
end
