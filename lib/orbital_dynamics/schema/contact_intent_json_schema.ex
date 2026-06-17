defmodule OrbitalDynamics.Schema.ContactIntentJsonSchema do
  @moduledoc false

  def property("direction", _opts) do
    %{
      "type" => "string",
      "enum" => ["downlink", "uplink", "command", "tracking", "health_check"]
    }
  end

  def property("approval_requirements", opts) do
    %{
      "type" => "array",
      "items" => Keyword.fetch!(opts, :approval_requirement_schema)
    }
  end

  def property("approval_rule_matches", opts) do
    %{
      "type" => "array",
      "items" => Keyword.fetch!(opts, :policy_decision_rule_match_schema)
    }
  end

  def property("model_limits", opts) do
    %{
      "type" => "array",
      "items" => %{"type" => "string", "enum" => Keyword.fetch!(opts, :model_limits)}
    }
  end

  def property("timeline_integrity_issue_count", _opts) do
    %{"type" => "integer", "minimum" => 0}
  end

  def property("timeline_integrity_issue_types", opts) do
    %{
      "type" => "array",
      "items" => %{
        "type" => "string",
        "enum" => Keyword.fetch!(opts, :timeline_integrity_issue_types)
      }
    }
  end

  def property("timeline_integrity_issues", _opts) do
    %{
      "type" => "array",
      "items" => %{
        "type" => "object",
        "additionalProperties" => true,
        "required" => ["issue_type"],
        "properties" => %{"issue_type" => %{"type" => "string"}}
      }
    }
  end
end
