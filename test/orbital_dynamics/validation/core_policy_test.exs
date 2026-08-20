defmodule OrbitalDynamics.Validation.CorePolicyTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.Propagators.{J2, TwoBody, TwoBodyDrag, TwoBodyNxCompiled}
  alias OrbitalDynamics.ForceModels.AtmosphericDrag
  alias OrbitalDynamics.{ResultSet, Schema, Validation}
  alias OrbitalDynamics.ResultSet.Artifact

  test "fetches validation records by model id and implementation module" do
    assert {:ok, %{"validation_level" => "educational", "model" => "point_mass_two_body"}} =
             Validation.record("propagator.two_body")

    assert {:ok, %{"id" => "propagator.j2", "validation_level" => "educational"}} =
             Validation.record(J2)

    assert {:ok, %{"validation_level" => "educational"}} = Validation.record(TwoBodyNxCompiled)

    assert {:ok,
            %{
              "id" => "force_model.atmospheric_drag",
              "implementation" => "OrbitalDynamics.ForceModels.AtmosphericDrag",
              "known_limits" => known_limits
            }} = Validation.record(AtmosphericDrag)

    assert known_limits == AtmosphericDrag.model_limits()

    {:ok, force_model_record} = Validation.record(AtmosphericDrag)
    force_model_artifact = Map.put(force_model_record, "schema_contract", "validation_record.v1")

    assert {:ok, %{"schema_contract" => "validation_record.v1", "status" => "pass"}} =
             Schema.validate_artifact(force_model_artifact)

    stale_force_model_artifact =
      Map.put(force_model_artifact, "known_limits", ["stale force-model limit"])

    assert {:error, stale_force_model_report} =
             Schema.validate_artifact(stale_force_model_artifact)

    assert Enum.any?(
             stale_force_model_report["errors"],
             &(&1["path"] == "$.known_limits" and
                 &1["message"] == "must match registered validation record known limits")
           )

    acceptance_report =
      Validation.model_acceptance_report([AtmosphericDrag], intended_use: :analysis)

    assert acceptance_report["status"] == "review_required"
    assert acceptance_report["unknown_model_count"] == 0

    assert acceptance_report["model_ids_by_status"] == %{
             "review_required" => ["force_model.atmospheric_drag"]
           }

    assert {:ok, %{"schema_contract" => "model_acceptance_report.v1", "status" => "pass"}} =
             Schema.validate_artifact(acceptance_report)

    assert {:ok,
            %{
              "id" => "propagator.two_body_drag",
              "implementation" => "OrbitalDynamics.Propagators.TwoBodyDrag",
              "known_limits" => drag_propagator_limits
            }} = Validation.record(TwoBodyDrag)

    assert drag_propagator_limits == TwoBodyDrag.model_limits()

    drag_acceptance_report =
      Validation.model_acceptance_report([TwoBodyDrag], intended_use: :analysis)

    assert drag_acceptance_report["status"] == "review_required"
    assert drag_acceptance_report["unknown_model_count"] == 0

    assert drag_acceptance_report["model_ids_by_status"] == %{
             "review_required" => ["propagator.two_body_drag"]
           }

    assert {:ok, %{"schema_contract" => "model_acceptance_report.v1", "status" => "pass"}} =
             Schema.validate_artifact(drag_acceptance_report)
  end

  test "keeps access root refinement at analysis level with interpolated-state limits" do
    assert {:ok,
            %{
              "id" => "event.access_windows.bracketed_bisection",
              "validation_level" => "analysis",
              "tolerances" => %{"event_time_s" => event_time_tolerance},
              "evidence" => evidence,
              "known_limits" => known_limits
            } = record} = Validation.record("event.access_windows.bracketed_bisection")

    assert event_time_tolerance =~ "final cubic-Hermite interpolated-state root bracket"
    assert Enum.any?(evidence, &String.contains?(&1, "analytical spherical-geometry crossing"))
    assert Enum.any?(known_limits, &String.contains?(&1, "not dense propagator output"))
    assert Enum.any?(known_limits, &String.contains?(&1, "no external validation"))

    artifact = Map.put(record, "schema_contract", "validation_record.v1")

    assert {:ok, %{"schema_contract" => "validation_record.v1", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "keeps the default sampled access validation identity compatible" do
    assert {:ok,
            %{
              "id" => "event.access_windows",
              "model" => "sampled_ground_station_access",
              "tolerances" => %{
                "event_time_s" => "bounded by output step with linear interpolation"
              },
              "known_limits" => [
                "no terrain mask",
                "no refraction model beyond assumption metadata"
              ]
            }} = Validation.record("event.access_windows")
  end

  test "public facades expose validation records policies and fixture verification" do
    assert OrbitalDynamics.validation_registry() == Validation.registry()

    assert OrbitalDynamics.validation_record("propagator.two_body") ==
             Validation.record("propagator.two_body")

    assert OrbitalDynamics.validation_tolerance_policy() == Validation.tolerance_policy()

    assert OrbitalDynamics.validation_model_acceptance_report(["event.access_windows"]) ==
             Validation.model_acceptance_report(["event.access_windows"])

    assert OrbitalDynamics.validation_safety_case_summary([]) ==
             Validation.safety_case_summary([])

    assert OrbitalDynamics.validation_schema_migration_report() ==
             Validation.schema_migration_report()

    schema_migration_opts = [
      deprecated_contracts: %{"campaign_plan.v1" => "campaign_strategy.v3"},
      future_contracts: [
        %{
          schema_contract: "campaign_plan.v2",
          artifact_family: "campaign_plan",
          schema_version: 2,
          replacement_contract: "campaign_strategy.v3",
          required_field_count: 12,
          optional_field_count: 3,
          nested_contract_count: 4
        }
      ]
    ]

    schema_migration_report =
      OrbitalDynamics.validation_schema_migration_report(schema_migration_opts)

    assert schema_migration_report == Validation.schema_migration_report(schema_migration_opts)

    assert %{
             "status" => "review_required",
             "deprecated_contract_count" => 1,
             "future_contract_count" => 1,
             "status_counts" => %{"current" => 122, "deprecated" => 1, "future" => 1},
             "migration_action_counts" => %{
               "continue_current_contract" => 122,
               "plan_replacement" => 1,
               "prepare_future_contract" => 1
             }
           } = schema_migration_report

    schema_migration_capabilities = Validation.capabilities()

    assert schema_migration_capabilities.schema_migration_actions == [
             "continue_current_contract",
             "plan_replacement",
             "prepare_future_contract",
             "review_deprecated_contract"
           ]

    assert Map.keys(schema_migration_report["migration_action_counts"]) --
             schema_migration_capabilities.schema_migration_actions == []

    assert OrbitalDynamics.backend_acceptance_policy() == Validation.backend_acceptance_policy()

    assert OrbitalDynamics.backend_acceptance_evidence(TwoBody) ==
             Validation.backend_acceptance_evidence(TwoBody)

    assert OrbitalDynamics.dependency_policy() == Validation.dependency_policy()
    assert OrbitalDynamics.validation_reference_fixtures() == Validation.reference_fixtures()

    fixture_id = "fixture.two_body.circular_leo_600s"

    assert OrbitalDynamics.validation_reference_fixture(fixture_id) ==
             Validation.reference_fixture(fixture_id)

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert OrbitalDynamics.verify_validation_reference_fixture(fixture_id, fixture["expected"]) ==
             Validation.verify_reference_fixture(fixture_id, fixture["expected"])

    assert %{"schema_contract" => "validation_reference_fixture_report.v1"} =
             OrbitalDynamics.validation_reference_fixture_report(%{
               fixture_id => fixture["expected"]
             })
  end

  test "builds model acceptance reports for declared intended use" do
    report =
      Validation.model_acceptance_report(
        [
          "orbit_data.simple_json",
          "event.access_windows",
          "propagator.two_body",
          "missing.model"
        ],
        intended_use: :operational_import
      )

    assert %{
             "schema_contract" => "model_acceptance_report.v1",
             "model" => "registry_model_acceptance_classifier",
             "intended_use" => "operational_import",
             "status" => "blocked",
             "model_count" => 4,
             "accepted_count" => 1,
             "review_required_count" => 1,
             "blocked_count" => 2,
             "unknown_model_count" => 1,
             "status_counts" => %{
               "accepted" => 1,
               "blocked" => 2,
               "review_required" => 1
             },
             "validation_level_counts" => %{
               "artifact_contract" => 1,
               "analysis" => 1,
               "educational" => 1,
               "unknown" => 1
             },
             "model_ids_by_status" => %{
               "accepted" => ["orbit_data.simple_json"],
               "blocked" => ["propagator.two_body", "missing.model"],
               "review_required" => ["event.access_windows"]
             },
             "model_ids_by_validation_level" => %{
               "analysis" => ["event.access_windows"],
               "artifact_contract" => ["orbit_data.simple_json"],
               "educational" => ["propagator.two_body"],
               "unknown" => ["missing.model"]
             },
             "model_ids_by_intended_use" => %{
               "operational_import" => [
                 "orbit_data.simple_json",
                 "event.access_windows",
                 "propagator.two_body",
                 "missing.model"
               ]
             }
           } = report

    assert [
             %{"model_id" => "orbit_data.simple_json", "status" => "accepted"},
             %{"model_id" => "event.access_windows", "status" => "review_required"},
             %{"model_id" => "propagator.two_body", "status" => "blocked"},
             %{"model_id" => "missing.model", "status" => "blocked"}
           ] = report["rows"]

    assert length(report["records"]) == 3
    assert Enum.all?(report["records"], &(&1["schema_contract"] == "validation_record.v1"))

    assert {:ok, %{"schema_contract" => "model_acceptance_report.v1"}} =
             Schema.validate_artifact(report, schema_contract: "model_acceptance_report.v1")

    invalid_report = Map.put(report, "accepted_count", 99)

    assert {:error, validation_report} =
             Schema.validate_artifact(invalid_report,
               schema_contract: "model_acceptance_report.v1"
             )

    assert Enum.any?(validation_report["errors"], &(&1["path"] == "$.accepted_count"))

    stale_model_report = Map.put(report, "model", "stale_model_acceptance_classifier")

    assert {:error, validation_report} =
             Schema.validate_artifact(stale_model_report,
               schema_contract: "model_acceptance_report.v1"
             )

    assert Enum.any?(
             validation_report["errors"],
             &(&1["path"] == "$.model" and
                 &1["message"] == "must equal \"registry_model_acceptance_classifier\"")
           )

    stale_status_counts = put_in(report, ["status_counts", "blocked"], 1)

    assert {:error, validation_report} =
             Schema.validate_artifact(stale_status_counts,
               schema_contract: "model_acceptance_report.v1"
             )

    assert Enum.any?(validation_report["errors"], &(&1["path"] == "$.status_counts"))

    stale_routing_report = put_in(report, ["model_ids_by_status", "accepted"], ["missing.model"])

    assert {:error, validation_report} =
             Schema.validate_artifact(stale_routing_report,
               schema_contract: "model_acceptance_report.v1"
             )

    assert Enum.any?(validation_report["errors"], &(&1["path"] == "$.model_ids_by_status"))

    capabilities = Validation.capabilities()

    assert :model_acceptance_status_counts in capabilities.summary_semantics
    assert :model_acceptance_model_ids_by_status in capabilities.summary_semantics
    assert :model_acceptance_model_ids_by_validation_level in capabilities.summary_semantics
    assert :model_acceptance_model_ids_by_intended_use in capabilities.summary_semantics
  end

  test "dependency policy keeps Nx required while EXLA remains optional" do
    assert %{
             "required_dependencies" => [
               %{
                 "package" => "nx",
                 "backend_modules" => nx_modules
               }
             ],
             "optional_dependencies" => [
               %{
                 "package" => "exla",
                 "backend_modules" => exla_modules
               }
             ],
             "backend_acceptance_policy" => "backend_acceptance_policy.v1",
             "decisions" => decisions
           } = Validation.dependency_policy()

    assert "OrbitalDynamics.Propagators.TwoBodyNxCompiled" in nx_modules
    assert "OrbitalDynamics.Propagators.TwoBodyExlaCpu" in exla_modules
    assert "do_not_mark_nx_optional_while_nx_modules_compile_unconditionally" in decisions
  end

  test "selects validation records from result-set assumptions" do
    result_set =
      result_set(%{
        propagator: TwoBody,
        outputs: [:trajectories, :access_windows, :eclipses]
      })

    ids =
      result_set
      |> Validation.records_for_result_set()
      |> Enum.map(& &1["id"])

    assert ids == [
             "propagator.two_body",
             "event.access_windows",
             "event.eclipses"
           ]

    assert OrbitalDynamics.validation_records_for_result_set(result_set) ==
             Validation.records_for_result_set(result_set)
  end

  test "archives model validation records in result artifacts" do
    artifact =
      %{propagator: J2, outputs: [:trajectories, :target_visibility]}
      |> result_set()
      |> Artifact.build()

    validation_ids =
      artifact.assumptions["model_validation"]
      |> Enum.map(& &1["id"])

    assert validation_ids == ["propagator.j2", "event.target_visibility"]
  end

  test "selects ground-track crossing validation from result-set assumptions" do
    result_set =
      result_set(%{
        propagator: TwoBody,
        outputs: [:trajectories, :ground_track_crossings]
      })

    ids =
      result_set
      |> Validation.records_for_result_set()
      |> Enum.map(& &1["id"])

    assert ids == ["propagator.two_body", "event.ground_track_crossings"]
  end

  test "documents tolerance policy and validation level vocabulary" do
    policy = Validation.tolerance_policy()

    assert policy["schema_contract"] == "validation_tolerance_policy.v1"
    assert policy["comparison_model"]["numeric_vectors"] =~ "maximum component-wise"

    assert policy["event_timing"]["event_time_tolerance_s"] =~
             "maximum adjacent trajectory sample spacing"

    assert policy["event_timing"]["event_time_tolerance_s"] =~
             "final cubic-Hermite interpolated-state root bracket"

    assert policy["event_timing"]["limit"] =~ "no external-validation or flight-fidelity claim"

    declared_levels =
      policy["validation_levels"]
      |> Map.keys()
      |> MapSet.new()

    registry_levels =
      Validation.registry()
      |> Map.values()
      |> Enum.map(& &1["validation_level"])
      |> MapSet.new()

    fixture_levels =
      Validation.reference_fixtures()
      |> Map.values()
      |> Enum.map(& &1["validation_level"])
      |> MapSet.new()

    assert MapSet.subset?(registry_levels, declared_levels)
    assert MapSet.subset?(fixture_levels, declared_levels)
  end

  test "documents orbit-data adapter validation boundaries" do
    assert {:ok, simple_json} = Validation.record("orbit_data.simple_json")
    assert simple_json["validation_level"] == "artifact_contract"
    assert simple_json["model"] == "simple_json_cartesian_state_estimate_batch"
    assert "no hidden unit conversion" in simple_json["known_limits"]

    assert {:ok, opm} = Validation.record("orbit_data.ccsds_opm_kvn")
    assert opm["implementation"] == "OrbitalDynamics.OrbitData.import_ccsds_opm"
    assert "Earth center only" in opm["known_limits"]
    assert "duplicate single-value KVN fields are rejected" in opm["known_limits"]

    assert "OPM covariance matrices are preserved as metadata-only evidence and are not propagated" in opm[
             "known_limits"
           ]

    assert "unit tests import and export complete OPM covariance matrix components as metadata-only evidence" in opm[
             "evidence"
           ]

    assert "OPM maneuver metadata is preserved as metadata-only evidence and is not propagated" in opm[
             "known_limits"
           ]

    assert "unit tests export and re-import multiple OPM MAN_* maneuver metadata blocks from maneuver_execution_delta evidence" in opm[
             "evidence"
           ]

    assert {:ok, oem} = Validation.record("orbit_data.ccsds_oem_kvn")
    assert oem["tolerances"]["position_km"] == "selected sample is preserved, no interpolation"
    assert "no interpolation despite OEM interpolation metadata" in oem["known_limits"]
    assert "duplicate single-value KVN fields are rejected" in oem["known_limits"]

    assert "OEM covariance blocks are preserved as metadata-only evidence and are not propagated" in oem[
             "known_limits"
           ]

    assert "unit tests import and export one OEM covariance block as metadata-only evidence" in oem[
             "evidence"
           ]

    assert {:ok, tle} = Validation.record("orbit_data.tle_metadata")
    assert tle["implementation"] == "OrbitalDynamics.OrbitData.inspect_tle"
    assert tle["tolerances"]["checksum"] == "exact modulo-10 TLE checksum match"
    assert "single-object metadata preflight only" in tle["known_limits"]

    assert "unit tests reject multi-object TLE drops as ambiguous metadata preflight input" in tle[
             "evidence"
           ]

    registry_levels =
      Validation.registry()
      |> Map.take([
        "orbit_data.simple_json",
        "orbit_data.ccsds_opm_kvn",
        "orbit_data.ccsds_oem_kvn",
        "orbit_data.tle_metadata"
      ])
      |> Map.values()
      |> Enum.map(& &1["validation_level"])

    assert Enum.all?(registry_levels, &(&1 == "artifact_contract"))
  end

  test "documents backend acceptance tiers" do
    policy = Validation.backend_acceptance_policy()

    assert policy["schema_contract"] == "backend_acceptance_policy.v1"
    assert policy["reference_backend"]["tier"] == "reference_default"

    assert policy["acceptance_tiers"]["reference_default"] == %{
             "description" => "default planning backend for current artifacts",
             "requires_benchmark_artifact" => false,
             "requires_reference_match" => true
           }

    assert policy["implementation_tiers"]["OrbitalDynamics.Propagators.TwoBody"] ==
             "reference_default"

    assert policy["implementation_tiers"]["OrbitalDynamics.Propagators.TwoBodyNxCompiled"] ==
             "experimental_accelerator"

    assert policy["acceptance_tiers"]["experimental_accelerator"][
             "requires_benchmark_artifact"
           ] == true

    assert {:ok,
            %{
              "backend_acceptance_policy" => "backend_acceptance_policy.v1",
              "implementation" => "OrbitalDynamics.Propagators.TwoBody",
              "tier" => "reference_default",
              "reference_backend" => true,
              "requires_reference_match" => true,
              "requires_benchmark_artifact" => false
            }} = Validation.backend_acceptance_evidence(TwoBody)

    assert {:ok,
            %{
              "implementation" => "OrbitalDynamics.Propagators.TwoBodyNxCompiled",
              "tier" => "experimental_accelerator",
              "reference_backend" => false,
              "requires_reference_match" => true,
              "requires_benchmark_artifact" => true
            }} = Validation.backend_acceptance_evidence(TwoBodyNxCompiled)

    assert {:error, {:unknown_backend_implementation, "UnknownBackend"}} =
             Validation.backend_acceptance_evidence("UnknownBackend")

    assert policy["comparison_requirements"]["numeric_tolerance_policy"] ==
             "validation_tolerance_policy.v1"

    assert Enum.any?(
             policy["benchmark_reference_cases"],
             &(&1["artifact_family"] == "orbital_dynamics.study.benchmark")
           )

    assert "speedup claims are workload-specific" in policy["known_limits"]
  end

  defp result_set(assumptions) do
    ResultSet.new!(%{
      study_id: :validation,
      trajectory_results: [],
      event_results: [],
      errors: [],
      assumptions: assumptions,
      metadata: %{}
    })
  end
end
