defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ResourceProjection.RowIdentities.StableEntityIds.DirectValues do
  @moduledoc false

  def station_id(row) do
    row["first_resource_pressure_ground_station_id"] ||
      row["ground_station_id"] ||
      row["station_id"]
  end

  def spacecraft_id(row), do: row["spacecraft_id"]
end
