defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.CandidateDiffRejection.CandidateRejectionFields.RowValues.Rows.IdentityValues do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common.StableIds

  def candidate_id(row) do
    row
    |> Map.get("candidate_id")
    |> StableIds.stable_id_or_nil()
  end

  def ground_station_id(%{} = row) do
    [
      Map.get(row, "ground_station_id"),
      get_in(row, ["activity_context", "ground_station_id"])
    ]
    |> Enum.find_value(&StableIds.stable_id_or_nil/1)
  end

  def ground_station_id(_row), do: nil
end
