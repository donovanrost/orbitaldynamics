defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ObjectiveGap.ObjectiveSatisfaction.IdentityCounts do
  @moduledoc false

  alias __MODULE__.IdentityValues

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.ObjectiveGap.IdentityCountValues

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.ObjectiveGap.ObjectiveSatisfaction.RowValues

  def ground_station_counts(report) do
    count(report, &IdentityValues.ground_station_ids/1)
  end

  def target_counts(report) do
    count(report, &IdentityValues.target_ids/1)
  end

  def collection_counts(report) do
    count(report, &IdentityValues.collection_ids/1)
  end

  def source_activity_id_counts(report) do
    count(report, &IdentityValues.source_activity_ids/1)
  end

  defp count(report, values_fun) do
    report
    |> RowValues.rows()
    |> IdentityCountValues.count(values_fun)
  end
end
