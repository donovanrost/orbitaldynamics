defmodule OrbitalDynamics.ResultSet.ArtifactTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.ResultSet.Artifact
  alias OrbitalDynamics.MissionPlan
  alias OrbitalDynamics.MissionPlan.Activity

  alias OrbitalDynamics.{
    CentralBody,
    Epoch,
    Frame,
    GroundStation,
    Schema,
    Spacecraft,
    StateVector,
    Study
  }

  alias OrbitalDynamics.Benchmark.ScenarioFixture
  alias OrbitalDynamics.Search.MonteCarlo

  test "builds compact JSON-safe result set artifact" do
    result_set = result_set()
    generated_at = DateTime.from_unix!(1_700_000_000)

    artifact = Artifact.build(result_set, generated_at: generated_at)

    assert artifact.schema_version == 1
    assert artifact.generated_at == "2023-11-14T22:13:20Z"
    assert artifact.study_id == "artifact_study"
    assert artifact.assumptions["outputs"] == ["trajectories", "access_windows", "eclipses"]
    assert artifact.assumptions["external_provider_policy"]["network_access"] == "none"
    assert artifact.assumptions["external_provider_policy"]["hidden_network_calls"] == false
    assert artifact.assumptions["backend_selection_policy"]["policy"] == "reference_default"

    assert artifact.assumptions["backend_selection_policy"]["backend_acceptance_policy"] ==
             "backend_acceptance_policy.v1"

    assert artifact.assumptions["backend_selection_policy"]["requires_reference_match"] == true

    assert artifact.assumptions["backend_selection_policy"]["requires_benchmark_artifact"] ==
             false

    assert artifact.assumptions["backend_selection_policy"]["backend_acceptance_evidence"][
             "tier"
           ] == "reference_default"

    assert artifact.assumptions["backend_selection_policy"]["performance_claim"] =~
             "benchmark artifacts"

    assert [
             %{"id" => "environment.solar.fixed_inertial_direction"},
             %{"id" => "environment.earth_rotation.constant_rate"}
           ] = artifact.assumptions["environment_models"]

    assert artifact.run["status"] == "completed"
    assert artifact.run["backend"] == "Elixir.OrbitalDynamics.Propagators.TwoBody"
    assert artifact.run["metadata"]["execution_mode"] == "local_tasks"
    assert artifact.run["metadata"]["scenario_count"] == 1
    assert artifact.execution_report.schema_contract == "execution_report.v1"
    assert artifact.execution_report.status == "completed"
    assert artifact.execution_report.study_id == "artifact_study"
    assert artifact.execution_report.execution_mode == "local_tasks"
    assert artifact.execution_report.scenario_count == 1
    assert artifact.execution_report.completed_scenario_count == 1
    assert artifact.execution_report.failed_scenario_count == 0
    assert artifact.execution_report.event_result_count == 2

    assert artifact.execution_report.model_limits == [
             "artifact_level_execution_summary",
             "not_resumable",
             "no_persistent_queue",
             "failed_scenarios_are_reported_not_retried"
           ]

    assert artifact.execution_report.model_limits == Artifact.execution_report_model_limits()
    assert artifact.execution_report.execution_plan["scenario_count"] == 1
    assert artifact.execution_report.execution_plan["task_batch_count"] == 1
    assert artifact.execution_report.execution_plan["resumability"] == "not_resumable"
    assert artifact.execution_report.failed_scenarios == []
    assert artifact.execution_report.assumptions.resumability == "not_resumable"
    refute Map.has_key?(artifact.execution_report.assumptions, :retry_scope)

    assert artifact.execution_report.assumptions.backend_selection_policy[
             "backend_acceptance_policy"
           ] == "backend_acceptance_policy.v1"

    assert artifact.execution_report.assumptions.backend_selection_policy[
             "backend_acceptance_evidence"
           ]["tier"] == "reference_default"

    assert artifact.execution_report.assumptions.external_provider_policy["network_access"] ==
             "none"

    assert {:ok, %{"schema_contract" => "execution_report.v1"}} =
             artifact.execution_report |> json_round_trip() |> Schema.validate_artifact()

    assert artifact.payload_metrics.schema_contract == "result_payload_metrics.v1"
    assert artifact.payload_metrics.encoding == "erlang_json_compact_utf8"
    assert artifact.payload_metrics.artifact_body_bytes > 0
    assert artifact.payload_metrics.top_level_key_count > 0
    assert artifact.payload_metrics.sections["trajectories"].row_count == 1
    assert artifact.payload_metrics.sections["access_windows"].bytes > 0

    assert [
             %{
               scenario_id: "artifact_1",
               sample_count: 3,
               propagation_backend: "scalar_elixir",
               force_model: "point_mass_two_body",
               numerical_method: "rk4_fixed_step",
               validation_level: "educational",
               model_limits: trajectory_model_limits,
               assumptions: %{
                 "force_model" => "point_mass_two_body",
                 "maneuver_count" => 0,
                 "maneuvers" => []
               },
               final_radius_km: final_radius_km,
               final_speed_km_s: final_speed_km_s,
               min_radius_km: min_radius_km,
               max_radius_km: max_radius_km,
               min_altitude_km: min_altitude_km,
               max_altitude_km: max_altitude_km,
               semi_major_axis_km: semi_major_axis_km,
               eccentricity: eccentricity,
               perigee_altitude_km: perigee_altitude_km,
               apogee_altitude_km: apogee_altitude_km
             }
           ] = artifact.trajectories

    assert "trajectory_summary_only" in trajectory_model_limits
    assert "point_mass_gravity_only" in trajectory_model_limits
    assert "not_flight_certified" in trajectory_model_limits

    assert trajectory_model_limits ==
             OrbitalDynamics.ResultSet.Artifact.trajectory_model_limits(%{
               "force_model" => "point_mass_two_body"
             })

    assert final_radius_km > 0.0
    assert final_speed_km_s > 0.0
    assert min_radius_km > 0.0
    assert max_radius_km >= min_radius_km
    assert min_altitude_km > 0.0
    assert max_altitude_km >= min_altitude_km
    assert semi_major_axis_km > 0.0
    assert eccentricity >= 0.0
    assert perigee_altitude_km > 0.0
    assert apogee_altitude_km >= perigee_altitude_km
    assert_in_delta hd(artifact.trajectories).starts_at_s, 0.0, 0.0
    assert_in_delta hd(artifact.trajectories).ends_at_s, 120.0, 0.0

    assert [
             %{
               scenario_id: "artifact_1",
               ground_station_id: "equator",
               sample_count: sample_count,
               event_detector: "access_windows",
               event_model: "sampled_ground_station_access",
               validation_level: "analysis",
               timing_policy: "sampled_state_linear_boundary",
               interpolation: "linear_sample_crossing",
               boundary_refinement: "aos_los_linear_margin_interpolation",
               model_limits: access_model_limits,
               assumptions: %{
                 "geometry_model" => "simplified_spherical_earth_rotation",
                 "event_timing_policy" => "sampled_state_linear_boundary",
                 "event_time_tolerance_s" => 60.0
               }
             }
           ] = artifact.access_windows

    assert_in_delta hd(artifact.access_windows).starts_at_s, 0.0, 0.0
    assert sample_count > 0
    assert "sample_cadence_limited" in access_model_limits
    assert "refinement_not_root_solved" in access_model_limits

    assert access_model_limits ==
             OrbitalDynamics.ResultSet.Artifact.event_detector_model_limits(:access_windows)

    assert [
             %{
               scenario_id: "artifact_1",
               sample_count: eclipse_sample_count,
               event_detector: "eclipses",
               event_model: "cylindrical_central_body_shadow",
               validation_level: "analysis",
               timing_policy: "sampled_state_linear_boundary",
               interpolation: "linear_sample_crossing",
               boundary_refinement: "eclipse_linear_shadow_margin_interpolation",
               model_limits: eclipse_model_limits,
               assumptions: %{
                 "shadow_model" => "cylindrical_central_body_shadow",
                 "event_detector" => "eclipses",
                 "event_time_tolerance_s" => 60.0
               }
             }
           ] = artifact.eclipse_intervals

    assert eclipse_sample_count > 0
    assert "cylindrical_shadow" in eclipse_model_limits
    assert "no_penumbra_model" in eclipse_model_limits

    assert eclipse_model_limits ==
             OrbitalDynamics.ResultSet.Artifact.event_detector_model_limits("eclipses")

    assert hd(artifact.eclipse_intervals).sun_direction == [-1.0, 0.0, 0.0]

    assert artifact.errors == []

    assert {:ok, %{"schema_contract" => "result_artifact.v1"}} =
             artifact
             |> json_round_trip()
             |> Schema.validate_artifact(schema_contract: "result_artifact.v1")

    assert :json.encode(artifact) |> IO.iodata_to_binary() =~ ~s("access_windows")
    assert :json.encode(artifact) |> IO.iodata_to_binary() =~ ~s("eclipse_intervals")
  end

  test "exports mode-specific access refinement evidence" do
    result_set = result_set()

    event_results =
      Enum.map(result_set.event_results, fn
        %{event_type: :ground_station_access, events: events} = result ->
          refined_events =
            Enum.map(events, fn event ->
              metadata =
                Map.merge(event.metadata, %{
                  root_refinement_requested: true,
                  interpolation: :cubic_hermite_state,
                  boundary_refinement: :aos_los_bracketed_bisection,
                  event_timing_policy: :sampled_state_bracketed_root_refinement
                })

              %{event | metadata: metadata}
            end)

          %{result | events: refined_events}

        result ->
          result
      end)

    artifact = Artifact.build(%{result_set | event_results: event_results})
    [access] = artifact.access_windows

    assert access.interpolation == "cubic_hermite_state"
    assert access.boundary_refinement == "aos_los_bracketed_bisection"
    assert access.timing_policy == "sampled_state_bracketed_root_refinement"
    assert "root_refinement_interpolated_state_only" in access.model_limits
    assert "root_refinement_not_externally_validated" in access.model_limits
    refute "refinement_not_root_solved" in access.model_limits
  end

  test "execution report isolates failed scenarios in result artifacts" do
    result_set = failed_result_set()
    artifact = Artifact.build(result_set, generated_at: DateTime.from_unix!(1_700_000_000))

    assert artifact.execution_report.status == "failed"
    assert artifact.execution_report.scenario_count == 1
    assert artifact.execution_report.completed_scenario_count == 0
    assert artifact.execution_report.failed_scenario_count == 1
    assert "failed_scenarios_are_reported_not_retried" in artifact.execution_report.model_limits
    expected_node = Atom.to_string(node())

    assert [
             %{
               scenario_id: "bad_artifact",
               scenario_index: 0,
               stage: "propagation",
               error: ["invalid_scenario", "initial_state_radius_km"],
               node: ^expected_node,
               resumability: "manual_rerun_only",
               retry_recommendation: "rerun_failed_scenario_from_source_manifest"
             }
           ] = artifact.execution_report.failed_scenarios

    assert {:ok, %{"schema_contract" => "execution_report.v1"}} =
             artifact.execution_report |> json_round_trip() |> Schema.validate_artifact()
  end

  test "preflights reusable result artifacts for manifest resume" do
    unique = System.unique_integer([:positive])
    manifest_path = Path.join(System.tmp_dir!(), "artifact_resume_manifest_#{unique}.json")
    artifact_path = Path.join(System.tmp_dir!(), "artifact_resume_result_#{unique}.json")

    on_exit(fn ->
      File.rm(manifest_path)
      File.rm(artifact_path)
    end)

    File.write!(manifest_path, ~s({"study_id":"artifact_study"}))

    artifact =
      result_set_for_manifest_resume(manifest_path)
      |> Artifact.build(generated_at: DateTime.from_unix!(1_700_000_000))

    Artifact.write_json!(artifact, artifact_path)

    assert {:ok, resumed_artifact} =
             Artifact.resume_check(artifact_path,
               study_id: :artifact_study,
               manifest_path: manifest_path,
               run_id: "artifact-resume-run"
             )

    assert resumed_artifact["study_id"] == "artifact_study"
    assert get_in(resumed_artifact, ["run", "id"]) == "artifact-resume-run"

    assert {:error,
            %{reason: :run_id_mismatch, expected: "other-run", actual: "artifact-resume-run"}} =
             Artifact.resume_check(artifact_path,
               study_id: :artifact_study,
               manifest_path: manifest_path,
               run_id: "other-run"
             )

    File.write!(manifest_path, ~s({"study_id":"artifact_study","changed":true}))

    assert {:error, %{reason: :manifest_sha_mismatch}} =
             Artifact.resume_check(artifact_path,
               study_id: :artifact_study,
               manifest_path: manifest_path,
               run_id: "artifact-resume-run"
             )
  end

  test "exports ground-track crossing rows with timing and coordinate assumptions" do
    [scenario] =
      ScenarioFixture.circular_leo(
        count: 1,
        duration_s: 120.0,
        output_step_s: 60.0,
        id_prefix: "ground_track_artifact"
      )

    study =
      Study.new!(:ground_track_artifact, [scenario],
        outputs: [:ground_track_crossings],
        propagator_opts: [max_step_s: 10.0]
      )

    assert {:ok, result_set} =
             OrbitalDynamics.run_study(study,
               ground_track_crossings: [
                 %{id: :prime_meridian, crossing: :longitude, longitude_deg: 0.0}
               ]
             )

    artifact = Artifact.build(result_set)

    assert [
             %{
               scenario_id: "ground_track_artifact_1",
               request_id: "prime_meridian",
               event_type: "longitude_crossing",
               crossing: "longitude",
               target_deg: target_deg,
               frame: "inertial",
               starts_at_s: starts_at_s,
               crossing_direction: "sampled_exact",
               sample_index: 0,
               event_detector: "ground_track_crossings",
               event_model: "sampled_geocentric_ground_track_crossing",
               validation_level: "analysis",
               timing_policy: "sampled_state_linear_boundary",
               interpolation: "linear_sample_crossing",
               model_limits: model_limits,
               assumptions: %{
                 "coordinate_model" => "geocentric_spherical_inertial",
                 "event_detector" => "ground_track_crossings",
                 "event_timing_policy" => "sampled_state_linear_boundary",
                 "event_time_tolerance_s" => 60.0
               }
             }
             | _
           ] = artifact.ground_track_crossings

    assert target_deg == 0.0
    assert starts_at_s == 0.0
    assert "geocentric_spherical_coordinates" in model_limits
    assert "no_earth_orientation_parameters" in model_limits

    assert [
             %{"id" => "propagator.two_body"},
             %{"id" => "event.ground_track_crossings"}
           ] = artifact.assumptions["model_validation"]
  end

  defp result_set_for_manifest_resume(manifest_path) do
    earth = CentralBody.earth()

    [scenario] =
      ScenarioFixture.circular_leo(
        count: 1,
        duration_s: 120.0,
        output_step_s: 60.0,
        id_prefix: "artifact"
      )

    study =
      Study.new!(:artifact_study, [scenario],
        outputs: [:trajectories],
        propagator_opts: [max_step_s: 10.0]
      )

    manifest = %{
      path: manifest_path,
      sha256: sha256(File.read!(manifest_path))
    }

    assert {:ok, result_set} =
             OrbitalDynamics.run_study(study,
               central_body: earth,
               run_id: "artifact-resume-run",
               manifest: manifest
             )

    result_set
  end

  test "exports provider-backed ground-track rotation assumptions" do
    [scenario] =
      ScenarioFixture.circular_leo(
        count: 1,
        duration_s: 120.0,
        output_step_s: 60.0,
        id_prefix: "provider_ground_track_artifact"
      )

    study =
      Study.new!(:provider_ground_track_artifact, [scenario],
        outputs: [:ground_track_crossings],
        propagator_opts: [max_step_s: 10.0]
      )

    assert {:ok, result_set} =
             OrbitalDynamics.run_study(study,
               ground_track_crossings: [
                 %{
                   id: :provider_prime_meridian,
                   crossing: :longitude,
                   longitude_deg: 0.0,
                   frame: :body_fixed,
                   earth_rotation_provider:
                     OrbitalDynamics.Environment.ConstantEarthRotationProvider
                 }
               ]
             )

    artifact = Artifact.build(result_set)

    assert [
             %{
               request_id: "provider_prime_meridian",
               frame: "body_fixed",
               assumptions: %{
                 "coordinate_model" => "geocentric_spherical_body_fixed_provider_rotation",
                 "earth_rotation_provider" =>
                   "Elixir.OrbitalDynamics.Environment.ConstantEarthRotationProvider",
                 "earth_rotation_provider_id" =>
                   "environment.provider.earth_rotation.constant_rate",
                 "earth_rotation_model" => "constant_earth_rotation",
                 "earth_rotation_rate_rad_s" => 7.2921150e-5,
                 "before_earth_rotation_angle_rad" => before_angle,
                 "after_earth_rotation_angle_rad" => after_angle
               }
             }
             | _
           ] = artifact.ground_track_crossings

    assert is_number(before_angle)
    assert is_number(after_angle)
  end

  test "writes artifact JSON to disk" do
    path = Path.join(System.tmp_dir!(), "orbital_dynamics_result_set_artifact_test.json")
    on_exit(fn -> File.rm(path) end)

    artifact = Artifact.build(result_set())

    assert ^path = Artifact.write_json!(artifact, path)
    assert File.read!(path) =~ ~s("study_id":"artifact_study")
  end

  test "writes nil artifact values as JSON null" do
    path = Path.join(System.tmp_dir!(), "orbital_dynamics_result_set_artifact_nil_test.json")
    on_exit(fn -> File.rm(path) end)

    Artifact.write_json!(%{trajectory: %{semi_major_axis_km: nil}, values: [nil]}, path)

    json = File.read!(path)

    assert %{
             "trajectory" => %{"semi_major_axis_km" => :null},
             "values" => [:null]
           } = :json.decode(json)

    assert json =~ ~s("semi_major_axis_km":null)
    refute json =~ ~s("nil")
  end

  test "writes generated artifact null values as JSON null without stringifying them" do
    path =
      Path.join(
        System.tmp_dir!(),
        "orbital_dynamics_result_set_artifact_generated_null_test.json"
      )

    on_exit(fn -> File.rm(path) end)

    artifact = Artifact.build(result_set())
    Artifact.write_json!(artifact, path)

    json = File.read!(path)
    decoded = :json.decode(json)

    assert get_in(decoded, ["run", "metadata", "task_supervisor_nodes"]) == :null
    assert get_in(decoded, ["execution_report", "task_supervisor_nodes"]) == :null
    refute json =~ ~s("task_supervisor_nodes":"null")
  end

  test "extracts maneuver recommendation rows from trajectory assumptions" do
    artifact = Artifact.build(maneuver_result_set())

    assert [
             %{
               "schema_contract" => "maneuver_recommendation.v1",
               "id" => "trim_burn",
               "scenario_id" => "maneuver_plan",
               "type" => "impulsive_burn",
               "epoch_s" => 60.0,
               "frame" => "eci_j2000",
               "delta_v_km_s" => delta_v_km_s,
               "delta_v_magnitude_km_s" => 0.01,
               "maneuver_model" => "impulsive_burns",
               "validation_level" => "artifact_contract",
               "model_limits" => recommendation_model_limits,
               "assumptions" => %{
                 "execution_boundary" => "recommendation_only_no_command_execution",
                 "source" => "trajectory_assumptions"
               }
             }
           ] = artifact.maneuver_recommendations

    assert delta_v_km_s == [0.0, 0.01, 0.0]

    assert recommendation_model_limits ==
             OrbitalDynamics.ManeuverReview.recommendation_model_limits()

    assert %{
             "schema_contract" => "maneuver_review_report.v1",
             "maneuver_count" => 1,
             "review_required_count" => 1,
             "total_delta_v_km_s" => 0.01,
             "rows" => [
               %{
                 "maneuver_id" => "trim_burn",
                 "required_operator_action" => "review_maneuver_recommendation",
                 "execution_boundary" => "recommendation_only_no_command_execution"
               }
             ]
           } = artifact.maneuver_review_report
  end

  test "adds declared search rankings to artifacts" do
    result_set =
      result_set(%{
        "search" => %{
          "objective" => "final_radius_km",
          "objective_direction" => "maximize",
          "rank_limit" => 1
        },
        "constraints" => [
          %{
            "id" => "minimum_altitude",
            "metric" => "min_altitude_km",
            "operator" => ">=",
            "value" => 600.0
          }
        ]
      })

    artifact = Artifact.build(result_set)

    assert artifact.scenario_rankings.objective == "final_radius_km"
    assert artifact.scenario_rankings.objective_direction == "maximize"
    assert artifact.scenario_rankings.rank_limit == 1
    assert artifact.scenario_rankings.model == "persisted_artifact_summary_and_ranking"
    assert artifact.scenario_rankings.source == "result_set_artifact.study_metadata.search"
    assert artifact.scenario_rankings.validation_level == "artifact_contract"

    assert artifact.scenario_rankings.model_limits ==
             OrbitalDynamics.ResultSet.Report.model_limits()

    assert artifact.scenario_rankings.assumptions.source == "study_metadata.search"

    assert [%{scenario_id: "artifact_1", value: value}] = artifact.scenario_rankings.rows
    assert value > 0.0

    assert [
             %{
               constraint_id: "minimum_altitude",
               scenario_id: "artifact_1",
               metric: "min_altitude_km",
               status: :pass
             }
           ] = artifact.constraint_results

    assert %{
             "schema_contract" => "constraint_report.v1",
             "constraint_count" => 1,
             "model_limits" => model_limits,
             "row_count" => 1,
             "status" => "pass",
             "status_counts" => %{"pass" => 1, "fail" => 0, "warning" => 0}
           } = artifact.constraint_report

    assert "artifact_level_only" in model_limits
    assert "missing_or_nil_values_fail" in model_limits
  end

  test "adds monte carlo reproducibility reports to result artifacts" do
    artifact = Artifact.build(monte_carlo_result_set())

    assert %{
             schema_contract: "monte_carlo_reproducibility_report.v1",
             model: "seeded_independent_normal_cartesian_dispersion",
             source: "study_metadata.monte_carlo",
             generator: "state_vector_dispersion",
             rng: "rand_exsss",
             sampling_method: "box_muller_transform",
             deterministic_seed: true,
             seed: 12_345,
             requested_count: 3,
             generated_scenario_count: 3,
             id_prefix: "dispersion",
             generated_scenario_ids: ["dispersion_1", "dispersion_2", "dispersion_3"],
             position_sigma_km: [0.1, 0.1, 0.05],
             velocity_sigma_km_s: [0.0001, 0.0001, 0.00005],
             seed_manifest: %{"monte_carlo_seed" => 12_345},
             assumptions: %{
               scenario_id_order: "artifact.trajectories order",
               distribution: "independent normal per Cartesian component",
               covariance_model: "none"
             },
             known_limits: known_limits,
             model_limits: model_limits
           } = artifact.monte_carlo_reproducibility_report

    assert "no_covariance_matrix" in known_limits
    assert model_limits == known_limits

    assert {:ok, %{"schema_contract" => "monte_carlo_reproducibility_report.v1"}} =
             artifact.monte_carlo_reproducibility_report
             |> json_round_trip()
             |> Schema.validate_artifact()
  end

  defp result_set(metadata \\ %{}) do
    earth = CentralBody.earth()

    [scenario] =
      ScenarioFixture.circular_leo(
        count: 1,
        duration_s: 120.0,
        output_step_s: 60.0,
        id_prefix: "artifact"
      )

    study =
      Study.new!(:artifact_study, [scenario],
        outputs: [:trajectories, :access_windows, :eclipses],
        propagator_opts: [max_step_s: 10.0],
        metadata: metadata
      )

    station = GroundStation.new!(:equator, 0.0, 0.0)

    assert {:ok, result_set} =
             OrbitalDynamics.run_study(study,
               ground_stations: [station],
               central_body: earth,
               sun_direction: {-1.0, 0.0, 0.0}
             )

    result_set
  end

  defp monte_carlo_result_set do
    [base_scenario] =
      ScenarioFixture.circular_leo(
        count: 1,
        duration_s: 120.0,
        output_step_s: 60.0,
        id_prefix: "base"
      )

    scenarios =
      MonteCarlo.state_vector_dispersion(base_scenario,
        count: 3,
        seed: 12_345,
        position_sigma_km: {0.1, 0.1, 0.05},
        velocity_sigma_km_s: {0.0001, 0.0001, 0.00005},
        id_prefix: "dispersion"
      )

    study =
      Study.new!(:monte_carlo_artifact_study, scenarios,
        outputs: [:trajectories],
        propagator_opts: [max_step_s: 10.0],
        seed_manifest: %{"monte_carlo_seed" => 12_345},
        metadata: %{
          "monte_carlo" => %{
            "generator" => "state_vector_dispersion",
            "id_prefix" => "dispersion",
            "count" => 3,
            "seed" => 12_345,
            "position_sigma_km" => [0.1, 0.1, 0.05],
            "velocity_sigma_km_s" => [0.0001, 0.0001, 0.00005],
            "objective" => "final_radius_km",
            "objective_direction" => "maximize",
            "rank_limit" => 2
          }
        }
      )

    assert {:ok, result_set} = OrbitalDynamics.run_study(study, central_body: CentralBody.earth())
    result_set
  end

  defp maneuver_result_set do
    plan =
      MissionPlan.new!(:maneuver_plan, Spacecraft.new!(:sat_1, 250.0), initial_state(),
        horizon_s: 120.0,
        output_step_s: 60.0,
        activities: [
          Activity.impulsive_burn!(:trim_burn, 60.0, {0.0, 0.01, 0.0},
            frame: Frame.earth_inertial_j2000()
          )
        ]
      )

    study =
      Study.new!(:maneuver_artifact_study, [MissionPlan.to_scenario!(plan)],
        outputs: [:trajectories],
        propagator_opts: [max_step_s: 10.0]
      )

    assert {:ok, result_set} = OrbitalDynamics.run_study(study, central_body: CentralBody.earth())
    result_set
  end

  defp failed_result_set do
    earth = CentralBody.earth()

    [scenario] =
      ScenarioFixture.circular_leo(
        count: 1,
        duration_s: 120.0,
        output_step_s: 60.0,
        id_prefix: "bad"
      )

    bad_scenario = %{scenario | id: :bad_artifact, initial_state: zero_radius_state()}
    study = Study.new!(:execution_failure_study, [bad_scenario], outputs: [:trajectories])

    assert {:ok, result_set} = OrbitalDynamics.run_study(study, central_body: earth)
    result_set
  end

  defp initial_state do
    StateVector.new!(
      {7000.0, 0.0, 0.0},
      {0.0, 7.5, 0.0},
      Epoch.new!(0.0, :tdb),
      Frame.earth_inertial_j2000()
    )
  end

  defp zero_radius_state do
    StateVector.new!(
      {0.0, 0.0, 0.0},
      {0.0, 0.0, 0.0},
      Epoch.new!(0.0, :tdb),
      Frame.earth_inertial_j2000()
    )
  end

  defp json_round_trip(value) do
    value
    |> :json.encode()
    |> IO.iodata_to_binary()
    |> :json.decode()
  end

  defp sha256(contents) do
    :crypto.hash(:sha256, contents)
    |> Base.encode16(case: :lower)
  end
end
