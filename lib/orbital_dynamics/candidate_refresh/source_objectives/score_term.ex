defmodule OrbitalDynamics.CandidateRefresh.SourceObjectives.ScoreTerm do
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

  def key(row) do
    row = stringify_keys(row)

    row["term_key"] ||
      row["score_term_key"] ||
      row["metric"] ||
      row["name"] ||
      row["key"]
  end

  def downlink_gap?(term) do
    term in [
      "downlink_shortfall_mb",
      "downlink_completion_gap_mb",
      "selected_downlink_shortfall_mb",
      "data_volume_shortfall_mb",
      "missing_data_volume_mb",
      "required_data_volume_gap_mb",
      "required_downlink_mb",
      "downlink_gap_mb",
      "downlink_demand_gap_mb"
    ]
  end

  def target_gap?(term) do
    term in [
      "target_gap_count",
      "target_coverage_gap_count",
      "coverage_gap_count",
      "missing_observation_count",
      "missing_revisit_count",
      "revisit_shortfall_count",
      "target_revisit_gap_count",
      "observation_shortfall_count"
    ]
  end

  def collection_latency_gap?(term) do
    term in [
      "collection_latency_gap",
      "collection_latency_shortfall",
      "collection_latency_downlink_gap_mb",
      "collection_latency_data_volume_gap_mb",
      "late_collection_latency",
      "data_latency_gap",
      "delivery_latency_gap"
    ] or String.contains?(term || "", "collection_latency")
  end

  def station_id(row), do: row |> stringify_keys() |> score_term_station_id()
  def source_activity_ids(row), do: row |> stringify_keys() |> score_term_source_activity_ids()
  def trust_boundary(row), do: row |> stringify_keys() |> score_term_trust_boundary()

  defp row_objectives(path, row, index) do
    row = stringify_keys(row)
    term = row |> key() |> normalized_token()

    cond do
      downlink_gap?(term) ->
        downlink_objectives(path, row, index)

      target_gap?(term) ->
        target_objectives(path, row, index, term)

      collection_latency_gap?(term) ->
        collection_latency_objectives(path, row, index)

      true ->
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
          "source" => "score_term_report.rows",
          "source_path" => path,
          "source_score_term_key" => key(row),
          "source_score_term_value" => value(row),
          "source_activity_ids" => score_term_source_activity_ids(row),
          "trust_boundary" => trust_boundary(row)
        }
        |> compact_map()
      ]
    else
      []
    end
  end

  defp target_objectives(path, row, index, term) do
    type = target_refresh_type(term)
    required_revisits = required_observations(row)

    row
    |> target_ids()
    |> Enum.map(fn target_id ->
      %{
        "id" => objective_id(path, row, index, type, target_id),
        "type" => type,
        "scenario_id" => stable_id_or_nil(row["scenario_id"]),
        "spacecraft_id" => spacecraft_id(row),
        "target_id" => target_id,
        "required_revisits" => required_revisits,
        "source" => "score_term_report.rows",
        "source_path" => path,
        "source_score_term_key" => key(row),
        "source_score_term_value" => value(row),
        "source_activity_ids" => score_term_source_activity_ids(row),
        "trust_boundary" => trust_boundary(row)
      }
      |> compact_map()
    end)
  end

  defp collection_latency_objectives(path, row, index) do
    required_downlink_mb = collection_required_downlink_mb(row)
    max_latency_s = latency_s(row)

    if positive_number_value?(required_downlink_mb) or positive_number_value?(max_latency_s) do
      [
        %{
          "id" => objective_id(path, row, index, "collection_latency"),
          "type" => "collection_latency",
          "scenario_id" => stable_id_or_nil(row["scenario_id"]),
          "spacecraft_id" => spacecraft_id(row),
          "target_id" => primary_target_id(row),
          "ground_station_id" => station_id(row),
          "collection_id" => identity_value(row, "collection_id"),
          "product_id" => identity_value(row, "product_id"),
          "product_ids" => identity_values(row, "product_id"),
          "payload_id" => identity_value(row, "payload_id"),
          "instrument_id" => identity_value(row, "instrument_id"),
          "required_downlink_mb" => required_downlink_mb,
          "max_latency_s" => max_latency_s,
          "source" => "score_term_report.rows",
          "source_path" => path,
          "source_score_term_key" => key(row),
          "source_score_term_value" => value(row),
          "source_activity_ids" => score_term_source_activity_ids(row),
          "trust_boundary" => trust_boundary(row)
        }
        |> compact_map()
      ]
    else
      []
    end
  end

  defp value(row) do
    first_number(row, [
      "value",
      "score_term_value",
      "term_value",
      "gap_value"
    ])
  end

  defp required_downlink_mb(row) do
    first_positive_number(row, [
      "required_downlink_mb",
      "required_data_volume_mb",
      "target_data_volume_mb",
      "required_volume_mb",
      "min_downlink_mb",
      "downlink_completion_gap_mb",
      "selected_downlink_shortfall_mb",
      "downlink_shortfall_mb",
      "data_volume_shortfall_mb",
      "missing_data_volume_mb",
      ["score_terms", "downlink_shortfall_mb"],
      ["score_terms", "downlink_completion_gap_mb"],
      ["score_terms", "required_downlink_mb"]
    ]) || gap_value(row)
  end

  defp required_observations(row) do
    first_positive_number(row, [
      "required_observations",
      "required_observation_count",
      "required_revisits",
      "required_revisit_count",
      "required_count",
      "target_gap_count",
      "target_coverage_gap_count",
      "coverage_gap_count",
      "missing_observation_count",
      "missing_revisit_count",
      "revisit_shortfall_count",
      ["score_terms", "target_gap_count"],
      ["score_terms", "missing_observation_count"],
      ["score_terms", "missing_revisit_count"],
      ["score_terms", "coverage_gap_count"]
    ]) || gap_value(row) || 1.0
  end

  defp latency_s(row) do
    first_positive_number(row, [
      "max_latency_s",
      "required_latency_s",
      "target_latency_s",
      "latency_limit_s",
      "max_delivery_latency_s",
      "required_delivery_latency_s",
      "target_delivery_latency_s",
      "collection_latency_gap_s",
      "latency_gap_s"
    ])
  end

  defp collection_required_downlink_mb(row) do
    explicit =
      first_positive_number(row, [
        "required_downlink_mb",
        "required_data_volume_mb",
        "target_data_volume_mb",
        "required_volume_mb",
        "min_downlink_mb",
        "collection_latency_downlink_gap_mb",
        "collection_latency_data_volume_gap_mb",
        "data_volume_shortfall_mb",
        "missing_data_volume_mb"
      ])

    term = row |> key() |> normalized_token()

    cond do
      positive_number_value?(explicit) ->
        explicit

      term in ["collection_latency_downlink_gap_mb", "collection_latency_data_volume_gap_mb"] ->
        gap_value(row)

      true ->
        nil
    end
  end

  defp gap_value(row) do
    case value(row) do
      value when is_number(value) and value > 0.0 -> value
      _value -> nil
    end
  end

  defp target_refresh_type(term)
       when term in ["target_coverage_gap_count", "coverage_gap_count"],
       do: "target_coverage"

  defp target_refresh_type(_term), do: "target_revisit"

  defp first_positive_number(row, paths) do
    paths
    |> Enum.find_value(fn path ->
      case number(row, path) do
        value when is_number(value) and value > 0.0 -> value
        _value -> nil
      end
    end)
  end

  defp first_number(row, paths), do: Enum.find_value(paths, &number(row, &1))
  defp number(row, path) when is_list(path), do: row |> get_in(path) |> numeric_value()
  defp number(row, path), do: row |> Map.get(path) |> numeric_value()

  defp primary_target_id(row) do
    row
    |> target_ids()
    |> List.first()
  end

  defp target_ids(row) do
    gap_targets =
      target_values(row, [
        "uncovered_target_ids",
        "uncovered_targets",
        "unsatisfied_target_ids",
        "unsatisfied_targets",
        "missing_target_ids",
        "missing_targets",
        "missed_target",
        "missed_targets",
        "missing_revisit_target_ids",
        "missing_revisit_targets",
        "missing_coverage_target_ids",
        "missing_coverage_targets",
        "target_gap_ids",
        "target_gap_targets"
      ])

    if gap_targets == [] do
      target_values(row, [
        "target_id",
        "target",
        "target_ids",
        "targets",
        "target_spec",
        "target_specs",
        "required_target_ids",
        "required_targets",
        "committed_targets",
        "priority_targets",
        "candidate_target_ids",
        "candidate_targets"
      ])
    else
      gap_targets
    end
  end

  defp target_values(row, fields) do
    fields
    |> Enum.flat_map(fn field -> target_value(Map.get(row, field)) end)
    |> Enum.map(&stable_id_or_nil/1)
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp target_value(values) when is_list(values), do: Enum.flat_map(values, &target_value/1)

  defp target_value(%{} = target) do
    [Map.get(target, "target_id") || Map.get(target, "id")]
  end

  defp target_value(value), do: [value]

  defp identity_value(row, field) do
    case identity_values(row, field) do
      values when is_list(values) -> List.first(values)
      _values -> nil
    end
  end

  defp identity_values(row, field) do
    field
    |> identity_aliases()
    |> Enum.flat_map(fn alias_field ->
      identity_value_from_source(Map.get(row, alias_field), field)
    end)
    |> Enum.map(&stable_id_or_nil/1)
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.uniq()
    |> Enum.sort()
    |> case do
      [] -> nil
      values -> values
    end
  end

  defp identity_value_from_source(values, field) when is_list(values),
    do: Enum.flat_map(values, &identity_value_from_source(&1, field))

  defp identity_value_from_source(%{} = value, field) do
    field
    |> identity_nested_keys()
    |> Enum.map(&Map.get(value, &1))
  end

  defp identity_value_from_source(value, _field), do: [value]

  defp identity_aliases("collection_id"),
    do: ["collection_id", "collection_ids", "collection", "collections"]

  defp identity_aliases("product_id"),
    do: [
      "product_id",
      "data_product_id",
      "product_ids",
      "data_product_ids",
      "product",
      "products"
    ]

  defp identity_aliases("payload_id"), do: ["payload_id", "payload_ids", "payload", "payloads"]

  defp identity_aliases("instrument_id"),
    do: ["instrument_id", "instrument_ids", "instrument", "instruments"]

  defp identity_nested_keys("collection_id"), do: ["collection_id", "id"]
  defp identity_nested_keys("product_id"), do: ["product_id", "data_product_id", "id"]
  defp identity_nested_keys("payload_id"), do: ["payload_id", "id"]
  defp identity_nested_keys("instrument_id"), do: ["instrument_id", "id"]

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
        nested_entity_id(row, "source_contact", [
          "ground_station_id",
          "station_id",
          "id"
        ]) ||
        nested_entity_id(row, "contact_candidate", [
          "ground_station_id",
          "station_id",
          "id"
        ]) ||
        nested_entity_id(row, "selected_contact", [
          "ground_station_id",
          "station_id",
          "id"
        ]) ||
        nested_entity_id(row, "source_activity", [
          "ground_station_id",
          "station_id",
          "id"
        ])
    )
  end

  defp spacecraft_id(row) do
    stable_id_or_nil(
      objective_satisfaction_spacecraft_id(row) ||
        nested_entity_id(row, "source_activity", [
          "spacecraft_id",
          "satellite_id"
        ]) ||
        nested_entity_id(row, "source_contact", [
          "spacecraft_id",
          "satellite_id"
        ]) ||
        nested_entity_id(row, "contact_candidate", [
          "spacecraft_id",
          "satellite_id"
        ])
    )
  end

  defp nested_entity_id(row, field, keys) do
    case Map.get(row, field) do
      %{} = entity -> objective_satisfaction_entity_id(entity, keys)
      _entity -> nil
    end
  end

  defp score_term_source_activity_ids(row) do
    [
      objective_satisfaction_source_activity_ids(row),
      nested_entity_id(row, "source_activity", ["activity_id", "id"]),
      nested_entity_id(row, "source_contact", ["contact_id", "activity_id", "id"]),
      nested_entity_id(row, "contact_candidate", ["contact_id", "activity_id", "id"]),
      nested_entity_id(row, "selected_contact", ["contact_id", "activity_id", "id"])
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

  defp objective_id(path, row, index, type, subject \\ nil) do
    base =
      stable_id_or_nil(row["id"]) ||
        stable_id_or_nil(row["term_id"]) ||
        "#{type}:#{index}"

    subject = stable_id_or_nil(subject)

    hash =
      :crypto.hash(:sha256, :erlang.term_to_binary({path, row, index, type, subject}))
      |> Base.encode16(case: :lower)
      |> binary_part(0, 8)

    ["score_term", type, subject || base, hash]
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

  defp positive_number_value?(value), do: is_number(value) and value > 0.0

  defp normalized_token(value), do: ValueEncoding.normalized_token(value)
  defp stable_id_or_nil(value), do: ValueEncoding.stable_id_or_nil(value)
  defp stringify_keys(value), do: ValueEncoding.stringify_keys(value)
  defp numeric_value(value), do: ValueEncoding.numeric_value(value)
  defp compact_map(map), do: ValueEncoding.compact_nil_values(map)
end
