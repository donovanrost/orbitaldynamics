defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ObjectiveGap.ObjectiveSatisfaction.IdentityCounts.IdentityValues do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceObjectives.ObjectiveSatisfaction,
    as: ObjectiveSatisfactionSourceObjectives

  def ground_station_ids(rows) do
    Enum.map(rows, &ObjectiveSatisfactionSourceObjectives.station_id/1)
  end

  def target_ids(rows) do
    Enum.flat_map(rows, &ObjectiveSatisfactionSourceObjectives.target_ids/1)
  end

  def collection_ids(rows) do
    Enum.flat_map(
      rows,
      &(ObjectiveSatisfactionSourceObjectives.identity_values(&1, "collection_id") || [])
    )
  end

  def source_activity_ids(rows) do
    Enum.flat_map(rows, &(ObjectiveSatisfactionSourceObjectives.source_activity_ids(&1) || []))
  end
end
