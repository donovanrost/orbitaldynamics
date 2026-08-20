defmodule OrbitalDynamics.EventDetectors.GroundTrackCrossings do
  @moduledoc """
  Sampled latitude and longitude crossing detection.

  This detector uses geocentric spherical coordinates from the trajectory's
  Cartesian position. By default longitude is evaluated in the inertial frame.
  Passing `frame: :body_fixed` applies the same constant Earth-rotation
  approximation used by access geometry. Crossing epochs are linearly
  interpolated between adjacent samples that bracket the requested latitude or
  longitude.
  """

  alias OrbitalDynamics.{Environment, EventTiming, StateVector, Trajectory}
  alias OrbitalDynamics.Environment.CampaignEnvironmentProvider

  @behaviour OrbitalDynamics.EventDetector
  @earth_rotation_rate_rad_s 7.2921150e-5
  @campaign_ground_track_known_limits [
    :sample_cadence_limited,
    :geocentric_spherical_coordinates,
    :earth_rotation_from_era_and_tabular_ut1_utc,
    :direct_era_rotation_from_eci_j2000_approximation,
    :no_cirs_or_precession_nutation_transform,
    :no_polar_motion_application,
    :no_tirs_claim,
    :refinement_not_root_solved
  ]

  @doc """
  Declares the detector model, timing policy, and known limits.
  """
  @impl OrbitalDynamics.EventDetector
  def capabilities do
    %{
      detector: :ground_track_crossings,
      model: :sampled_geocentric_ground_track_crossing,
      validation_level: :analysis,
      timing_policy: :sampled_state_linear_boundary,
      interpolation: :linear_sample_crossing,
      boundary_refinement: :ground_track_linear_margin_interpolation,
      supported_frames: [:inertial, :body_fixed],
      coordinate_models: [
        :geocentric_spherical_inertial,
        :geocentric_spherical_body_fixed_constant_rotation,
        :geocentric_spherical_body_fixed_configured_constant_rotation,
        :geocentric_spherical_body_fixed_provider_rotation
      ],
      supported_body_fixed_rotation_options: [
        :rotation_rate_rad_s,
        :rotation_epoch_s,
        :rotation_angle_offset_rad,
        :earth_rotation_provider
      ],
      known_limits: [
        :sample_cadence_limited,
        :geocentric_spherical_coordinates,
        :constant_earth_rotation_body_fixed,
        :configured_constant_rotation_only,
        :refinement_not_root_solved,
        :no_earth_orientation_parameters
      ]
    }
  end

  @doc false
  def validate_earth_rotation_provider(provider, request) when is_map(request) do
    with {:ok, rotation} <- provider_rotation_model(provider),
         true <- Environment.provider_supports_request?(rotation.provider_capability, request),
         :ok <- preflight_provider_products(rotation, request) do
      :ok
    else
      false -> {:error, {:environment_provider_request_mismatch, request}}
      {:error, reason} -> {:error, reason}
    end
  end

  def validate_earth_rotation_provider(_provider, _request),
    do: {:error, {:invalid_option, :earth_rotation_provider}}

  @impl OrbitalDynamics.EventDetector
  def detect(%Trajectory{} = trajectory, opts \\ []) do
    with {:ok, crossing} <- crossing_option(Keyword.get(opts, :crossing, :latitude)),
         {:ok, target_deg} <- target_deg(crossing, opts),
         :ok <- validate_target(crossing, target_deg),
         {:ok, frame} <- reference_frame(opts),
         {:ok, rotation} <- rotation_model(frame, opts),
         :ok <- validate_campaign_evidence_option(opts, rotation),
         {:ok, samples} <- samples(trajectory, crossing, target_deg, frame, rotation) do
      {:ok,
       samples
       |> Enum.chunk_every(2, 1, :discard)
       |> Enum.flat_map(&crossing_event(&1, crossing, target_deg, trajectory, frame, rotation))
       |> Enum.map(&EventTiming.annotate_event(&1, trajectory, :ground_track_crossings))}
    end
  end

  @doc """
  Refines one bracketed latitude or longitude crossing boundary between two samples.

  The refinement uses the same geocentric latitude/longitude margin and linear
  interpolation model as `detect/2`. It is useful for artifact metadata and
  coarse ground-track timing; it is not a root-solved event time.
  """
  def refine_crossing_boundary(
        %StateVector{} = before_state,
        %StateVector{} = after_state,
        opts \\ []
      ) do
    with {:ok, crossing} <- crossing_option(Keyword.get(opts, :crossing, :latitude)),
         {:ok, target_deg} <- target_deg(crossing, opts),
         :ok <- validate_target(crossing, target_deg),
         {:ok, frame} <- reference_frame(opts),
         {:ok, rotation} <- rotation_model(frame, opts),
         :ok <- validate_campaign_evidence_option(opts, rotation),
         {:ok, before} <-
           ground_track_sample(before_state, 0, crossing, target_deg, frame, rotation),
         {:ok, after_sample} <-
           ground_track_sample(after_state, 1, crossing, target_deg, frame, rotation) do
      before_margin = before.margin_deg
      after_margin = unwrap_margin(after_sample.margin_deg, before_margin)

      if bracketed_boundary?(before_margin, after_margin) do
        fraction = interpolation_fraction(before_margin, after_margin)

        {:ok,
         %{
           boundary: crossing_type(crossing),
           crossing: crossing,
           crossing_direction: crossing_direction(crossing, before_margin, after_margin),
           epoch: interpolate_epoch(before_state.epoch, after_state.epoch, fraction),
           interpolation: :linear_sample_crossing,
           interpolation_fraction: fraction,
           target_deg: target_deg,
           before_margin_deg: before_margin,
           after_margin_deg: after_margin,
           before_latitude_deg: before.latitude_deg,
           before_longitude_deg: before.longitude_deg,
           after_latitude_deg: after_sample.latitude_deg,
           after_longitude_deg: after_sample.longitude_deg,
           assumptions:
             EventTiming.boundary_policy(before_state.epoch, after_state.epoch)
             |> Map.merge(%{
               refinement_model: :ground_track_linear_margin_interpolation,
               coordinate_model: coordinate_model(frame, rotation),
               frame: frame
             })
             |> Map.merge(rotation_assumptions(frame, rotation, before, after_sample))
         }}
      else
        {:error, :not_bracketed}
      end
    end
  end

  defp crossing_option(crossing) when crossing in [:latitude, "latitude"], do: {:ok, :latitude}
  defp crossing_option(crossing) when crossing in [:longitude, "longitude"], do: {:ok, :longitude}
  defp crossing_option(other), do: {:error, {:unsupported_crossing, other}}

  defp target_deg(:latitude, opts), do: required_number(opts, :latitude_deg)
  defp target_deg(:longitude, opts), do: required_number(opts, :longitude_deg)

  defp validate_target(:latitude, target) when target >= -90.0 and target <= 90.0, do: :ok
  defp validate_target(:latitude, _target), do: {:error, {:invalid_option, :latitude_deg}}

  defp validate_target(:longitude, target) when target >= -180.0 and target <= 180.0, do: :ok
  defp validate_target(:longitude, _target), do: {:error, {:invalid_option, :longitude_deg}}

  defp required_number(opts, key) do
    case Keyword.get(opts, key) do
      value when is_integer(value) or is_float(value) -> {:ok, value * 1.0}
      _value -> {:error, {:missing_option, key}}
    end
  end

  defp reference_frame(opts) do
    case Keyword.get(opts, :frame, :inertial) do
      frame when frame in [:inertial, "inertial"] -> {:ok, :inertial}
      frame when frame in [:body_fixed, "body_fixed"] -> {:ok, :body_fixed}
      _frame -> {:error, {:invalid_option, :frame}}
    end
  end

  defp rotation_model(:inertial, _opts), do: {:ok, nil}

  defp rotation_model(:body_fixed, opts) do
    case Keyword.fetch(opts, :earth_rotation_provider) do
      {:ok, provider} ->
        provider_rotation_model(provider)

      :error ->
        with {:ok, rotation_rate_rad_s} <-
               optional_number(opts, :rotation_rate_rad_s, @earth_rotation_rate_rad_s),
             {:ok, rotation_epoch_s} <- optional_number(opts, :rotation_epoch_s, 0.0),
             {:ok, rotation_angle_offset_rad} <-
               optional_number(opts, :rotation_angle_offset_rad, 0.0) do
          {:ok,
           %{
             mode: :constant_rate,
             rotation_rate_rad_s: rotation_rate_rad_s,
             rotation_epoch_s: rotation_epoch_s,
             rotation_angle_offset_rad: rotation_angle_offset_rad,
             configured?:
               rotation_rate_rad_s != @earth_rotation_rate_rad_s or rotation_epoch_s != 0.0 or
                 rotation_angle_offset_rad != 0.0
           }}
        end
    end
  end

  defp provider_rotation_model(provider) when is_atom(provider) do
    provider_rotation_model({provider, []})
  end

  defp provider_rotation_model({provider, provider_opts}) when is_atom(provider) do
    with true <- Code.ensure_loaded?(provider),
         true <- function_exported?(provider, :fetch, 2),
         true <- function_exported?(provider, :capabilities, 0),
         true <- Keyword.keyword?(provider_opts) do
      configured_provider_rotation_model(provider, provider_opts)
    else
      false -> {:error, {:invalid_option, :earth_rotation_provider}}
      {:error, reason} -> {:error, reason}
    end
  end

  defp provider_rotation_model(_provider),
    do: {:error, {:invalid_option, :earth_rotation_provider}}

  defp configured_provider_rotation_model(CampaignEnvironmentProvider, provider_opts) do
    with {:ok, configuration} <-
           CampaignEnvironmentProvider.trusted_configuration(provider_opts) do
      {:ok,
       %{
         mode: :provider,
         provider: CampaignEnvironmentProvider,
         provider_opts: configuration.provider_opts,
         provider_capability: configuration.capability,
         provider_provenance: configuration.provenance,
         trusted_campaign?: true,
         configured?: true
       }}
    end
  end

  defp configured_provider_rotation_model(provider, provider_opts) do
    with false <- CampaignEnvironmentProvider.reserved_evidence?(provider_opts),
         {:ok, provider_capability} <-
           Environment.configured_provider_capability(provider, provider_opts),
         false <- CampaignEnvironmentProvider.reserved_evidence?(provider_capability),
         :ok <- validate_capability_module_binding(provider, provider_capability) do
      {:ok,
       %{
         mode: :provider,
         provider: provider,
         provider_opts: provider_opts,
         provider_capability: provider_capability,
         trusted_campaign?: false,
         configured?: true
       }}
    else
      true -> {:error, {:untrusted_campaign_environment_provider, provider}}
      {:error, reason} -> {:error, reason}
    end
  end

  defp validate_capability_module_binding(provider, configured_capability) do
    base_capability = provider.capabilities()

    stable_keys = [
      "id",
      "schema_contract",
      "category",
      "model",
      "validation_level",
      "interpolation",
      "supported_bodies",
      "supported_frames",
      "supported_time_scales",
      "network_access",
      "outputs",
      "known_limits"
    ]

    case Enum.find(stable_keys, fn key ->
           Map.get(configured_capability, key) != Map.get(base_capability, key)
         end) do
      nil -> :ok
      key -> {:error, {:environment_provider_capability_mismatch, provider, key}}
    end
  rescue
    _exception -> {:error, {:invalid_option, :earth_rotation_provider}}
  end

  defp preflight_provider_products(rotation, request) do
    request
    |> provider_request_epochs()
    |> Enum.reduce_while(:ok, fn seconds_since_j2000, :ok ->
      case provider_rotation_product(rotation, seconds_since_j2000) do
        {:ok, _product} -> {:cont, :ok}
        {:error, reason} -> {:halt, {:error, reason}}
      end
    end)
  end

  defp provider_request_epochs(request) do
    [
      Map.get(request, :starts_at_s) || Map.get(request, "starts_at_s"),
      Map.get(request, :ends_at_s) || Map.get(request, "ends_at_s")
    ]
    |> Enum.filter(&is_number/1)
    |> Enum.uniq()
  end

  defp optional_number(opts, key, default) do
    case Keyword.get(opts, key, default) do
      value when is_integer(value) or is_float(value) -> {:ok, value * 1.0}
      _value -> {:error, {:invalid_option, key}}
    end
  end

  defp validate_campaign_evidence_option(opts, %{trusted_campaign?: true} = rotation) do
    case Keyword.fetch(opts, :campaign_environment) do
      :error -> :ok
      {:ok, evidence} when evidence == rotation.provider_provenance -> :ok
      {:ok, _evidence} -> {:error, {:campaign_environment_provenance_mismatch, :ground_track}}
    end
  end

  defp validate_campaign_evidence_option(opts, _rotation) do
    if Keyword.has_key?(opts, :campaign_environment) do
      {:error, {:untrusted_campaign_environment_evidence, :ground_track}}
    else
      :ok
    end
  end

  defp samples(%Trajectory{} = trajectory, crossing, target_deg, frame, rotation) do
    trajectory.states
    |> Enum.with_index()
    |> Enum.reduce_while({:ok, []}, fn {state, index}, {:ok, acc} ->
      case ground_track_sample(state, index, crossing, target_deg, frame, rotation) do
        {:ok, sample} -> {:cont, {:ok, [sample | acc]}}
        {:error, reason} -> {:halt, {:error, reason}}
      end
    end)
    |> case do
      {:ok, values} -> {:ok, Enum.reverse(values)}
      {:error, reason} -> {:error, reason}
    end
  end

  defp ground_track_sample(state, index, crossing, target_deg, frame, rotation) do
    with {:ok, latitude_deg, longitude_deg, rotation_metadata} <-
           geocentric_lat_lon(
             state.position_km,
             state.epoch.seconds_since_j2000,
             frame,
             rotation
           ) do
      value_deg =
        case crossing do
          :latitude -> latitude_deg
          :longitude -> longitude_deg
        end

      {:ok,
       %{
         index: index,
         state: state,
         latitude_deg: latitude_deg,
         longitude_deg: longitude_deg,
         value_deg: value_deg,
         margin_deg: margin_deg(crossing, value_deg, target_deg),
         rotation_metadata: rotation_metadata
       }}
    end
  end

  defp geocentric_lat_lon(position_km, seconds_since_j2000, frame, rotation) do
    with {:ok, {x, y, z}, rotation_metadata} <-
           position_for_frame(position_km, seconds_since_j2000, frame, rotation) do
      radius = :math.sqrt(x * x + y * y + z * z)

      if radius > 0.0 do
        latitude_deg = radians_to_degrees(:math.asin(z / radius))
        longitude_deg = normalize_longitude(radians_to_degrees(:math.atan2(y, x)))
        {:ok, latitude_deg, longitude_deg, rotation_metadata}
      else
        {:error, {:invalid_trajectory, :zero_position}}
      end
    end
  end

  defp position_for_frame(position_km, _seconds_since_j2000, :inertial, _rotation),
    do: {:ok, position_km, %{}}

  defp position_for_frame(
         position_km,
         seconds_since_j2000,
         :body_fixed,
         %{mode: :constant_rate} = rotation
       ) do
    rotate_z(position_km, -earth_rotation_angle(seconds_since_j2000, rotation))
    |> then(&{:ok, &1, %{}})
  end

  defp position_for_frame(
         position_km,
         seconds_since_j2000,
         :body_fixed,
         %{mode: :provider} = rotation
       ) do
    with {:ok, angle_rad, metadata} <-
           provider_rotation_angle(rotation, seconds_since_j2000) do
      {:ok, rotate_z(position_km, -angle_rad), metadata}
    end
  end

  defp crossing_event([before, after_sample], crossing, target_deg, trajectory, frame, rotation) do
    before_margin = before.margin_deg
    after_margin = unwrap_margin(after_sample.margin_deg, before_margin)

    cond do
      before_margin == 0.0 ->
        [event_from_sample(before, crossing, target_deg, trajectory, frame, rotation, :sampled)]

      before_margin * after_margin < 0.0 ->
        [
          interpolated_event(
            before,
            after_sample,
            before_margin,
            after_margin,
            crossing,
            target_deg,
            trajectory,
            frame,
            rotation
          )
        ]

      true ->
        []
    end
  end

  defp event_from_sample(sample, crossing, target_deg, trajectory, frame, rotation, interpolation) do
    %{
      type: crossing_type(crossing),
      starts_at: sample.state.epoch,
      metadata:
        metadata(sample, sample, crossing, target_deg, trajectory, frame, rotation, %{
          interpolation: interpolation,
          crossing_direction: :sampled_exact,
          sample_index: sample.index
        })
    }
  end

  defp interpolated_event(
         before,
         after_sample,
         before_margin,
         after_margin,
         crossing,
         target_deg,
         trajectory,
         frame,
         rotation
       ) do
    denominator = after_margin - before_margin
    fraction = max(0.0, min(1.0, -before_margin / denominator))
    before_epoch = before.state.epoch
    after_epoch = after_sample.state.epoch
    duration_s = after_epoch.seconds_since_j2000 - before_epoch.seconds_since_j2000

    starts_at = %{
      before_epoch
      | seconds_since_j2000: before_epoch.seconds_since_j2000 + fraction * duration_s
    }

    %{
      type: crossing_type(crossing),
      starts_at: starts_at,
      metadata:
        metadata(before, after_sample, crossing, target_deg, trajectory, frame, rotation, %{
          interpolation: :linear_sample_crossing,
          crossing_direction: crossing_direction(crossing, before_margin, after_margin),
          interpolation_fraction: fraction,
          timing_boundary:
            EventTiming.boundary_policy(before.state.epoch, after_sample.state.epoch)
        })
    }
  end

  defp metadata(before, after_sample, crossing, target_deg, trajectory, frame, rotation, extra) do
    Map.merge(
      %{
        scenario_id: trajectory.scenario_id,
        crossing: crossing,
        target_deg: target_deg,
        frame: frame,
        coordinate_model: coordinate_model(frame, rotation),
        start_sample_index: before.index,
        end_sample_index: after_sample.index,
        before_latitude_deg: before.latitude_deg,
        before_longitude_deg: before.longitude_deg,
        after_latitude_deg: after_sample.latitude_deg,
        after_longitude_deg: after_sample.longitude_deg
      },
      extra
    )
    |> Map.merge(rotation_assumptions(frame, rotation, before, after_sample))
  end

  defp coordinate_model(:inertial, _rotation), do: :geocentric_spherical_inertial

  defp coordinate_model(:body_fixed, %{mode: :provider}),
    do: :geocentric_spherical_body_fixed_provider_rotation

  defp coordinate_model(:body_fixed, %{configured?: true}),
    do: :geocentric_spherical_body_fixed_configured_constant_rotation

  defp coordinate_model(:body_fixed, _rotation),
    do: :geocentric_spherical_body_fixed_constant_rotation

  defp rotation_assumptions(:inertial, _rotation, _before, _after_sample), do: %{}

  defp rotation_assumptions(
         :body_fixed,
         %{mode: :constant_rate} = rotation,
         _before,
         _after_sample
       ) do
    %{
      earth_rotation_rate_rad_s: rotation.rotation_rate_rad_s,
      rotation_epoch_s: rotation.rotation_epoch_s,
      rotation_angle_offset_rad: rotation.rotation_angle_offset_rad
    }
  end

  defp rotation_assumptions(
         :body_fixed,
         %{mode: :provider, provider: provider} = rotation,
         before,
         after_sample
       ) do
    before_metadata = before.rotation_metadata
    after_metadata = after_sample.rotation_metadata
    provider_capability = Map.get(rotation, :provider_capability, %{})
    provider_coverage = Map.get(provider_capability, "coverage", %{})

    %{
      earth_rotation_provider: provider,
      earth_rotation_provider_id: Map.get(before_metadata, :earth_rotation_provider_id),
      earth_rotation_model: Map.get(before_metadata, :earth_rotation_model),
      earth_rotation_provider_coverage_starts_at_s: provider_coverage["starts_at_s"],
      earth_rotation_provider_coverage_ends_at_s: provider_coverage["ends_at_s"],
      earth_rotation_provider_sample_count:
        get_in(provider_capability, ["parameters", "sample_count"]),
      earth_rotation_provider_revision:
        Map.get(before_metadata, :earth_rotation_provider_revision) ||
          Map.get(after_metadata, :earth_rotation_provider_revision),
      earth_rotation_dataset_revision:
        Map.get(before_metadata, :earth_rotation_dataset_revision) ||
          Map.get(after_metadata, :earth_rotation_dataset_revision),
      earth_rotation_dataset_semantic_sha256:
        Map.get(before_metadata, :earth_rotation_dataset_semantic_sha256) ||
          Map.get(after_metadata, :earth_rotation_dataset_semantic_sha256),
      earth_rotation_content_sha256:
        Map.get(before_metadata, :earth_rotation_content_sha256) ||
          Map.get(after_metadata, :earth_rotation_content_sha256),
      earth_rotation_source_table_id:
        Map.get(before_metadata, :earth_rotation_source_table_id) ||
          Map.get(after_metadata, :earth_rotation_source_table_id),
      earth_rotation_provider_provenance:
        Map.get(before_metadata, :earth_rotation_provider_provenance) ||
          Map.get(after_metadata, :earth_rotation_provider_provenance),
      earth_rotation_frame:
        Map.get(before_metadata, :earth_rotation_frame) ||
          Map.get(after_metadata, :earth_rotation_frame),
      polar_motion_applied:
        Map.get(before_metadata, :polar_motion_applied) ||
          Map.get(after_metadata, :polar_motion_applied),
      known_limits: ground_track_known_limits(rotation),
      earth_rotation_rate_rad_s:
        Map.get(before_metadata, :earth_rotation_rate_rad_s) ||
          Map.get(after_metadata, :earth_rotation_rate_rad_s),
      before_earth_rotation_angle_rad: Map.get(before_metadata, :earth_rotation_angle_rad),
      after_earth_rotation_angle_rad: Map.get(after_metadata, :earth_rotation_angle_rad),
      earth_rotation_interpolation:
        Map.get(before_metadata, :earth_rotation_interpolation) ||
          Map.get(after_metadata, :earth_rotation_interpolation)
    }
    |> Enum.reject(fn {_key, value} -> is_nil(value) end)
    |> Map.new()
  end

  defp provider_rotation_angle(rotation, seconds_since_j2000) do
    case provider_rotation_product(rotation, seconds_since_j2000) do
      {:ok, %{} = product} ->
        angle_rad = get_product_value(product, "earth_rotation_angle_rad")

        if is_number(angle_rad) do
          {:ok, angle_rad,
           %{
             earth_rotation_provider_id: get_product_value(product, "provider_id"),
             earth_rotation_model: get_product_value(product, "model"),
             earth_rotation_rate_rad_s: get_product_value(product, "earth_rotation_rate_rad_s"),
             earth_rotation_interpolation: get_product_value(product, "interpolation"),
             earth_rotation_provider_coverage_starts_at_s:
               get_product_value(product, "coverage_starts_at_s"),
             earth_rotation_provider_coverage_ends_at_s:
               get_product_value(product, "coverage_ends_at_s"),
             earth_rotation_provider_sample_count: get_product_value(product, "sample_count"),
             earth_rotation_provider_revision: get_product_value(product, "provider_revision"),
             earth_rotation_dataset_revision: get_product_value(product, "dataset_revision"),
             earth_rotation_dataset_semantic_sha256:
               get_product_value(product, "dataset_semantic_sha256"),
             earth_rotation_content_sha256: get_product_value(product, "content_sha256"),
             earth_rotation_source_table_id: get_product_value(product, "source_table_id"),
             earth_rotation_provider_provenance: get_product_value(product, "provenance"),
             earth_rotation_frame: get_product_value(product, "frame"),
             polar_motion_applied: get_product_value(product, "polar_motion_applied"),
             earth_rotation_angle_rad: angle_rad
           }}
        else
          {:error, {:invalid_environment_product, :earth_rotation_angle_rad}}
        end

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp provider_rotation_product(rotation, seconds_since_j2000) do
    opts = Keyword.put(rotation.provider_opts, :seconds_since_j2000, seconds_since_j2000)

    case rotation.provider.fetch(:earth_rotation, opts) do
      {:ok, %{} = product} ->
        with :ok <- validate_provider_product(product, rotation) do
          {:ok, product}
        end

      {:error, reason} ->
        {:error, reason}

      _other ->
        {:error, {:invalid_environment_product, :earth_rotation}}
    end
  end

  defp validate_provider_product(
         product,
         %{trusted_campaign?: true, provider_capability: capability} = rotation
       ) do
    CampaignEnvironmentProvider.validate_product_binding(
      product,
      capability,
      rotation.provider_provenance
    )
  end

  defp validate_provider_product(product, rotation) do
    capability = rotation.provider_capability

    with false <- CampaignEnvironmentProvider.reserved_evidence?(product),
         :ok <- matching_product_field(product, "provider_id", capability["id"]),
         :ok <- matching_product_field(product, "model", capability["model"]),
         :ok <- validate_declared_product_evidence(product, capability) do
      :ok
    else
      true -> {:error, {:untrusted_campaign_environment_evidence, rotation.provider}}
      {:error, reason} -> {:error, reason}
    end
  end

  defp validate_declared_product_evidence(product, capability) do
    evidence_bearing? = evidence_bearing_capability?(capability)

    bindings = [
      {"provider_revision", capability_value(capability, "provider_revision"), true},
      {"dataset_revision", capability_value(capability, "dataset_revision"), true},
      {"dataset_semantic_sha256", capability_value(capability, "dataset_semantic_sha256"), true},
      {"content_sha256", capability_content_sha256(capability), true},
      {"source_table_id", capability_source_table_id(capability), true},
      {"provenance", capability["provenance"], true},
      {"known_limits", capability["known_limits"], evidence_bearing?},
      {"coverage_starts_at_s", get_in(capability, ["coverage", "starts_at_s"]), true},
      {"coverage_ends_at_s", get_in(capability, ["coverage", "ends_at_s"]), true},
      {"sample_count", get_in(capability, ["parameters", "sample_count"]), true}
    ]

    Enum.reduce_while(bindings, :ok, fn {field, expected, required_when_declared?}, :ok ->
      case fetch_product_value(product, field) do
        :error when is_nil(expected) or not required_when_declared? ->
          {:cont, :ok}

        :error ->
          {:halt, {:error, {:invalid_environment_product, field}}}

        {:ok, _actual} when is_nil(expected) ->
          {:halt, {:error, {:unbound_environment_product_evidence, field}}}

        {:ok, actual} when actual == expected ->
          {:cont, :ok}

        {:ok, actual} ->
          {:halt, {:error, {:environment_provider_product_mismatch, field, expected, actual}}}
      end
    end)
  end

  defp evidence_bearing_capability?(capability) do
    not is_nil(capability["provenance"]) or
      Enum.any?(
        [
          "provider_revision",
          "dataset_revision",
          "dataset_semantic_sha256"
        ],
        &(not is_nil(capability_value(capability, &1)))
      ) or
      not is_nil(capability_content_sha256(capability))
  end

  defp matching_product_field(product, field, expected) do
    case fetch_product_value(product, field) do
      {:ok, ^expected} -> :ok
      {:ok, actual} -> {:error, {:environment_provider_product_mismatch, field, expected, actual}}
      :error -> {:error, {:invalid_environment_product, field}}
    end
  end

  defp capability_value(capability, field) do
    get_in(capability, ["parameters", field]) ||
      get_in(capability, ["provenance", field]) ||
      get_in(capability, ["source_identity", field])
  end

  defp capability_content_sha256(capability) do
    get_in(capability, ["source_identity", "content_identity", "sha256"]) ||
      get_in(capability, ["provenance", "content_sha256"])
  end

  defp capability_source_table_id(capability) do
    get_in(capability, ["provenance", "source_table_id"])
  end

  defp fetch_product_value(%{} = product, key) do
    case Map.fetch(product, key) do
      {:ok, value} -> {:ok, value}
      :error -> fetch_existing_atom_value(product, key)
    end
  end

  defp fetch_existing_atom_value(product, key) do
    Map.fetch(product, String.to_existing_atom(key))
  rescue
    ArgumentError -> :error
  end

  defp get_product_value(%{} = product, key) when is_binary(key) do
    case Map.fetch(product, key) do
      {:ok, value} -> value
      :error -> Map.get(product, String.to_existing_atom(key))
    end
  rescue
    ArgumentError -> Map.get(product, key)
  end

  defp ground_track_known_limits(%{trusted_campaign?: true}),
    do: @campaign_ground_track_known_limits

  defp ground_track_known_limits(_rotation), do: nil

  defp crossing_type(:latitude), do: :latitude_crossing
  defp crossing_type(:longitude), do: :longitude_crossing

  defp crossing_direction(:latitude, before_margin, after_margin) do
    cond do
      before_margin == 0.0 or after_margin == 0.0 -> :sampled_exact
      after_margin > before_margin -> :northbound
      true -> :southbound
    end
  end

  defp crossing_direction(:longitude, before_margin, after_margin) do
    cond do
      before_margin == 0.0 or after_margin == 0.0 -> :sampled_exact
      after_margin > before_margin -> :eastbound
      true -> :westbound
    end
  end

  defp interpolation_fraction(before_margin, after_margin) do
    denominator = after_margin - before_margin

    if denominator == 0.0 do
      0.0
    else
      max(0.0, min(1.0, -before_margin / denominator))
    end
  end

  defp bracketed_boundary?(before_margin, after_margin) do
    before_margin == 0.0 or after_margin == 0.0 or
      (before_margin < 0.0 and after_margin > 0.0) or
      (before_margin > 0.0 and after_margin < 0.0)
  end

  defp interpolate_epoch(before_epoch, after_epoch, fraction) do
    duration_s = after_epoch.seconds_since_j2000 - before_epoch.seconds_since_j2000

    %{
      before_epoch
      | seconds_since_j2000: before_epoch.seconds_since_j2000 + fraction * duration_s
    }
  end

  defp margin_deg(:latitude, value_deg, target_deg), do: value_deg - target_deg

  defp margin_deg(:longitude, value_deg, target_deg) do
    signed_longitude_delta(value_deg, target_deg)
  end

  defp unwrap_margin(margin, previous_margin) do
    cond do
      margin - previous_margin > 180.0 -> margin - 360.0
      previous_margin - margin > 180.0 -> margin + 360.0
      true -> margin
    end
  end

  defp signed_longitude_delta(value_deg, target_deg) do
    value_deg
    |> Kernel.-(target_deg)
    |> normalize_longitude()
  end

  defp normalize_longitude(value_deg) do
    value_deg
    |> Kernel.+(180.0)
    |> :math.fmod(360.0)
    |> case do
      value when value < 0.0 -> value + 360.0
      value -> value
    end
    |> Kernel.-(180.0)
  end

  defp earth_rotation_angle(seconds_since_j2000, rotation) do
    rotation.rotation_angle_offset_rad +
      rotation.rotation_rate_rad_s * (seconds_since_j2000 - rotation.rotation_epoch_s)
  end

  defp rotate_z({x, y, z}, angle_rad) do
    cos_angle = :math.cos(angle_rad)
    sin_angle = :math.sin(angle_rad)

    {
      cos_angle * x - sin_angle * y,
      sin_angle * x + cos_angle * y,
      z
    }
  end

  defp radians_to_degrees(radians), do: radians * 180.0 / :math.pi()
end
