defmodule OrbitalDynamics.CampaignPlanner.EventRiskIndicator.ResourcePressure do
  @moduledoc false

  def indicators(%{"type" => "resource_margin_pressure"} = event) do
    field = event["resource_field"] || "resource_margin"
    value = Map.get(event, field)
    threshold = Map.get(event, "#{field}_threshold")
    spacecraft_id = branch_event_spacecraft_id(event)

    [
      %{
        "type" => field <> "_low",
        "severity" => "medium",
        "reason" => "spacecraft #{spacecraft_id} #{field} #{value} below threshold #{threshold}",
        "value" => value,
        "spacecraft_id" => spacecraft_id,
        "scenario_id" => event["scenario_id"],
        "timeline_id" => event["timeline_id"],
        "source_activity_id" => event["source_activity_id"],
        "replacement_activity_id" => event["replacement_activity_id"],
        "source_activity_ids" => event["source_activity_ids"],
        "resource_margin_risk_type" => field <> "_low",
        "resource_field" => field,
        "resource_margin_value" => value,
        "resource_margin_threshold" => threshold,
        "resource_margin_field_value" =>
          resource_margin_field_value_context(field, value, threshold),
        "suppressed_reason" => event["suppressed_reason"],
        "source_quality" => event["source_quality"],
        "resource_trust_boundary_status" => event["resource_trust_boundary_status"],
        "operator_training_requirement_count" => event["operator_training_requirement_count"],
        "required_operator_roles" => event["required_operator_roles"],
        "starts_at_s" => event["starts_at_s"],
        "ends_at_s" => event["ends_at_s"],
        "diff_status" => event["diff_status"],
        "changed_fields" => event["changed_fields"],
        "required_operator_action" => event["required_operator_action"],
        "requires_operator_review" => event["requires_operator_review"],
        "feedback_source" => event["feedback_source"],
        "feedback_scope" => event["feedback_scope"],
        "feedback_key" => event["feedback_key"],
        "trust_boundary" => event["trust_boundary"],
        "derivation_reasons" => event["derivation_reasons"]
      }
      |> compact_map()
    ]
  end

  def indicators(%{"type" => "resource_availability_constraint"} = event) do
    field = event["resource_field"] || "resource_available"
    risk_type = resource_availability_constraint_risk_type(event, field)
    spacecraft_id = branch_event_spacecraft_id(event)
    value = Map.get(event, field, Map.get(event, "available", false))

    [
      %{
        "type" => risk_type,
        "severity" => "medium",
        "reason" => "spacecraft #{spacecraft_id} #{field} false constrains generated candidates",
        "value" => value,
        "spacecraft_id" => spacecraft_id,
        "scenario_id" => event["scenario_id"],
        "timeline_id" => event["timeline_id"],
        "source_activity_id" => event["source_activity_id"],
        "replacement_activity_id" => event["replacement_activity_id"],
        "source_activity_ids" => event["source_activity_ids"],
        "resource_availability_risk_type" => risk_type,
        "resource_field" => field,
        "resource_availability_value" => value,
        field => value,
        "suppressed_reason" => event["suppressed_reason"],
        "approval_status" => event["approval_status"],
        "policy_classification" => event["policy_classification"],
        "resource_filter_status" => event["resource_filter_status"],
        "suppression_status" => event["suppression_status"],
        "resource_id" => event["resource_id"],
        "planned_resource_id" => event["planned_resource_id"],
        "realized_resource_id" => event["realized_resource_id"],
        "resource_match_status" => event["resource_match_status"],
        "resource_identity_mismatch_fields" => event["resource_identity_mismatch_fields"],
        "resource_trust_boundary_status" => event["resource_trust_boundary_status"],
        "source_quality" => event["source_quality"],
        "starts_at_s" => event["starts_at_s"],
        "ends_at_s" => event["ends_at_s"],
        "diff_status" => event["diff_status"],
        "changed_fields" => event["changed_fields"],
        "required_operator_action" => event["required_operator_action"],
        "requires_operator_review" => event["requires_operator_review"],
        "feedback_source" => event["feedback_source"],
        "feedback_scope" => event["feedback_scope"],
        "feedback_key" => event["feedback_key"],
        "trust_boundary" => event["trust_boundary"],
        "derivation_reasons" => event["derivation_reasons"]
      }
      |> compact_map()
    ]
  end

  def indicators(_event), do: []

  defp resource_availability_constraint_risk_type(event, "payload_available") do
    if "projected_spacecraft_degraded_payload_unavailable" in List.wrap(
         event["derivation_reasons"]
       ) do
      "spacecraft_degraded_payload_unavailable"
    else
      "payload_unavailable"
    end
  end

  defp resource_availability_constraint_risk_type(_event, field) do
    String.replace(field, "_available", "_unavailable")
  end

  defp resource_margin_field_value_context(field, value, threshold)
       when is_binary(field) and is_number(value) do
    %{
      "field" => field,
      "value" => value,
      "threshold" => threshold
    }
    |> compact_map()
  end

  defp resource_margin_field_value_context(_field, _value, _threshold), do: nil

  defp branch_event_spacecraft_id(event) do
    case encode_value(Map.get(event, "spacecraft_id") || Map.get(event, "scenario_id")) do
      value when value in [nil, ""] -> nil
      value -> value
    end
  end

  defp compact_map(map) do
    map
    |> Enum.reject(fn {_key, value} -> is_nil(value) end)
    |> Map.new()
  end

  defp encode_value(%_{} = struct), do: struct |> Map.from_struct() |> encode_value()

  defp encode_value(%{} = map) do
    Map.new(map, fn {key, value} -> {encode_value(key), encode_value(value)} end)
  end

  defp encode_value(values) when is_list(values) do
    if Keyword.keyword?(values) do
      Map.new(values, fn {key, value} -> {encode_value(key), encode_value(value)} end)
    else
      Enum.map(values, &encode_value/1)
    end
  end

  defp encode_value(value) when is_tuple(value), do: value |> Tuple.to_list() |> encode_value()
  defp encode_value(nil), do: nil
  defp encode_value(value) when is_boolean(value), do: value
  defp encode_value(value) when is_atom(value), do: Atom.to_string(value)
  defp encode_value(value), do: value
end
