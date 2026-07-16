defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactFilter.StationSuppressionFields.CountFields.FieldSpecs do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.ContactFilter.SourceReportFields.Report

  def values do
    [
      {"station_suppression_ground_station_counts",
       &Report.station_suppression_ground_station_counts/1},
      {"station_suppression_availability_counts",
       &Report.station_suppression_availability_counts/1},
      {"station_suppression_status_counts", &Report.station_suppression_status_counts/1}
    ]
  end
end
