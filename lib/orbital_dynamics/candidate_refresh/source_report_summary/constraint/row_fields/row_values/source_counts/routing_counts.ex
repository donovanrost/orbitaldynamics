defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.Constraint.RowFields.RowValues.SourceCounts.RoutingCounts do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.Constraint.RowFields.RowValues.SourceCounts.CountValues

  alias __MODULE__.ObjectiveCounts

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.Constraint.RowFields.RowValues.SourceCounts.Rows

  def ground_station_counts(report) do
    ObjectiveCounts.counts(report, &Rows.station_id/1)
  end

  def metric_counts(report) do
    ObjectiveCounts.counts(report, &Rows.metric/1)
  end

  def constraint_id_counts(report) do
    ObjectiveCounts.counts(report, &Rows.constraint_id/1)
  end

  def source_activity_id_counts(report) do
    report
    |> rows()
    |> CountValues.source_activity_id_counts()
  end

  def resource_counts(report) do
    ObjectiveCounts.counts(report, &Rows.resource_id/1)
  end

  def spacecraft_counts(report) do
    ObjectiveCounts.counts(report, &Rows.spacecraft_id/1)
  end

  defp rows(report), do: Rows.rows(report)
end
