defmodule OrbitalDynamics.CandidateRefresh.SourceObjectives.ObjectiveSatisfaction do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.ValueEncoding
  alias OrbitalDynamics.CollectionLatencyObjectiveType
  alias OrbitalDynamics.TargetObservationObjectiveType
  require TargetObservationObjectiveType

  @boolean_true_tokens ~w(true 1)
  @boolean_false_tokens ~w(false 0)

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

  def normalize_row(row) do
    row
    |> stringify_keys()
    |> maybe_put("objective", objective_type(row))
    |> maybe_put("status", row_status(row))
  end

  def objective_type(row) do
    row = stringify_keys(row)

    (row["objective"] || row["objective_type"] || row["type"])
    |> normalized_token()
  end

  def gap_status?(status),
    do: status in ["partial", "unmet", "candidate_available", "no_candidate_window"]

  def station_id(row) do
    row = stringify_keys(row)

    stable_id_or_nil(
      row["ground_station_id"] ||
        row["station_id"] ||
        entity_id(row["ground_station"], [
          "ground_station_id",
          "station_id",
          "id"
        ]) ||
        entity_id(row["station"], ["ground_station_id", "station_id", "id"])
    )
  end

  def spacecraft_id(row) do
    row = stringify_keys(row)

    stable_id_or_nil(
      row["spacecraft_id"] ||
        row["satellite_id"] ||
        entity_id(row["spacecraft"], [
          "spacecraft_id",
          "satellite_id",
          "id"
        ]) ||
        entity_id(row["satellite"], ["spacecraft_id", "satellite_id", "id"])
    )
  end

  def target_ids(row) do
    row = stringify_keys(row)

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

  def identity_values(row, field) do
    row = stringify_keys(row)

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

  def source_activity_ids(row) do
    row = stringify_keys(row)

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

  def trust_boundary(row) do
    row = stringify_keys(row)

    Map.get(row, "trust_boundary") ||
      get_in(row, ["provenance", "trust_boundary"]) ||
      row["_source_report_trust_boundary"]
  end

  defp row_objectives(path, row, index) do
    row = normalize_row(row)

    if gap_status?(row["status"]) do
      case objective_type(row) do
        type when type in ["downlink_completion", "required_downlink_completion"] ->
          downlink_objectives(path, row, index)

        type
        when TargetObservationObjectiveType.is_supported(type) or
               type in [
                 "target_coverage",
                 "coverage",
                 "priority_commitment",
                 "target_revisit"
               ] ->
          target_objectives(path, row, index, type)

        type ->
          if CollectionLatencyObjectiveType.supported?(type) do
            collection_latency_objectives(path, row, index)
          else
            []
          end
      end
    else
      []
    end
  end

  defp downlink_objectives(path, row, index) do
    required_downlink_mb = required_downlink_mb(row)

    if positive_number_value?(required_downlink_mb) do
      [
        %{
          "id" => objective_id(path, row, index, "downlink_completion"),
          "type" => "downlink_completion",
          "scenario_id" => stable_id_or_nil(row["scenario_id"]),
          "spacecraft_id" => spacecraft_id(row),
          "ground_station_id" => station_id(row),
          "required_downlink_mb" => required_downlink_mb,
          "source" => "objective_satisfaction_report.rows",
          "source_path" => path,
          "source_objective" => row["objective"],
          "source_objective_status" => row["status"],
          "provider_objective_status" => row["_source_objective_status"],
          "planned_downlink_mb" => planned_downlink_mb(row),
          "selected_downlink_mb" => selected_downlink_mb(row),
          "source_activity_ids" => source_activity_ids(row),
          "trust_boundary" => trust_boundary(row)
        }
        |> compact_map()
      ]
    else
      []
    end
  end

  defp target_objectives(path, row, index, type) do
    row
    |> target_ids()
    |> Enum.map(fn target_id ->
      %{
        "id" => objective_id(path, row, index, type, target_id),
        "type" => refresh_target_type(type),
        "scenario_id" => stable_id_or_nil(row["scenario_id"]),
        "spacecraft_id" => spacecraft_id(row),
        "target_id" => target_id,
        "required_observations" => required_observations(row),
        "source" => "objective_satisfaction_report.rows",
        "source_path" => path,
        "source_objective" => row["objective"],
        "source_objective_status" => row["status"],
        "provider_objective_status" => row["_source_objective_status"],
        "source_activity_ids" => source_activity_ids(row),
        "trust_boundary" => trust_boundary(row)
      }
      |> compact_map()
    end)
  end

  defp collection_latency_objectives(path, row, index) do
    required_downlink_mb = required_downlink_mb(row)
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
          "source" => "objective_satisfaction_report.rows",
          "source_path" => path,
          "source_objective" => row["objective"],
          "source_objective_status" => row["status"],
          "provider_objective_status" => row["_source_objective_status"],
          "planned_latency_s" => planned_latency_s(row),
          "source_activity_ids" => source_activity_ids(row),
          "trust_boundary" => trust_boundary(row)
        }
        |> compact_map()
      ]
    else
      []
    end
  end

  defp refresh_target_type("coverage"), do: "target_coverage"

  defp refresh_target_type(type),
    do: TargetObservationObjectiveType.canonical(type) || type

  defp row_status(row) do
    [
      row["status"],
      row["objective_status"],
      row["satisfaction_status"],
      row["objective_satisfaction_status"],
      row["completion_status"],
      row["requirement_status"],
      row["downlink_requirement_status"],
      row["coverage_status"],
      row["delivery_requirement_status"],
      row["source_objective_status"]
    ]
    |> Enum.find(&(&1 not in [nil, ""]))
    |> case do
      nil -> boolean_status(row)
      status -> status_value(status)
    end
  end

  defp boolean_status(row) do
    [
      row["satisfied"],
      row["objective_satisfied"],
      row["requirement_satisfied"],
      row["downlink_requirement_satisfied"],
      row["coverage_satisfied"],
      row["delivery_satisfied"],
      row["met"],
      row["objective_met"]
    ]
    |> Enum.find_value(fn value ->
      case boolean_value(value) do
        true -> "met"
        false -> "unmet"
        nil -> nil
      end
    end)
  end

  defp status_value(status) when is_boolean(status), do: if(status, do: "met", else: "unmet")

  defp status_value(status) do
    case normalized_token(status) do
      status when status in ["satisfied", "complete", "completed", "selected", "met"] ->
        "met"

      status
      when status in [
             "unsatisfied",
             "not_satisfied",
             "not_met",
             "missing",
             "missed",
             "failed",
             "late",
             "overdue",
             "violated",
             "breached"
           ] ->
        "unmet"

      status
      when status in [
             "partial",
             "shortfall",
             "insufficient",
             "below_target",
             "below_threshold",
             "under_target",
             "under_threshold",
             "gap",
             "has_gap",
             "at_risk",
             "needs_replan",
             "needs_refresh",
             "requires_attention",
             "degraded",
             "behind_plan"
           ] ->
        "partial"

      status
      when status in ["candidate_found", "candidate_window_available", "viable_candidate"] ->
        "candidate_available"

      status when status in ["no_candidate", "no_window", "no_viable_candidate"] ->
        "no_candidate_window"

      status ->
        status
    end
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
    ])
  end

  defp planned_downlink_mb(row) do
    first_number(row, [
      "planned_downlink_mb",
      "selected_downlink_mb",
      "satisfied_downlink_mb",
      "actual_downlink_mb",
      "selected_data_volume_mb",
      "planned_data_volume_mb"
    ])
  end

  defp selected_downlink_mb(row) do
    first_number(row, [
      "selected_downlink_mb",
      "satisfied_downlink_mb",
      "actual_downlink_mb",
      "selected_data_volume_mb"
    ])
  end

  defp required_observations(row) do
    explicit =
      first_positive_number(row, [
        "required_observations",
        "required_observation_count",
        "required_revisits",
        "required_revisit_count",
        "required_count",
        "target_gap_count",
        "missing_observation_count",
        "missing_revisit_count",
        "coverage_shortfall_count",
        ["score_terms", "target_gap_count"],
        ["score_terms", "missing_observation_count"],
        ["score_terms", "missing_revisit_count"],
        ["score_terms", "coverage_gap_count"]
      ])

    planned =
      first_number(row, [
        "planned_observations",
        "selected_observations",
        "selected_count",
        "satisfied_count",
        "planned_revisits",
        "selected_revisits"
      ])

    cond do
      positive_number_value?(explicit) and is_number(planned) and explicit > planned ->
        max(explicit - planned, 1.0)

      positive_number_value?(explicit) ->
        explicit

      true ->
        1.0
    end
  end

  defp latency_s(row) do
    first_positive_number(row, [
      "max_latency_s",
      "required_latency_s",
      "target_latency_s",
      "latency_limit_s",
      "max_delivery_latency_s",
      "required_delivery_latency_s",
      "target_delivery_latency_s"
    ])
  end

  defp planned_latency_s(row) do
    first_number(row, [
      "planned_latency_s",
      "actual_latency_s",
      "delivery_latency_s",
      "planned_delivery_latency_s",
      "actual_delivery_latency_s"
    ])
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

  defp first_number(row, paths) do
    paths
    |> Enum.find_value(fn path -> number(row, path) end)
  end

  defp number(row, path) when is_list(path), do: row |> get_in(path) |> numeric_value()
  defp number(row, path), do: row |> Map.get(path) |> numeric_value()

  defp primary_target_id(row) do
    row
    |> target_ids()
    |> List.first()
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
    target = stringify_keys(target)
    [Map.get(target, "target_id") || Map.get(target, "id")]
  end

  defp target_value(value), do: [value]

  defp identity_value(row, field) do
    case identity_values(row, field) do
      values when is_list(values) -> List.first(values)
      _values -> nil
    end
  end

  defp identity_value_from_source(values, field) when is_list(values),
    do: Enum.flat_map(values, &identity_value_from_source(&1, field))

  defp identity_value_from_source(%{} = value, field) do
    value = stringify_keys(value)

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

  defp identity_aliases("payload_id"),
    do: ["payload_id", "payload_ids", "payload", "payloads"]

  defp identity_aliases("instrument_id"),
    do: ["instrument_id", "instrument_ids", "instrument", "instruments"]

  defp identity_nested_keys("collection_id"), do: ["collection_id", "id"]

  defp identity_nested_keys("product_id"),
    do: ["product_id", "data_product_id", "id"]

  defp identity_nested_keys("payload_id"), do: ["payload_id", "id"]
  defp identity_nested_keys("instrument_id"), do: ["instrument_id", "id"]

  defp entity_id(%{} = entity, fields) do
    entity = stringify_keys(entity)
    Enum.find_value(fields, &Map.get(entity, &1))
  end

  defp entity_id(_entity, _fields), do: nil

  defp objective_id(path, row, index, type, subject \\ nil) do
    base =
      stable_id_or_nil(row["id"]) ||
        stable_id_or_nil(row["objective_id"]) ||
        "#{type}:#{index}"

    subject = stable_id_or_nil(subject)

    hash =
      :crypto.hash(:sha256, :erlang.term_to_binary({path, row, index, type, subject}))
      |> Base.encode16(case: :lower)
      |> binary_part(0, 8)

    ["objective_satisfaction", type, subject || base, hash]
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

  defp stable_id_or_nil(value), do: ValueEncoding.stable_id_or_nil(value)
  defp stringify_keys(value), do: ValueEncoding.stringify_keys(value)
  defp normalized_token(value), do: ValueEncoding.normalized_token(value)
  defp numeric_value(value), do: ValueEncoding.numeric_value(value)

  defp boolean_value(value) when is_boolean(value), do: value

  defp boolean_value(value) when is_number(value) do
    cond do
      value == 1 -> true
      value == 0 -> false
      true -> nil
    end
  end

  defp boolean_value(value) when is_binary(value) do
    case String.downcase(String.trim(value)) do
      value when value in @boolean_true_tokens -> true
      value when value in @boolean_false_tokens -> false
      _value -> nil
    end
  end

  defp boolean_value(_value), do: nil

  defp compact_map(map), do: ValueEncoding.compact_nil_values(map)

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)
end
