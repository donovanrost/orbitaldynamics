defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.LinkCapacity.ThroughputFields.LineageFields.ActualFields do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.LinkCapacity.SourceReportFields.Throughput.LineageReport,
    as: ThroughputLineageReport

  alias __MODULE__.MergedValues

  def fields(reports) do
    %{
      "actual_throughput_contact_ids" =>
        MergedValues.string_list(
          reports,
          &ThroughputLineageReport.actual_throughput_contact_ids/1
        ),
      "actual_throughput_source_window_ids" =>
        MergedValues.string_list(
          reports,
          &ThroughputLineageReport.actual_throughput_source_window_ids/1
        ),
      "actual_throughput_station_calendar_entry_ids" =>
        MergedValues.string_list(
          reports,
          &ThroughputLineageReport.actual_throughput_station_calendar_entry_ids/1
        ),
      "actual_throughput_station_calendar_provider_entry_ids" =>
        MergedValues.string_list(
          reports,
          &ThroughputLineageReport.actual_throughput_station_calendar_provider_entry_ids/1
        ),
      "actual_throughput_contact_id_counts" =>
        MergedValues.count_map(
          reports,
          &ThroughputLineageReport.actual_throughput_contact_id_counts/1
        )
    }
  end
end
