defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.StationReservation.ProviderContentionFields do
  @moduledoc false

  alias __MODULE__.Aggregates

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.StationCalendar.SourceReportFields.ProviderContention.Report,
    as: ProviderContentionReport

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.StationReservation.SourceReportFields.Report

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [
      sum_report_count: 2
    ]

  def fields(reports) do
    reports
    |> base_fields()
    |> Map.merge(Aggregates.fields(reports))
  end

  defp base_fields(reports) do
    %{
      "provider_calendar_contention_group_count" =>
        sum_report_count(reports, &Report.provider_calendar_contention_group_count/1),
      "provider_calendar_contention_group_ids" => ProviderContentionReport.group_ids(reports),
      "provider_calendar_contention_source_entry_ids" =>
        ProviderContentionReport.source_entry_ids(reports),
      "provider_calendar_contention_provider_entry_ids" =>
        ProviderContentionReport.provider_entry_ids(reports)
    }
  end
end
