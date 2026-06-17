defmodule OrbitalDynamics.Schema.TimelinePreservationJsonSchema do
  @moduledoc false

  @report "timeline_preservation_report.v1"
  @status "timeline_preservation_status.v1"

  @report_integer_fields [
    "activity_count",
    "mutable_activity_count",
    "preserve_activity_count",
    "review_change_activity_count",
    "preservation_sensitive_activity_count"
  ]

  @report_count_map_fields [
    "protection_decision_counts",
    "protection_category_counts",
    "protection_reason_counts"
  ]

  @report_stable_id_array_fields [
    "preserve_activity_ids",
    "preserve_timeline_ids",
    "review_change_activity_ids",
    "review_change_timeline_ids",
    "mutable_activity_ids",
    "preservation_sensitive_activity_ids",
    "preservation_sensitive_timeline_ids"
  ]

  @report_stable_id_array_map_fields [
    "activity_id_sets_by_protection_decision",
    "timeline_id_sets_by_protection_decision",
    "activity_id_sets_by_protection_category",
    "timeline_id_sets_by_protection_category",
    "activity_id_sets_by_protection_reason",
    "timeline_id_sets_by_protection_reason"
  ]

  @status_boolean_fields [
    "requires_preservation",
    "requires_operator_review",
    "locked",
    "approved",
    "invalid_activity_input"
  ]

  @status_string_fields [
    "status",
    "approval_status"
  ]

  @status_object_fields [
    "protection_decision",
    "protection_category",
    "protection_reason",
    "invalid_activity_input_reason"
  ]

  @status_stable_id_fields ["activity_id", "timeline_id"]

  def property("schema_contract", opts) do
    %{"type" => "string", "const" => Keyword.fetch!(opts, :contract_name)}
  end

  def property("model", opts) do
    %{"type" => "string", "const" => model_const(Keyword.fetch!(opts, :contract_name))}
  end

  def property("source", opts) do
    require_contract!(opts, [@report], "source")
    %{"type" => "string"}
  end

  def property("model_limits", opts) do
    model_limits = Keyword.fetch!(opts, :model_limits)

    %{
      "type" => "array",
      "const" => model_limits,
      "items" => %{"type" => "string", "enum" => model_limits}
    }
  end

  def property(field, opts) when field in @report_integer_fields do
    require_contract!(opts, [@report], field)
    %{"type" => "integer", "minimum" => 0}
  end

  def property(field, opts) when field in @report_count_map_fields do
    require_contract!(opts, [@report], field)
    schema_value(opts, :count_map_schema)
  end

  def property(field, opts) when field in @report_stable_id_array_fields do
    require_contract!(opts, [@report], field)
    schema_value(opts, :stable_id_array_schema)
  end

  def property(field, opts) when field in @report_stable_id_array_map_fields do
    require_contract!(opts, [@report], field)
    schema_value(opts, :stable_id_array_map_schema)
  end

  def property("rows", opts) do
    require_contract!(opts, [@report], "rows")
    %{"type" => "array", "items" => schema_value(opts, :protection_decision_schema)}
  end

  def property("timeline_preservation_status", _opts) do
    %{"type" => "string", "enum" => ["clear", "preservation_required", "review_required"]}
  end

  def property(field, opts) when field in @status_boolean_fields do
    require_contract!(opts, [@status], field)
    %{"type" => "boolean"}
  end

  def property(field, opts) when field in @status_string_fields do
    require_contract!(opts, [@status], field)
    %{"type" => "string"}
  end

  def property(field, opts) when field in @status_object_fields do
    require_contract!(opts, [@status], field)
    %{"type" => "object"}
  end

  def property(field, opts) when field in @status_stable_id_fields do
    require_contract!(opts, [@status], field)
    %{"type" => "string", "pattern" => Keyword.fetch!(opts, :stable_id_pattern)}
  end

  def property("timeline_identity", opts) do
    require_contract!(opts, [@status], "timeline_identity")
    schema_value(opts, :timeline_identity_schema)
  end

  def property("assumptions", opts) do
    Keyword.fetch!(opts, :assumptions_schema).(Keyword.fetch!(opts, :contract_name))
  end

  defp model_const(@report), do: "artifact_only_lifecycle_preservation_summary"
  defp model_const(@status), do: "artifact_only_lifecycle_preservation_status"

  defp schema_value(opts, key) do
    case Keyword.fetch!(opts, key) do
      fun when is_function(fun, 0) -> fun.()
      value -> value
    end
  end

  defp require_contract!(opts, allowed_contracts, field) do
    contract_name = Keyword.fetch!(opts, :contract_name)

    if contract_name not in allowed_contracts do
      raise ArgumentError,
            "field #{inspect(field)} is not valid for timeline preservation contract #{inspect(contract_name)}"
    end
  end
end
