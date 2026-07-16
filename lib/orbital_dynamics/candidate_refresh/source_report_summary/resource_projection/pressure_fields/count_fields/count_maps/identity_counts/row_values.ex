defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ResourceProjection.PressureFields.CountFields.CountMaps.IdentityCounts.RowValues do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.ResourceProjection.RowIdentities
  alias __MODULE__.ProjectedValues

  def ground_station_ids(report) do
    ProjectedValues.map(report, &RowIdentities.station_id/1)
  end

  def spacecraft_ids(report) do
    ProjectedValues.map(report, &RowIdentities.spacecraft_id/1)
  end

  def activity_ids(report) do
    ProjectedValues.flat_map(report, &(RowIdentities.source_activity_ids(&1) || []))
  end
end
