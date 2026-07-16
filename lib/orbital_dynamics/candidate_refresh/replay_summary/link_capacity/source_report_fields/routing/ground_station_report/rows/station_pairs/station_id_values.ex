defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.LinkCapacity.SourceReportFields.Routing.GroundStationReport.Rows.StationPairs.StationIdValues do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.LinkCapacity.SourceReportFields.Routing.GroundStationReport.Rows.StationPairs.Normalization

  def station_id(row) do
    [
      row["ground_station_id"],
      row["station_id"],
      nested_station_id(row)
    ]
    |> Enum.find_value(&stable_id_or_nil/1)
  end

  defp nested_station_id(candidate) do
    Enum.find_value(["ground_station", "station"], fn station_key ->
      case Map.get(candidate, station_key) do
        %{} = station ->
          Enum.find_value(["ground_station_id", "station_id", "id"], fn identity_key ->
            Map.get(station, identity_key)
          end)

        _station ->
          nil
      end
    end)
  end

  defp stable_id_or_nil(value), do: Normalization.stable_id_or_nil(value)
end
