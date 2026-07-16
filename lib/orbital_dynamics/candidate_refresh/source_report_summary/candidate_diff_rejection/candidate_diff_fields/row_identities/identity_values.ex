defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.CandidateDiffRejection.CandidateDiffFields.RowIdentities.IdentityValues do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common.StableIds

  alias __MODULE__.NestedStationIds

  def candidate_id(%{} = row) do
    StableIds.stable_id_or_nil(
      Map.get(row, "candidate_id") ||
        Map.get(row, "id") ||
        Map.get(row, "activity_id") ||
        get_in(row, ["activity_context", "activity_id"])
    )
  end

  def candidate_id(_row), do: nil

  def ground_station_id(%{} = row) do
    StableIds.stable_id_or_nil(
      Map.get(row, "ground_station_id") ||
        Map.get(row, "station_id") ||
        NestedStationIds.value(row) ||
        get_in(row, ["source_window", "ground_station_id"]) ||
        get_in(row, ["source_window", "station_id"]) ||
        get_in(row, ["activity_context", "ground_station_id"])
    )
  end

  def ground_station_id(_row), do: nil
end
