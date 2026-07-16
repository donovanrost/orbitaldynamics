defmodule OrbitalDynamics.Schema.PolicyActionRuleJsonSchema do
  @moduledoc false

  alias OrbitalDynamics.Policy
  alias OrbitalDynamics.Schema.CommonJsonSchema
  alias OrbitalDynamics.Schema.PolicyContextJsonSchema

  @policy_classifications ["auto_approvable", "operator_review_required", "blocked_by_policy"]

  def action_rule(opts) do
    action_rule_from_context(
      Keyword.fetch!(opts, :stable_id_pattern),
      Keyword.fetch!(opts, :policy_context_fields),
      Keyword.fetch!(opts, :number_fields),
      Keyword.fetch!(opts, :integer_fields)
    )
  end

  def action_rule_from_context(
        stable_id_pattern,
        policy_context_fields,
        number_fields,
        integer_fields
      ) do
    schema(%{
      policy_context_properties:
        policy_context_fields
        |> PolicyContextJsonSchema.properties(),
      number_fields: number_fields,
      integer_fields: integer_fields,
      stable_id_pattern: stable_id_pattern,
      cadence_import_statuses: Policy.capabilities().cadence_import_statuses
    })
  end

  def schema(opts) do
    %{
      "type" => "object",
      "additionalProperties" => true,
      "properties" =>
        opts.policy_context_properties
        |> Map.merge(CommonJsonSchema.number_properties(opts.number_fields))
        |> Map.merge(CommonJsonSchema.integer_properties(opts.integer_fields))
        |> Map.merge(properties(opts))
    }
  end

  defp properties(opts) do
    %{
      "id" => %{"type" => "string", "pattern" => opts.stable_id_pattern},
      "classification" => %{
        "type" => "string",
        "enum" => @policy_classifications
      },
      "reason" => %{"type" => "string"},
      "policy_classification" => %{
        "type" => "string",
        "enum" => @policy_classifications
      },
      "policy_classifications" => %{
        "type" => "array",
        "items" => %{
          "type" => "string",
          "enum" => @policy_classifications
        }
      },
      "priority_fields_without_numeric_evidence_count_min" => %{
        "type" => "integer",
        "minimum" => 0
      },
      "station_calendar_ambiguous_entry_count_min" => %{
        "type" => "integer",
        "minimum" => 0
      },
      "station_calendar_ambiguous_entry_count_max" => %{
        "type" => "integer",
        "minimum" => 0
      },
      "contention_window_s_min" => %{"type" => "number", "minimum" => 0},
      "total_contact_duration_s_min" => %{"type" => "number", "minimum" => 0},
      "overlap_duration_s_min" => %{"type" => "number", "minimum" => 0},
      "max_concurrent_contacts_min" => %{"type" => "integer", "minimum" => 0},
      "overlap_contact_pair_count_min" => %{"type" => "integer", "minimum" => 0},
      "cadence_import_status" => %{
        "type" => "string",
        "enum" => opts.cadence_import_statuses
      },
      "cadence_import_statuses" => %{
        "type" => "array",
        "items" => %{
          "type" => "string",
          "enum" => opts.cadence_import_statuses
        }
      },
      "escalation_level" => %{"type" => "string"},
      "escalation_queue" => %{"type" => "string"},
      "escalation_role" => %{"type" => "string"},
      "required_authority" => %{"type" => "string"},
      "sla_s" => %{"type" => "number"}
    }
  end
end
