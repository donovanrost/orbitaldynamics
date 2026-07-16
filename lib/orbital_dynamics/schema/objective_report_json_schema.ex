defmodule OrbitalDynamics.Schema.ObjectiveReportJsonSchema do
  @moduledoc false

  alias OrbitalDynamics.Schema.CommonJsonSchema

  @objective_satisfaction_report "objective_satisfaction_report.v1"
  @objective_tradeoff_report "objective_tradeoff_report.v1"

  @satisfaction_statuses [
    "met",
    "partial",
    "unmet",
    "selected",
    "candidate_available",
    "no_candidate_window",
    "no_requirement"
  ]

  @satisfaction_count_fields [
    "required_count",
    "candidate_count",
    "selected_count",
    "satisfied_count"
  ]

  @satisfaction_number_fields [
    "candidate_downlink_mb",
    "required_downlink_mb",
    "satisfied_downlink_mb",
    "selected_downlink_mb"
  ]

  @satisfaction_stable_id_fields [
    "id",
    "target_id"
  ]

  @satisfaction_stable_id_array_fields [
    "candidate_target_ids",
    "selected_target_ids",
    "selected_contact_ids",
    "selected_activity_ids"
  ]

  @tradeoff_count_fields [
    "activity_count",
    "selected_observation_count",
    "selected_contact_count"
  ]

  @tradeoff_number_fields [
    "score",
    "score_delta_from_selected"
  ]

  def property_field?(field, @objective_satisfaction_report)
      when field in ["rows", "model", "model_limits", "objective_count"],
      do: true

  def property_field?(field, @objective_tradeoff_report)
      when field in [
             "tradeoffs",
             "ranking_count",
             "score_term_keys",
             "model",
             "model_limits",
             "policy"
           ],
      do: true

  def property_field?(_field, _contract_name), do: false

  def property_opts("rows", @objective_satisfaction_report, deps) do
    [satisfaction_row_schema: fetch_dep!(deps, :satisfaction_row_schema)]
  end

  def property_opts("model_limits", @objective_satisfaction_report, deps) do
    [satisfaction_model_limits: fetch_dep!(deps, :satisfaction_model_limits)]
  end

  def property_opts("tradeoffs", @objective_tradeoff_report, deps) do
    [tradeoff_row_schema: fetch_dep!(deps, :tradeoff_row_schema)]
  end

  def property_opts("model", @objective_tradeoff_report, deps) do
    [tradeoff_models: fetch_dep!(deps, :tradeoff_models)]
  end

  def property_opts("model_limits", @objective_tradeoff_report, deps) do
    [score_report_model_limits: fetch_dep!(deps, :score_report_model_limits)]
  end

  def property_opts(_field, _contract_name, _deps), do: []

  def property_fun_from_context(deps) when is_list(deps) do
    fn field -> property_from_context(field, deps) end
  end

  def property_from_context(field, deps) when is_list(deps) do
    contract_name = fetch_dep!(deps, :contract_name)

    property(field, contract_name, property_opts(field, contract_name, deps))
  end

  def property("rows", @objective_satisfaction_report, opts) do
    %{"type" => "array", "items" => Keyword.fetch!(opts, :satisfaction_row_schema)}
  end

  def property("model", @objective_satisfaction_report, _opts) do
    %{"type" => "string", "const" => "campaign_v1_selected_activity_objective_summary"}
  end

  def property("model_limits", @objective_satisfaction_report, opts) do
    model_limits = Keyword.fetch!(opts, :satisfaction_model_limits)

    %{
      "type" => "array",
      "items" => %{"type" => "string", "enum" => model_limits}
    }
  end

  def property("objective_count", @objective_satisfaction_report, _opts) do
    %{"type" => "integer", "minimum" => 0}
  end

  def property("tradeoffs", @objective_tradeoff_report, opts) do
    %{"type" => "array", "items" => Keyword.fetch!(opts, :tradeoff_row_schema)}
  end

  def property("ranking_count", @objective_tradeoff_report, _opts) do
    %{"type" => "integer", "minimum" => 0}
  end

  def property("score_term_keys", @objective_tradeoff_report, _opts) do
    CommonJsonSchema.string_array()
  end

  def property("model", @objective_tradeoff_report, opts) do
    %{"type" => "string", "enum" => Keyword.fetch!(opts, :tradeoff_models)}
  end

  def property("model_limits", @objective_tradeoff_report, opts) do
    model_limits = Keyword.fetch!(opts, :score_report_model_limits)

    %{
      "type" => "array",
      "items" => %{"type" => "string", "enum" => model_limits}
    }
  end

  def property("policy", @objective_tradeoff_report, _opts) do
    %{"type" => "object", "additionalProperties" => true}
  end

  def satisfaction_row(opts) do
    %{
      "type" => "object",
      "additionalProperties" => true,
      "required" => [
        "id",
        "objective",
        "status",
        "candidate_count",
        "selected_count",
        "satisfied_count"
      ],
      "properties" => satisfaction_row_properties(opts)
    }
  end

  def satisfaction_row_from_context(stable_id_pattern, stable_id_array_schema) do
    satisfaction_row(
      stable_id_pattern: stable_id_pattern,
      stable_id_array_schema: stable_id_array_schema
    )
  end

  def satisfaction_row_from_context(deps) when is_list(deps) do
    satisfaction_row(
      stable_id_pattern: fetch_dep!(deps, :stable_id_pattern),
      stable_id_array_schema: fetch_dep!(deps, :stable_id_array_schema)
    )
  end

  def tradeoff_row(opts) do
    %{
      "type" => "object",
      "additionalProperties" => true,
      "required" => [
        "rank",
        "scenario_id",
        "score",
        "score_delta_from_selected",
        "activity_count",
        "score_terms",
        "activity_ids"
      ],
      "properties" => tradeoff_row_properties(opts)
    }
  end

  def tradeoff_row_from_context(stable_id_pattern, numeric_map_schema, string_array_schema) do
    tradeoff_row(
      stable_id_pattern: stable_id_pattern,
      numeric_map_schema: numeric_map_schema,
      string_array_schema: string_array_schema
    )
  end

  def tradeoff_row_from_context(deps) when is_list(deps) do
    tradeoff_row(
      stable_id_pattern: fetch_dep!(deps, :stable_id_pattern),
      numeric_map_schema: fetch_dep!(deps, :numeric_map_schema),
      string_array_schema: fetch_dep!(deps, :string_array_schema)
    )
  end

  defp satisfaction_row_properties(opts) do
    %{
      "objective" => %{"type" => "string"},
      "status" => %{"type" => "string", "enum" => @satisfaction_statuses}
    }
    |> Map.merge(stable_id_properties(Keyword.fetch!(opts, :stable_id_pattern)))
    |> Map.merge(CommonJsonSchema.non_negative_integer_properties(@satisfaction_count_fields))
    |> Map.merge(CommonJsonSchema.number_properties(@satisfaction_number_fields))
    |> Map.merge(stable_id_array_properties(Keyword.fetch!(opts, :stable_id_array_schema)))
  end

  defp tradeoff_row_properties(opts) do
    %{
      "rank" => %{"type" => "integer"},
      "scenario_id" => %{
        "type" => "string",
        "pattern" => Keyword.fetch!(opts, :stable_id_pattern)
      },
      "score_terms" => Keyword.fetch!(opts, :numeric_map_schema),
      "activity_ids" => Keyword.fetch!(opts, :string_array_schema)
    }
    |> Map.merge(CommonJsonSchema.number_properties(@tradeoff_number_fields))
    |> Map.merge(CommonJsonSchema.non_negative_integer_properties(@tradeoff_count_fields))
  end

  defp stable_id_properties(stable_id_pattern) do
    Map.new(
      @satisfaction_stable_id_fields,
      &{&1, %{"type" => "string", "pattern" => stable_id_pattern}}
    )
  end

  defp stable_id_array_properties(stable_id_array_schema) do
    Map.new(@satisfaction_stable_id_array_fields, &{&1, stable_id_array_schema})
  end

  defp fetch_dep!(deps, key) do
    case Keyword.fetch!(deps, key) do
      value when is_function(value, 0) -> value.()
      value -> value
    end
  end
end
