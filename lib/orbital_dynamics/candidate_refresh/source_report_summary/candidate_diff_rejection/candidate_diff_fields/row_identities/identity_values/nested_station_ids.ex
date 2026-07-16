defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.CandidateDiffRejection.CandidateDiffFields.RowIdentities.IdentityValues.NestedStationIds do
  @moduledoc false

  @station_keys ["ground_station", "station"]
  @identity_keys ["ground_station_id", "station_id", "id"]

  def value(candidate) do
    Enum.find_value(@station_keys, fn station_key ->
      case Map.get(candidate, station_key) do
        %{} = station -> station_id(station)
        _station -> nil
      end
    end)
  end

  defp station_id(station) do
    Enum.find_value(@identity_keys, &Map.get(station, &1))
  end
end
