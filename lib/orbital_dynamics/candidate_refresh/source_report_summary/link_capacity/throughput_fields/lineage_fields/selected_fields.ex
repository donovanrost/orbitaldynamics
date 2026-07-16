defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.LinkCapacity.ThroughputFields.LineageFields.SelectedFields do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.LinkCapacity.SourceReportFields.Throughput.LineageReport,
    as: ThroughputLineageReport

  alias __MODULE__.MergedValues

  def fields(reports) do
    %{
      "selected_contact_ids" =>
        MergedValues.string_list(reports, &ThroughputLineageReport.selected_contact_ids/1),
      "selected_source_window_ids" =>
        MergedValues.string_list(reports, &ThroughputLineageReport.selected_source_window_ids/1),
      "selected_station_calendar_entry_ids" =>
        MergedValues.string_list(
          reports,
          &ThroughputLineageReport.selected_station_calendar_entry_ids/1
        ),
      "selected_station_calendar_provider_entry_ids" =>
        MergedValues.string_list(
          reports,
          &ThroughputLineageReport.selected_station_calendar_provider_entry_ids/1
        ),
      "selected_contact_id_counts" =>
        MergedValues.count_map(reports, &ThroughputLineageReport.selected_contact_id_counts/1)
    }
  end
end
