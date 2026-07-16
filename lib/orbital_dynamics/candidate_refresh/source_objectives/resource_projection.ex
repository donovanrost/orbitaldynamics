defmodule OrbitalDynamics.CandidateRefresh.SourceObjectives.ResourceProjection do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.ValueEncoding

  def objectives(source_reports) when is_list(source_reports) do
    Enum.flat_map(source_reports, fn {path, report} ->
      report
      |> Map.get("projected_resources", [])
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
          "source" => "resource_projection_report.projected_resources",
          "source_path" => path,
          "source_resource_pressure_status" => pressure_status(row),
          "source_resource_pressure_types" => pressure_types(row),
          "source_activity_ids" => source_activity_ids(row),
          "trust_boundary" => trust_boundary(row)
        }
        |> compact_map()
      ]
    else
      []
    end
  end

  defp downlink_pressure?(row) do
    positive_number_value?(required_downlink_mb(row)) and
      station_id(row) not in [nil, ""]
  end

  defp required_downlink_mb(row) do
    first_positive_number(row, [
      "projected_downlink_shortfall_mb",
      "peak_downlink_shortfall_mb",
      "downlink_shortfall_mb",
      "selected_downlink_shortfall_mb",
      "required_downlink_mb",
      "required_data_volume_mb",
      "target_data_volume_mb",
      ["first_resource_pressure", "downlink_shortfall_mb"],
      ["first_resource_pressure", "projected_downlink_shortfall_mb"],
      ["source_activity", "downlink_shortfall_mb"],
      ["source_activity", "required_downlink_mb"],
      ["source_activity", "target_data_volume_mb"]
    ])
  end

  defp station_id(row) do
    stable_id_or_nil(
      row["first_resource_pressure_ground_station_id"] ||
        row["ground_station_id"] ||
        row["station_id"] ||
        nested_entity_id(row, "first_resource_pressure", [
          "ground_station_id",
          "station_id",
          "id"
        ]) ||
        nested_entity_id(row, "source_activity", [
          "ground_station_id",
          "station_id",
          "id"
        ]) ||
        nested_entity_id(row, "source_contact", [
          "ground_station_id",
          "station_id",
          "id"
        ]) ||
        objective_satisfaction_station_id(row)
    )
  end

  defp spacecraft_id(row) do
    stable_id_or_nil(
      row["spacecraft_id"] ||
        nested_entity_id(row, "first_resource_pressure", [
          "spacecraft_id",
          "satellite_id"
        ]) ||
        nested_entity_id(row, "source_activity", [
          "spacecraft_id",
          "satellite_id"
        ]) ||
        objective_satisfaction_spacecraft_id(row)
    )
  end

  defp pressure_status(row), do: normalized_token(row["resource_pressure_status"])

  defp pressure_types(row) do
    row
    |> Map.get("resource_pressure_types")
    |> List.wrap()
    |> Enum.map(&normalized_token/1)
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.uniq()
    |> Enum.sort()
    |> case do
      [] -> nil
      types -> types
    end
  end

  defp source_activity_ids(row) do
    [
      row["first_resource_pressure_activity_id"],
      row["activity_ids"],
      row["source_activity_ids"],
      nested_entity_id(row, "first_resource_pressure", ["activity_id", "id"]),
      nested_entity_id(row, "source_activity", ["activity_id", "id"]),
      objective_satisfaction_source_activity_ids(row)
    ]
    |> List.flatten()
    |> Enum.map(&stable_id_or_nil/1)
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.uniq()
    |> Enum.sort()
    |> case do
      [] -> nil
      ids -> ids
    end
  end

  defp trust_boundary(row) do
    row["resource_trust_boundary"] ||
      row["trust_boundary"] ||
      get_in(row, ["resource_provenance", "trust_boundary"]) ||
      get_in(row, ["provenance", "trust_boundary"]) ||
      row["_source_report_trust_boundary"]
  end

  defp objective_id(path, row, index, type) do
    base =
      stable_id_or_nil(row["id"]) ||
        stable_id_or_nil(row["spacecraft_id"]) ||
        "#{type}:#{index}"

    hash =
      :crypto.hash(:sha256, :erlang.term_to_binary({path, row, index, type}))
      |> Base.encode16(case: :lower)
      |> binary_part(0, 8)

    ["resource_projection", type, base, hash]
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.join(":")
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

  defp objective_satisfaction_entity_id(%{} = entity, fields) do
    entity = stringify_keys(entity)
    Enum.find_value(fields, &Map.get(entity, &1))
  end

  defp objective_satisfaction_entity_id(_entity, _fields), do: nil

  defp objective_satisfaction_station_id(row) do
    stable_id_or_nil(
      row["ground_station_id"] ||
        row["station_id"] ||
        objective_satisfaction_entity_id(row["ground_station"], [
          "ground_station_id",
          "station_id",
          "id"
        ]) ||
        objective_satisfaction_entity_id(row["station"], ["ground_station_id", "station_id", "id"])
    )
  end

  defp objective_satisfaction_spacecraft_id(row) do
    stable_id_or_nil(
      row["spacecraft_id"] ||
        row["satellite_id"] ||
        objective_satisfaction_entity_id(row["spacecraft"], [
          "spacecraft_id",
          "satellite_id",
          "id"
        ]) ||
        objective_satisfaction_entity_id(row["satellite"], ["spacecraft_id", "satellite_id", "id"])
    )
  end

  defp objective_satisfaction_source_activity_ids(row) do
    [
      row["source_activity_id"],
      row["source_activity_ids"],
      row["selected_activity_ids"],
      row["selected_contact_ids"],
      row["satisfied_contact_ids"],
      row["missed_downlink_activity_id"],
      row["missed_downlink_activity_ids"]
    ]
    |> List.flatten()
    |> Enum.map(&stable_id_or_nil/1)
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.uniq()
    |> Enum.sort()
    |> case do
      [] -> nil
      ids -> ids
    end
  end

  defp nested_entity_id(row, field, keys) do
    case Map.get(row, field) do
      %{} = entity -> objective_satisfaction_entity_id(entity, keys)
      _entity -> nil
    end
  end

  defp result_artifact_trust_boundary(artifact) do
    artifact = stringify_keys(artifact)

    Map.get(artifact, "trust_boundary") ||
      get_in(artifact, ["provenance", "trust_boundary"]) ||
      get_in(artifact, ["metadata", "trust_boundary"]) ||
      get_in(artifact, ["assumptions", "trust_boundary"])
  end

  defp positive_number_value?(value), do: is_number(value) and value > 0.0

  defp normalized_token(value), do: ValueEncoding.normalized_token(value)
  defp stable_id_or_nil(value), do: ValueEncoding.stable_id_or_nil(value)
  defp stringify_keys(value), do: ValueEncoding.stringify_keys(value)
  defp numeric_value(value), do: ValueEncoding.numeric_value(value)
  defp compact_map(map), do: ValueEncoding.compact_nil_values(map)
end
