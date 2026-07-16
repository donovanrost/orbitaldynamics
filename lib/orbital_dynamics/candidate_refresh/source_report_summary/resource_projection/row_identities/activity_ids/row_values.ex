defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ResourceProjection.RowIdentities.ActivityIds.RowValues do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.ResourceProjection.RowIdentities.SourceEntities

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.ResourceProjection.RowIdentities.ActivityIds.ObjectiveSatisfactionIds

  def values(row) do
    [
      row["first_resource_pressure_activity_id"],
      row["activity_ids"],
      row["source_activity_ids"],
      SourceEntities.nested_source_activity_ids(row),
      ObjectiveSatisfactionIds.values(row)
    ]
  end
end
