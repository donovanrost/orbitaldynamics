defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ResourceProjection.RowIdentities.StableEntityIds.CandidateValues do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.ResourceProjection.RowIdentities.StableEntityIds.DirectValues

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.ResourceProjection.RowIdentities.StableEntityIds.FallbackValues

  def station_id(row) do
    DirectValues.station_id(row) ||
      FallbackValues.station_id(row)
  end

  def spacecraft_id(row) do
    DirectValues.spacecraft_id(row) ||
      FallbackValues.spacecraft_id(row)
  end
end
