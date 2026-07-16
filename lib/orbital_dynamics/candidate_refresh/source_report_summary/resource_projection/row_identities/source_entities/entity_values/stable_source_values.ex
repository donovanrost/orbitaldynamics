defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ResourceProjection.RowIdentities.SourceEntities.EntityValues.StableSourceValues do
  @moduledoc false

  alias __MODULE__.SourceValues

  def station_id(row) do
    SourceValues.station_id(row)
  end

  def spacecraft_id(row) do
    SourceValues.spacecraft_id(row)
  end
end
