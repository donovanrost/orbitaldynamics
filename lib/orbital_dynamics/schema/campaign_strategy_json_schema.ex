defmodule OrbitalDynamics.Schema.CampaignStrategyJsonSchema do
  @moduledoc false

  @strategy_policy_weight_fields [
    "approval_load_weight",
    "asset_balance_weight",
    "coverage_weight",
    "downlink_completion_weight",
    "fuel_preservation_weight",
    "latency_weight",
    "mission_value_weight",
    "priority_commitment_weight",
    "probability_weight",
    "revisit_weight",
    "risk_weight",
    "schedule_stability_weight"
  ]

  def property("strategy_policy", _opts) do
    %{
      "type" => "object",
      "additionalProperties" => true,
      "properties" => Map.new(@strategy_policy_weight_fields, &{&1, %{"type" => "number"}})
    }
  end

  def property("branches", opts) do
    %{
      "type" => "array",
      "items" => Keyword.fetch!(opts, :strategy_branch_schema)
    }
  end
end
