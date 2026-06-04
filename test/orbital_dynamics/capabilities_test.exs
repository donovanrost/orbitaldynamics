defmodule OrbitalDynamics.CapabilitiesTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.Communications.{ContactAllocation, ContactFilter}
  alias OrbitalDynamics.EventDetectors.AccessWindows

  alias OrbitalDynamics.Propagators.{
    J2,
    J2ExlaCpu,
    TwoBody,
    TwoBodyExlaCpu,
    TwoBodyNx,
    TwoBodyNxCompiled
  }

  alias OrbitalDynamics.{ResourceFilter, Schema}

  test "public capability catalog exposes declared model metadata by product area" do
    catalog = OrbitalDynamics.capability_catalog()

    assert catalog.analysis.propagator == TwoBody.capabilities()
    assert catalog.analysis.propagators.two_body == TwoBody.capabilities()
    assert catalog.analysis.propagators.j2 == J2.capabilities()
    assert catalog.analysis.propagators.two_body_nx == TwoBodyNx.capabilities()
    assert catalog.analysis.propagators.two_body_nx_compiled == TwoBodyNxCompiled.capabilities()
    assert catalog.analysis.propagators.two_body_exla_cpu == TwoBodyExlaCpu.capabilities()
    assert catalog.analysis.propagators.j2_exla_cpu == J2ExlaCpu.capabilities()
    assert catalog.analysis.access_windows == AccessWindows.capabilities()
    assert catalog.analysis.orbit_data == OrbitalDynamics.OrbitData.capabilities()
    assert catalog.planning.candidate_refresh == OrbitalDynamics.CandidateRefresh.capabilities()
    assert catalog.planning.search.grid == OrbitalDynamics.Search.Grid.capabilities()
    assert catalog.planning.search.monte_carlo == OrbitalDynamics.Search.MonteCarlo.capabilities()
    assert catalog.operations.contact_allocation == ContactAllocation.capabilities()
    assert catalog.operations.policy == OrbitalDynamics.Policy.capabilities()
    assert catalog.operations.cadence_import == OrbitalDynamics.CadenceImport.capabilities()

    assert catalog.constraints.artifact_metric ==
             OrbitalDynamics.Constraints.ArtifactMetric.capabilities()

    assert catalog.constraints.campaign_local ==
             OrbitalDynamics.Constraints.CampaignLocal.capabilities()

    assert catalog.validation.schema == Schema.capabilities()
    assert catalog.reporting.result_set == OrbitalDynamics.ResultSet.Report.capabilities()

    assert catalog.reporting.study_benchmark ==
             OrbitalDynamics.Study.Benchmark.Report.capabilities()

    assert "total_delta_v_km_s" in catalog.reporting.result_set.supported_objectives
    assert "campaign_plan.v1" in catalog.validation.schema.artifact_contracts
    assert "cadence_import_manifest.v1" in catalog.validation.schema.artifact_contracts
    assert "operator_review_package.v1" in catalog.validation.schema.artifact_contracts
    assert "schema_validation_report.v1" in catalog.validation.schema.validation_report_contracts
    assert catalog.validation.schema.artifact_contract_count == map_size(Schema.contracts())
    assert catalog.validation.schema.compatibility_policy_version == 1
    assert catalog.validation.schema.identity_policy_version == 1

    assert "executable_elixir_validator_is_source_of_truth" in catalog.validation.schema.known_limits

    assert :constraint_report in catalog.constraints.artifact_metric.outputs
    assert :constraint_report in catalog.constraints.campaign_local.outputs
    assert catalog.planning.search.monte_carlo.deterministic_seed == true

    assert [
             %{
               "schema_contract" => "environment_model_capability.v1",
               "model" => "fixed_inertial_solar_direction"
             },
             %{
               "schema_contract" => "environment_model_capability.v1",
               "model" => "constant_earth_rotation"
             }
           ] = catalog.environment.models

    assert [
             %{
               "schema_contract" => "environment_provider_capability.v1",
               "model" => "fixed_inertial_solar_direction"
             }
             | _
           ] = catalog.environment.providers
  end

  test "public capability catalog artifact is JSON-facing and schema-valid" do
    artifact = OrbitalDynamics.capability_catalog_artifact()

    assert %{
             "schema_contract" => "capability_catalog.v1",
             "schema_version" => 1,
             "model" => "public_capability_catalog",
             "validation" => %{
               "schema" => %{
                 "artifact_contracts" => artifact_contracts,
                 "artifact_contract_count" => artifact_contract_count
               }
             }
           } = artifact

    assert artifact_contract_count == map_size(Schema.contracts())
    assert artifact_contract_count == length(artifact_contracts)
    assert "capability_catalog.v1" in artifact_contracts

    assert :null =
             get_in(artifact, [
               "environment",
               "providers",
               Access.at(0),
               "coverage",
               "starts_at_s"
             ])

    assert :null =
             get_in(artifact, ["environment", "providers", Access.at(0), "coverage", "ends_at_s"])

    refute artifact |> :json.encode() |> IO.iodata_to_binary() =~ ~s("nil")

    assert {:ok, %{"schema_contract" => "capability_catalog.v1", "status" => "pass"}} =
             Schema.validate_artifact(artifact)

    assert {:ok, capability_catalog_schema} = Schema.json_schema("capability_catalog.v1")

    assert get_in(capability_catalog_schema, ["properties", "model", "const"]) ==
             "public_capability_catalog"

    stale_model_artifact = Map.put(artifact, "model", "stale_capability_catalog")

    assert {:error, stale_model_report} = Schema.validate_artifact(stale_model_artifact)

    assert Enum.any?(
             stale_model_report["errors"],
             &(&1["path"] == "$.model" and
                 &1["message"] == "must equal \"public_capability_catalog\"")
           )
  end

  test "public capability facades resolve to exported top-level functions" do
    missing_facades =
      OrbitalDynamics.capability_catalog()
      |> public_facade_entries()
      |> Enum.flat_map(fn {path, facades} ->
        facades
        |> Enum.reject(&exported_orbital_dynamics_facade?/1)
        |> Enum.map(&{path, &1})
      end)

    assert missing_facades == []
  end

  test "filter capability suppression reasons are schema-visible" do
    capability_reasons =
      (ContactFilter.capabilities().suppression_reasons ++
         ResourceFilter.capabilities().suppression_reasons)
      |> Enum.uniq()
      |> Enum.sort()

    for contract <- ["contact_filter_report.v1", "resource_filter_report.v1"] do
      assert {:ok, schema} = Schema.json_schema(contract)

      schema_reasons =
        schema
        |> get_in([
          "properties",
          "suppressed_candidates",
          "items",
          "properties",
          "suppressed_reason",
          "enum"
        ])
        |> Enum.sort()

      assert schema_reasons == capability_reasons
    end
  end

  defp public_facade_entries(value, path \\ [])

  defp public_facade_entries(%{} = value, path) do
    current =
      case Map.get(value, :public_facades) do
        facades when is_list(facades) -> [{Enum.reverse(path), facades}]
        _value -> []
      end

    nested =
      value
      |> Enum.flat_map(fn
        {key, nested_value} when is_atom(key) or is_binary(key) ->
          public_facade_entries(nested_value, [key | path])

        _entry ->
          []
      end)

    current ++ nested
  end

  defp public_facade_entries(_value, _path), do: []

  defp exported_orbital_dynamics_facade?(facade) when is_atom(facade) do
    Enum.any?(0..5, &function_exported?(OrbitalDynamics, facade, &1))
  end

  defp exported_orbital_dynamics_facade?(_facade), do: false
end
