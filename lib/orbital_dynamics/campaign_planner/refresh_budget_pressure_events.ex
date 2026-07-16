defmodule OrbitalDynamics.CampaignPlanner.RefreshBudgetPressureEvents do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.{ScalarValues, ValueEncoding}

  def source(row), do: source(row, row_callbacks())

  def source(%{"source_refresh_budget_report" => %{} = source} = row, opts)
      when map_size(source) > 0 do
    {pressure_row(source, row, opts), "source_refresh_budget_report"}
  end

  def source(row, opts), do: {pressure_row(row, row, opts), "refresh_budget_review"}

  def pressure_row(source, row), do: pressure_row(source, row, row_callbacks())

  def pressure_row(source, row, opts) do
    stringify_keys = Keyword.fetch!(opts, :stringify_keys)
    put_operator_review_row_fallback = Keyword.fetch!(opts, :put_operator_review_row_fallback)
    put_if_present = Keyword.fetch!(opts, :put_if_present)

    source
    |> stringify_keys.()
    |> put_operator_review_row_fallback.(row, "id", nil)
    |> put_operator_review_row_fallback.(row, "input_candidate_count", nil)
    |> put_operator_review_row_fallback.(row, "kept_candidate_count", nil)
    |> put_operator_review_row_fallback.(row, "dropped_candidate_count", nil)
    |> put_operator_review_row_fallback.(row, "max_candidate_activities", nil)
    |> put_operator_review_row_fallback.(row, "invalid_candidate_limit_policy", nil)
    |> put_operator_review_row_fallback.(row, "invalid_candidate_limit_policy_reason", nil)
    |> put_operator_review_row_fallback.(row, "selection_order", nil)
    |> put_operator_review_row_fallback.(row, "kept_candidate_ids", nil)
    |> put_operator_review_row_fallback.(row, "dropped_candidate_ids", nil)
    |> put_operator_review_row_fallback.(row, "required_operator_action", nil)
    |> put_if_present.("source_refresh_budget_report", row["source_refresh_budget_report"])
  end

  def review_row?(row), do: review_row?(row, default_callbacks())

  def review_row?(row, opts) do
    (row["source_review_type"] == "refresh_budget_review" or
       row["review_type"] == "refresh_budget_review" or
       row["import_action"] == "review_refresh_budget") and
      relaxed_limit(row, opts) != nil
  end

  def pressure_branch(row, source_path, index),
    do: pressure_branch(row, source_path, index, default_callbacks())

  def pressure_branch(row, source_path, index, opts) when is_list(opts) do
    case pressure_event(row, source_path, opts) do
      nil ->
        []

      event ->
        identity = pressure_identity(row, index, opts)

        [
          %{
            "id" => "derived_refresh_budget_pressure_#{identity}",
            "label" => "Derived refresh-budget pressure #{identity}",
            "events" => [event],
            "metadata" => %{"derived_source" => source_path}
          }
        ]
    end
  end

  def pressure_event(row, source_path), do: pressure_event(row, source_path, default_callbacks())

  def pressure_event(row, source_path, opts) when is_list(opts) do
    case relaxed_limit(row, opts) do
      relaxed_limit when is_integer(relaxed_limit) and relaxed_limit > 0 ->
        ceil_count = Keyword.fetch!(opts, :ceil_count)
        compact_map = Keyword.fetch!(opts, :compact_map)
        numeric_or_nil = Keyword.fetch!(opts, :numeric_or_nil)
        operator_review_trust_boundary = Keyword.fetch!(opts, :operator_review_trust_boundary)

        %{
          "type" => "refresh_budget_pressure",
          "input_candidate_count" => ceil_count.(row["input_candidate_count"] || 0),
          "kept_candidate_count" => ceil_count.(row["kept_candidate_count"] || 0),
          "dropped_candidate_count" => ceil_count.(row["dropped_candidate_count"] || 0),
          "current_max_candidate_activities" => numeric_or_nil.(row["max_candidate_activities"]),
          "relaxed_max_candidate_activities" => relaxed_limit,
          "invalid_candidate_limit_policy" => row["invalid_candidate_limit_policy"],
          "invalid_candidate_limit_policy_reason" => row["invalid_candidate_limit_policy_reason"],
          "selection_order" => row["selection_order"],
          "kept_candidate_ids" => row["kept_candidate_ids"],
          "dropped_candidate_ids" => row["dropped_candidate_ids"],
          "required_operator_action" => row["required_operator_action"],
          "derivation_reasons" => ["refresh_budget_candidate_limit_pressure"],
          "feedback_source" => source_path,
          "feedback_scope" => "refresh_budget",
          "feedback_key" => row["id"] || row["subject_id"] || "refresh_budget",
          "trust_boundary" => operator_review_trust_boundary.(row),
          "source_refresh_budget_report" => Map.get(row, "source_refresh_budget_report", row)
        }
        |> compact_map.()

      _limit ->
        nil
    end
  end

  def relaxed_limit(row, opts) do
    ceil_count = Keyword.fetch!(opts, :ceil_count)
    dropped_count = ceil_count.(row["dropped_candidate_count"] || 0)
    invalid_policy? = row["invalid_candidate_limit_policy"] == true

    if dropped_count > 0 or invalid_policy? do
      input_count = ceil_count.(row["input_candidate_count"] || 0)
      kept_count = ceil_count.(row["kept_candidate_count"] || 0)
      current_limit = ceil_count.(row["max_candidate_activities"] || 0)

      [input_count, kept_count + dropped_count, current_limit + dropped_count]
      |> Enum.reject(&(&1 <= 0))
      |> Enum.max(fn -> nil end)
      |> case do
        limit when is_integer(limit) and limit > current_limit -> limit
        limit when is_integer(limit) and invalid_policy? -> limit
        _limit -> nil
      end
    end
  end

  defp pressure_identity(row, index, opts) do
    branch_id_fragment = Keyword.fetch!(opts, :branch_id_fragment)

    [
      row["id"],
      row["subject_id"],
      row["refresh_gate_status"],
      "limit_#{relaxed_limit(row, opts)}",
      index
    ]
    |> Enum.find(&(&1 not in [nil, ""]))
    |> branch_id_fragment.()
  end

  defp row_callbacks do
    [
      put_if_present: &put_if_present/3,
      put_operator_review_row_fallback: &put_operator_review_row_fallback/4,
      stringify_keys: &ValueEncoding.stringify_keys/1
    ]
  end

  defp default_callbacks do
    [
      branch_id_fragment: &ValueEncoding.branch_id_fragment/1,
      ceil_count: &ScalarValues.ceil_count/1,
      compact_map: &ValueEncoding.compact_map/1,
      numeric_or_nil: &ScalarValues.numeric_or_nil/1,
      operator_review_trust_boundary: &operator_review_trust_boundary/1,
      put_if_present: &put_if_present/3,
      put_operator_review_row_fallback: &put_operator_review_row_fallback/4,
      stringify_keys: &ValueEncoding.stringify_keys/1
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
end
