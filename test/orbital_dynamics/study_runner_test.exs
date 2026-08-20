defmodule OrbitalDynamics.StudyRunnerTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.{
    CentralBody,
    Epoch,
    Frame,
    GroundStation,
    Scenario,
    Spacecraft,
    StateVector,
    Study,
    StudyRunner
  }

  alias OrbitalDynamics.Propagators.TwoBodyNxCompiled
  alias OrbitalDynamics.Environment.CampaignEnvironmentProvider

  defmodule UntrustedCampaignProvider do
    defdelegate load(opts), to: CampaignEnvironmentProvider
    defdelegate configured_capability(opts), to: CampaignEnvironmentProvider
    defdelegate provenance(dataset), to: CampaignEnvironmentProvider
    defdelegate capabilities(), to: CampaignEnvironmentProvider
    defdelegate fetch(kind, opts), to: CampaignEnvironmentProvider
  end

  defmodule CounterfeitGroundTrackCapabilityProvider do
    def capabilities, do: CampaignEnvironmentProvider.capabilities()
    def fetch(_kind, _opts), do: raise("reserved capability must fail before fetch")
  end

  defmodule CounterfeitGroundTrackProductProvider do
    alias OrbitalDynamics.Environment.ConstantEarthRotationProvider

    def capabilities, do: ConstantEarthRotationProvider.capabilities()

    def fetch(:earth_rotation, opts) do
      with {:ok, product} <- ConstantEarthRotationProvider.fetch(:earth_rotation, opts) do
        {:ok,
         product
         |> Map.put(
           "provider_id",
           "environment.provider.campaign.jpl_de441_iers_finals2000a"
         )
         |> Map.put("campaign_environment", %{
           "trust_boundary" => "sha256_verified_checked_in_campaign_table"
         })}
      end
    end
  end

  test "runs trajectories and access windows for a study" do
    earth = CentralBody.earth()

    study =
      Study.new!(:leo_access, [scenario(:a, earth)], outputs: [:trajectories, :access_windows])

    station = GroundStation.new!(:equator, 0.0, 0.0)

    assert {:ok, result_set} =
             OrbitalDynamics.run_study(study, ground_stations: [station], central_body: earth)

    assert result_set.study_id == :leo_access
    assert [%{scenario_id: :a, trajectory: trajectory}] = result_set.trajectory_results
    assert trajectory.scenario_id == :a

    assert [
             %{
               scenario_id: :a,
               event_type: :ground_station_access,
               source: %{ground_station_id: :equator},
               events: events
             }
           ] = result_set.event_results

    assert [%{type: :ground_station_access} | _] = events
    assert result_set.errors == []
    assert result_set.metadata.output_count.trajectories == 1
    assert result_set.metadata.output_count.event_results == 1
    assert result_set.metadata.run["status"] == "completed"
    assert result_set.metadata.run["node"] == Atom.to_string(node())
    assert result_set.metadata.run["duration_ms"] >= 0
    assert result_set.metadata.run["metadata"]["execution_mode"] == "local_tasks"
    assert result_set.metadata.run["metadata"]["task_supervisor_node"] == Atom.to_string(node())
    assert result_set.metadata.run["metadata"]["scenario_count"] == 1
    assert result_set.metadata.run["metadata"]["scheduler_count"] == System.schedulers_online()
    assert is_integer(result_set.metadata.run["metadata"]["phase_timings_ms"]["propagation"])
    assert is_integer(result_set.metadata.run["metadata"]["phase_timings_ms"]["event_detection"])

    assert result_set.metadata.run["metadata"]["execution_plan"] == %{
             "batch_propagation" => false,
             "batches_per_wave" => System.schedulers_online(),
             "chunking_enabled" => false,
             "distribution_mode" => "local_tasks",
             "effective_task_chunk_size" => 1,
             "effective_task_concurrency" => System.schedulers_online(),
             "max_concurrency" => System.schedulers_online(),
             "requested_task_chunk_size" => 1,
             "resolved_task_chunk_size" => 1,
             "adaptive_chunking" => %{
               "applied_task_chunk_size" => 1,
               "concurrent_task_batches" => System.schedulers_online(),
               "policy" => "explicit",
               "reason" => "operator_supplied_task_chunk_size",
               "recommended_task_chunk_size" => 1,
               "requested_task_chunk_size" => 1,
               "supervisor_count" => 0,
               "target_wave_count" => nil
             },
             "resumability" => "not_resumable",
             "scenario_count" => 1,
             "supervisor_count" => 1,
             "task_batch_count" => 1,
             "wave_count" => 1
           }

    assert result_set.assumptions.external_provider_policy == %{
             network_access: "none",
             hidden_network_calls: false,
             external_provider_count: 0,
             external_providers: [],
             rule:
               "planning runs must not call external services unless an external provider is explicitly configured"
           }

    assert result_set.metadata.run["metadata"]["external_provider_policy"]["network_access"] ==
             "none"

    assert result_set.assumptions.backend_selection_policy.policy == "reference_default"
    assert result_set.assumptions.backend_selection_policy.backend == :scalar_elixir
    assert result_set.assumptions.backend_selection_policy.reference_backend == true
    assert result_set.assumptions.backend_selection_policy.requires_reference_match == true
    assert result_set.assumptions.backend_selection_policy.requires_benchmark_artifact == false

    assert result_set.assumptions.backend_selection_policy.backend_acceptance_policy ==
             "backend_acceptance_policy.v1"

    assert result_set.assumptions.backend_selection_policy.batch_selection_reason ==
             "propagator_does_not_support_batching"

    assert result_set.metadata.run["metadata"]["backend_selection_policy"]["policy"] ==
             "reference_default"

    assert result_set.metadata.run["metadata"]["backend_selection_policy"][
             "backend_acceptance_evidence"
           ]["tier"] == "reference_default"
  end

  test "records explicit external provider configuration without making hidden calls" do
    earth = CentralBody.earth()
    study = Study.new!(:provider_policy, [scenario(:a, earth)], outputs: [:trajectories])

    assert {:ok, result_set} =
             OrbitalDynamics.run_study(study,
               external_providers: [
                 %{"id" => "station_calendar_demo", "type" => "station_calendar"}
               ]
             )

    assert result_set.assumptions.external_provider_policy.network_access ==
             "explicitly_configured"

    assert result_set.assumptions.external_provider_policy.hidden_network_calls == false
    assert result_set.assumptions.external_provider_policy.external_provider_count == 1

    assert result_set.assumptions.external_provider_policy.external_providers == [
             %{"id" => "station_calendar_demo", "type" => "station_calendar"}
           ]

    assert get_in(result_set.metadata.run, [
             "metadata",
             "external_provider_policy",
             "external_providers",
             Access.at(0),
             "id"
           ]) == "station_calendar_demo"
  end

  test "honors explicit deterministic run provenance overrides" do
    earth = CentralBody.earth()
    study = Study.new!(:deterministic_run, [scenario(:a, earth)], outputs: [:trajectories])

    assert {:ok, result_set} =
             OrbitalDynamics.run_study(study,
               run_id: "deterministic_run-1",
               git_revision: nil
             )

    assert result_set.metadata.run["id"] == "deterministic_run-1"
    assert result_set.metadata.run["metadata"]["git_revision"] == nil
  end

  test "supports access windows without returning trajectories" do
    earth = CentralBody.earth()
    study = Study.new!(:access_only, [scenario(:a, earth)], outputs: [:access_windows])
    station = GroundStation.new!(:equator, 0.0, 0.0)

    assert {:ok, result_set} =
             OrbitalDynamics.run_study(study, ground_stations: [station], central_body: earth)

    assert result_set.trajectory_results == []
    assert length(result_set.event_results) == 1
  end

  test "multiple stations produce station-tagged event results" do
    earth = CentralBody.earth()
    study = Study.new!(:multi_station, [scenario(:a, earth)], outputs: [:access_windows])
    stations = [GroundStation.new!(:equator, 0.0, 0.0), GroundStation.new!(:opposite, 0.0, 180.0)]

    assert {:ok, result_set} =
             OrbitalDynamics.run_study(study, ground_stations: stations, central_body: earth)

    assert Enum.map(result_set.event_results, & &1.source.ground_station_id) == [
             :equator,
             :opposite
           ]
  end

  test "supports eclipse intervals without requiring ground stations" do
    earth = CentralBody.earth()
    study = Study.new!(:eclipse_only, [scenario(:a, earth)], outputs: [:eclipses])

    assert {:ok, result_set} =
             OrbitalDynamics.run_study(study,
               central_body: earth,
               sun_direction: {-1.0, 0.0, 0.0}
             )

    assert result_set.trajectory_results == []

    assert [
             %{
               scenario_id: :a,
               event_type: :eclipse,
               source: %{shadow_model: :cylindrical_central_body_shadow},
               events: [%{type: :eclipse} | _]
             }
           ] = result_set.event_results

    assert result_set.errors == []
    assert result_set.assumptions.sun_direction == {-1.0, 0.0, 0.0}
  end

  test "consumes one finite campaign environment and archives exact result provenance" do
    earth = CentralBody.earth()

    study =
      Study.new!(:campaign_environment, [campaign_scenario(:campaign, earth, 820_497_600.0)],
        outputs: [:eclipses, :ground_track_crossings]
      )

    opts = [
      campaign_environment:
        {CampaignEnvironmentProvider, CampaignEnvironmentProvider.checked_in_options()},
      ground_track_crossings: [
        %{
          id: :campaign_meridian,
          crossing: :longitude,
          longitude_deg: -80.0,
          frame: :body_fixed
        }
      ]
    ]

    assert :ok = StudyRunner.validate_run_inputs(study, opts)
    assert {:ok, result_set} = StudyRunner.run(study, opts)
    assert result_set.errors == []

    provenance = result_set.assumptions.campaign_environment

    assert provenance["provider_id"] ==
             "environment.provider.campaign.jpl_de441_iers_finals2000a"

    assert provenance["provider_revision"] == "campaign_environment_provider.v2"
    assert provenance["dataset_revision"] == "jpl_de441__iers_finals2000a_2026-08-13.v2"

    assert provenance["dataset_semantic_sha256"] ==
             "afb0c7252b0b2d2c7e987651e639e02b76bc9ac1ff19d0927b3bf3e6a9ebb5db"

    assert provenance["content_sha256"] ==
             "757d8d4d1694d0a3cf3897b337cfd2ec818e3ab8715d7103df999d1a0a3697e9"

    assert provenance["earth_fixed_frame"] ==
             "earth_fixed_era_from_eci_j2000_approximation"

    assert provenance["coverage"] == %{
             "starts_at_s" => 820_497_600.0,
             "ends_at_s" => 820_756_800.0,
             "time_scale" => "utc"
           }

    eclipse_result = Enum.find(result_set.event_results, &(&1.event_type == :eclipse))

    ground_track_result =
      Enum.find(result_set.event_results, &(&1.event_type == :ground_track_crossing))

    assert eclipse_result.source.campaign_environment == provenance
    assert ground_track_result.source.campaign_environment == provenance

    artifact =
      OrbitalDynamics.ResultSet.Artifact.build(result_set,
        generated_at: ~U[2026-08-20 00:00:00Z]
      )

    artifact_provenance = artifact.assumptions["campaign_environment"]
    assert artifact_provenance["provider_id"] == provenance["provider_id"]
    assert artifact_provenance["provider_revision"] == provenance["provider_revision"]
    assert artifact_provenance["dataset_revision"] == provenance["dataset_revision"]

    assert artifact_provenance["dataset_semantic_sha256"] ==
             provenance["dataset_semantic_sha256"]

    assert artifact_provenance["content_sha256"] == provenance["content_sha256"]
    assert artifact_provenance["coverage"] == provenance["coverage"]

    assert Enum.map(artifact.assumptions["environment_models"], & &1["id"]) == [
             "environment.solar.campaign_tabular_geocentric_direction",
             "environment.earth_rotation.campaign_era_from_eci_j2000_approximation"
           ]

    assert Enum.all?(artifact.assumptions["environment_models"], fn model ->
             model["parameters"]["content_sha256"] == provenance["content_sha256"] and
               model["parameters"]["dataset_semantic_sha256"] ==
                 provenance["dataset_semantic_sha256"] and
               model["parameters"]["coverage"] == provenance["coverage"]
           end)

    assert [campaign_crossing] = artifact.ground_track_crossings

    assert "earth_rotation_from_era_and_tabular_ut1_utc" in campaign_crossing.model_limits
    assert "direct_era_rotation_from_eci_j2000_approximation" in campaign_crossing.model_limits
    assert "no_cirs_or_precession_nutation_transform" in campaign_crossing.model_limits
    assert "no_polar_motion_application" in campaign_crossing.model_limits
    assert "no_tirs_claim" in campaign_crossing.model_limits
    refute "constant_earth_rotation_body_fixed" in campaign_crossing.model_limits
    refute "no_earth_orientation_parameters" in campaign_crossing.model_limits

    assert campaign_crossing.assumptions["earth_rotation_frame"] ==
             "earth_fixed_era_from_eci_j2000_approximation"

    assert campaign_crossing.assumptions["earth_rotation_model"] ==
             "earth_fixed_era_from_eci_j2000_approximation"

    assert campaign_crossing.assumptions["polar_motion_applied"] == false

    assert campaign_crossing.assumptions["earth_rotation_dataset_semantic_sha256"] ==
             provenance["dataset_semantic_sha256"]

    crossing_provenance =
      campaign_crossing.assumptions["earth_rotation_provider_provenance"]

    assert crossing_provenance["provider_id"] == provenance["provider_id"]
    assert crossing_provenance["provider_revision"] == provenance["provider_revision"]
    assert crossing_provenance["dataset_revision"] == provenance["dataset_revision"]

    assert crossing_provenance["dataset_semantic_sha256"] ==
             provenance["dataset_semantic_sha256"]

    assert crossing_provenance["content_sha256"] == provenance["content_sha256"]
    assert crossing_provenance["earth_fixed_frame"] == provenance["earth_fixed_frame"]
    assert crossing_provenance["coverage"] == provenance["coverage"]
  end

  test "archives constant-rate Earth rotation when campaign and AccessGeometry are both consumed" do
    earth = CentralBody.earth()

    study =
      Study.new!(:mixed_campaign_access, [campaign_scenario(:mixed, earth, 820_497_600.0)],
        outputs: [:eclipses, :access_windows]
      )

    assert {:ok, result_set} =
             StudyRunner.run(study,
               campaign_environment:
                 {CampaignEnvironmentProvider, CampaignEnvironmentProvider.checked_in_options()},
               ground_stations: [GroundStation.new!(:equator, 0.0, 0.0)],
               central_body: earth
             )

    artifact = OrbitalDynamics.ResultSet.Artifact.build(result_set)

    assert Enum.map(artifact.assumptions["environment_models"], & &1["id"]) == [
             "environment.solar.campaign_tabular_geocentric_direction",
             "environment.earth_rotation.constant_rate"
           ]
  end

  test "rejects unknown campaign provider modules before event generation" do
    earth = CentralBody.earth()

    study =
      Study.new!(
        :untrusted_campaign_environment,
        [campaign_scenario(:untrusted, earth, 820_497_600.0)],
        outputs: [:eclipses, :ground_track_crossings]
      )

    assert {:error, {:untrusted_campaign_environment_provider, UntrustedCampaignProvider}} =
             StudyRunner.run(study,
               campaign_environment:
                 {UntrustedCampaignProvider, CampaignEnvironmentProvider.checked_in_options()},
               ground_track_crossings: [
                 %{id: :untrusted, crossing: :longitude, longitude_deg: 0.0, frame: :body_fixed}
               ]
             )
  end

  test "rejects reserved campaign claims through generic ground-track providers before execution" do
    earth = CentralBody.earth()

    study =
      Study.new!(:counterfeit_ground_track, [scenario(:counterfeit, earth)],
        outputs: [:ground_track_crossings]
      )

    request = fn provider ->
      [
        %{
          id: :counterfeit,
          crossing: :longitude,
          longitude_deg: 0.0,
          frame: :body_fixed,
          earth_rotation_provider: provider
        }
      ]
    end

    assert {:error,
            {:untrusted_campaign_environment_provider, CounterfeitGroundTrackCapabilityProvider}} =
             StudyRunner.run(study,
               ground_track_crossings: request.(CounterfeitGroundTrackCapabilityProvider)
             )

    assert {:error,
            {:untrusted_campaign_environment_evidence, CounterfeitGroundTrackProductProvider}} =
             StudyRunner.run(study,
               ground_track_crossings: request.(CounterfeitGroundTrackProductProvider)
             )

    assert {:error, {:untrusted_campaign_environment_evidence, :ground_track_crossings}} =
             StudyRunner.run(study,
               ground_track_crossings: [
                 request.(OrbitalDynamics.Environment.ConstantEarthRotationProvider)
                 |> hd()
                 |> Map.put(:campaign_environment, %{
                   "provider_id" => "environment.provider.campaign.jpl_de441_iers_finals2000a"
                 })
               ]
             )
  end

  test "rejects campaign environment requests outside finite coverage or in the wrong time scale" do
    earth = CentralBody.earth()
    provider = {CampaignEnvironmentProvider, CampaignEnvironmentProvider.checked_in_options()}

    outside_study =
      Study.new!(
        :campaign_outside,
        [campaign_scenario(:outside, earth, 820_756_800.0)],
        outputs: [:eclipses]
      )

    assert {:error,
            {:campaign_environment_request_outside_coverage,
             %{starts_at_s: 820_756_800.0, ends_at_s: 820_757_400.0}}} =
             StudyRunner.run(outside_study, campaign_environment: provider)

    wrong_scale_study =
      Study.new!(
        :campaign_wrong_scale,
        [campaign_scenario(:wrong_scale, earth, 820_497_600.0, :tdb)],
        outputs: [:eclipses]
      )

    assert {:error, {:campaign_environment_request_mismatch, request}} =
             StudyRunner.run(wrong_scale_study, campaign_environment: provider)

    assert request.time_scales == [:tdb]
  end

  test "requires the exact checked-in campaign option boundary" do
    earth = CentralBody.earth()

    study =
      Study.new!(
        :campaign_option_boundary,
        [campaign_scenario(:option_boundary, earth, 820_497_600.0)],
        outputs: [:eclipses]
      )

    forged_options =
      CampaignEnvironmentProvider.checked_in_options()
      |> Keyword.put(:caller_provenance, %{"provider_id" => "forged"})

    assert {:error, {:invalid_campaign_environment_configuration, :checked_in_options_required}} =
             StudyRunner.run(study,
               campaign_environment: {CampaignEnvironmentProvider, forged_options}
             )
  end

  test "preserves fixed-Sun and constant-rotation defaults without campaign opt-in" do
    earth = CentralBody.earth()

    study =
      Study.new!(:legacy_environment, [scenario(:legacy, earth)],
        outputs: [:eclipses, :ground_track_crossings]
      )

    assert {:ok, result_set} =
             StudyRunner.run(study,
               ground_track_crossings: [
                 %{
                   id: :legacy_meridian,
                   crossing: :longitude,
                   longitude_deg: 0.0,
                   frame: :body_fixed
                 }
               ]
             )

    refute Map.has_key?(result_set.assumptions, :campaign_environment)
    assert result_set.assumptions.sun_direction == {1.0, 0.0, 0.0}

    assert Enum.map(OrbitalDynamics.Environment.records_for_result_set(result_set), & &1["id"]) ==
             [
               "environment.solar.fixed_inertial_direction",
               "environment.earth_rotation.constant_rate"
             ]

    eclipse_result = Enum.find(result_set.event_results, &(&1.event_type == :eclipse))
    assert eclipse_result.source == %{shadow_model: :cylindrical_central_body_shadow}

    legacy_artifact = OrbitalDynamics.ResultSet.Artifact.build(result_set)
    assert [legacy_crossing | _events] = legacy_artifact.ground_track_crossings
    assert "constant_earth_rotation_body_fixed" in legacy_crossing.model_limits
    assert "no_earth_orientation_parameters" in legacy_crossing.model_limits
  end

  test "supports ground-track crossings as a study output" do
    earth = CentralBody.earth()

    study =
      Study.new!(:ground_track_study, [scenario(:a, earth)], outputs: [:ground_track_crossings])

    assert {:ok, result_set} =
             OrbitalDynamics.run_study(study,
               ground_track_crossings: [
                 %{
                   id: :prime_meridian,
                   crossing: :longitude,
                   longitude_deg: 0.0,
                   frame: :body_fixed,
                   rotation_rate_rad_s: 7.2921150e-5,
                   rotation_epoch_s: 0.0,
                   rotation_angle_offset_rad: 0.0
                 }
               ]
             )

    assert result_set.trajectory_results == []

    assert [
             %{
               scenario_id: :a,
               event_type: :ground_track_crossing,
               source: %{
                 crossing: :longitude,
                 target_deg: target_deg,
                 frame: :body_fixed,
                 rotation_rate_rad_s: 7.2921150e-5,
                 rotation_epoch_s: rotation_epoch_s,
                 rotation_angle_offset_rad: rotation_angle_offset_rad,
                 request_id: :prime_meridian
               },
               events: [%{type: :longitude_crossing} | _]
             }
           ] = result_set.event_results

    assert target_deg == 0.0
    assert rotation_epoch_s == 0.0
    assert rotation_angle_offset_rad == 0.0
    assert result_set.errors == []

    assert result_set.assumptions.ground_track_crossings == [
             %{
               id: :prime_meridian,
               crossing: :longitude,
               longitude_deg: 0.0,
               frame: :body_fixed,
               rotation_rate_rad_s: 7.2921150e-5,
               rotation_epoch_s: 0.0,
               rotation_angle_offset_rad: 0.0
             }
           ]
  end

  test "passes Earth-rotation providers through ground-track study requests" do
    earth = CentralBody.earth()

    study =
      Study.new!(:provider_ground_track_study, [scenario(:a, earth)],
        outputs: [:ground_track_crossings]
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

    assert [
             %{
               source: %{
                 earth_rotation_provider:
                   OrbitalDynamics.Environment.ConstantEarthRotationProvider
               },
               events: [%{metadata: metadata} | _]
             }
           ] = result_set.event_results

    assert metadata.coordinate_model == :geocentric_spherical_body_fixed_provider_rotation

    assert metadata.earth_rotation_provider_id ==
             "environment.provider.earth_rotation.constant_rate"

    assert metadata.earth_rotation_model == "constant_earth_rotation"
  end

  test "validates configured Earth-rotation provider coverage against the study horizon" do
    earth = CentralBody.earth()

    study =
      Study.new!(:configured_provider_ground_track_study, [scenario(:a, earth)],
        outputs: [:ground_track_crossings]
      )

    provider = OrbitalDynamics.Environment.TabularEarthOrientationProvider

    valid_ground_track_crossings = [
      %{
        id: :tabular_prime_meridian,
        crossing: :longitude,
        longitude_deg: 0.0,
        frame: :body_fixed,
        earth_rotation_provider:
          {provider,
           samples: [
             %{seconds_since_j2000: 0.0, earth_rotation_angle_rad: 0.0},
             %{seconds_since_j2000: 600.0, earth_rotation_angle_rad: 0.04375269}
           ]}
      }
    ]

    assert {:ok, result_set} =
             OrbitalDynamics.run_study(study,
               ground_track_crossings: valid_ground_track_crossings
             )

    assert [%{events: [%{metadata: metadata} | _]}] = result_set.event_results
    assert metadata.earth_rotation_provider_id == provider.capabilities()["id"]
    assert metadata.earth_rotation_provider_coverage_starts_at_s == 0.0
    assert metadata.earth_rotation_provider_coverage_ends_at_s == 600.0
    assert metadata.earth_rotation_provider_sample_count == 2

    assert :ok =
             OrbitalDynamics.validate_study_run_inputs(study,
               ground_track_crossings: valid_ground_track_crossings
             )

    assert {:error, {:invalid_option, :ground_track_crossings}} =
             OrbitalDynamics.run_study(study,
               ground_track_crossings: [
                 %{
                   crossing: :longitude,
                   longitude_deg: 0.0,
                   frame: :body_fixed,
                   earth_rotation_provider:
                     {provider,
                      samples: [
                        %{seconds_since_j2000: 0.0, earth_rotation_angle_rad: 0.0},
                        %{seconds_since_j2000: 300.0, earth_rotation_angle_rad: 0.021876345}
                      ]}
                 }
               ]
             )

    assert {:error, {:invalid_option, :ground_track_crossings}} =
             OrbitalDynamics.run_study(study,
               ground_track_crossings: [
                 %{
                   crossing: :longitude,
                   longitude_deg: 0.0,
                   frame: :body_fixed,
                   earth_rotation_provider:
                     OrbitalDynamics.Environment.ExponentialAtmosphereProvider
                 }
               ]
             )
  end

  test "propagation errors are captured in result set errors" do
    earth = CentralBody.earth()
    bad_scenario = %{scenario(:bad, earth) | initial_state: state({0.0, 0.0, 0.0}, earth)}
    study = Study.new!(:bad_study, [bad_scenario], outputs: [:trajectories])

    assert {:ok, result_set} = OrbitalDynamics.run_study(study)

    assert result_set.trajectory_results == []

    assert [
             %{
               scenario_id: :bad,
               scenario_index: 0,
               stage: :propagation,
               error: {:invalid_scenario, :initial_state_radius_km}
             }
           ] = result_set.errors
  end

  test "retries failed scenarios in deterministic source-manifest order" do
    earth = CentralBody.earth()

    study =
      Study.new!(
        :retry_study,
        [scenario(:a, earth), scenario(:b, earth), scenario(:c, earth)],
        outputs: [:trajectories],
        seed_manifest: %{"monte_carlo_seed" => 17},
        metadata: %{"assumption_set" => "retry-test-v1"}
      )

    execution_report = %{
      "schema_contract" => "execution_report.v1",
      "study_id" => "retry_study",
      "run_id" => "source-run",
      "status" => "completed_with_errors",
      "scenario_count" => 3,
      "failed_scenarios" => [
        %{"scenario_id" => "c", "scenario_index" => 2},
        %{"scenario_id" => "a", "scenario_index" => 0}
      ]
    }

    assert {:ok, retry_plan} =
             StudyRunner.failed_scenario_retry_plan(study, execution_report)

    assert retry_plan.scenario_indexes == [0, 2]
    assert retry_plan.scenario_ids == ["a", "c"]
    assert retry_plan.ordering == "source_manifest_scenario_order"
    assert retry_plan.source_run_id == "source-run"

    retry_source = %{
      path: "study_results/source-run.json",
      sha256: String.duplicate("a", 64),
      run_id: "source-run"
    }

    assert {:ok, result_set} =
             StudyRunner.retry_failed(study, execution_report,
               central_body: earth,
               run_id: "retry-run",
               retry_source: retry_source
             )

    assert Enum.map(result_set.trajectory_results, & &1.scenario_id) == [:a, :c]
    assert Enum.map(result_set.trajectory_results, & &1.scenario_index) == [0, 2]
    assert result_set.errors == []
    assert result_set.assumptions.seed_manifest == %{"monte_carlo_seed" => 17}
    assert result_set.assumptions.study_metadata == %{"assumption_set" => "retry-test-v1"}
    assert result_set.assumptions.retry.scenario_indexes == [0, 2]
    assert result_set.assumptions.retry.source_artifact == retry_source

    assert get_in(result_set.metadata.run, ["metadata", "execution_plan", "resumability"]) ==
             "failed_scenario_retry"

    assert get_in(result_set.metadata.run, ["metadata", "execution_plan", "scenario_count"]) ==
             2

    assert get_in(result_set.metadata.run, ["metadata", "retry", "scenario_indexes"]) == [0, 2]

    artifact = OrbitalDynamics.ResultSet.Artifact.build(result_set)

    assert artifact.execution_report.scenario_count == 2
    assert artifact.execution_report.completed_scenario_count == 2
    assert artifact.execution_report.failed_scenario_count == 0
    assert artifact.execution_report.execution_plan["resumability"] == "failed_scenario_retry"

    assert artifact.execution_report.model_limits ==
             OrbitalDynamics.ResultSet.Artifact.retry_execution_report_model_limits()

    refute "not_resumable" in artifact.execution_report.model_limits
    refute "failed_scenarios_are_reported_not_retried" in artifact.execution_report.model_limits

    assert artifact.execution_report.assumptions.resumability == "failed_scenario_retry"
    assert artifact.execution_report.assumptions.retry_scope == "failed_scenarios_only"
    assert artifact.execution_report.assumptions.checkpoint_resume == false
    assert artifact.execution_report.assumptions.source_results_merged == false
    assert artifact.execution_report.assumptions.persistent_queue == false
    assert artifact.execution_report.assumptions.automatic_retry == false

    assert artifact.execution_report.execution_plan["retry"]["scenario_indexes"] == [0, 2]

    assert {:ok, %{"schema_contract" => "result_artifact.v1"}} =
             artifact
             |> :json.encode()
             |> IO.iodata_to_binary()
             |> :json.decode()
             |> OrbitalDynamics.Schema.validate_artifact(contract: "result_artifact.v1")
  end

  test "rejects invalid failed-scenario retry reports" do
    earth = CentralBody.earth()
    study = Study.new!(:retry_study, [scenario(:a, earth), scenario(:b, earth)])

    base_report = %{
      "schema_contract" => "execution_report.v1",
      "study_id" => "retry_study",
      "run_id" => "source-run",
      "status" => "completed_with_errors",
      "scenario_count" => 2
    }

    assert {:error, :no_failed_scenarios} =
             StudyRunner.failed_scenario_retry_plan(
               study,
               Map.put(base_report, "failed_scenarios", [])
             )

    assert {:error, {:retry_scenario_id_mismatch, 1, "b", "a"}} =
             StudyRunner.failed_scenario_retry_plan(
               study,
               Map.put(base_report, "failed_scenarios", [
                 %{"scenario_index" => 1, "scenario_id" => "a"}
               ])
             )

    assert {:error, {:duplicate_retry_scenario_index, 0}} =
             StudyRunner.failed_scenario_retry_plan(
               study,
               Map.put(base_report, "failed_scenarios", [
                 %{"scenario_index" => 0, "scenario_id" => "a"},
                 %{"scenario_index" => 0, "scenario_id" => "a"}
               ])
             )
  end

  test "uses batch propagation for local batch-capable propagators" do
    earth = CentralBody.earth()

    study =
      Study.new!(:batch_study, [scenario(:a, earth), scenario(:b, earth)],
        outputs: [:trajectories],
        propagator: TwoBodyNxCompiled,
        propagator_opts: [max_step_s: 10.0]
      )

    assert {:ok, result_set} = OrbitalDynamics.run_study(study)

    assert Enum.map(result_set.trajectory_results, & &1.scenario_id) == [:a, :b]
    assert Enum.all?(result_set.trajectory_results, &(&1.node == node()))

    assert Enum.all?(
             result_set.trajectory_results,
             &(&1.trajectory.assumptions.backend == :nx_compiled)
           )

    assert result_set.metadata.run["metadata"]["execution_mode"] == "local_batch"
    assert result_set.metadata.run["metadata"]["batch_propagation"] == true
    assert result_set.metadata.run["options"]["batch_propagation"] == true
    assert result_set.assumptions.backend_selection_policy.policy == "experimental_accelerator"
    assert result_set.assumptions.backend_selection_policy.backend == :nx_compiled
    assert result_set.assumptions.backend_selection_policy.reference_backend == false
    assert result_set.assumptions.backend_selection_policy.requires_reference_match == true
    assert result_set.assumptions.backend_selection_policy.requires_benchmark_artifact == true
    assert result_set.assumptions.backend_selection_policy.batch_propagation_selected == true

    assert result_set.assumptions.backend_selection_policy.batch_selection_reason ==
             "propagator_supports_batching_and_no_explicit_task_distribution"

    assert result_set.metadata.run["metadata"]["backend_selection_policy"][
             "performance_claim"
           ] =~ "benchmark artifacts"

    assert result_set.metadata.run["metadata"]["backend_selection_policy"][
             "backend_acceptance_evidence"
           ]["requires_benchmark_artifact"] == true
  end

  test "unsupported outputs return a clear error" do
    earth = CentralBody.earth()
    study = Study.new!(:bad_output, [scenario(:a, earth)], outputs: [:thermal])

    assert {:error, {:unsupported_outputs, [:thermal]}} = OrbitalDynamics.run_study(study)
  end

  test "access windows require ground stations" do
    earth = CentralBody.earth()
    study = Study.new!(:missing_station, [scenario(:a, earth)], outputs: [:access_windows])

    assert {:error, {:missing_option, :ground_stations}} = OrbitalDynamics.run_study(study)
  end

  test "ground-track crossings require crossing requests" do
    earth = CentralBody.earth()

    study =
      Study.new!(:missing_ground_track, [scenario(:a, earth)], outputs: [:ground_track_crossings])

    assert {:error, {:missing_option, :ground_track_crossings}} =
             OrbitalDynamics.run_study(study)

    assert {:error, {:invalid_option, :ground_track_crossings}} =
             OrbitalDynamics.run_study(study, ground_track_crossings: [%{crossing: :latitude}])

    assert {:error, {:invalid_option, :ground_track_crossings}} =
             OrbitalDynamics.run_study(study,
               ground_track_crossings: [
                 %{
                   crossing: :longitude,
                   longitude_deg: 0.0,
                   frame: :body_fixed,
                   rotation_rate_rad_s: :fast
                 }
               ]
             )
  end

  test "remote task supervisors require connected nodes" do
    earth = CentralBody.earth()
    study = Study.new!(:remote_unavailable, [scenario(:a, earth)], outputs: [:trajectories])

    assert {:error, {:node_unavailable, :"missing@127.0.0.1"}} =
             OrbitalDynamics.run_study(study,
               task_supervisor: {OrbitalDynamics.ScenarioSupervisor, :"missing@127.0.0.1"}
             )
  end

  test "task supervisor lists must not be empty" do
    earth = CentralBody.earth()
    study = Study.new!(:empty_supervisors, [scenario(:a, earth)], outputs: [:trajectories])

    assert {:error, {:invalid_option, :task_supervisors}} =
             OrbitalDynamics.run_study(study, task_supervisors: [])
  end

  test "multiple local task supervisors are recorded in run metadata" do
    earth = CentralBody.earth()

    study =
      Study.new!(:local_multi_supervisor, [scenario(:a, earth), scenario(:b, earth)],
        outputs: [:trajectories]
      )

    assert {:ok, result_set} =
             OrbitalDynamics.run_study(study,
               task_supervisors: [
                 OrbitalDynamics.ScenarioSupervisor,
                 OrbitalDynamics.ScenarioSupervisor
               ],
               task_chunk_size: 2,
               max_concurrency: 2
             )

    assert Enum.map(result_set.trajectory_results, & &1.scenario_id) == [:a, :b]
    assert result_set.metadata.run["metadata"]["execution_mode"] == "local_tasks"

    assert result_set.metadata.run["metadata"]["task_supervisor_nodes"] == [
             Atom.to_string(node()),
             Atom.to_string(node())
           ]

    assert result_set.metadata.run["options"]["task_chunk_size"] == 2

    assert result_set.metadata.run["metadata"]["execution_plan"] == %{
             "batch_propagation" => false,
             "batches_per_wave" => 4,
             "chunking_enabled" => true,
             "distribution_mode" => "local_tasks",
             "effective_task_chunk_size" => 2,
             "effective_task_concurrency" => 4,
             "max_concurrency" => 2,
             "requested_task_chunk_size" => 2,
             "resolved_task_chunk_size" => 2,
             "adaptive_chunking" => %{
               "applied_task_chunk_size" => 2,
               "concurrent_task_batches" => 4,
               "policy" => "explicit",
               "reason" => "operator_supplied_task_chunk_size",
               "recommended_task_chunk_size" => 2,
               "requested_task_chunk_size" => 2,
               "supervisor_count" => 2,
               "target_wave_count" => nil
             },
             "resumability" => "not_resumable",
             "scenario_count" => 2,
             "supervisor_count" => 2,
             "task_batch_count" => 1,
             "wave_count" => 1
           }
  end

  test "auto task chunking resolves deterministic distributed execution chunks" do
    earth = CentralBody.earth()

    scenarios = for id <- 1..5, do: scenario(:"auto_#{id}", earth)
    study = Study.new!(:auto_chunked_supervisors, scenarios, outputs: [:trajectories])

    assert {:ok, result_set} =
             OrbitalDynamics.run_study(study,
               task_supervisors: [
                 OrbitalDynamics.ScenarioSupervisor,
                 OrbitalDynamics.ScenarioSupervisor
               ],
               task_chunk_size: :auto,
               max_concurrency: 1
             )

    assert result_set.metadata.run["options"]["task_chunk_size"] == 2

    assert result_set.metadata.run["metadata"]["execution_plan"] == %{
             "batch_propagation" => false,
             "batches_per_wave" => 2,
             "chunking_enabled" => true,
             "distribution_mode" => "local_tasks",
             "effective_task_chunk_size" => 2,
             "effective_task_concurrency" => 2,
             "max_concurrency" => 1,
             "requested_task_chunk_size" => "auto",
             "resolved_task_chunk_size" => 2,
             "adaptive_chunking" => %{
               "applied_task_chunk_size" => 2,
               "concurrent_task_batches" => 2,
               "policy" => "auto",
               "reason" => "target_two_distributed_task_waves",
               "recommended_task_chunk_size" => 2,
               "requested_task_chunk_size" => "auto",
               "supervisor_count" => 2,
               "target_wave_count" => 2
             },
             "resumability" => "not_resumable",
             "scenario_count" => 5,
             "supervisor_count" => 2,
             "task_batch_count" => 3,
             "wave_count" => 2
           }
  end

  test "distributed task supervisors require connected nodes" do
    earth = CentralBody.earth()
    study = Study.new!(:distributed_unavailable, [scenario(:a, earth)], outputs: [:trajectories])

    assert {:error, {:node_unavailable, :"missing@127.0.0.1"}} =
             OrbitalDynamics.run_study(study,
               task_supervisors: [
                 OrbitalDynamics.ScenarioSupervisor,
                 {OrbitalDynamics.ScenarioSupervisor, :"missing@127.0.0.1"}
               ]
             )
  end

  defp scenario(id, earth) do
    Scenario.new!(id, Spacecraft.new!(:"sat_#{id}", 250.0), state({7_000.0, 0.0, 0.0}, earth),
      duration_s: 600.0,
      output_step_s: 60.0,
      central_body: earth
    )
  end

  defp campaign_scenario(id, earth, seconds_since_j2000, scale \\ :utc) do
    velocity_km_s = :math.sqrt(earth.mu_km3_s2 / 7_000.0)

    initial_state =
      StateVector.new!(
        {7_000.0, 0.0, 0.0},
        {0.0, velocity_km_s, 0.0},
        Epoch.new!(seconds_since_j2000, scale),
        Frame.earth_inertial_j2000()
      )

    Scenario.new!(id, Spacecraft.new!(:"sat_#{id}", 250.0), initial_state,
      duration_s: 600.0,
      output_step_s: 60.0,
      central_body: earth
    )
  end

  defp state(position_km, earth) do
    velocity_km_s = :math.sqrt(earth.mu_km3_s2 / 7_000.0)

    StateVector.new!(
      position_km,
      {0.0, velocity_km_s, 0.0},
      Epoch.new!(0.0, :tdb),
      Frame.earth_inertial_j2000()
    )
  end
end
