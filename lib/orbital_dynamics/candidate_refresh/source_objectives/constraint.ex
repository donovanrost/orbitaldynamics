defmodule OrbitalDynamics.CandidateRefresh.SourceObjectives.Constraint do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.ValueEncoding

  def objectives(source_reports) when is_list(source_reports) do
    Enum.flat_map(source_reports, fn {path, report} ->
      report
      |> Map.get("rows", [])
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

  def status_value(status) do
    case normalized_token(status) do
      status when status in ["pass", "passed", "satisfied", "met", "ok"] -> "pass"
      status when status in ["fail", "failed", "violation", "violated", "breached"] -> "fail"
      status when status in ["warn", "warning", "at_risk", "degraded"] -> "warning"
      status -> status
    end
  end

  def downlink_gap?(row) do
    row = stringify_keys(row)

    positive_number_value?(required_downlink_mb(row)) and
      station_id(row) not in [nil, ""]
  end

  def resource_margin_gap?(row) do
    row = stringify_keys(row)
    metric = metric(row)

    pressure_status?(row) and
      (resource_margin_metric?(metric) or resource_id(row) not in [nil, ""])
  end

  def station_id(row), do: row |> stringify_keys() |> score_term_station_id()

  def metric(row) do
    row = stringify_keys(row)
    normalized_token(row["metric"] || row["constraint_id"])
  end

  def id(row) do
    row = stringify_keys(row)
    stable_id_or_nil(row["constraint_id"] || row["id"])
  end

  def source_activity_ids(row) do
    row
    |> stringify_keys()
    |> constraint_source_activity_ids()
  end

  def resource_id(row) do
    row = stringify_keys(row)

    stable_id_or_nil(
      row["resource_id"] ||
        row["resource_name"] ||
        row["battery_id"] ||
        row["energy_resource_id"] ||
        row["storage_resource_id"] ||
        row["consumable_id"] ||
        row["resource"]
    )
  end

  def spacecraft_id(row), do: row |> stringify_keys() |> score_term_spacecraft_id()
  def trust_boundary(row), do: row |> stringify_keys() |> score_term_trust_boundary()

  defp row_objectives(path, row, index) do
    row = stringify_keys(row)

    if pressure_status?(row) and downlink_gap?(row) do
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
          "source" => "constraint_report.rows",
          "source_path" => path,
          "source_constraint_id" => stable_id_or_nil(row["constraint_id"]),
          "source_constraint_metric" => metric(row),
          "source_constraint_status" => status_value(row["status"]),
          "source_constraint_value" => numeric_value(row["value"]),
          "source_constraint_threshold" => numeric_value(row["threshold"]),
          "source_activity_ids" => constraint_source_activity_ids(row),
          "trust_boundary" => trust_boundary(row)
        }
        |> compact_map()
      ]
    else
      []
    end
  end

  defp pressure_status?(row) do
    status_value(row["status"] || row["constraint_status"]) in [
      "fail",
      "warning",
      "violated"
    ]
  end

  defp resource_margin_metric?(metric) do
    metric in [
      "resource_margin",
      "resource_margin_value",
      "resource_margin_percent",
      "minimum_resource_margin",
      "min_resource_margin",
      "remaining_resource_margin",
      "resource_minimum_margin",
      "battery_margin",
      "power_margin",
      "energy_margin",
      "storage_margin",
      "data_storage_margin",
      "propellant_margin",
      "fuel_margin",
      "thermal_margin"
    ] or String.contains?(metric || "", "resource_margin") or
      String.ends_with?(metric || "", "_margin")
  end

  defp required_downlink_mb(row) do
    explicit =
      first_positive_number(row, [
        "required_downlink_mb",
        "required_data_volume_mb",
        "target_data_volume_mb",
        "required_volume_mb",
        "min_downlink_mb",
        "downlink_completion_gap_mb",
        "selected_downlink_shortfall_mb",
        "selected_data_volume_shortfall_mb",
        "downlink_shortfall_mb",
        "data_volume_shortfall_mb",
        "missing_data_volume_mb",
        ["throughput_model", "required_downlink_mb"],
        ["throughput_model", "target_data_volume_mb"],
        ["activity_context", "required_downlink_mb"],
        ["activity_context", "target_data_volume_mb"]
      ])

    cond do
      positive_number_value?(explicit) ->
        explicit

      metric(row) in [
        "selected_downlink_shortfall_mb",
        "selected_data_volume_shortfall_mb",
        "downlink_shortfall_mb",
        "data_volume_shortfall_mb",
        "missing_data_volume_mb",
        "required_data_volume_gap_mb"
      ] ->
        first_positive_number(row, ["value", "score"])

      true ->
        nil
    end
  end

  defp constraint_source_activity_ids(row) do
    [
      objective_satisfaction_source_activity_ids(row),
      score_term_source_activity_ids(row),
      row["activity_id"],
      row["activity_ids"]
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

  defp objective_id(path, row, index, type) do
    base =
      stable_id_or_nil(row["id"]) ||
        stable_id_or_nil(row["constraint_id"]) ||
        "#{type}:#{index}"

    hash =
      :crypto.hash(:sha256, :erlang.term_to_binary({path, row, index, type}))
      |> Base.encode16(case: :lower)
      |> binary_part(0, 8)

    ["constraint", type, base, hash]
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

  defp score_term_station_id(row) do
    stable_id_or_nil(
      objective_satisfaction_station_id(row) ||
        score_term_nested_entity_id(row, "source_contact", [
          "ground_station_id",
          "station_id",
          "id"
        ]) ||
        score_term_nested_entity_id(row, "contact_candidate", [
          "ground_station_id",
          "station_id",
          "id"
        ]) ||
        score_term_nested_entity_id(row, "selected_contact", [
          "ground_station_id",
          "station_id",
          "id"
        ]) ||
        score_term_nested_entity_id(row, "source_activity", [
          "ground_station_id",
          "station_id",
          "id"
        ])
    )
  end

  defp score_term_spacecraft_id(row) do
    stable_id_or_nil(
      objective_satisfaction_spacecraft_id(row) ||
        score_term_nested_entity_id(row, "source_activity", [
          "spacecraft_id",
          "satellite_id"
        ]) ||
        score_term_nested_entity_id(row, "source_contact", [
          "spacecraft_id",
          "satellite_id"
        ]) ||
        score_term_nested_entity_id(row, "contact_candidate", [
          "spacecraft_id",
          "satellite_id"
        ])
    )
  end

  defp score_term_nested_entity_id(row, field, keys) do
    case Map.get(row, field) do
      %{} = entity -> objective_satisfaction_entity_id(entity, keys)
      _entity -> nil
    end
  end

  defp score_term_source_activity_ids(row) do
    [
      objective_satisfaction_source_activity_ids(row),
      score_term_nested_entity_id(row, "source_activity", ["activity_id", "id"]),
      score_term_nested_entity_id(row, "source_contact", ["contact_id", "activity_id", "id"]),
      score_term_nested_entity_id(row, "contact_candidate", ["contact_id", "activity_id", "id"]),
      score_term_nested_entity_id(row, "selected_contact", ["contact_id", "activity_id", "id"])
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

  defp score_term_trust_boundary(row) do
    Map.get(row, "trust_boundary") ||
      get_in(row, ["provenance", "trust_boundary"]) ||
      row["_source_report_trust_boundary"]
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
