defmodule OrbitalDynamics.Schema.CommandWindowReportJsonSchema do
  @moduledoc false

  alias OrbitalDynamics.Schema.CommonJsonSchema

  @scalar_count_fields [
    "window_count",
    "command_count",
    "tracking_count",
    "uplink_count",
    "health_check_count",
    "review_required_count",
    "source_window_lineage_count"
  ]

  @stable_id_array_map_fields [
    "activity_ids_by_window_type",
    "review_activity_ids_by_required_operator_action"
  ]

  def property_field?(field)
      when field in [
             "source",
             "model",
             "model_limits",
             "rows"
           ],
      do: true

  def property_field?(field)
      when field in @stable_id_array_map_fields or field in @scalar_count_fields,
      do: true

  def property_field?(_field), do: false

  def property_opts("model_limits", deps) do
    [model_limits: fetch_dep!(deps, :model_limits)]
  end

  def property_opts("rows", deps) do
    [row_schema: fetch_dep!(deps, :row_schema)]
  end

  def property_opts(_field, _deps), do: []

  def property_from_context(field, deps) when is_list(deps) do
    property(field, property_opts(field, deps))
  end

  def property_fun_from_context(deps) when is_list(deps) do
    fn field -> property_from_context(field, deps) end
  end

  def property("source", _opts) do
    %{"type" => "string"}
  end

  def property("model", _opts) do
    %{
      "type" => "string",
      "const" => "artifact_only_command_window_report"
    }
  end

  def property("model_limits", opts) do
    model_limits = Keyword.fetch!(opts, :model_limits)

    %{
      "type" => "array",
      "items" => %{"type" => "string", "enum" => model_limits}
    }
  end

  def property("rows", opts) do
    %{
      "type" => "array",
      "items" => Keyword.fetch!(opts, :row_schema)
    }
  end

  def property(field, _opts) when field in @stable_id_array_map_fields do
    CommonJsonSchema.string_list_map()
  end

  def property(field, _opts) when field in @scalar_count_fields do
    %{"type" => "integer", "minimum" => 0}
  end

  def row(opts) do
    stable_id_pattern = Keyword.fetch!(opts, :stable_id_pattern)
    activity_context_schema = Keyword.fetch!(opts, :activity_context_schema)
    policy_decision_schema = Keyword.fetch!(opts, :policy_decision_schema)

    %{
      "type" => "object",
      "additionalProperties" => true,
      "required" => [
        "id",
        "rank",
        "activity_id",
        "timeline_id",
        "activity_type",
        "window_type",
        "starts_at_s",
        "ends_at_s",
        "status",
        "approval_status",
        "locked",
        "required_operator_action",
        "execution_boundary",
        "cadence_import_status",
        "has_source_window",
        "has_cadence_import",
        "timeline_identity"
      ],
      "properties" => %{
        "id" => stable_id(stable_id_pattern),
        "rank" => %{"type" => "integer"},
        "activity_id" => stable_id(stable_id_pattern),
        "timeline_id" => stable_id(stable_id_pattern),
        "scenario_id" => stable_id(stable_id_pattern),
        "activity_type" => %{"type" => "string"},
        "window_type" => %{
          "type" => "string",
          "enum" => [
            "command_window",
            "tracking_window",
            "uplink_window",
            "health_check_window",
            "command_context_window"
          ]
        },
        "direction" => %{"type" => "string"},
        "ground_station_id" => %{"type" => "string"},
        "starts_at_s" => %{"type" => "number"},
        "ends_at_s" => %{"type" => "number"},
        "status" => %{"type" => "string"},
        "approval_status" => %{"type" => "string"},
        "locked" => %{"type" => "boolean"},
        "required_operator_action" => %{"type" => "string"},
        "operator_action_reason" => %{"type" => "string"},
        "execution_boundary" => %{"type" => "string"},
        "cadence_import_status" => %{"type" => "string"},
        "cadence_import_type" => %{"type" => "string"},
        "source_window_id" => %{"type" => "string"},
        "source_window_type" => %{"type" => "string"},
        "activity_context" => activity_context_schema,
        "dependency_activity_ids" => CommonJsonSchema.stable_id_array(stable_id_pattern),
        "dependency_timeline_ids" => CommonJsonSchema.stable_id_array(stable_id_pattern),
        "exclusive_with_activity_ids" => CommonJsonSchema.stable_id_array(stable_id_pattern),
        "exclusive_with_timeline_ids" => CommonJsonSchema.stable_id_array(stable_id_pattern),
        "approval_requirements" => %{"type" => "array"},
        "approval_rule_matches" => %{"type" => "array"},
        "has_source_window" => %{"type" => "boolean"},
        "has_cadence_import" => %{"type" => "boolean"},
        "timeline_identity" => %{
          "type" => "object",
          "additionalProperties" => true
        },
        "policy_decision" => policy_decision_schema
      }
    }
  end

  defp stable_id(stable_id_pattern) do
    %{"type" => "string", "pattern" => stable_id_pattern}
  end

  defp fetch_dep!(deps, key) do
    case Keyword.fetch!(deps, key) do
      fun when is_function(fun, 0) -> fun.()
      value -> value
    end
  end
end
