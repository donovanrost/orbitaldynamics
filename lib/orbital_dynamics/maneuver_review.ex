defmodule OrbitalDynamics.ManeuverReview do
  @moduledoc """
  Builds artifact-only maneuver review reports.

  The report normalizes `maneuver_recommendation.v1` rows into a stable
  review/import table. It does not command a burn, mutate a plan, or claim
  maneuver feasibility beyond the source recommendation assumptions.
  """

  @schema_contract "maneuver_review_report.v1"
  alias OrbitalDynamics.Policy

  @stable_id_regex ~r/^[A-Za-z0-9][A-Za-z0-9._:@-]*$/

  @doc """
  Declares the maneuver-review report model and known limits.
  """
  def capabilities do
    %{
      artifact_contract: @schema_contract,
      model: :artifact_only_maneuver_review_report,
      validation_level: :artifact_contract,
      source_contract: "maneuver_recommendation.v1",
      row_semantics: [
        :required_operator_action,
        :approval_status,
        :execution_boundary,
        :source_recommendation,
        :execution_uncertainty,
        :maneuver_success_factor,
        :invalid_maneuver_recommendation_review
      ],
      known_limits: [
        :no_command_execution,
        :no_schedule_mutation,
        :no_finite_burn_model,
        :uncertainty_is_review_metadata_not_execution_model,
        :source_recommendations_must_carry_validation_limits
      ]
    }
  end

  @doc """
  Returns the declared model limits for `maneuver_recommendation.v1` rows.
  """
  def recommendation_model_limits do
    [
      "impulsive_burn_only",
      "recommendation_only_no_command_execution",
      "no_finite_burn_model",
      "requires_operator_review_before_execution"
    ]
  end

  @doc """
  Builds a `maneuver_review_report.v1` from maneuver recommendations.
  """
  def report(recommendations, opts \\ [])

  def report(recommendations, opts) when is_list(recommendations) do
    source = opts |> Keyword.get(:source, "maneuver_recommendations") |> to_string()
    source_artifact_id = Keyword.get(opts, :source_artifact_id)

    rows =
      recommendations
      |> Enum.with_index(1)
      |> Enum.map(fn {recommendation, index} ->
        normalize_recommendation_input(recommendation, index)
      end)
      |> Enum.sort_by(&maneuver_sort_key/1)
      |> Enum.with_index(1)
      |> Enum.map(fn {recommendation, rank} ->
        review_row(recommendation, rank, Keyword.get(opts, :approval_policy))
      end)

    invalid_rows = Enum.filter(rows, &Map.get(&1, "invalid_maneuver_recommendation", false))

    %{
      "schema_contract" => @schema_contract,
      "model" => "artifact_only_maneuver_review_report",
      "source" => source,
      "source_artifact_id" => encode_value(source_artifact_id),
      "maneuver_count" => length(rows),
      "review_required_count" => length(rows),
      "invalid_maneuver_recommendation_count" => length(invalid_rows),
      "invalid_maneuver_recommendation_ids" => Enum.map(invalid_rows, & &1["maneuver_id"]),
      "execution_uncertainty_declared_count" => execution_uncertainty_count(rows, "declared"),
      "execution_uncertainty_missing_count" => execution_uncertainty_count(rows, "missing"),
      "total_delta_v_km_s" => total_delta_v(rows),
      "model_limits" => model_limits(),
      "rows" => rows,
      "assumptions" => %{
        "boundary" => "review_only_no_command_execution",
        "source" => "maneuver_recommendation.v1",
        "execution_boundary" => "recommendation_only_no_command_execution"
      }
    }
    |> Map.merge(execution_uncertainty_summary_fields(rows))
    |> compact_map()
  end

  def report(_recommendations, _opts),
    do: raise(ArgumentError, "maneuver recommendations must be a list")

  defp normalize_recommendation_input(recommendation, index) when is_map(recommendation) do
    recommendation = stringify_keys(recommendation)
    invalid_reasons = invalid_recommendation_reasons(recommendation)

    if invalid_reasons == [] do
      normalize_recommendation(recommendation)
    else
      invalid_recommendation_input(recommendation, index, invalid_reasons)
    end
  end

  defp normalize_recommendation_input(recommendation, index) do
    invalid_recommendation_input(
      %{"invalid_recommendation_shape" => encode_value(recommendation)},
      index,
      ["invalid_recommendation_shape"]
    )
  end

  defp invalid_recommendation_reasons(recommendation) do
    [
      invalid_stable_field_reason(recommendation, "id", "missing_maneuver_id"),
      invalid_stable_field_reason(recommendation, "scenario_id", "missing_scenario_id"),
      invalid_string_field_reason(recommendation, "type", "missing_maneuver_type"),
      invalid_number_field_reason(recommendation, "epoch_s", "missing_epoch_s"),
      invalid_string_field_reason(recommendation, "frame", "missing_frame"),
      invalid_delta_v_reason(recommendation),
      invalid_optional_number_field_reason(recommendation, "delta_v_magnitude_km_s"),
      invalid_string_field_reason(recommendation, "maneuver_model", "missing_maneuver_model"),
      invalid_unit_interval_reason(recommendation, "maneuver_success_factor"),
      invalid_string_optional_field_reason(recommendation, "maneuver_success_factor_source"),
      invalid_execution_uncertainty_reason(recommendation)
    ]
    |> Enum.reject(&is_nil/1)
  end

  defp invalid_stable_field_reason(recommendation, field, missing_reason) do
    case Map.get(recommendation, field) |> encode_value() do
      value when is_binary(value) ->
        if Regex.match?(@stable_id_regex, value), do: nil, else: "invalid_#{field}"

      _value ->
        missing_reason
    end
  end

  defp invalid_string_field_reason(recommendation, field, missing_reason) do
    case Map.get(recommendation, field) |> encode_value() do
      value when is_binary(value) and value != "" -> nil
      _value -> missing_reason
    end
  end

  defp invalid_number_field_reason(recommendation, field, missing_reason) do
    case numeric_value(Map.get(recommendation, field)) do
      value when is_number(value) -> nil
      _value -> missing_reason
    end
  end

  defp invalid_unit_interval_reason(recommendation, field) do
    case numeric_value(Map.get(recommendation, field)) do
      nil -> nil
      value when is_number(value) and value >= 0.0 and value <= 1.0 -> nil
      _value -> "invalid_#{field}"
    end
  end

  defp invalid_optional_number_field_reason(recommendation, field) do
    case Map.fetch(recommendation, field) do
      {:ok, value} ->
        if invalid_optional_number?(value), do: "invalid_#{field}"

      :error ->
        nil
    end
  end

  defp invalid_string_optional_field_reason(recommendation, field) do
    case Map.get(recommendation, field) |> encode_optional_value() do
      nil -> nil
      value when is_binary(value) and value != "" -> nil
      _value -> "invalid_#{field}"
    end
  end

  defp invalid_delta_v_reason(recommendation) do
    case numeric_triplet(Map.get(recommendation, "delta_v_km_s")) do
      nil -> "invalid_delta_v_km_s"
      _delta_v -> nil
    end
  end

  defp invalid_execution_uncertainty_reason(recommendation) do
    uncertainty =
      Map.get(recommendation, "execution_uncertainty") ||
        Map.get(recommendation, "maneuver_execution_uncertainty") ||
        get_in(recommendation, ["assumptions", "execution_uncertainty"]) ||
        get_in(recommendation, ["assumptions", "maneuver_execution_uncertainty"])

    case uncertainty do
      nil ->
        nil

      %{} = uncertainty ->
        uncertainty = stringify_keys(uncertainty)

        cond do
          invalid_optional_number?(uncertainty["timing_3sigma_s"]) ->
            "invalid_execution_uncertainty"

          invalid_optional_numeric_triplet?(uncertainty["delta_v_3sigma_km_s"]) ->
            "invalid_execution_uncertainty"

          invalid_optional_string?(uncertainty["source"]) ->
            "invalid_execution_uncertainty"

          invalid_optional_string?(uncertainty["model"]) ->
            "invalid_execution_uncertainty"

          true ->
            nil
        end

      _value ->
        "invalid_execution_uncertainty"
    end
  end

  defp invalid_optional_number?(nil), do: false
  defp invalid_optional_number?(value), do: is_nil(numeric_value(value))

  defp invalid_optional_numeric_triplet?(nil), do: false
  defp invalid_optional_numeric_triplet?(value), do: is_nil(numeric_triplet(value))

  defp invalid_optional_string?(nil), do: false
  defp invalid_optional_string?(value), do: not (is_binary(value) and value != "")

  defp invalid_recommendation_input(source_recommendation, index, reasons) do
    maneuver_id =
      valid_stable_id_or_default(source_recommendation["id"], "invalid_maneuver:#{index}")

    scenario_id =
      valid_stable_id_or_default(source_recommendation["scenario_id"], "unknown_scenario")

    %{
      "id" => maneuver_id,
      "scenario_id" => scenario_id,
      "type" =>
        valid_string_or_default(source_recommendation["type"], "invalid_maneuver_recommendation"),
      "epoch_s" => valid_number_or_default(source_recommendation["epoch_s"], 0.0),
      "epoch_scale" => valid_string_or_default(source_recommendation["epoch_scale"], nil),
      "frame" => valid_string_or_default(source_recommendation["frame"], "unknown"),
      "delta_v_km_s" =>
        numeric_triplet(Map.get(source_recommendation, "delta_v_km_s")) || [0.0, 0.0, 0.0],
      "delta_v_magnitude_km_s" =>
        valid_number_or_default(source_recommendation["delta_v_magnitude_km_s"], 0.0),
      "maneuver_model" =>
        valid_string_or_default(source_recommendation["maneuver_model"], "unknown"),
      "invalid_maneuver_recommendation" => true,
      "invalid_maneuver_recommendation_reasons" => reasons,
      "source_recommendation" => source_recommendation
    }
    |> compact_map()
  end

  defp valid_stable_id_or_default(value, default) do
    case encode_optional_value(value) do
      value when is_binary(value) ->
        if Regex.match?(@stable_id_regex, value), do: value, else: default

      _value ->
        default
    end
  end

  defp valid_string_or_default(value, default) do
    case encode_optional_value(value) do
      value when is_binary(value) and value != "" -> value
      _value -> default
    end
  end

  defp valid_number_or_default(value, default) do
    case numeric_value(value) do
      value when is_number(value) -> value
      _value -> default
    end
  end

  defp normalize_recommendation(recommendation) do
    delta_v = numeric_triplet(Map.get(recommendation, "delta_v_km_s"))

    magnitude =
      numeric_value(Map.get(recommendation, "delta_v_magnitude_km_s")) || vector_norm(delta_v)

    recommendation
    |> Map.put("epoch_s", numeric_value(Map.get(recommendation, "epoch_s")))
    |> Map.put("delta_v_km_s", delta_v)
    |> maybe_put("delta_v_magnitude_km_s", magnitude)
    |> normalize_optional_unit_interval("maneuver_success_factor")
    |> normalize_recommendation_execution_uncertainty("execution_uncertainty")
    |> normalize_recommendation_execution_uncertainty("maneuver_execution_uncertainty")
    |> normalize_assumption_execution_uncertainty("execution_uncertainty")
    |> normalize_assumption_execution_uncertainty("maneuver_execution_uncertainty")
  end

  defp normalize_optional_unit_interval(recommendation, field) do
    case Map.get(recommendation, field) do
      nil -> recommendation
      value -> Map.put(recommendation, field, numeric_value(value))
    end
  end

  defp normalize_recommendation_execution_uncertainty(recommendation, field) do
    case Map.get(recommendation, field) do
      %{} = uncertainty ->
        Map.put(recommendation, field, normalize_execution_uncertainty(uncertainty))

      _value ->
        recommendation
    end
  end

  defp normalize_assumption_execution_uncertainty(
         %{"assumptions" => %{} = assumptions} = recommendation,
         field
       ) do
    case Map.get(assumptions, field) do
      %{} = uncertainty ->
        put_in(
          recommendation,
          ["assumptions", field],
          normalize_execution_uncertainty(uncertainty)
        )

      _value ->
        recommendation
    end
  end

  defp normalize_assumption_execution_uncertainty(recommendation, _field), do: recommendation

  defp normalize_execution_uncertainty(%{} = uncertainty) do
    uncertainty = stringify_keys(uncertainty)

    uncertainty
    |> normalize_uncertainty_number("timing_3sigma_s")
    |> normalize_uncertainty_triplet("delta_v_3sigma_km_s")
  end

  defp normalize_uncertainty_number(%{} = uncertainty, key) do
    case Map.fetch(uncertainty, key) do
      {:ok, value} ->
        case numeric_value(value) do
          nil -> uncertainty
          number -> Map.put(uncertainty, key, number)
        end

      :error ->
        uncertainty
    end
  end

  defp normalize_uncertainty_triplet(%{} = uncertainty, key) do
    case Map.fetch(uncertainty, key) do
      {:ok, value} ->
        case numeric_triplet(value) do
          nil -> uncertainty
          triplet -> Map.put(uncertainty, key, triplet)
        end

      :error ->
        uncertainty
    end
  end

  defp encode_optional_value(nil), do: nil
  defp encode_optional_value(value), do: encode_value(value)

  defp maneuver_sort_key(%{"invalid_maneuver_recommendation" => true} = recommendation) do
    {"~invalid", recommendation["scenario_id"], recommendation["id"]}
  end

  defp maneuver_sort_key(recommendation) do
    {recommendation["scenario_id"], recommendation["epoch_s"], recommendation["id"]}
  end

  defp model_limits do
    capabilities()
    |> Map.fetch!(:known_limits)
    |> Enum.map(&Atom.to_string/1)
  end

  defp review_row(recommendation, rank, approval_policy) do
    execution_uncertainty = maneuver_execution_uncertainty(recommendation)
    execution_uncertainty_status = execution_uncertainty_status(execution_uncertainty)

    row =
      %{
        "id" => "maneuver_review:#{recommendation["scenario_id"]}:#{recommendation["id"]}",
        "rank" => rank,
        "maneuver_id" => recommendation["id"],
        "scenario_id" => recommendation["scenario_id"],
        "maneuver_type" => recommendation["type"],
        "epoch_s" => recommendation["epoch_s"],
        "epoch_scale" => recommendation["epoch_scale"],
        "frame" => recommendation["frame"],
        "delta_v_km_s" => recommendation["delta_v_km_s"],
        "delta_v_magnitude_km_s" => recommendation["delta_v_magnitude_km_s"],
        "maneuver_model" => recommendation["maneuver_model"],
        "approval_status" => "operator_review_required",
        "required_operator_action" => required_operator_action(recommendation),
        "reason" => review_reason(recommendation),
        "execution_boundary" => execution_boundary(recommendation),
        "execution_uncertainty_status" => execution_uncertainty_status,
        "execution_uncertainty" => execution_uncertainty,
        "maneuver_success_factor" => recommendation["maneuver_success_factor"],
        "maneuver_success_factor_source" => recommendation["maneuver_success_factor_source"],
        "invalid_maneuver_recommendation" => recommendation["invalid_maneuver_recommendation"],
        "invalid_maneuver_recommendation_reasons" =>
          recommendation["invalid_maneuver_recommendation_reasons"],
        "source_recommendation" => source_recommendation(recommendation)
      }
      |> Map.merge(execution_uncertainty_fields(execution_uncertainty))
      |> compact_map()

    maybe_apply_approval_policy(row, approval_policy)
  end

  defp maybe_apply_approval_policy(row, nil), do: row

  defp maybe_apply_approval_policy(row, approval_policy) do
    requirement = maneuver_approval_requirement(row)

    {status, requirements, matches, decision} =
      Policy.decide(
        [requirement],
        [],
        %{"id" => "maneuver_review", "events" => []},
        %{},
        approval_policy
      )

    row
    |> Map.put("approval_status", status)
    |> Map.put("approval_requirements", requirements)
    |> Map.put("approval_rule_matches", matches)
    |> Map.put("policy_decision", decision)
  end

  defp source_recommendation(%{"invalid_maneuver_recommendation" => true} = recommendation) do
    recommendation
    |> Map.get("source_recommendation", %{})
    |> sanitize_invalid_source_recommendation(
      Map.get(recommendation, "invalid_maneuver_recommendation_reasons", [])
    )
  end

  defp source_recommendation(recommendation), do: recommendation

  defp sanitize_invalid_source_recommendation(%{} = source_recommendation, reasons) do
    reasons
    |> Enum.reduce(source_recommendation, fn
      "invalid_maneuver_success_factor", recommendation ->
        Map.delete(recommendation, "maneuver_success_factor")

      "invalid_delta_v_magnitude_km_s", recommendation ->
        Map.delete(recommendation, "delta_v_magnitude_km_s")

      _reason, recommendation ->
        recommendation
    end)
  end

  defp maneuver_approval_requirement(row) do
    recommendation = Map.get(row, "source_recommendation", %{})

    %{
      "activity_id" => row["maneuver_id"],
      "activity_type" => row["maneuver_type"],
      "action" => row["required_operator_action"],
      "requirement_type" =>
        Map.get(recommendation, "requirement_type", "maneuver_authority_review"),
      "reason" => row["reason"],
      "activity_context" =>
        %{
          "maneuver_id" => row["maneuver_id"],
          "maneuver_type" => row["maneuver_type"],
          "scenario_id" => row["scenario_id"],
          "epoch_s" => row["epoch_s"],
          "frame" => row["frame"],
          "delta_v_magnitude_km_s" => row["delta_v_magnitude_km_s"],
          "execution_uncertainty_status" => row["execution_uncertainty_status"],
          "timing_3sigma_s" => row["timing_3sigma_s"],
          "delta_v_3sigma_km_s" => row["delta_v_3sigma_km_s"],
          "delta_v_3sigma_magnitude_km_s" => row["delta_v_3sigma_magnitude_km_s"],
          "maneuver_success_factor" => row["maneuver_success_factor"],
          "maneuver_success_factor_source" => row["maneuver_success_factor_source"],
          "invalid_maneuver_recommendation" => row["invalid_maneuver_recommendation"],
          "invalid_maneuver_recommendation_reasons" =>
            row["invalid_maneuver_recommendation_reasons"],
          "source_recommendation" => row["source_recommendation"]
        }
        |> compact_map()
    }
    |> compact_map()
  end

  defp review_reason(recommendation) do
    if Map.get(recommendation, "invalid_maneuver_recommendation", false) do
      reasons =
        recommendation
        |> Map.get("invalid_maneuver_recommendation_reasons", ["invalid_maneuver_recommendation"])
        |> Enum.join(",")

      "maneuver recommendation input is invalid: #{reasons}"
    else
      valid_review_reason(recommendation)
    end
  end

  defp valid_review_reason(recommendation) do
    delta_v = Map.get(recommendation, "delta_v_magnitude_km_s")
    epoch_s = Map.get(recommendation, "epoch_s")

    "review #{Map.get(recommendation, "type", "maneuver")} maneuver at #{epoch_s}s with #{delta_v} km/s delta-v"
  end

  defp required_operator_action(%{"invalid_maneuver_recommendation" => true}),
    do: "review_invalid_maneuver_recommendation"

  defp required_operator_action(_recommendation), do: "review_maneuver_recommendation"

  defp execution_boundary(recommendation) do
    if Map.get(recommendation, "invalid_maneuver_recommendation", false) do
      "review_only_invalid_maneuver_recommendation"
    else
      valid_execution_boundary(recommendation)
    end
  end

  defp valid_execution_boundary(recommendation) do
    get_in(recommendation, ["assumptions", "execution_boundary"]) ||
      "recommendation_only_no_command_execution"
  end

  defp maneuver_execution_uncertainty(recommendation) do
    uncertainty =
      Map.get(recommendation, "execution_uncertainty") ||
        Map.get(recommendation, "maneuver_execution_uncertainty") ||
        get_in(recommendation, ["assumptions", "execution_uncertainty"]) ||
        get_in(recommendation, ["assumptions", "maneuver_execution_uncertainty"])

    case uncertainty do
      %{} = uncertainty -> normalize_execution_uncertainty(uncertainty)
      _other -> nil
    end
  end

  defp execution_uncertainty_status(nil), do: "missing"
  defp execution_uncertainty_status(%{}), do: "declared"

  defp execution_uncertainty_fields(nil), do: %{}

  defp execution_uncertainty_fields(%{} = uncertainty) do
    delta_v_3sigma_km_s = numeric_triplet(Map.get(uncertainty, "delta_v_3sigma_km_s"))

    %{
      "timing_3sigma_s" => numeric_value(Map.get(uncertainty, "timing_3sigma_s")),
      "delta_v_3sigma_km_s" => delta_v_3sigma_km_s,
      "delta_v_3sigma_magnitude_km_s" => vector_norm(delta_v_3sigma_km_s),
      "execution_uncertainty_source" =>
        Map.get(uncertainty, "source") || Map.get(uncertainty, "model")
    }
    |> compact_map()
  end

  defp numeric_triplet([x, y, z]) do
    triplet = Enum.map([x, y, z], &numeric_value/1)

    if Enum.all?(triplet, &is_number/1), do: triplet, else: nil
  end

  defp numeric_triplet(_value), do: nil

  defp numeric_value(value) when is_number(value), do: value

  defp numeric_value(value) when is_binary(value) do
    case Float.parse(String.trim(value)) do
      {number, ""} -> number
      _other -> nil
    end
  end

  defp numeric_value(_value), do: nil

  defp vector_norm(nil), do: nil

  defp vector_norm([x, y, z]) do
    :math.sqrt(x * x + y * y + z * z)
  end

  defp total_delta_v(rows) do
    rows
    |> Enum.map(&Map.get(&1, "delta_v_magnitude_km_s"))
    |> Enum.filter(&is_number/1)
    |> Enum.sum()
  end

  defp execution_uncertainty_summary_fields(rows) do
    %{
      "max_timing_3sigma_s" => max_number(rows, "timing_3sigma_s"),
      "max_delta_v_3sigma_magnitude_km_s" => max_number(rows, "delta_v_3sigma_magnitude_km_s"),
      "total_delta_v_3sigma_magnitude_km_s" => sum_number(rows, "delta_v_3sigma_magnitude_km_s")
    }
  end

  defp max_number(rows, field) do
    rows
    |> Enum.map(&Map.get(&1, field))
    |> Enum.filter(&is_number/1)
    |> Enum.max(fn -> nil end)
  end

  defp sum_number(rows, field) do
    values =
      rows
      |> Enum.map(&Map.get(&1, field))
      |> Enum.filter(&is_number/1)

    if values == [], do: nil, else: Enum.sum(values)
  end

  defp execution_uncertainty_count(rows, status) do
    Enum.count(rows, &(Map.get(&1, "execution_uncertainty_status") == status))
  end

  defp stringify_keys(%{} = map) do
    Map.new(map, fn {key, value} -> {encode_key(key), stringify_keys(value)} end)
  end

  defp stringify_keys(values) when is_list(values), do: Enum.map(values, &stringify_keys/1)
  defp stringify_keys(value), do: encode_value(value)

  defp encode_key(key) when is_atom(key), do: Atom.to_string(key)
  defp encode_key(key), do: key

  defp encode_value(value) when is_boolean(value), do: value
  defp encode_value(value) when is_atom(value), do: Atom.to_string(value)
  defp encode_value(value), do: value

  defp compact_map(map) do
    map
    |> Enum.reject(fn {_key, value} -> is_nil(value) end)
    |> Map.new()
  end

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)
end
