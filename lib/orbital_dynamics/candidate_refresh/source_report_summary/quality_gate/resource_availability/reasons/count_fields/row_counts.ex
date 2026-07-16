defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.QualityGate.ResourceAvailability.Reasons.CountFields.RowCounts do
  @moduledoc false

  alias __MODULE__.RowMaps
  alias __MODULE__.StationReasonCounts

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [
      numeric_report_count: 2
    ]

  def resource_availability_pressure_count(report) do
    case RowMaps.rows(report) do
      [] ->
        numeric_report_count(report, "resource_availability_pressure_count")

      rows ->
        rows
        |> Enum.map(&numeric_report_count(&1, "resource_availability_pressure_count"))
        |> Enum.sum()
    end
  end

  def resource_availability_reason_counts(report) do
    RowMaps.count_map(report, "resource_availability_reason_counts")
  end

  def station_availability_reason_counts(report) do
    StationReasonCounts.counts(report)
  end

  def resource_blocking_dimension_counts(report) do
    RowMaps.count_map(report, "resource_blocking_dimension_counts")
  end
end
