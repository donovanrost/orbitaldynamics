defmodule OrbitalDynamics.CampaignPlanner.CandidateDiffPressureEvents do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.{
    ActivityTiming,
    CandidateDiffMetadata,
    ScalarValues,
    ValueEncoding
  }

  def source(row), do: source(row, row_callbacks())

  def source(%{"source_candidate_diff" => %{} = source} = row, opts)
      when map_size(source) > 0 and is_list(opts) do
    {review_row(source, row, opts), "source_candidate_diff"}
  end

  def source(row, opts) when is_list(opts),
    do: {review_row(row, row, opts), "candidate_diff_review"}

  def review_row(source, row), do: review_row(source, row, row_callbacks())

  def review_row(source, row, opts) when is_list(opts) do
    stringify_keys = Keyword.fetch!(opts, :stringify_keys)
    put_if_present = Keyword.fetch!(opts, :put_if_present)

    candidate_diff =
      source
      |> stringify_keys.()
      |> put_row_fallback(row, "id", "activity_id", opts)
      |> put_row_fallback(row, "activity_id", opts)
      |> put_row_fallback(row, "activity_type", opts)
      |> put_row_fallback(row, "scenario_id", opts)
      |> put_row_fallback(row, "target_id", opts)
      |> put_row_fallback(row, "source_target_id", opts)
      |> put_row_fallback(row, "source_target", opts)
      |> put_row_fallback(row, "target_latitude_deg", opts)
      |> put_row_fallback(row, "target_longitude_deg", opts)
      |> put_row_fallback(row, "target_minimum_elevation_deg", opts)
      |> put_row_fallback(row, "target_priority", opts)
      |> put_row_fallback(row, "target_priority_source", opts)
      |> put_row_fallback(row, "target_priority_objective_ids", opts)
      |> put_row_fallback(row, "target_priority_objective_type", opts)
      |> put_row_fallback(row, "ground_station_id", opts)
      |> put_row_fallback(row, "direction", opts)
      |> put_row_fallback(row, "source_window_id", opts)
      |> put_row_fallback(row, "source_window_type", opts)
      |> put_row_fallback(row, "replacement_source_window_id", opts)
      |> put_row_fallback(row, "starts_at_s", opts)
      |> put_row_fallback(row, "ends_at_s", opts)
      |> put_row_fallback(row, "invalidated_candidate_id", opts)
      |> put_row_fallback(row, "replacement_candidate_id", opts)
      |> put_row_fallback(row, "invalidated_reason", opts)
      |> put_row_fallback(row, "semantic_change_reasons", opts)
      |> put_row_fallback(row, "semantic_change_details", opts)
      |> put_row_fallback(row, "changed_fields", opts)
      |> put_row_fallback(row, "candidate_diff_changed_fields", opts)
      |> put_row_fallback(row, "candidate_diff_changed_field_count", opts)
      |> put_row_fallback(row, "candidate_diff_match_status", opts)
      |> put_row_fallback(row, "candidate_budget_match_status", opts)
      |> put_row_fallback(row, "budget_dropped_candidate_ids", opts)
      |> put_row_fallback(row, "required_operator_action", opts)
      |> put_changed_fields()

    candidate_diff
    |> put_if_present.(
      "source_candidate_diff",
      enriched_source_candidate_diff(row["source_candidate_diff"], candidate_diff, opts)
    )
  end

  def review_row?(row), do: review_row?(row, pressure_callbacks())

  def review_row?(row, opts) when is_list(opts) do
    stable_id_string? = Keyword.fetch!(opts, :stable_id_string?)

    (row["source_review_type"] == "candidate_diff_review" or
       row["review_type"] == "candidate_diff_review" or
       row["import_action"] == "review_candidate_diff") and
      stable_id_string?.(replacement_candidate_id(row))
  end

  def pressure_branch(row, source_path, index),
    do: pressure_branch(row, source_path, index, pressure_callbacks())

  def pressure_branch(row, source_path, index, opts) when is_list(opts) do
    case pressure_event(row, source_path, opts) do
      nil ->
        []

      event ->
        identity = pressure_identity(row, index, opts)

        [
          %{
            "id" => "derived_candidate_diff_replacement_#{identity}",
            "label" => "Derived candidate-diff replacement #{identity}",
            "events" => [event],
            "metadata" => %{"derived_source" => source_path}
          }
        ]
    end
  end

  def pressure_event(row, source_path), do: pressure_event(row, source_path, pressure_callbacks())

  def pressure_event(row, source_path, opts) when is_list(opts) do
    stable_id_string? = Keyword.fetch!(opts, :stable_id_string?)
    replacement_id = replacement_candidate_id(row)

    if stable_id_string?.(replacement_id) do
      activity_raw_start = Keyword.fetch!(opts, :activity_raw_start)
      activity_raw_end = Keyword.fetch!(opts, :activity_raw_end)
      compact_map = Keyword.fetch!(opts, :compact_map)
      operator_review_trust_boundary = Keyword.fetch!(opts, :operator_review_trust_boundary)

      %{
        "type" => "candidate_diff_replacement",
        "replacement_candidate_id" => replacement_id,
        "invalidated_candidate_id" => row["invalidated_candidate_id"] || row["id"],
        "activity_id" => row["activity_id"] || row["id"],
        "activity_type" => row["activity_type"] || row["type"],
        "scenario_id" => row["scenario_id"],
        "target_id" => row["target_id"],
        "source_target_id" => row["source_target_id"],
        "source_target" => row["source_target"],
        "target_latitude_deg" => row["target_latitude_deg"],
        "target_longitude_deg" => row["target_longitude_deg"],
        "target_minimum_elevation_deg" => row["target_minimum_elevation_deg"],
        "target_priority" => row["target_priority"],
        "target_priority_source" => row["target_priority_source"],
        "target_priority_objective_ids" => row["target_priority_objective_ids"],
        "target_priority_objective_type" => row["target_priority_objective_type"],
        "ground_station_id" => row["ground_station_id"],
        "direction" => row["direction"],
        "starts_at_s" => activity_raw_start.(row),
        "ends_at_s" => activity_raw_end.(row),
        "source_window_id" => row["source_window_id"],
        "source_window_type" => row["source_window_type"],
        "replacement_source_window_id" => row["replacement_source_window_id"],
        "invalidated_reason" => row["invalidated_reason"],
        "semantic_change_reasons" => row["semantic_change_reasons"],
        "semantic_change_details" => row["semantic_change_details"],
        "changed_fields" => row["changed_fields"],
        "candidate_diff_changed_fields" => row["candidate_diff_changed_fields"],
        "candidate_diff_changed_field_count" => row["candidate_diff_changed_field_count"],
        "candidate_diff_match_status" => row["candidate_diff_match_status"],
        "candidate_budget_match_status" => row["candidate_budget_match_status"],
        "budget_dropped_candidate_ids" => row["budget_dropped_candidate_ids"],
        "required_operator_action" => row["required_operator_action"],
        "derivation_reasons" => ["candidate_diff_replacement"],
        "feedback_source" => source_path,
        "feedback_scope" => "candidate_diff",
        "feedback_key" => replacement_id,
        "trust_boundary" => operator_review_trust_boundary.(row),
        "source_candidate_diff" => Map.get(row, "source_candidate_diff", row)
      }
      |> Map.merge(CandidateDiffMetadata.scoped_context(row))
      |> compact_map.()
    end
  end

  def replacement_candidate_id(row) do
    row["replacement_candidate_id"] ||
      get_in(row, ["source_candidate_diff", "replacement_candidate_id"]) ||
      get_in(row, ["candidate_diff", "replacement_candidate_id"])
  end

  defp put_row_fallback(source, row, field, opts) do
    Keyword.fetch!(opts, :put_operator_review_row_fallback).(source, row, field, nil)
  end

  defp put_row_fallback(source, row, field, row_field, opts) do
    Keyword.fetch!(opts, :put_operator_review_row_fallback).(source, row, field, row_field)
  end

  defp row_callbacks do
    [
      compact_map: &ValueEncoding.compact_map/1,
      put_if_present: &put_if_present/3,
      put_operator_review_row_fallback: &put_operator_review_row_fallback/4,
      stringify_keys: &ValueEncoding.stringify_keys/1
    ]
  end

  defp pressure_callbacks do
    [
      stringify_keys: &ValueEncoding.stringify_keys/1,
      put_operator_review_row_fallback: &put_operator_review_row_fallback/4,
      put_if_present: &put_if_present/3,
      stable_id_string?: &ScalarValues.stable_id_string?/1,
      activity_raw_start: &ActivityTiming.activity_raw_start/1,
      activity_raw_end: &ActivityTiming.activity_raw_end/1,
      operator_review_trust_boundary: &operator_review_trust_boundary/1,
      compact_map: &ValueEncoding.compact_map/1,
      branch_id_fragment: &ValueEncoding.branch_id_fragment/1
    ]
  end

  defp operator_review_trust_boundary(row) do
    Map.get(row, "trust_boundary") ||
      get_in(row, ["provenance", "trust_boundary"]) ||
      row["_source_report_trust_boundary"]
  end

  defp put_operator_review_row_fallback(source, row, field, row_field) do
    row_field = row_field || field

    case Map.get(source, field) do
      value when value in [nil, ""] -> put_if_present(source, field, row[row_field])
      _value -> source
    end
  end

  defp put_if_present(map, _key, value) when value in [nil, ""], do: map
  defp put_if_present(map, key, value), do: Map.put(map, key, value)

  defp enriched_source_candidate_diff(%{} = source_candidate_diff, candidate_diff, opts) do
    stringify_keys = Keyword.fetch!(opts, :stringify_keys)
    compact_map = Keyword.fetch!(opts, :compact_map)

    source_candidate_diff
    |> stringify_keys.()
    |> Map.merge(Map.take(candidate_diff, evidence_fields()))
    |> compact_map.()
  end

  defp enriched_source_candidate_diff(_source_candidate_diff, _candidate_diff, _opts), do: nil

  defp put_changed_fields(row) do
    case changed_fields(row) do
      [] ->
        row

      fields ->
        row
        |> Map.put("changed_fields", fields)
        |> Map.put("candidate_diff_changed_fields", fields)
        |> Map.put("candidate_diff_changed_field_count", length(fields))
    end
  end

  defp changed_fields(row) do
    row
    |> Map.get("candidate_diff_changed_fields", Map.get(row, "changed_fields"))
    |> List.wrap()
    |> Enum.concat(semantic_change_detail_fields(row["semantic_change_details"]))
    |> Enum.filter(&is_binary/1)
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp semantic_change_detail_fields(details) do
    details
    |> List.wrap()
    |> Enum.map(&Map.get(&1, "field"))
  end

  defp evidence_fields do
    [
      "id",
      "type",
      "activity_id",
      "activity_type",
      "scenario_id",
      "target_id",
      "source_target_id",
      "source_target",
      "target_latitude_deg",
      "target_longitude_deg",
      "target_minimum_elevation_deg",
      "target_priority",
      "target_priority_source",
      "target_priority_objective_ids",
      "target_priority_objective_type",
      "ground_station_id",
      "direction",
      "source_window_id",
      "source_window_type",
      "replacement_source_window_id",
      "starts_at_s",
      "ends_at_s",
      "invalidated_candidate_id",
      "replacement_candidate_id",
      "invalidated_reason",
      "semantic_change_reasons",
      "semantic_change_details",
      "changed_fields",
      "candidate_diff_changed_fields",
      "candidate_diff_changed_field_count",
      "candidate_diff_match_status",
      "candidate_budget_match_status",
      "budget_dropped_candidate_ids",
      "required_operator_action"
      | CandidateDiffMetadata.scoped_context_fields()
    ]
  end

  defp pressure_identity(row, index, opts) do
    branch_id_fragment = Keyword.fetch!(opts, :branch_id_fragment)

    [
      replacement_candidate_id(row),
      row["invalidated_candidate_id"],
      row["activity_id"],
      row["id"],
      index
    ]
    |> Enum.find(&(&1 not in [nil, ""]))
    |> branch_id_fragment.()
  end
end
