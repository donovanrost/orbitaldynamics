defmodule OrbitalDynamics.Schema.ResourceProjectionHandoffJsonSchema do
  @moduledoc false

  def battery_properties(fields) when is_list(fields) do
    Map.new(fields, &{&1, number_schema()})
  end

  def evidence_properties(opts) do
    stable_id_pattern = Keyword.fetch!(opts, :stable_id_pattern)

    %{
      "source" => %{"type" => "string"},
      "rank" => %{"type" => "integer"},
      "subject_id" => %{"type" => "string"},
      "action" => %{"type" => "string"},
      "required_operator_action" => %{"type" => "string"},
      "reason" => %{"type" => "string"},
      "approval_status" => %{"type" => "string"},
      "review_queue" => %{"type" => "string"},
      "review_queue_key" => %{"type" => "string"},
      "spacecraft_id" => %{"type" => "string", "pattern" => stable_id_pattern},
      "activity_count" => non_negative_integer_schema(),
      "effective_activity_count" => non_negative_integer_schema(),
      "ignored_activity_count" => non_negative_integer_schema(),
      "ignored_activity_ids" => Keyword.fetch!(opts, :stable_id_array_schema),
      "observation_count" => non_negative_integer_schema(),
      "downlink_count" => non_negative_integer_schema(),
      "estimated_storage_produced_mb" => number_schema(),
      "estimated_downlink_mb" => number_schema(),
      "starting_storage_used_mb" => number_schema(),
      "projected_storage_used_mb" => number_schema(),
      "storage_capacity_mb" => number_schema(),
      "starting_storage_margin" => number_schema(),
      "projected_storage_margin" => number_schema(),
      "downlink_capacity_mb" => number_schema(),
      "starting_downlink_margin" => number_schema(),
      "projected_downlink_margin" => number_schema(),
      "resource_source_quality" => %{"type" => "string"},
      "resource_flow_count" => non_negative_integer_schema(),
      "peak_storage_overflow_mb" => number_schema(),
      "peak_downlink_shortfall_mb" => number_schema(),
      "peak_unused_downlink_capacity_mb" => number_schema(),
      "projected_storage_overflow_mb" => number_schema(),
      "projected_downlink_shortfall_mb" => number_schema(),
      "projected_battery_overuse_wh" => number_schema(),
      "first_resource_pressure_activity_id" => %{
        "type" => "string",
        "pattern" => stable_id_pattern
      },
      "first_resource_pressure_activity_type" => %{"type" => "string"},
      "first_resource_pressure_kind" => %{"type" => "string"},
      "first_resource_pressure_starts_at_s" => number_schema(),
      "fuel_margin" => number_schema(),
      "power_margin" => number_schema(),
      "resource_trust_boundary_status" => %{"type" => "string"},
      "storage_limited_downlinked_mb" => number_schema(),
      "unused_downlink_capacity_mb" => number_schema(),
      "warnings" => Keyword.fetch!(opts, :string_array_schema),
      "policy_bundle_id" => %{"type" => "string", "pattern" => stable_id_pattern},
      "rule_id" => %{"type" => "string", "pattern" => stable_id_pattern},
      "requirement_type" => %{"type" => "string"},
      "approval_requirements" => %{
        "type" => "array",
        "items" => Keyword.fetch!(opts, :approval_requirement_schema)
      },
      "approval_rule_matches" => %{
        "type" => "array",
        "items" => Keyword.fetch!(opts, :policy_decision_rule_match_schema)
      },
      "escalation_level" => %{"type" => "string"},
      "escalation_queue" => %{"type" => "string"},
      "escalation_role" => %{"type" => "string"},
      "sla_s" => number_schema()
    }
  end

  defp non_negative_integer_schema do
    %{"type" => "integer", "minimum" => 0}
  end

  defp number_schema do
    %{"type" => "number"}
  end
end
