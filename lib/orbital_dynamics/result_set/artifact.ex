defmodule OrbitalDynamics.ResultSet.Artifact do
  @moduledoc """
  JSON-serializable study result artifact.

  The artifact intentionally stores compact trajectory summaries instead of all
  propagated state samples. Event products and errors are preserved in detail.
  """

  alias OrbitalDynamics.{
    CampaignPlanner,
    CandidateRefresh,
    Environment,
    ManeuverReview,
    OrbitElements,
    Schema
  }

  alias OrbitalDynamics.Constraints.ArtifactMetric

  alias OrbitalDynamics.EventDetectors.{
    AccessWindows,
    Eclipses,
    GroundTrackCrossings,
    TargetVisibility
  }

  alias OrbitalDynamics.ResultSet
  alias OrbitalDynamics.ResultSet.Report
  alias OrbitalDynamics.Search.MonteCarlo
  alias OrbitalDynamics.Validation

  @schema_version 1
  @event_detector_modules %{
    "access_windows" => AccessWindows,
    "eclipses" => Eclipses,
    "ground_track_crossings" => GroundTrackCrossings,
    "target_visibility" => TargetVisibility
  }
  @event_timing_keys [
    :interpolation,
    :boundary_refinement,
    :start_boundary,
    :end_boundary,
    :start_boundary_detail,
    :end_boundary_detail,
    :event_timing_policy,
    :event_detector,
    :event_time_tolerance_s,
    :max_sample_step_s,
    :confidence
  ]

  @doc """
  Builds a JSON-serializable artifact map.
  """
  def build(%ResultSet{} = result_set, opts \\ []) do
    generated_at = Keyword.get_lazy(opts, :generated_at, &DateTime.utc_now/0)

    %{
      schema_version: @schema_version,
      generated_at: DateTime.to_iso8601(generated_at),
      study_id: encode_value(result_set.study_id),
      assumptions: encode_value(artifact_assumptions(result_set)),
      metadata: encode_value(result_metadata(result_set.metadata)),
      trajectories: Enum.map(result_set.trajectory_results, &trajectory_summary/1),
      maneuver_recommendations: maneuver_recommendations(result_set.trajectory_results),
      access_windows: access_windows(result_set.event_results),
      eclipse_intervals: eclipse_intervals(result_set.event_results),
      target_visibility_windows: target_visibility_windows(result_set.event_results),
      ground_track_crossings: ground_track_crossings(result_set.event_results),
      errors: Enum.map(result_set.errors, &encode_value/1)
    }
    |> maybe_add_candidate_refresh(result_set, generated_at)
    |> maybe_add_campaign_plan(result_set, generated_at)
    |> maybe_add_run(result_set.metadata)
    |> add_execution_report(result_set)
    |> maybe_add_monte_carlo_reproducibility_report()
    |> maybe_add_scenario_rankings()
    |> maybe_add_constraint_results()
    |> maybe_add_maneuver_review_report()
    |> add_payload_metrics()
  end

  @doc """
  Writes a result-set artifact as JSON.
  """
  def write_json!(artifact, path) when is_map(artifact) and is_binary(path) do
    path
    |> Path.dirname()
    |> File.mkdir_p!()

    json =
      artifact
      |> encode_value()
      |> :json.encode()
      |> IO.iodata_to_binary()

    File.write!(path, json <> "\n")
    path
  end

  @doc """
  Checks whether an existing result artifact can be reused for a manifest run.

  The preflight validates the saved artifact as `result_artifact.v1`, then
  optionally checks the expected study ID, manifest SHA, and run ID. It does not
  rerun propagation or mutate the artifact.
  """
  def resume_check(path, opts \\ []) when is_binary(path) do
    with {:ok, artifact} <- read_json_artifact(path),
         :ok <- validate_result_artifact_for_resume(artifact),
         :ok <- validate_resume_study_id(artifact, Keyword.get(opts, :study_id)),
         :ok <- validate_resume_manifest_sha(artifact, opts),
         :ok <- validate_resume_run_id(artifact, Keyword.get(opts, :run_id)) do
      {:ok, artifact}
    end
  end

  defp read_json_artifact(path) do
    with {:ok, contents} <- File.read(path),
         {:ok, artifact} <- decode_json_artifact(contents) do
      {:ok, artifact}
    else
      {:error, %{} = reason} -> {:error, reason}
      {:error, reason} -> {:error, %{reason: :read_error, path: path, error: reason}}
    end
  end

  defp decode_json_artifact(contents) when is_binary(contents) do
    {:ok, :json.decode(contents)}
  rescue
    exception ->
      {:error, %{reason: :invalid_json, error: Exception.message(exception)}}
  end

  defp validate_result_artifact_for_resume(%{} = artifact) do
    case Schema.validate_artifact(artifact, contract: "result_artifact.v1") do
      {:ok, _report} -> :ok
      {:error, report} -> {:error, %{reason: :invalid_artifact, errors: report["errors"]}}
    end
  end

  defp validate_result_artifact_for_resume(_artifact),
    do: {:error, %{reason: :invalid_artifact, errors: ["must be a JSON object"]}}

  defp validate_resume_study_id(_artifact, nil), do: :ok

  defp validate_resume_study_id(artifact, expected_study_id) do
    expected = resume_identity(expected_study_id)
    actual = Map.get(artifact, "study_id")

    if actual == expected do
      :ok
    else
      {:error, %{reason: :study_id_mismatch, expected: expected, actual: actual}}
    end
  end

  defp validate_resume_manifest_sha(artifact, opts) do
    case expected_resume_manifest_sha(opts) do
      {:ok, nil} ->
        :ok

      {:ok, expected} ->
        actual = get_in(artifact, ["run", "metadata", "manifest", "sha256"])

        if actual == expected do
          :ok
        else
          {:error, %{reason: :manifest_sha_mismatch, expected: expected, actual: actual}}
        end

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp expected_resume_manifest_sha(opts) do
    cond do
      Keyword.has_key?(opts, :manifest_sha) ->
        {:ok, Keyword.get(opts, :manifest_sha)}

      manifest_path = Keyword.get(opts, :manifest_path) ->
        case File.read(manifest_path) do
          {:ok, contents} ->
            {:ok, Base.encode16(:crypto.hash(:sha256, contents), case: :lower)}

          {:error, error} ->
            {:error, %{reason: :manifest_read_error, path: manifest_path, error: error}}
        end

      true ->
        {:ok, nil}
    end
  end

  defp validate_resume_run_id(_artifact, nil), do: :ok

  defp validate_resume_run_id(artifact, expected_run_id) do
    expected = resume_identity(expected_run_id)
    actual = get_in(artifact, ["run", "id"])

    if actual == expected do
      :ok
    else
      {:error, %{reason: :run_id_mismatch, expected: expected, actual: actual}}
    end
  end

  defp resume_identity(value) when is_atom(value), do: Atom.to_string(value)
  defp resume_identity(value) when is_binary(value), do: value
  defp resume_identity(value), do: to_string(value)

  defp trajectory_summary(%{scenario_id: scenario_id, trajectory: trajectory} = result) do
    states = trajectory.states
    first_state = List.first(states)
    last_state = List.last(states)
    radius_stats = radius_stats(states)
    final_elements = final_orbital_elements(last_state, trajectory.assumptions)

    %{
      scenario_id: encode_value(scenario_id),
      node: encode_value(Map.get(result, :node)),
      sample_count: length(states),
      starts_at_s: epoch_seconds(first_state),
      ends_at_s: epoch_seconds(last_state),
      final_position_km: encode_value(last_state.position_km),
      final_velocity_km_s: encode_value(last_state.velocity_km_s),
      final_radius_km: vector_norm(last_state.position_km),
      final_speed_km_s: vector_norm(last_state.velocity_km_s),
      min_radius_km: radius_stats.min_radius_km,
      max_radius_km: radius_stats.max_radius_km,
      min_altitude_km: altitude(radius_stats.min_radius_km, trajectory.assumptions),
      max_altitude_km: altitude(radius_stats.max_radius_km, trajectory.assumptions),
      semi_major_axis_km: final_elements.semi_major_axis_km,
      eccentricity: final_elements.eccentricity,
      perigee_radius_km: final_elements.perigee_radius_km,
      apogee_radius_km: final_elements.apogee_radius_km,
      perigee_altitude_km: altitude(final_elements.perigee_radius_km, trajectory.assumptions),
      apogee_altitude_km: altitude(final_elements.apogee_radius_km, trajectory.assumptions),
      assumptions: encode_value(trajectory.assumptions)
    }
    |> Map.merge(trajectory_capability_fields(trajectory.assumptions))
  end

  defp trajectory_capability_fields(assumptions) do
    %{
      propagation_backend: get_key(assumptions, :backend) || :scalar_elixir,
      force_model: get_key(assumptions, :force_model),
      numerical_method: get_key(assumptions, :numerical_method),
      validation_level: :educational,
      model_limits: trajectory_model_limits(assumptions)
    }
    |> Enum.reject(fn {_key, value} -> is_nil(value) end)
    |> Map.new(fn {key, value} -> {key, encode_value(value)} end)
  end

  @doc """
  Returns the declared model limits for trajectory summary rows.
  """
  def trajectory_model_limits(assumptions) do
    base_limits = [
      "trajectory_summary_only",
      "state_samples_not_archived",
      "not_flight_certified"
    ]

    force_model_limits =
      case get_key(assumptions, :force_model) do
        :earth_j2 ->
          ["j2_only", "no_drag_model", "no_higher_order_gravity"]

        "earth_j2" ->
          ["j2_only", "no_drag_model", "no_higher_order_gravity"]

        :point_mass_two_body ->
          ["point_mass_gravity_only", "no_perturbation_model"]

        "point_mass_two_body" ->
          ["point_mass_gravity_only", "no_perturbation_model"]

        :point_mass_two_body_atmospheric_drag ->
          OrbitalDynamics.Propagators.TwoBodyDrag.model_limits()

        "point_mass_two_body_atmospheric_drag" ->
          OrbitalDynamics.Propagators.TwoBodyDrag.model_limits()

        _unknown ->
          []
      end

    Enum.uniq(base_limits ++ force_model_limits)
  end

  @doc """
  Returns the declared model limits for event detector result rows.
  """
  def event_detector_model_limits(detector) when is_atom(detector) do
    detector
    |> Atom.to_string()
    |> event_detector_model_limits()
  end

  def event_detector_model_limits(detector) when is_binary(detector) do
    case Map.get(@event_detector_modules, detector) do
      nil -> nil
      module -> model_limits(module)
    end
  end

  def event_detector_model_limits(_detector), do: nil

  defp access_windows(event_results) do
    event_results
    |> Enum.filter(&(&1.event_type == :ground_station_access))
    |> Enum.flat_map(fn result ->
      Enum.map(result.events, fn event ->
        %{
          scenario_id: encode_value(result.scenario_id),
          ground_station_id: encode_value(result.source.ground_station_id),
          starts_at_s: event.starts_at.seconds_since_j2000,
          ends_at_s: event.ends_at.seconds_since_j2000,
          max_elevation_deg: event.metadata.max_elevation_deg,
          minimum_elevation_deg: event.metadata.minimum_elevation_deg,
          sample_count: event.metadata.sample_count,
          model_limits: model_limits(AccessWindows),
          assumptions:
            encode_value(
              Map.take(
                event.metadata,
                [
                  :geometry_model,
                  :refraction,
                  :terrain_mask
                ] ++ @event_timing_keys
              )
            )
        }
        |> Map.merge(detector_capability_fields(AccessWindows))
      end)
    end)
  end

  defp eclipse_intervals(event_results) do
    event_results
    |> Enum.filter(&(&1.event_type == :eclipse))
    |> Enum.flat_map(fn result ->
      Enum.map(result.events, fn event ->
        %{
          scenario_id: encode_value(result.scenario_id),
          starts_at_s: event.starts_at.seconds_since_j2000,
          ends_at_s: event.ends_at.seconds_since_j2000,
          sample_count: event.metadata.sample_count,
          sun_direction: encode_value(event.metadata.sun_direction),
          minimum_shadow_axis_distance_km: event.metadata.minimum_shadow_axis_distance_km,
          maximum_shadow_margin_km: event.metadata.maximum_shadow_margin_km,
          model_limits: model_limits(Eclipses),
          assumptions:
            encode_value(
              Map.take(
                event.metadata,
                [
                  :shadow_model,
                  :central_body,
                  :central_body_radius_km,
                  :interpolation
                ] ++ @event_timing_keys
              )
            )
        }
        |> Map.merge(detector_capability_fields(Eclipses))
      end)
    end)
  end

  defp target_visibility_windows(event_results) do
    event_results
    |> Enum.filter(&(&1.event_type == :target_visibility))
    |> Enum.flat_map(fn result ->
      Enum.map(result.events, fn event ->
        %{
          scenario_id: encode_value(result.scenario_id),
          target_id: encode_value(result.source.target_id),
          starts_at_s: event.starts_at.seconds_since_j2000,
          ends_at_s: event.ends_at.seconds_since_j2000,
          max_elevation_deg: event.metadata.max_elevation_deg,
          minimum_elevation_deg: event.metadata.minimum_elevation_deg,
          target_priority: event.metadata.target_priority,
          sample_count: event.metadata.sample_count,
          model_limits: model_limits(TargetVisibility),
          assumptions:
            encode_value(
              Map.take(
                event.metadata,
                [
                  :geometry_model,
                  :interpolation,
                  :refraction,
                  :terrain_mask
                ] ++ @event_timing_keys
              )
            )
        }
        |> Map.merge(detector_capability_fields(TargetVisibility))
      end)
    end)
  end

  defp ground_track_crossings(event_results) do
    event_results
    |> Enum.filter(&(&1.event_type == :ground_track_crossing))
    |> Enum.flat_map(fn result ->
      Enum.map(result.events, fn event ->
        %{
          scenario_id: encode_value(result.scenario_id),
          request_id: encode_value(Map.get(result.source, :request_id)),
          event_type: encode_value(event.type),
          crossing: encode_value(result.source.crossing),
          target_deg: result.source.target_deg,
          frame: encode_value(result.source.frame),
          starts_at_s: event.starts_at.seconds_since_j2000,
          crossing_direction: encode_value(event.metadata.crossing_direction),
          start_sample_index: Map.get(event.metadata, :start_sample_index),
          end_sample_index: Map.get(event.metadata, :end_sample_index),
          sample_index: Map.get(event.metadata, :sample_index),
          model_limits: model_limits(GroundTrackCrossings),
          assumptions:
            encode_value(
              Map.take(
                event.metadata,
                [
                  :coordinate_model,
                  :earth_rotation_provider,
                  :earth_rotation_provider_id,
                  :earth_rotation_model,
                  :earth_rotation_rate_rad_s,
                  :earth_rotation_interpolation,
                  :before_earth_rotation_angle_rad,
                  :after_earth_rotation_angle_rad,
                  :rotation_epoch_s,
                  :rotation_angle_offset_rad,
                  :interpolation
                ] ++ @event_timing_keys
              )
              |> Enum.reject(fn {_key, value} -> is_nil(value) end)
              |> Map.new()
            )
        }
        |> Map.merge(detector_capability_fields(GroundTrackCrossings))
        |> Enum.reject(fn {_key, value} -> is_nil(value) end)
        |> Map.new()
      end)
    end)
  end

  defp model_limits(module) do
    module.capabilities()
    |> Map.fetch!(:known_limits)
    |> Enum.map(&Atom.to_string/1)
  end

  defp detector_capability_fields(module) do
    capabilities = module.capabilities()

    %{
      event_detector: Map.get(capabilities, :detector),
      event_model: Map.get(capabilities, :model),
      validation_level: Map.get(capabilities, :validation_level),
      timing_policy: Map.get(capabilities, :timing_policy),
      interpolation: Map.get(capabilities, :interpolation),
      boundary_refinement: Map.get(capabilities, :boundary_refinement)
    }
    |> Enum.reject(fn {_key, value} -> is_nil(value) end)
    |> Map.new(fn {key, value} -> {key, encode_value(value)} end)
  end

  defp maneuver_recommendations(trajectory_results) do
    trajectory_results
    |> Enum.flat_map(fn result ->
      scenario_id = encode_value(Map.get(result, :scenario_id))
      assumptions = result.trajectory.assumptions
      maneuver_model = get_key(assumptions, :maneuver_model)

      assumptions
      |> get_key(:maneuvers)
      |> List.wrap()
      |> Enum.map(&maneuver_recommendation(scenario_id, &1, maneuver_model))
    end)
    |> Enum.sort_by(&{&1["scenario_id"], &1["epoch_s"], &1["id"]})
  end

  defp maneuver_recommendation(scenario_id, maneuver, maneuver_model) do
    maneuver = encode_value(maneuver)

    %{
      "schema_contract" => "maneuver_recommendation.v1",
      "id" => Map.fetch!(maneuver, "id"),
      "scenario_id" => scenario_id,
      "type" => Map.get(maneuver, "type", "impulsive_burn"),
      "epoch_s" => Map.fetch!(maneuver, "epoch_s"),
      "epoch_scale" => Map.get(maneuver, "epoch_scale"),
      "frame" => Map.get(maneuver, "frame"),
      "delta_v_km_s" => Map.fetch!(maneuver, "delta_v_km_s"),
      "delta_v_magnitude_km_s" => Map.get(maneuver, "delta_v_magnitude_km_s"),
      "maneuver_model" => encode_value(maneuver_model || "impulsive_burns"),
      "validation_level" => "artifact_contract",
      "model_limits" => ManeuverReview.recommendation_model_limits(),
      "assumptions" => %{
        "source" => "trajectory_assumptions",
        "execution_boundary" => "recommendation_only_no_command_execution"
      }
    }
    |> Enum.reject(fn {_key, value} -> is_nil(value) end)
    |> Map.new()
  end

  defp maybe_add_maneuver_review_report(%{maneuver_recommendations: []} = artifact),
    do: artifact

  defp maybe_add_maneuver_review_report(%{maneuver_recommendations: recommendations} = artifact) do
    Map.put(
      artifact,
      :maneuver_review_report,
      ManeuverReview.report(recommendations,
        source: "result_set_artifact.maneuver_recommendations",
        source_artifact_id: artifact.study_id
      )
    )
  end

  defp maybe_add_campaign_plan(
         %{assumptions: %{"study_metadata" => %{"campaign" => campaign}}} = artifact,
         result_set,
         generated_at
       )
       when is_map(campaign) do
    Map.put(
      artifact,
      :campaign_plan,
      CampaignPlanner.build(result_set, campaign: campaign, generated_at: generated_at)
    )
  end

  defp maybe_add_campaign_plan(artifact, _result_set, _generated_at), do: artifact

  defp maybe_add_candidate_refresh(
         %{assumptions: %{"study_metadata" => %{"candidate_refresh" => candidate_refresh}}} =
           artifact,
         result_set,
         generated_at
       )
       when is_map(candidate_refresh) do
    Map.put(
      artifact,
      :candidate_refresh,
      CandidateRefresh.build(result_set,
        candidate_refresh: candidate_refresh,
        generated_at: generated_at
      )
    )
  end

  defp maybe_add_candidate_refresh(artifact, _result_set, _generated_at), do: artifact

  defp maybe_add_run(artifact, %{run: run}), do: Map.put(artifact, :run, encode_value(run))
  defp maybe_add_run(artifact, %{"run" => run}), do: Map.put(artifact, :run, encode_value(run))
  defp maybe_add_run(artifact, _metadata), do: artifact

  defp add_execution_report(artifact, %ResultSet{} = result_set) do
    run = encoded_run(result_set.metadata)
    run_metadata = Map.get(run || %{}, "metadata", %{})
    errors = Enum.map(result_set.errors, &encode_value/1)
    completed_scenario_count = length(result_set.trajectory_results)
    failed_scenario_count = length(errors)
    model_limits = execution_report_model_limits(run_metadata)
    assumptions = execution_report_assumptions(run_metadata)

    Map.put(artifact, :execution_report, %{
      schema_contract: "execution_report.v1",
      study_id: encode_value(result_set.study_id),
      run_id: Map.get(run || %{}, "id"),
      status: execution_status(run, completed_scenario_count, failed_scenario_count),
      execution_mode: Map.get(run_metadata, "execution_mode"),
      backend: Map.get(run || %{}, "backend"),
      node: Map.get(run || %{}, "node"),
      scenario_count: Map.get(run_metadata, "scenario_count"),
      completed_scenario_count: completed_scenario_count,
      failed_scenario_count: failed_scenario_count,
      event_result_count: length(result_set.event_results),
      model_limits: model_limits,
      batch_propagation: Map.get(run_metadata, "batch_propagation"),
      task_chunk_size: get_in(run || %{}, ["options", "task_chunk_size"]),
      timeout: get_in(run || %{}, ["options", "timeout"]),
      effective_task_concurrency: Map.get(run_metadata, "effective_task_concurrency"),
      task_supervisor_node: Map.get(run_metadata, "task_supervisor_node"),
      task_supervisor_nodes: Map.get(run_metadata, "task_supervisor_nodes"),
      phase_timings_ms: Map.get(run_metadata, "phase_timings_ms", %{}),
      execution_plan: Map.get(run_metadata, "execution_plan", %{}),
      node_distribution:
        node_distribution(result_set.trajectory_results, errors, Map.get(run || %{}, "node")),
      failed_scenarios: failed_scenarios(errors),
      assumptions: assumptions
    })
  end

  @doc """
  Returns the declared model limits for execution summary reports.
  """
  def execution_report_model_limits do
    [
      "artifact_level_execution_summary",
      "not_resumable",
      "no_persistent_queue",
      "failed_scenarios_are_reported_not_retried"
    ]
  end

  @doc """
  Returns the declared model limits for an explicit failed-scenario retry batch.
  """
  def retry_execution_report_model_limits do
    [
      "artifact_level_execution_summary",
      "failed_scenario_retry_batch",
      "no_checkpoint_resume",
      "no_persistent_queue",
      "source_results_are_not_merged",
      "failed_scenarios_are_not_automatically_retried"
    ]
  end

  @doc """
  Returns the exact execution-report model limits for a report or run metadata map.
  """
  def execution_report_model_limits(report_or_run_metadata) when is_map(report_or_run_metadata) do
    if failed_scenario_retry?(report_or_run_metadata) do
      retry_execution_report_model_limits()
    else
      execution_report_model_limits()
    end
  end

  @doc """
  Returns every execution-report model-limit value accepted by JSON Schema.
  """
  def execution_report_model_limit_values do
    Enum.uniq(execution_report_model_limits() ++ retry_execution_report_model_limits())
  end

  defp execution_report_assumptions(run_metadata) do
    assumptions = %{
      backend_selection_policy: Map.get(run_metadata, "backend_selection_policy"),
      external_provider_policy: Map.get(run_metadata, "external_provider_policy"),
      source: "study_run_metadata",
      purpose: "failure_isolation_and_long_running_execution_review",
      resumability: "not_resumable"
    }

    if failed_scenario_retry?(run_metadata) do
      Map.merge(assumptions, %{
        resumability: "failed_scenario_retry",
        retry_scope: "failed_scenarios_only",
        checkpoint_resume: false,
        source_results_merged: false,
        persistent_queue: false,
        automatic_retry: false
      })
    else
      assumptions
    end
  end

  defp failed_scenario_retry?(report_or_run_metadata) do
    execution_plan =
      Map.get(report_or_run_metadata, "execution_plan") ||
        Map.get(report_or_run_metadata, :execution_plan) || %{}

    resumability =
      Map.get(execution_plan, "resumability") || Map.get(execution_plan, :resumability)

    resumability == "failed_scenario_retry"
  end

  defp encoded_run(%{run: run}), do: encode_value(run)
  defp encoded_run(%{"run" => run}), do: encode_value(run)
  defp encoded_run(_metadata), do: nil

  defp maybe_add_monte_carlo_reproducibility_report(
         %{assumptions: %{"study_metadata" => %{"monte_carlo" => monte_carlo}}} = artifact
       )
       when is_map(monte_carlo) do
    capabilities = MonteCarlo.capabilities()
    generated_scenario_ids = generated_scenario_ids(artifact)

    report =
      %{
        schema_contract: "monte_carlo_reproducibility_report.v1",
        model: Atom.to_string(capabilities.model),
        source: "study_metadata.monte_carlo",
        generator: Map.get(monte_carlo, "generator"),
        rng: Atom.to_string(capabilities.rng),
        sampling_method: Atom.to_string(capabilities.sampling_method),
        deterministic_seed: capabilities.deterministic_seed,
        seed: Map.get(monte_carlo, "seed"),
        requested_count: Map.get(monte_carlo, "count"),
        generated_scenario_count: length(generated_scenario_ids),
        id_prefix: Map.get(monte_carlo, "id_prefix"),
        generated_scenario_ids: generated_scenario_ids,
        position_sigma_km: Map.get(monte_carlo, "position_sigma_km"),
        velocity_sigma_km_s: Map.get(monte_carlo, "velocity_sigma_km_s"),
        seed_manifest: Map.get(artifact.assumptions, "seed_manifest", %{}),
        assumptions: %{
          scenario_id_order: "artifact.trajectories order",
          base_scenario: "monte_carlo.base_scenario",
          distribution: "independent normal per Cartesian component",
          covariance_model: "none"
        },
        known_limits: Enum.map(capabilities.known_limits, &Atom.to_string/1),
        model_limits: Enum.map(capabilities.known_limits, &Atom.to_string/1)
      }
      |> Enum.reject(fn {_key, value} -> is_nil(value) end)
      |> Map.new()

    Map.put(artifact, :monte_carlo_reproducibility_report, report)
  end

  defp maybe_add_monte_carlo_reproducibility_report(artifact), do: artifact

  defp generated_scenario_ids(artifact) do
    artifact
    |> Map.get(:trajectories, [])
    |> Enum.map(fn trajectory ->
      Map.get(trajectory, :scenario_id) || Map.get(trajectory, "scenario_id")
    end)
    |> Enum.reject(&is_nil/1)
  end

  defp execution_status(_run, _completed_scenario_count, 0), do: "completed"

  defp execution_status(_run, 0, failed_scenario_count) when failed_scenario_count > 0,
    do: "failed"

  defp execution_status(%{"status" => status}, _completed_scenario_count, _failed_scenario_count)
       when is_binary(status) and status not in ["completed"],
       do: status

  defp execution_status(_run, _completed_scenario_count, _failed_scenario_count),
    do: "completed_with_errors"

  defp node_distribution(trajectory_results, errors, fallback_node) do
    trajectory_nodes = Enum.map(trajectory_results, &Map.get(&1, :node))
    error_nodes = Enum.map(errors, &(Map.get(&1, "node") || fallback_node || "unknown"))

    (trajectory_nodes ++ error_nodes)
    |> Enum.reject(&is_nil/1)
    |> Enum.map(&encode_value/1)
    |> Enum.frequencies()
  end

  defp failed_scenarios(errors) do
    Enum.map(errors, fn error ->
      %{
        scenario_id: Map.get(error, "scenario_id"),
        scenario_index: Map.get(error, "scenario_index"),
        stage: Map.get(error, "stage"),
        error: Map.get(error, "error"),
        node: Map.get(error, "node"),
        resumability: "manual_rerun_only",
        retry_recommendation: "rerun_failed_scenario_from_source_manifest"
      }
      |> Enum.reject(fn {_key, value} -> is_nil(value) end)
      |> Map.new()
    end)
  end

  defp result_metadata(%{} = metadata) do
    metadata
    |> Map.delete(:run)
    |> Map.delete("run")
  end

  defp maybe_add_scenario_rankings(
         %{assumptions: %{"study_metadata" => study_metadata}} = artifact
       ) do
    case ranking_metadata(study_metadata) do
      %{"objective" => objective} = ranking when is_binary(objective) ->
        rank_limit = Map.get(ranking, "rank_limit", 10)

        rows =
          artifact
          |> encode_value()
          |> Report.rank(objective, limit: rank_limit)

        capabilities = Report.capabilities()

        Map.put(artifact, :scenario_rankings, %{
          objective: objective,
          objective_direction:
            Map.get(ranking, "objective_direction", Report.objective_direction_label(objective)),
          rank_limit: rank_limit,
          model: encode_value(capabilities.model),
          source: ranking_source(study_metadata),
          validation_level: encode_value(capabilities.validation_level),
          model_limits: Report.model_limits(),
          assumptions: %{
            source: ranking_metadata_source(study_metadata),
            ranking_boundary: "artifact_level_only_no_rerun_propagation",
            missing_metric_policy: "missing_metric_rows_are_excluded_from_rankings"
          },
          rows: rows
        })

      _ranking ->
        artifact
    end
  end

  defp maybe_add_scenario_rankings(artifact), do: artifact

  defp ranking_metadata(%{"search" => %{"objective" => _objective} = search}), do: search

  defp ranking_metadata(%{"monte_carlo" => %{"objective" => _objective} = monte_carlo}),
    do: monte_carlo

  defp ranking_metadata(_study_metadata), do: nil

  defp ranking_source(%{"search" => %{"objective" => _objective}}),
    do: "result_set_artifact.study_metadata.search"

  defp ranking_source(%{"monte_carlo" => %{"objective" => _objective}}),
    do: "result_set_artifact.study_metadata.monte_carlo"

  defp ranking_source(_study_metadata), do: "result_set_artifact.study_metadata"

  defp ranking_metadata_source(%{"search" => %{"objective" => _objective}}),
    do: "study_metadata.search"

  defp ranking_metadata_source(%{"monte_carlo" => %{"objective" => _objective}}),
    do: "study_metadata.monte_carlo"

  defp ranking_metadata_source(_study_metadata), do: "study_metadata"

  defp maybe_add_constraint_results(
         %{assumptions: %{"study_metadata" => %{"constraints" => constraints}}} = artifact
       )
       when is_list(constraints) do
    {:ok, rows} =
      artifact
      |> encode_value()
      |> ArtifactMetric.evaluate_all(constraints)

    {:ok, report} =
      artifact
      |> encode_value()
      |> ArtifactMetric.report(constraints)

    artifact
    |> Map.put(:constraint_results, rows)
    |> Map.put(:constraint_report, report)
  end

  defp maybe_add_constraint_results(artifact), do: artifact

  defp add_payload_metrics(artifact) do
    encoded_artifact = json_bytes(artifact)

    Map.put(artifact, :payload_metrics, %{
      schema_contract: "result_payload_metrics.v1",
      encoding: "erlang_json_compact_utf8",
      artifact_body_bytes: encoded_artifact,
      top_level_key_count: map_size(artifact),
      sections:
        artifact
        |> Enum.sort_by(fn {key, _value} -> encode_key(key) end)
        |> Map.new(fn {key, value} ->
          {encode_key(key),
           %{
             bytes: json_bytes(value),
             row_count: payload_row_count(value)
           }}
        end)
    })
  end

  defp json_bytes(value) do
    value
    |> encode_value()
    |> :json.encode()
    |> IO.iodata_to_binary()
    |> byte_size()
  end

  defp payload_row_count(value) when is_list(value), do: length(value)

  defp payload_row_count(%{} = value) do
    case value do
      %{rows: rows} when is_list(rows) -> length(rows)
      %{"rows" => rows} when is_list(rows) -> length(rows)
      _value -> :null
    end
  end

  defp payload_row_count(_value), do: :null

  defp artifact_assumptions(%ResultSet{} = result_set) do
    validations = Validation.records_for_result_set(result_set)
    environment_models = Environment.records_for_result_set(result_set)

    result_set.assumptions
    |> maybe_put_assumption("model_validation", validations)
    |> maybe_put_assumption("environment_models", environment_models)
  end

  defp maybe_put_assumption(assumptions, _key, []), do: assumptions
  defp maybe_put_assumption(assumptions, key, values), do: Map.put(assumptions, key, values)

  defp epoch_seconds(nil), do: nil
  defp epoch_seconds(state), do: state.epoch.seconds_since_j2000

  defp radius_stats([]), do: %{min_radius_km: nil, max_radius_km: nil}

  defp radius_stats(states) do
    radii = Enum.map(states, &vector_norm(&1.position_km))

    %{
      min_radius_km: Enum.min(radii),
      max_radius_km: Enum.max(radii)
    }
  end

  defp final_orbital_elements(nil, _assumptions) do
    %{
      semi_major_axis_km: nil,
      eccentricity: nil,
      perigee_radius_km: nil,
      apogee_radius_km: nil
    }
  end

  defp final_orbital_elements(state, assumptions) do
    with mu_km3_s2 when is_number(mu_km3_s2) <- Map.get(assumptions, :mu_km3_s2),
         {:ok, %OrbitElements{orbit_class: :elliptic} = elements} <-
           OrbitElements.from_state(state, mu_km3_s2) do
      %{
        semi_major_axis_km: elements.semi_major_axis_km,
        eccentricity: elements.eccentricity,
        perigee_radius_km: elements.perigee_radius_km,
        apogee_radius_km: elements.apogee_radius_km
      }
    else
      _not_available ->
        %{
          semi_major_axis_km: nil,
          eccentricity: nil,
          perigee_radius_km: nil,
          apogee_radius_km: nil
        }
    end
  end

  defp altitude(nil, _assumptions), do: nil

  defp altitude(radius_km, assumptions) when is_number(radius_km) do
    case Map.get(assumptions, :equatorial_radius_km) do
      body_radius_km when is_number(body_radius_km) -> radius_km - body_radius_km
      _missing_radius -> nil
    end
  end

  defp vector_norm({x, y, z}), do: :math.sqrt(x * x + y * y + z * z)

  defp get_key(%{} = map, key) when is_atom(key),
    do: Map.get(map, key) || Map.get(map, Atom.to_string(key))

  defp get_key(_map, _key), do: nil

  defp encode_value(values) when is_list(values) do
    if values != [] and Keyword.keyword?(values) do
      Map.new(values, fn {key, value} -> {encode_key(key), encode_value(value)} end)
    else
      Enum.map(values, &encode_value/1)
    end
  end

  defp encode_value(value) when is_map(value) do
    Map.new(value, fn {key, value} -> {encode_key(key), encode_value(value)} end)
  end

  defp encode_value(nil), do: :null
  defp encode_value(:null), do: :null
  defp encode_value(value) when is_boolean(value), do: value
  defp encode_value(value) when is_atom(value), do: Atom.to_string(value)
  defp encode_value(value) when is_tuple(value), do: value |> Tuple.to_list() |> encode_value()
  defp encode_value(value), do: value

  defp encode_key(key) when is_atom(key), do: Atom.to_string(key)
  defp encode_key(key) when is_binary(key), do: key
  defp encode_key(key), do: inspect(key)
end
