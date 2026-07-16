defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.Constraint.RowFields.RowValues do
  @moduledoc false

  alias __MODULE__.SourceCounts.{GapCounts, RoutingCounts, StatusCounts}
  alias __MODULE__.TrustBoundaries

  def row_trust_boundaries(rows, report) do
    TrustBoundaries.row_trust_boundaries(rows, report)
  end

  def row_count(report), do: length(Map.get(report, "rows", []))

  def downlink_gap_count(report), do: GapCounts.downlink_gap_count(report)

  def resource_margin_count(report), do: GapCounts.resource_margin_count(report)

  def status_counts(report), do: StatusCounts.status_counts(report)

  def ground_station_counts(report), do: RoutingCounts.ground_station_counts(report)

  def metric_counts(report), do: RoutingCounts.metric_counts(report)

  def constraint_id_counts(report), do: RoutingCounts.constraint_id_counts(report)

  def source_activity_id_counts(report), do: RoutingCounts.source_activity_id_counts(report)

  def resource_counts(report), do: RoutingCounts.resource_counts(report)

  def spacecraft_counts(report), do: RoutingCounts.spacecraft_counts(report)
end
