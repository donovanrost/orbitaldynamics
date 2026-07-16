defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.ContactFilter.SourceReportFields.Report.Rows.StationSuppressionGroups do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.ContactFilter.SourceReportFields.Report.Rows.RowValues

  def contact_ids_by(rows, key_fun) do
    ids_by(rows, key_fun, &RowValues.row_contact_id/1)
  end

  def ids_by(rows, key_fun, id_fun) do
    rows
    |> Enum.reduce(%{}, fn row, acc ->
      key = key_fun.(row)
      identifier = id_fun.(row)

      if key in [nil, ""] or identifier in [nil, ""] do
        acc
      else
        Map.update(acc, key, [identifier], fn current ->
          ([identifier] ++ current)
          |> Enum.uniq()
          |> Enum.sort()
        end)
      end
    end)
    |> non_empty_map()
  end

  def nested_station_id(candidate) do
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

  defp non_empty_map(nil), do: nil
  defp non_empty_map(map) when map_size(map) == 0, do: nil
  defp non_empty_map(map), do: map
end
