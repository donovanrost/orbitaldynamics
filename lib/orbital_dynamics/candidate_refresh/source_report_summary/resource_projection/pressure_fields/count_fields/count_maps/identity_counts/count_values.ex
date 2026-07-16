defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ResourceProjection.PressureFields.CountFields.CountMaps.IdentityCounts.CountValues do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.ResourceProjection.PressureFields.CountFields.CountMaps.IdentityCounts.RowValues
  alias __MODULE__.ReportCounts

  def ground_station_counts(report) do
    ReportCounts.from_report(report, &RowValues.ground_station_ids/1)
  end

  def spacecraft_counts(report) do
    ReportCounts.from_report(report, &RowValues.spacecraft_ids/1)
  end

  def activity_id_counts(report) do
    ReportCounts.from_report(report, &RowValues.activity_ids/1)
  end
end
