defmodule OrbitalDynamics.Schema.ScopedDownlinkContextJsonSchema do
  @moduledoc false

  alias OrbitalDynamics.Schema.CommonJsonSchema

  def scoped_from_context(opts) when is_list(opts) do
    opts
    |> Keyword.fetch!(:stable_id_pattern)
    |> scoped()
  end

  def scoped_from_context(stable_id_pattern) when is_binary(stable_id_pattern) do
    scoped(stable_id_pattern)
  end

  def scoped(stable_id_pattern) do
    %{
      "target_id" => stable_id(stable_id_pattern),
      "target_ids" => CommonJsonSchema.stable_id_array(stable_id_pattern),
      "collection_id" => stable_id(stable_id_pattern),
      "collection_ids" => CommonJsonSchema.stable_id_array(stable_id_pattern),
      "product_id" => stable_id(stable_id_pattern),
      "product_ids" => CommonJsonSchema.stable_id_array(stable_id_pattern),
      "payload_id" => stable_id(stable_id_pattern),
      "payload_ids" => CommonJsonSchema.stable_id_array(stable_id_pattern),
      "instrument_id" => stable_id(stable_id_pattern),
      "instrument_ids" => CommonJsonSchema.stable_id_array(stable_id_pattern),
      "objective_id" => stable_id(stable_id_pattern),
      "objective_ids" => CommonJsonSchema.stable_id_array(stable_id_pattern),
      "objective_type" => %{"type" => "string"},
      "objective_types" => CommonJsonSchema.string_array(),
      "objective_status" => %{"type" => "string"},
      "objective_statuses" => CommonJsonSchema.string_array(),
      "source_objective_status" => %{"type" => "string"},
      "source_objective_statuses" => CommonJsonSchema.string_array(),
      "latency_objective" => %{"type" => "boolean"},
      "max_latency_s" => %{"type" => "number"},
      "planned_latency_s" => %{"type" => "number"},
      "required_contacts" => %{"type" => "number"},
      "planned_contacts" => %{"type" => "number"},
      "required_downlink_mb" => %{"type" => "number"},
      "planned_downlink_mb" => %{"type" => "number"},
      "contact_result" => %{"type" => "string"},
      "contact_results" => CommonJsonSchema.string_array(),
      "realized_status" => %{"type" => "string"},
      "realized_statuses" => CommonJsonSchema.string_array(),
      "source_activity_id" => stable_id(stable_id_pattern),
      "source_activity_ids" => CommonJsonSchema.stable_id_array(stable_id_pattern),
      "missed_downlink_activity_id" => stable_id(stable_id_pattern),
      "missed_downlink_activity_ids" => CommonJsonSchema.stable_id_array(stable_id_pattern),
      "feedback_source" => %{"type" => "string"},
      "feedback_sources" => CommonJsonSchema.string_array(),
      "feedback_scope" => %{"type" => "string"},
      "feedback_scopes" => CommonJsonSchema.string_array(),
      "trust_boundary" => %{"type" => "string"},
      "trust_boundaries" => CommonJsonSchema.string_array(),
      "derivation_reasons" => CommonJsonSchema.string_array()
    }
  end

  def candidate_refresh_from_context(opts) when is_list(opts) do
    opts
    |> Keyword.fetch!(:stable_id_pattern)
    |> candidate_refresh()
  end

  def candidate_refresh_from_context(stable_id_pattern) when is_binary(stable_id_pattern) do
    candidate_refresh(stable_id_pattern)
  end

  def candidate_refresh(stable_id_pattern) do
    stable_id_pattern
    |> scoped()
    |> Map.merge(%{
      "collection_latency_objective_ids" => CommonJsonSchema.stable_id_array(stable_id_pattern),
      "collection_latency_objective_count" => %{"type" => "integer", "minimum" => 0},
      "collection_latency_objective_source" => %{"type" => "string"},
      "collection_latency_objective_types" => CommonJsonSchema.string_array(),
      "max_latency_s" => %{"type" => "number", "minimum" => 0},
      "planned_latency_s" => %{"type" => "number", "minimum" => 0},
      "required_downlink_mb" => %{"type" => "number", "minimum" => 0},
      "candidate_downlink_mb" => %{"type" => "number", "minimum" => 0},
      "downlink_completion_ratio" => %{"type" => "number", "minimum" => 0, "maximum" => 1},
      "selected_downlink_shortfall_mb" => %{"type" => "number", "minimum" => 0},
      "downlink_requirement_status" => %{"type" => "string"},
      "downlink_completion_source" => %{"type" => "string"},
      "downlink_completion_sources" => CommonJsonSchema.string_array()
    })
  end

  def branch_from_context(opts) when is_list(opts) do
    opts
    |> Keyword.fetch!(:stable_id_pattern)
    |> branch()
  end

  def branch_from_context(stable_id_pattern) when is_binary(stable_id_pattern) do
    branch(stable_id_pattern)
  end

  def branch(stable_id_pattern) do
    %{
      "branch_scenario_ids" => CommonJsonSchema.stable_id_array(stable_id_pattern),
      "branch_target_ids" => CommonJsonSchema.stable_id_array(stable_id_pattern),
      "branch_collection_ids" => CommonJsonSchema.stable_id_array(stable_id_pattern),
      "branch_product_ids" => CommonJsonSchema.stable_id_array(stable_id_pattern),
      "branch_payload_ids" => CommonJsonSchema.stable_id_array(stable_id_pattern),
      "branch_instrument_ids" => CommonJsonSchema.stable_id_array(stable_id_pattern),
      "branch_objective_ids" => CommonJsonSchema.stable_id_array(stable_id_pattern),
      "branch_objective_types" => CommonJsonSchema.string_array(),
      "branch_objective_statuses" => CommonJsonSchema.string_array(),
      "branch_source_objective_statuses" => CommonJsonSchema.string_array(),
      "branch_feedback_sources" => CommonJsonSchema.string_array(),
      "branch_feedback_scopes" => CommonJsonSchema.string_array(),
      "branch_contact_results" => CommonJsonSchema.string_array(),
      "branch_contact_allocation_statuses" => CommonJsonSchema.string_array(),
      "branch_contact_allocation_effective_statuses" => CommonJsonSchema.string_array(),
      "branch_contact_allocation_reasons" => CommonJsonSchema.string_array(),
      "branch_contact_allocation_review_statuses" => CommonJsonSchema.string_array(),
      "branch_contact_allocation_approval_statuses" => CommonJsonSchema.string_array(),
      "branch_contact_allocation_policy_classifications" => CommonJsonSchema.string_array(),
      "branch_realized_statuses" => CommonJsonSchema.string_array(),
      "branch_transition_types" => CommonJsonSchema.string_array(),
      "branch_transition_categories" => CommonJsonSchema.string_array(),
      "branch_transition_reasons" => CommonJsonSchema.string_array(),
      "branch_requires_operator_review" => %{"type" => "boolean"},
      "branch_requires_operator_review_count" => %{"type" => "integer", "minimum" => 0},
      "branch_missed_downlink_activity_ids" =>
        CommonJsonSchema.stable_id_array(stable_id_pattern),
      "branch_source_activity_ids" => CommonJsonSchema.stable_id_array(stable_id_pattern),
      "branch_source_window_ids" => CommonJsonSchema.stable_id_array(stable_id_pattern),
      "branch_source_window_count" => %{"type" => "integer", "minimum" => 0},
      "branch_source_window_bounds" => %{
        "type" => "array",
        "items" => %{
          "type" => "object",
          "additionalProperties" => false,
          "required" => ["source_window_id"],
          "anyOf" => [
            %{"required" => ["earliest_starts_at_s"]},
            %{"required" => ["latest_ends_at_s"]}
          ],
          "properties" => %{
            "source_window_id" => %{"type" => "string", "pattern" => stable_id_pattern},
            "earliest_starts_at_s" => %{"type" => "number"},
            "latest_ends_at_s" => %{"type" => "number"}
          }
        }
      },
      "branch_source_window_bound_count" => %{"type" => "integer", "minimum" => 0},
      "branch_untimed_source_window_ids" => CommonJsonSchema.stable_id_array(stable_id_pattern),
      "branch_untimed_source_window_count" => %{"type" => "integer", "minimum" => 0},
      "branch_earliest_starts_at_s" => %{"type" => "number"},
      "branch_latest_ends_at_s" => %{"type" => "number"},
      "branch_max_latency_s" => %{"type" => "number"},
      "branch_planned_latency_s" => %{"type" => "number"},
      "branch_required_contacts" => %{"type" => "number"},
      "branch_planned_contacts" => %{"type" => "number"},
      "branch_required_downlink_mb" => %{"type" => "number"},
      "branch_planned_downlink_mb" => %{"type" => "number"},
      "branch_actual_downlink_completion_ratio" => %{
        "type" => "number",
        "minimum" => 0,
        "maximum" => 1
      }
    }
  end

  defp stable_id(stable_id_pattern) do
    %{"type" => "string", "pattern" => stable_id_pattern}
  end
end
