defmodule OrbitalDynamics.Schema.TimelineSupportJsonSchema do
  @moduledoc false

  def protection_decision_from_context(deps) when is_list(deps) do
    protection_decision(
      stable_id_pattern: fetch_dep!(deps, :stable_id_pattern),
      timeline_identity_schema: fetch_dep!(deps, :timeline_identity_schema)
    )
  end

  def protection_decision(opts) do
    stable_id_pattern = Keyword.fetch!(opts, :stable_id_pattern)
    timeline_identity_schema = Keyword.fetch!(opts, :timeline_identity_schema)

    %{
      "type" => "object",
      "additionalProperties" => true,
      "properties" => %{
        "activity_id" => %{"type" => "string", "pattern" => stable_id_pattern},
        "timeline_id" => %{"type" => "string", "pattern" => stable_id_pattern},
        "status" => %{"type" => "string"},
        "approval_status" => %{"type" => "string"},
        "locked" => %{"type" => "boolean"},
        "approved" => %{"type" => "boolean"},
        "timeline_identity" => timeline_identity_schema,
        "invalid_activity_input" => %{"type" => "boolean"},
        "invalid_activity_input_reason" => %{"type" => "string"},
        "protection_decision" => %{"type" => "string"},
        "protection_category" => %{"type" => "string"},
        "reason" => %{"type" => "string"}
      }
    }
  end

  def lifecycle_transition_from_context do
    lifecycle_transition()
  end

  def lifecycle_transition do
    %{
      "type" => "object",
      "additionalProperties" => true,
      "properties" => %{
        "field" => %{"type" => "string"},
        "transition_type" => %{"type" => "string", "enum" => ["added", "removed", "changed"]},
        "from" => %{"type" => "string"},
        "to" => %{"type" => "string"},
        "from_category" => %{"type" => "string"},
        "to_category" => %{"type" => "string"},
        "transition_category" => %{"type" => "string"},
        "requires_operator_review" => %{"type" => "boolean"},
        "operator_action_reason" => %{"type" => "string"}
      }
    }
  end

  def timeline_link_from_context(deps) when is_list(deps) do
    timeline_link(
      stable_id_pattern: fetch_dep!(deps, :stable_id_pattern),
      timeline_identity_schema: fetch_dep!(deps, :timeline_identity_schema)
    )
  end

  def timeline_link(opts) do
    stable_id_pattern = Keyword.fetch!(opts, :stable_id_pattern)
    timeline_identity_schema = Keyword.fetch!(opts, :timeline_identity_schema)

    %{
      "type" => "object",
      "additionalProperties" => true,
      "properties" => %{
        "source_timeline_id" => %{"type" => "string", "pattern" => stable_id_pattern},
        "source_activity_id" => %{"type" => "string", "pattern" => stable_id_pattern},
        "source_invalid_activity_input" => %{"type" => "boolean"},
        "source_invalid_activity_input_reason" => %{"type" => "string"},
        "source_activity" => %{"type" => "object", "additionalProperties" => true},
        "source_timeline_identity" => timeline_identity_schema,
        "replacement_timeline_id" => %{"type" => "string", "pattern" => stable_id_pattern},
        "replacement_activity_id" => %{"type" => "string", "pattern" => stable_id_pattern},
        "replacement_invalid_activity_input" => %{"type" => "boolean"},
        "replacement_invalid_activity_input_reason" => %{"type" => "string"},
        "replacement_activity" => %{"type" => "object", "additionalProperties" => true},
        "replacement_timeline_identity" => timeline_identity_schema
      }
    }
  end

  def precondition_from_context(deps) when is_list(deps) do
    precondition(capability: fetch_dep!(deps, :capability))
  end

  def precondition(opts) do
    capability = Keyword.fetch!(opts, :capability)

    %{
      "type" => "object",
      "additionalProperties" => true,
      "required" => ["type", "status", "field", "reason"],
      "properties" => %{
        "type" => %{
          "type" => "string",
          "enum" => capability.activity_precondition_types
        },
        "status" => %{
          "type" => "string",
          "enum" => capability.activity_precondition_statuses
        },
        "field" => %{"type" => "string"},
        "reason" => %{"type" => "string"},
        "value" => %{"type" => ["string", "number", "boolean", "object"]}
      }
    }
  end

  defp fetch_dep!(deps, key) do
    case Keyword.fetch!(deps, key) do
      fun when is_function(fun, 0) -> fun.()
      value -> value
    end
  end
end
