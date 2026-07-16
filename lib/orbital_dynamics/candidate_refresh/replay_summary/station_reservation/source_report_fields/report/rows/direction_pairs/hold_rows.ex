defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.StationReservation.SourceReportFields.Report.Rows.DirectionPairs.HoldRows do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.StationReservation.SourceReportFields.Report.Rows.DirectionPairs.Normalization

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.StationReservation.SourceReportFields.Report.Rows.DirectionPairs.RowValues

  def hold_ids_by_direction_from_rows(report) do
    if hold_replay_report?(report) do
      report
      |> report_rows()
      |> Enum.flat_map(fn row ->
        row = stringify_keys(row)
        directions = row_directions(row)
        reservation_ids = row_reservation_ids(row)

        for direction <- directions,
            reservation_id <- reservation_ids,
            direction not in [nil, ""],
            reservation_id not in [nil, ""] do
          {direction, reservation_id}
        end
      end)
      |> Enum.uniq()
      |> grouped_ids()
    end
  end

  def hold_contact_ids_by_direction_from_rows(report) do
    if hold_replay_report?(report) do
      report
      |> report_rows()
      |> Enum.flat_map(fn row ->
        row = stringify_keys(row)
        directions = row_directions(row)
        contact_ids = row_contact_ids(row)

        for direction <- directions,
            contact_id <- contact_ids,
            direction not in [nil, ""],
            contact_id not in [nil, ""] do
          {direction, contact_id}
        end
      end)
      |> Enum.uniq()
      |> grouped_ids()
    end
  end

  defp report_rows(report) do
    Map.get(report, "affected_contacts", []) ++
      Map.get(report, "provider_calendar_contention_groups", [])
  end

  defp grouped_ids(pairs) do
    pairs
    |> Enum.reject(fn {key, value} -> key in [nil, ""] or value in [nil, ""] end)
    |> Enum.group_by(fn {key, _value} -> to_string(key) end, fn {_key, value} -> value end)
    |> Map.new(fn {key, values} -> {key, sorted_string_values(values)} end)
    |> non_empty_map()
  end

  defp sorted_string_values(values) when is_list(values) do
    values
    |> Enum.map(&encode_value/1)
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp sorted_string_values(_values), do: []

  defp hold_import_readiness_report?(report) do
    report = stringify_keys(report)

    report["model"] == "preserved_station_reservation_hold_import_readiness_summary" or
      Map.has_key?(report, "reservation_hold_import_status_counts") or
      Map.has_key?(report, "required_import_action_counts") or
      Map.has_key?(report, "import_readiness_status") or
      Map.has_key?(report, "import_classification")
  end

  defp hold_replay_report?(report) do
    report = stringify_keys(report)

    report["model"] in [
      "preserved_station_reservation_hold_summary",
      "preserved_station_reservation_hold_import_readiness_summary"
    ] or hold_import_readiness_report?(report)
  end

  defp row_directions(row), do: RowValues.row_directions(row)

  defp row_contact_ids(row), do: RowValues.row_contact_ids(row)

  defp row_reservation_ids(row), do: RowValues.row_reservation_ids(row)

  defp stringify_keys(value), do: Normalization.stringify_keys(value)

  defp encode_value(value), do: Normalization.encode_value(value)

  defp non_empty_map(map) when map_size(map) == 0, do: nil
  defp non_empty_map(map), do: map
end
