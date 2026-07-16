defmodule OrbitalDynamics.CandidateRefresh.BuildGroundNetwork do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.{
    ContactIntentStationFeedback,
    ContactReportStationFeedback,
    ResultArtifactTrustBoundary,
    StationCalendarReportStationFeedback,
    StationState,
    ValueEncoding
  }

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common.EncodedValue

  alias OrbitalDynamics.CandidateRefresh.SourceReports.ContactIntentCollection,
    as: ContactIntentCollectionSourceReports

  alias OrbitalDynamics.CandidateRefresh.SourceReports.ContactReviewCollection,
    as: ContactReviewCollectionSourceReports

  alias OrbitalDynamics.CandidateRefresh.SourceReports.ResultArtifactCollection,
    as: ResultArtifactCollectionSourceReports

  alias OrbitalDynamics.CandidateRefresh.SourceReports.StationSchedule,
    as: StationScheduleSourceReports

  alias OrbitalDynamics.Communications.StationCalendar

  def build(refresh) do
    raw_entries =
      ground_network_entries(Map.get(refresh, "ground_network")) ++
        ground_network_entries(Map.get(refresh, "station_calendar")) ++
        ground_network_entries(get_in(refresh, ["mission_state", "ground_network"])) ++
        ground_network_entries(get_in(refresh, ["mission_state", "station_calendar"])) ++
        ground_network_entries(get_in(refresh, ["accepted_planning_state", "ground_network"])) ++
        ground_network_entries(get_in(refresh, ["accepted_planning_state", "station_calendar"])) ++
        source_station_calendar_entries(refresh) ++
        source_contact_intent_entries(refresh) ++
        source_contact_filter_entries(refresh) ++
        source_contact_allocation_entries(refresh)

    provider_entries =
      station_calendar_provider_entries(Map.get(refresh, "station_calendar_provider")) ++
        station_calendar_provider_entries(
          get_in(refresh, ["mission_state", "station_calendar_provider"])
        ) ++
        station_calendar_provider_entries(
          get_in(refresh, ["accepted_planning_state", "station_calendar_provider"])
        )

    prefer_provider_station_calendar_entries(raw_entries, provider_entries)
  end

  defp ground_network_entries(entries) when is_list(entries) do
    entries
    |> Enum.map(&stringify_keys/1)
    |> Enum.map(&StationState.normalize_ground_network_station/1)
  end

  defp ground_network_entries(_entries), do: []

  defp stringify_keys(value), do: EncodedValue.value_with_keyword_maps(value)

  defp source_station_calendar_entries(refresh) do
    source_report_ground_network_entries(
      refresh,
      :source_station_calendar_reports,
      &StationCalendarReportStationFeedback.entries/1
    )
  end

  defp source_contact_intent_entries(refresh) do
    source_report_ground_network_entries(
      refresh,
      :source_contact_intents,
      &ContactIntentStationFeedback.entries/1
    )
  end

  defp source_contact_filter_entries(refresh) do
    source_report_ground_network_entries(
      refresh,
      :source_contact_filter_reports,
      &ContactReportStationFeedback.contact_filter_entries/1
    )
  end

  defp source_contact_allocation_entries(refresh) do
    source_report_ground_network_entries(
      refresh,
      :source_contact_allocation_reports,
      &ContactReportStationFeedback.contact_allocation_entries/1
    )
  end

  defp source_report_ground_network_entries(refresh, source_key, entries_fun) do
    refresh
    |> source_reports(source_key)
    |> then(entries_fun)
  end

  defp source_reports(refresh, :source_station_calendar_reports) do
    inherited_result_artifact_source_reports(
      refresh,
      &StationScheduleSourceReports.station_calendar_reports/3
    )
  end

  defp source_reports(refresh, :source_contact_intents) do
    inherited_result_artifact_source_reports(
      refresh,
      &ContactIntentCollectionSourceReports.reports/3
    )
  end

  defp source_reports(refresh, :source_contact_filter_reports) do
    inherited_result_artifact_source_reports(
      refresh,
      &ContactReviewCollectionSourceReports.contact_filter_reports/3
    )
  end

  defp source_reports(refresh, :source_contact_allocation_reports) do
    inherited_result_artifact_source_reports(
      refresh,
      &ContactReviewCollectionSourceReports.contact_allocation_reports/3
    )
  end

  defp inherited_result_artifact_source_reports(refresh, reports_fun) do
    reports_fun.(
      refresh,
      &ResultArtifactCollectionSourceReports.reports/1,
      &ResultArtifactTrustBoundary.inherit/2
    )
  end

  defp station_calendar_provider_entries(%{} = provider),
    do: StationCalendar.to_ground_network(provider)

  defp station_calendar_provider_entries(providers) when is_list(providers) do
    Enum.flat_map(providers, &station_calendar_provider_entries/1)
  end

  defp station_calendar_provider_entries(_provider), do: []

  defp prefer_provider_station_calendar_entries(raw_entries, []),
    do: raw_entries

  defp prefer_provider_station_calendar_entries(raw_entries, provider_entries) do
    provider_entry_ids =
      provider_entries
      |> Enum.flat_map(&station_calendar_explicit_entry_ids/1)
      |> MapSet.new()

    raw_entries
    |> Enum.reject(fn entry ->
      entry
      |> station_calendar_explicit_entry_ids()
      |> Enum.any?(&MapSet.member?(provider_entry_ids, &1))
    end)
    |> Kernel.++(provider_entries)
  end

  defp station_calendar_explicit_entry_ids(station) do
    station
    |> Map.take(["station_calendar_entry_id", "id", "provider_entry_id"])
    |> Map.values()
    |> Enum.map(&stable_id_or_nil/1)
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
  end

  defp stable_id_or_nil(value), do: ValueEncoding.stable_id_or_nil(value)
end
