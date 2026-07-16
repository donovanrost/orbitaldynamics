defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ObjectiveGap.ObjectiveTradeoffFields.RowValues.IdentityCounts do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceObjectives.ObjectiveSatisfaction,
    as: ObjectiveSatisfactionSourceObjectives

  alias OrbitalDynamics.CandidateRefresh.SourceObjectives.ObjectiveTradeoff,
    as: ObjectiveTradeoffSourceObjectives

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [count_source_report_values: 1]

  def ground_station_counts(rows) do
    rows
    |> Enum.map(&ObjectiveTradeoffSourceObjectives.station_id/1)
    |> count_source_report_values()
  end

  def target_counts(rows) do
    rows
    |> Enum.flat_map(&ObjectiveSatisfactionSourceObjectives.target_ids/1)
    |> count_source_report_values()
  end

  def collection_counts(rows) do
    rows
    |> Enum.flat_map(
      &(ObjectiveSatisfactionSourceObjectives.identity_values(&1, "collection_id") || [])
    )
    |> count_source_report_values()
  end

  def source_activity_id_counts(rows) do
    rows
    |> Enum.flat_map(&(ObjectiveTradeoffSourceObjectives.source_activity_ids(&1) || []))
    |> count_source_report_values()
  end
end
