defmodule OrbitalDynamics.Schema.DownlinkLinkBudgetRegistryContracts do
  @moduledoc false

  def contracts do
    %{
      "downlink_link_budget.v1" => %{
        "schema_contract" => "downlink_link_budget.v1",
        "artifact_family" => "downlink_link_budget",
        "schema_version" => 1,
        "required_fields" => [
          "schema_contract",
          "id",
          "model",
          "status",
          "pass",
          "contact_binding",
          "access_window",
          "geometry",
          "spacecraft_terminal",
          "ground_terminal",
          "rf_link",
          "margin_policy",
          "derived",
          "assumptions",
          "provenance",
          "model_limits"
        ],
        "optional_fields" => [],
        "nested_contracts" => []
      }
    }
  end
end
