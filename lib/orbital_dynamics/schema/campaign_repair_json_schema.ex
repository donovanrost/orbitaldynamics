defmodule OrbitalDynamics.Schema.CampaignRepairJsonSchema do
  @moduledoc false

  @property_fields [
    "activities",
    "source_candidate_activities",
    "deltas",
    "approval_requirements",
    "approval_policy",
    "policy_decision",
    "timeline_transition_application_report",
    "warnings"
  ]

  def property_field?(field) when field in @property_fields, do: true
  def property_field?(_field), do: false

  def property_fun_from_context(deps) when is_list(deps) do
    fn field ->
      property(field, property_opts(field, deps))
    end
  end

  def property_opts("activities", deps) do
    [planned_activity_schema: fetch_dep!(deps, :planned_activity_schema)]
  end

  def property_opts("source_candidate_activities", deps) do
    [candidate_activity_schema: fetch_dep!(deps, :candidate_activity_schema)]
  end

  def property_opts("deltas", deps) do
    [plan_delta_schema: fetch_dep!(deps, :plan_delta_schema)]
  end

  def property_opts("approval_requirements", deps) do
    [approval_requirement_schema: fetch_dep!(deps, :approval_requirement_schema)]
  end

  def property_opts("approval_policy", deps) do
    [policy_action_rule_schema: fetch_dep!(deps, :policy_action_rule_schema)]
  end

  def property_opts("policy_decision", deps) do
    [policy_decision_schema: fetch_dep!(deps, :policy_decision_schema)]
  end

  def property_opts("timeline_transition_application_report", deps) do
    [
      required_fields: fetch_dep!(deps, :timeline_transition_required_fields),
      optional_fields: fetch_dep!(deps, :timeline_transition_optional_fields),
      property_fun: fetch_dep!(deps, :timeline_transition_property_fun)
    ]
  end

  def property_opts(_field, _deps), do: []

  def property("activities", opts) do
    array_of(Keyword.fetch!(opts, :planned_activity_schema))
  end

  def property("source_candidate_activities", opts) do
    array_of(Keyword.fetch!(opts, :candidate_activity_schema))
  end

  def property("deltas", opts) do
    array_of(Keyword.fetch!(opts, :plan_delta_schema))
  end

  def property("approval_requirements", opts) do
    array_of(Keyword.fetch!(opts, :approval_requirement_schema))
  end

  def property("approval_policy", opts) do
    OrbitalDynamics.Schema.PolicyDecisionJsonSchema.approval_policy(
      policy_action_rule_schema: Keyword.fetch!(opts, :policy_action_rule_schema)
    )
  end

  def property("policy_decision", opts) do
    Keyword.fetch!(opts, :policy_decision_schema)
  end

  def property("timeline_transition_application_report", opts) do
    required_fields = Keyword.fetch!(opts, :required_fields)
    optional_fields = Keyword.fetch!(opts, :optional_fields)
    property_fun = Keyword.fetch!(opts, :property_fun)

    %{
      "type" => "object",
      "additionalProperties" => true,
      "required" => required_fields,
      "properties" =>
        (required_fields ++ optional_fields)
        |> Enum.uniq()
        |> Enum.sort()
        |> Map.new(&{&1, property_fun.(&1)})
    }
  end

  def property("warnings", _opts) do
    string_array_schema()
  end

  def plan_delta_from_deps(deps) do
    deps
    |> plan_delta_opts()
    |> plan_delta()
  end

  def plan_delta_from_context(
        stable_id_pattern,
        planned_activity_schema,
        realized_activity_schema,
        timeline_link_schema,
        activity_context_schema
      ) do
    [
      stable_id_pattern: stable_id_pattern,
      planned_activity_schema: planned_activity_schema,
      realized_activity_schema: realized_activity_schema,
      timeline_link_schema: timeline_link_schema,
      activity_context_schema: activity_context_schema
    ]
    |> plan_delta_opts()
    |> plan_delta()
  end

  def plan_delta(opts) do
    stable_id_pattern = Keyword.fetch!(opts, :stable_id_pattern)
    planned_activity_schema = Keyword.fetch!(opts, :planned_activity_schema)
    realized_activity_schema = Keyword.fetch!(opts, :realized_activity_schema)
    timeline_link_schema = Keyword.fetch!(opts, :timeline_link_schema)
    activity_context_schema = Keyword.fetch!(opts, :activity_context_schema)

    %{
      "type" => "object",
      "additionalProperties" => true,
      "required" => [
        "activity_id",
        "activity_type",
        "status",
        "repair_action"
      ],
      "properties" => %{
        "schema_contract" => %{"type" => "string", "const" => "plan_delta.v1"},
        "activity_id" => %{"type" => "string", "pattern" => stable_id_pattern},
        "activity_type" => %{"type" => "string"},
        "status" => %{"type" => "string"},
        "repair_action" => %{"type" => "string"},
        "reason" => %{"type" => "string"},
        "requires_approval" => %{"type" => "boolean"},
        "replacement_activity_id" => %{
          "type" => "string",
          "pattern" => stable_id_pattern
        },
        "source_timeline_id" => %{"type" => "string", "pattern" => stable_id_pattern},
        "replacement_timeline_id" => %{"type" => "string", "pattern" => stable_id_pattern},
        "planned" => planned_activity_schema,
        "realized" => realized_activity_schema,
        "timeline_link" => timeline_link_schema,
        "source_activity_context" => activity_context_schema,
        "replacement_activity_context" => activity_context_schema
      }
    }
  end

  defp array_of(item_schema) do
    %{
      "type" => "array",
      "items" => item_schema
    }
  end

  defp string_array_schema do
    %{"type" => "array", "items" => %{"type" => "string"}}
  end

  defp fetch_dep!(deps, key) do
    deps
    |> Keyword.fetch!(key)
    |> call_dep()
  end

  defp plan_delta_opts(deps) do
    [
      stable_id_pattern: fetch_dep!(deps, :stable_id_pattern),
      planned_activity_schema: fetch_dep!(deps, :planned_activity_schema),
      realized_activity_schema: fetch_dep!(deps, :realized_activity_schema),
      timeline_link_schema: fetch_dep!(deps, :timeline_link_schema),
      activity_context_schema: fetch_dep!(deps, :activity_context_schema)
    ]
  end

  defp call_dep(dep) when is_function(dep, 0), do: dep.()
  defp call_dep(dep), do: dep
end
