defmodule OrbitalDynamics.CandidateRefresh.SourceObjectives.LinkCapacity do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.ValueEncoding

  def objectives(source_reports) when is_list(source_reports) do
    Enum.flat_map(source_reports, fn {path, report} ->
      report
      |> report_objective_rows()
      |> Enum.map(&stringify_keys/1)
      |> Enum.with_index(1)
      |> Enum.flat_map(fn {row, index} ->
        row =
          Map.put_new(
            row,
            "_source_report_trust_boundary",
            result_artifact_trust_boundary(report)
          )

        row_objectives(path, row, index)
      end)
    end)
  end

  def objectives(_source_reports), do: []

  defp report_objective_rows(%{"rows" => rows} = report) when is_list(rows) do
    rows =
      rows
      |> Enum.map(&stringify_keys/1)
      |> Enum.map(&Map.put_new(&1, "source_report", "rows"))

    if Enum.any?(rows, &downlink_pressure?/1) do
      rows
    else
      [Map.put(report, "source_report", "top_level")]
    end
  end

  defp report_objective_rows(%{} = report), do: [Map.put(report, "source_report", "top_level")]

  defp row_objectives(path, row, index) do
    row = stringify_keys(row)

    if downlink_pressure?(row) do
      downlink_objectives(path, row, index)
    else
      []
    end
  end

  defp downlink_objectives(path, row, index) do
    required_downlink_mb = required_downlink_mb(row)
    station_id = station_id(row)

    if positive_number_value?(required_downlink_mb) and station_id not in [nil, ""] do
      [
        %{
          "id" => objective_id(path, row, index, "downlink_completion"),
          "type" => "downlink_completion",
          "scenario_id" => stable_id_or_nil(row["scenario_id"]),
          "spacecraft_id" => spacecraft_id(row),
          "ground_station_id" => station_id,
          "required_downlink_mb" => required_downlink_mb,
          "source" => "link_capacity_report.rows",
          "source_path" => path,
          "source_link_capacity_report" => row["source_report"],
          "source_selected_downlink_shortfall_mb" =>
            numeric_value(row["selected_downlink_shortfall_mb"]),
          "source_actual_downlink_shortfall_mb" =>
            numeric_value(row["actual_downlink_shortfall_mb"]),
          "source_required_downlink_mb" => numeric_value(row["required_downlink_mb"]),
          "source_capacity_adjusted_throughput_mb" =>
            numeric_value(row["capacity_adjusted_throughput_mb"]),
          "source_selected_capacity_adjusted_throughput_mb" =>
            numeric_value(row["selected_capacity_adjusted_throughput_mb"]),
          "source_unused_capacity_adjusted_throughput_mb" =>
            numeric_value(row["unused_capacity_adjusted_throughput_mb"]),
          "source_downlink_requirement_status" =>
            normalized_token(row["downlink_requirement_status"]),
          "source_actual_downlink_requirement_status" =>
            normalized_token(row["actual_downlink_requirement_status"]),
          "source_activity_ids" => source_contact_ids(row),
          "source_window_id" => source_window_id(row),
          "source_window_ids" => source_window_ids(row),
          "trust_boundary" => trust_boundary(row)
        }
        |> compact_map()
      ]
    else
      []
    end
  end

  defp downlink_pressure?(row) do
    positive_number_value?(required_downlink_mb(row)) and station_id(row) not in [nil, ""]
  end

  defp required_downlink_mb(row) do
    first_positive_number(row, [
      "selected_downlink_shortfall_mb",
      "actual_downlink_shortfall_mb"
    ])
  end

  defp station_id(row) do
    [
      row["ground_station_id"],
      row["station_id"],
      nested_station_id(row)
    ]
    |> Enum.find_value(&stable_id_or_nil/1)
  end

  defp spacecraft_id(row) do
    [
      row["spacecraft_id"],
      row["source_spacecraft_id"],
      row["scenario_id"],
      source_contact_values(row)
      |> Enum.filter(&is_map/1)
      |> Enum.map(&stringify_keys/1)
      |> Enum.flat_map(fn contact ->
        [
          contact["spacecraft_id"],
          contact["scenario_id"],
          get_in(contact, ["spacecraft", "id"]),
          get_in(contact, ["satellite", "id"])
        ]
      end)
    ]
    |> List.flatten()
    |> Enum.find_value(&stable_id_or_nil/1)
  end

  defp source_contact_ids(row) do
    row
    |> source_contact_values()
    |> Enum.map(&source_contact_id/1)
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.uniq()
    |> Enum.sort()
    |> case do
      [] -> nil
      ids -> ids
    end
  end

  defp source_contact_values(row) do
    [
      row["selected_contact_ids"],
      row["selected_contact_id"],
      row["actual_throughput_contact_ids"],
      row["actual_throughput_contact_id"],
      row["actual_completion_contact_ids"],
      row["actual_completion_contact_id"],
      row["required_downlink_contact_ids"],
      row["required_downlink_contact_id"],
      row["contact_ids"],
      row["contact_id"],
      row["selected_contacts"],
      row["selected_contact"],
      row["actual_throughput_contacts"],
      row["actual_throughput_contact"],
      row["actual_completion_contacts"],
      row["actual_completion_contact"],
      row["required_downlink_contacts"],
      row["required_downlink_contact"],
      row["source_contacts"],
      row["source_contact"],
      row["contacts"],
      row["contact"]
    ]
    |> List.flatten()
  end

  defp source_contact_id(%{} = contact) do
    contact = stringify_keys(contact)

    [
      contact["id"],
      contact["activity_id"],
      contact["contact_id"],
      get_in(contact, ["activity_context", "id"]),
      get_in(contact, ["activity_context", "activity_id"])
    ]
    |> Enum.find_value(&stable_id_or_nil/1)
  end

  defp source_contact_id(value), do: stable_id_or_nil(value)

  defp source_window_id(row) do
    case source_window_ids(row) do
      [source_window_id] -> source_window_id
      _source_window_ids -> nil
    end
  end

  defp source_window_ids(row) do
    [
      row_source_window_ids(row),
      source_contact_window_ids(row)
    ]
    |> List.flatten()
    |> Enum.map(&stable_id_or_nil/1)
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.uniq()
    |> Enum.sort()
    |> case do
      [] -> nil
      source_window_ids -> source_window_ids
    end
  end

  defp row_source_window_ids(row) do
    [
      row["source_window_id"],
      row["source_window_ids"],
      get_in(row, ["source_window", "id"]),
      get_in(row, ["activity_context", "source_window_id"])
    ]
    |> List.flatten()
    |> Enum.map(&stable_id_or_nil/1)
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp source_contact_window_ids(row) do
    row
    |> source_contact_values()
    |> Enum.filter(&is_map/1)
    |> Enum.map(&stringify_keys/1)
    |> Enum.flat_map(&contact_source_window_ids/1)
  end

  defp contact_source_window_ids(%{} = contact) do
    contact = stringify_keys(contact)

    [
      contact["source_window_id"],
      get_in(contact, ["source_window", "id"]),
      get_in(contact, ["activity_context", "source_window_id"])
    ]
    |> List.flatten()
    |> Enum.map(&stable_id_or_nil/1)
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp contact_source_window_ids(_contact), do: []

  defp trust_boundary(row) do
    Map.get(row, "trust_boundary") ||
      get_in(row, ["provenance", "trust_boundary"]) ||
      get_in(row, ["source_link_capacity", "trust_boundary"]) ||
      get_in(row, ["source_link_capacity", "provenance", "trust_boundary"]) ||
      row["_source_report_trust_boundary"]
  end

  defp objective_id(path, row, index, type) do
    base =
      stable_id_or_nil(row["id"]) ||
        stable_id_or_nil(row["ground_station_id"]) ||
        stable_id_or_nil(row["station_id"]) ||
        "#{type}:#{index}"

    hash =
      :crypto.hash(:sha256, :erlang.term_to_binary({path, row, index, type}))
      |> Base.encode16(case: :lower)
      |> binary_part(0, 8)

    ["link_capacity", type, base, hash]
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.join(":")
  end

  defp result_artifact_trust_boundary(artifact) do
    artifact = stringify_keys(artifact)

    Map.get(artifact, "trust_boundary") ||
      get_in(artifact, ["provenance", "trust_boundary"]) ||
      get_in(artifact, ["metadata", "trust_boundary"]) ||
      get_in(artifact, ["assumptions", "trust_boundary"])
  end

  defp first_positive_number(row, paths) do
    paths
    |> Enum.find_value(fn path ->
      case number(row, path) do
        value when is_number(value) and value > 0.0 -> value
        _value -> nil
      end
    end)
  end

  defp number(row, path) when is_list(path), do: row |> get_in(path) |> numeric_value()
  defp number(row, path), do: row |> Map.get(path) |> numeric_value()

  defp nested_station_id(candidate) do
    Enum.find_value(["ground_station", "station"], fn station_key ->
      case Map.get(candidate, station_key) do
        %{} = station ->
          station = stringify_keys(station)

          Enum.find_value(["ground_station_id", "station_id", "id"], fn identity_key ->
            Map.get(station, identity_key)
          end)

        _station ->
          nil
      end
    end)
  end

  defp positive_number_value?(value), do: is_number(value) and value > 0.0

  defp stable_id_or_nil(value), do: ValueEncoding.stable_id_or_nil(value)
  defp stringify_keys(value), do: ValueEncoding.stringify_keys(value)
  defp normalized_token(value), do: ValueEncoding.normalized_token(value)
  defp numeric_value(value), do: ValueEncoding.numeric_value(value)
  defp compact_map(map), do: ValueEncoding.compact_nil_values(map)
end
