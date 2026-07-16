defmodule OrbitalDynamics.CandidateRefresh.SourceReports.StationReservation do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.EntryFallbacks
  alias OrbitalDynamics.CandidateRefresh.SourceReports.StationReservationEncoding
  alias OrbitalDynamics.CandidateRefresh.SourceReports.StationReservationSummaryReports

  def entries(path, value) do
    EntryFallbacks.entries(path, value, fn entry_path, entry_value ->
      report = stringify_keys(entry_value)

      cond do
        report?(report) ->
          {entry_path, report}

        StationReservationSummaryReports.review_summary?(report) ->
          {entry_path, StationReservationSummaryReports.report_from_review_summary(report)}

        StationReservationSummaryReports.hold_summary?(report) ->
          {entry_path, StationReservationSummaryReports.report_from_hold_summary(report)}

        StationReservationSummaryReports.hold_import_readiness_summary?(report) ->
          {entry_path,
           StationReservationSummaryReports.report_from_hold_import_readiness_summary(report)}

        true ->
          nil
      end
    end)
  end

  def report?(%{} = report) do
    rows = Map.get(report, "affected_contacts") || Map.get(report, :affected_contacts)

    provider_groups =
      Map.get(report, "provider_calendar_contention_groups") ||
        Map.get(report, :provider_calendar_contention_groups)

    schema_contract = Map.get(report, "schema_contract") || Map.get(report, :schema_contract)

    (is_list(rows) or is_list(provider_groups)) and
      schema_contract in [nil, "station_reservation_report.v1"]
  end

  def report?(_report), do: false

  defp stringify_keys(value), do: StationReservationEncoding.stringify_keys(value)
end
