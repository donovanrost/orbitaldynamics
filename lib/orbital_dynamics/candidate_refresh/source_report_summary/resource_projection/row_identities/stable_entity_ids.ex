defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ResourceProjection.RowIdentities.StableEntityIds do
  @moduledoc false

  alias __MODULE__.CandidateValues
  alias __MODULE__.RowValues
  alias __MODULE__.StableValues

  def station_id(row) do
    row
    |> RowValues.normalize()
    |> CandidateValues.station_id()
    |> StableValues.id()
  end

  def spacecraft_id(row) do
    row
    |> RowValues.normalize()
    |> CandidateValues.spacecraft_id()
    |> StableValues.id()
  end
end
