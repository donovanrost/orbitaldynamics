defmodule OrbitalDynamics.Schema.JsonDocumentTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.Schema.JsonDocument

  test "exports direct definitions without expanding discarded transitive definitions" do
    contract = fn nested ->
      %{
        "artifact_family" => "example",
        "schema_version" => 1,
        "required_fields" => ["id"],
        "nested_contracts" => nested
      }
    end

    contracts = %{"child" => contract.(["leaf"]), "leaf" => contract.([])}

    special_contract_names =
      ~w(accepted_planning_state constraint_report environment_model_capability
         environment_provider_capability maneuver_execution_delta planned_activity
         realized_activity spacecraft_state_estimate station_calendar_provider
         subsystem_model_capability validation_record)a
      |> Map.new(&{&1, "unused:#{&1}"})

    opts = [
      json_schema_draft: "https://json-schema.org/draft/2020-12/schema",
      compatibility_policy: %{"policy_version" => 1},
      identity_policy: %{"policy_version" => 1},
      contract_names: special_contract_names,
      contract_fun: fn name ->
        send(self(), {:resolved_contract, name})
        Map.fetch(contracts, name)
      end,
      property_fun: fn "id", _name, _contract -> %{"type" => "string"} end
    ]

    schema = JsonDocument.build("root", contract.(["child"]), opts)

    assert Map.keys(schema["$defs"]) == ["child"]
    child = schema["$defs"]["child"]
    assert child["properties"]["id"] == %{"type" => "string"}
    assert child["x-orbital-dynamics"]["nested_contracts"] == ["leaf"]
    refute Map.has_key?(child, "$defs")
    refute Map.has_key?(child["x-orbital-dynamics"], "identity_policy")
    assert_received {:resolved_contract, "child"}
    refute_received {:resolved_contract, "leaf"}
  end
end
