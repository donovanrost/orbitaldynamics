defmodule OrbitalDynamics.Schema.ApprovalRequirementJsonSchema do
  @moduledoc false

  @requirement_types [
    "contact_schedule_change",
    "observation_reassignment",
    "maneuver_timing_change",
    "downstream_window_review",
    "strategic_addition",
    "cancellation",
    "command_review",
    "health_check_review",
    "operator_review"
  ]

  @policy_classifications [
    "auto_approvable",
    "operator_review_required",
    "blocked_by_policy"
  ]

  @property_fields [
    "schema_contract",
    "activity_id",
    "activity_type",
    "action",
    "reason",
    "requirement_type",
    "activity_context",
    "approval_rule_matches",
    "policy_bundle_id",
    "policy_classification",
    "policy_decision",
    "required_authority",
    "rule_id"
  ]

  def property_field?(field) when field in @property_fields, do: true
  def property_field?(_field), do: false

  def property("schema_contract", _opts) do
    %{
      "type" => "string",
      "const" => "approval_requirement.v1",
      "description" => "Stable executable contract identifier"
    }
  end

  def property(field, opts) when field in @property_fields do
    schema(opts)
    |> get_in(["properties", field])
  end

  def property_from_deps(field, deps) do
    property(field, opts(deps))
  end

  def property_from_context(field, deps) when is_list(deps) do
    property_from_deps(field, deps)
  end

  def property_fun_from_context(deps) when is_list(deps) do
    fn field ->
      property_from_context(field, deps)
    end
  end

  def schema_from_deps(deps) do
    deps
    |> opts()
    |> schema()
  end

  def schema_from_context(deps) when is_list(deps) do
    schema_from_deps(deps)
  end

  def schema(opts) do
    stable_id_pattern = Keyword.fetch!(opts, :stable_id_pattern)

    %{
      "type" => "object",
      "additionalProperties" => true,
      "required" => ["activity_id", "activity_type", "action", "reason"],
      "properties" => %{
        "schema_contract" => %{"type" => "string", "const" => "approval_requirement.v1"},
        "activity_id" => %{"type" => "string", "pattern" => stable_id_pattern},
        "activity_type" => %{"type" => "string"},
        "action" => %{"type" => "string"},
        "reason" => %{"type" => "string"},
        "policy_bundle_id" => %{"type" => "string", "pattern" => stable_id_pattern},
        "rule_id" => %{"type" => "string", "pattern" => stable_id_pattern},
        "required_authority" => %{"type" => "string"},
        "requirement_type" => %{"type" => "string", "enum" => @requirement_types},
        "policy_classification" => %{
          "type" => "string",
          "enum" => @policy_classifications
        },
        "approval_rule_matches" => %{
          "type" => "array",
          "items" => Keyword.fetch!(opts, :rule_match_schema)
        },
        "activity_context" => Keyword.fetch!(opts, :activity_context_schema),
        "policy_decision" => %{
          "type" => "object",
          "additionalProperties" => true,
          "properties" => %{
            "classification" => %{
              "type" => "string",
              "enum" => @policy_classifications
            },
            "policy_bundle_id" => %{"type" => "string", "pattern" => stable_id_pattern},
            "escalations" => %{
              "type" => "array",
              "items" => Keyword.fetch!(opts, :policy_escalation_schema)
            }
          }
        }
      }
    }
  end

  defp opts(deps) do
    [
      stable_id_pattern: Keyword.fetch!(deps, :stable_id_pattern),
      rule_match_schema: deps |> Keyword.fetch!(:rule_match_schema) |> call_dep(),
      activity_context_schema: deps |> Keyword.fetch!(:activity_context_schema) |> call_dep(),
      policy_escalation_schema: deps |> Keyword.fetch!(:policy_escalation_schema) |> call_dep()
    ]
  end

  defp call_dep(dep) when is_function(dep, 0), do: dep.()
  defp call_dep(dep), do: dep
end
