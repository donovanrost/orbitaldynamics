defmodule Mix.Tasks.OrbitalDynamics.CapabilitiesTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureIO

  alias OrbitalDynamics.Schema

  test "prints a text capability catalog summary" do
    on_exit(fn -> Mix.Task.reenable("orbital_dynamics.capabilities") end)

    output =
      capture_io(fn ->
        Mix.Task.run("orbital_dynamics.capabilities", [])
      end)

    catalog = OrbitalDynamics.capability_catalog()

    assert output =~ "OrbitalDynamics capability catalog"
    assert output =~ "artifact contracts: #{catalog.validation.schema.artifact_contract_count}"

    assert output =~
             "cadence import sources: #{length(catalog.operations.cadence_import.supported_sources)}"

    assert output =~
             "operator review types: #{length(catalog.operations.operator_review.review_types)}"

    assert output =~ "propagators:"
  end

  test "prints a JSON capability catalog" do
    on_exit(fn -> Mix.Task.reenable("orbital_dynamics.capabilities") end)

    output =
      capture_io(fn ->
        Mix.Task.run("orbital_dynamics.capabilities", ["--format", "json"])
      end)

    assert %{
             "schema_contract" => "capability_catalog.v1",
             "schema_version" => 1,
             "model" => "public_capability_catalog",
             "analysis" => %{"propagators" => propagators},
             "planning" => %{
               "mission_plan_activity" => %{
                 "contact_direction_aliases" => activity_direction_aliases
               }
             },
             "operations" => %{
               "cadence_import" => %{"supported_sources" => supported_sources},
               "operator_review" => %{"review_types" => review_types},
               "policy" => %{"direction_aliases" => direction_aliases}
             },
             "validation" => %{
               "schema" => %{
                 "artifact_contracts" => artifact_contracts,
                 "artifact_contract_count" => artifact_contract_count,
                 "known_limits" => known_limits
               }
             }
           } = artifact = output |> String.trim() |> :json.decode()

    assert Map.has_key?(propagators, "two_body")
    assert "campaign_plan.v1" in artifact_contracts
    assert "campaign_plan.v1" in supported_sources
    assert "operator_review_package.v1" in supported_sources
    assert "schema_validation_report.v1" in artifact_contracts
    assert "execution_review" in review_types
    assert activity_direction_aliases["track_ing"] == "tracking"
    assert activity_direction_aliases["healthcheck"] == "health_check"
    assert direction_aliases["track_ing"] == "tracking"
    assert direction_aliases["healthcheck"] == "health_check"
    assert artifact_contract_count == length(artifact_contracts)
    assert "executable_elixir_validator_is_source_of_truth" in known_limits

    assert :null =
             get_in(artifact, [
               "environment",
               "providers",
               Access.at(0),
               "coverage",
               "starts_at_s"
             ])

    refute output =~ ~s("nil")

    assert {:ok, %{"schema_contract" => "capability_catalog.v1", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "writes the JSON capability catalog to a file" do
    output_path =
      Path.join(
        System.tmp_dir!(),
        "orbital_dynamics_capabilities_#{System.unique_integer([:positive])}.json"
      )

    on_exit(fn ->
      File.rm(output_path)
      Mix.Task.reenable("orbital_dynamics.capabilities")
    end)

    capture_io(fn ->
      Mix.Task.run("orbital_dynamics.capabilities", ["--output", output_path])
    end)

    assert %{
             "schema_contract" => "capability_catalog.v1",
             "validation" => %{
               "schema" => %{"artifact_contract_count" => artifact_contract_count}
             }
           } = artifact = output_path |> File.read!() |> :json.decode()

    assert artifact_contract_count == map_size(OrbitalDynamics.artifact_contracts())

    assert :null =
             get_in(artifact, [
               "environment",
               "providers",
               Access.at(0),
               "coverage",
               "starts_at_s"
             ])

    refute File.read!(output_path) =~ ~s("nil")

    assert {:ok, %{"schema_contract" => "capability_catalog.v1", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "rejects unsupported formats" do
    on_exit(fn -> Mix.Task.reenable("orbital_dynamics.capabilities") end)

    assert_raise Mix.Error, ~r/--format must be text or json/, fn ->
      Mix.Task.run("orbital_dynamics.capabilities", ["--format", "xml"])
    end
  end
end
