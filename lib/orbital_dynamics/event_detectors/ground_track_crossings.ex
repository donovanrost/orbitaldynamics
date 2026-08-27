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

  alias OrbitalDynamics.{Environment, Epoch, EventTiming, Frame, StateVector, Trajectory}
  alias OrbitalDynamics.Environment.CampaignEnvironmentProvider
  alias OrbitalDynamics.Environment.CampaignEnvironmentProvider.Dataset

  @behaviour OrbitalDynamics.EventDetector
  @earth_rotation_rate_rad_s 7.2921150e-5
  @max_states 10_000
  @max_opts_length 64
  @max_container_depth 12
  @max_container_entries 4_096
  @max_list_length 1_024
  @max_map_size 128
  @safe_number_limit 1.0e15
  @request_aliases [
    {:starts_at_s, "starts_at_s"},
    {:ends_at_s, "ends_at_s"},
    {:body, "body"},
    {:bodies, "bodies"},
    {:central_body, "central_body"},
    {:output, "output"},
    {:outputs, "outputs"},
    {:product, "product"},
    {:kind, "kind"},
    {:frame, "frame"},
    {:frames, "frames"},
    {:time_scale, "time_scale"},
    {:time_scales, "time_scales"}
  ]
  @request_keys Enum.flat_map(@request_aliases, fn {atom_key, string_key} ->
                  [atom_key, string_key]
                end)
  @product_aliases [
    {"provider_id", :provider_id},
    {"model", :model},
    {"earth_rotation_angle_rad", :earth_rotation_angle_rad},
    {"earth_rotation_rate_rad_s", :earth_rotation_rate_rad_s},
    {"interpolation", :interpolation},
    {"provider_revision", :provider_revision},
    {"dataset_revision", :dataset_revision},
    {"dataset_semantic_sha256", :dataset_semantic_sha256},
    {"content_sha256", :content_sha256},
    {"source_table_id", :source_table_id},
    {"provenance", :provenance},
    {"known_limits", :known_limits},
    {"coverage_starts_at_s", :coverage_starts_at_s},
    {"coverage_ends_at_s", :coverage_ends_at_s},
    {"sample_count", :sample_count},
    {"frame", :frame},
    {"polar_motion_applied", :polar_motion_applied}
  ]
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
  @allowed_options [
    :crossing,
    :latitude_deg,
    :longitude_deg,
    :frame,
    :rotation_rate_rad_s,
    :rotation_epoch_s,
    :rotation_angle_offset_rad,
    :earth_rotation_provider,
    :campaign_environment
  ]
  @numeric_options [
    :latitude_deg,
    :longitude_deg,
    :rotation_rate_rad_s,
    :rotation_epoch_s,
    :rotation_angle_offset_rad
  ]
  @campaign_dataset_fields [
    :table_id,
    :provider_id,
    :provider_revision,
    :dataset_revision,
    :body,
    :source_inertial_frame,
    :provider_inertial_frame,
    :earth_fixed_frame,
    :time_scale,
    :interpolation,
    :sample_interval_s,
    :coverage,
    :samples,
    :sources,
    :known_limits,
    :content_verification
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
    with :ok <- validate_provider_request(request),
         {:ok, rotation} <- provider_rotation_model(provider),
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
  def detect(trajectory, opts \\ [])

  def detect(%Trajectory{} = trajectory, opts) do
    with :ok <- validate_opts(opts),
         :ok <- validate_trajectory(trajectory),
         {:ok, crossing} <- crossing_option(Keyword.get(opts, :crossing, :latitude)),
         {:ok, target_deg} <- target_deg(crossing, opts),
         :ok <- validate_target(crossing, target_deg),
         {:ok, frame} <- reference_frame(opts),
         {:ok, rotation} <- rotation_model(frame, opts),
         :ok <- validate_campaign_evidence_option(opts, rotation),
         {:ok, samples} <- samples(trajectory, crossing, target_deg, frame, rotation),
         {:ok, events} <-
           crossing_events(samples, crossing, target_deg, trajectory, frame, rotation),
         {:ok, annotated_events} <- annotate_events(events, trajectory) do
      {:ok, annotated_events}
    end
  end

  def detect(_trajectory, opts) do
    with :ok <- validate_opts(opts), do: {:error, {:invalid_option, :trajectory}}
  end

  @doc """
  Refines one bracketed latitude or longitude crossing boundary between two samples.

  The refinement uses the same geocentric latitude/longitude margin and linear
  interpolation model as `detect/2`. It is useful for artifact metadata and
  coarse ground-track timing; it is not a root-solved event time.
  """
  def refine_crossing_boundary(before_state, after_state, opts \\ [])

  def refine_crossing_boundary(
        %StateVector{} = before_state,
        %StateVector{} = after_state,
        opts
      ) do
    with :ok <- validate_opts(opts),
         :ok <- validate_state_pair(before_state, after_state),
         {:ok, crossing} <- crossing_option(Keyword.get(opts, :crossing, :latitude)),
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

  def refine_crossing_boundary(_before_state, _after_state, opts) do
    with :ok <- validate_opts(opts), do: {:error, {:invalid_option, :crossing_boundary}}
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
    case Keyword.fetch(opts, key) do
      {:ok, value} when is_integer(value) or is_float(value) ->
        if finite_number?(value) do
          {:ok, value * 1.0}
        else
          {:error, {:invalid_option, key}}
        end

      {:ok, _value} ->
        {:error, {:invalid_option, key}}

      :error ->
        {:error, {:missing_option, key}}
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
         :ok <- validate_provider_opts(provider_opts) do
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
           safe_campaign_trusted_configuration(provider_opts) do
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
           safe_configured_provider_capability(provider, provider_opts),
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

  defp safe_campaign_trusted_configuration(provider_opts) do
    CampaignEnvironmentProvider.trusted_configuration(provider_opts)
  rescue
    _error in [
      ArgumentError,
      ArithmeticError,
      BadMapError,
      FunctionClauseError,
      KeyError,
      MatchError,
      RuntimeError,
      UndefinedFunctionError
    ] ->
      {:error,
       {:environment_provider_callback_failed, CampaignEnvironmentProvider,
        :trusted_configuration}}
  end

  defp validate_capability_module_binding(provider, configured_capability) do
    with {:ok, base_capability} <- safe_provider_capabilities(provider) do
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
             capability_field_changed?(configured_capability, base_capability, key)
           end) do
        nil -> :ok
        key -> {:error, {:environment_provider_capability_mismatch, provider, key}}
      end
    end
  rescue
    _error in [BadMapError, KeyError] -> {:error, {:invalid_option, :earth_rotation_provider}}
  end

  defp capability_field_changed?(configured_capability, base_capability, key) do
    case {Map.fetch(configured_capability, key), Map.fetch(base_capability, key)} do
      {:error, :error} -> false
      {{:ok, configured_value}, {:ok, base_value}} -> configured_value != base_value
      _added_or_removed -> true
    end
  end

  defp safe_configured_provider_capability(provider, provider_opts) do
    Environment.configured_provider_capability(provider, provider_opts)
  rescue
    _error in [
      ArgumentError,
      ArithmeticError,
      BadMapError,
      FunctionClauseError,
      KeyError,
      MatchError,
      RuntimeError,
      UndefinedFunctionError
    ] ->
      {:error, {:environment_provider_callback_failed, provider, :capabilities}}
  end

  defp safe_provider_capabilities(provider) do
    {:ok, provider.capabilities()}
  rescue
    _error in [
      ArgumentError,
      ArithmeticError,
      BadMapError,
      FunctionClauseError,
      KeyError,
      MatchError,
      RuntimeError,
      UndefinedFunctionError
    ] ->
      {:error, {:environment_provider_callback_failed, provider, :capabilities}}
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

  defp validate_provider_request(%{} = request) do
    with :ok <- preflight_provider_request_top_level(request),
         :ok <- preflight_provider_request_numeric_bounds(request),
         :ok <- preflight_container(request, :provider_request),
         :ok <- reject_alias_collisions(request, @request_aliases),
         :ok <- reject_unsupported_request_keys(request),
         {:ok, starts_at_s} <- request_epoch(request, :starts_at_s, "starts_at_s"),
         {:ok, ends_at_s} <- request_epoch(request, :ends_at_s, "ends_at_s") do
      if ends_at_s >= starts_at_s do
        :ok
      else
        {:error, {:invalid_field, "ends_at_s"}}
      end
    end
  end

  defp preflight_provider_request_top_level(%{__struct__: _struct}),
    do: {:error, {:invalid_container, :provider_request}}

  defp preflight_provider_request_top_level(%{} = request) do
    cond do
      map_size(request) > @max_map_size ->
        {:error, {:container_limit_exceeded, :provider_request}}

      invalid_map_key?(request) ->
        {:error, {:invalid_container, :provider_request}}

      true ->
        :ok
    end
  end

  defp preflight_provider_request_numeric_bounds(%{__struct__: _struct}), do: :ok

  defp preflight_provider_request_numeric_bounds(%{} = request) do
    Enum.reduce_while(request, :ok, fn {key, value}, :ok ->
      case request_field_name(key) do
        {:ok, field_name} ->
          case preflight_provider_request_numeric_value(value, field_name) do
            :ok -> {:cont, :ok}
            {:error, reason} -> {:halt, {:error, reason}}
          end

        :unknown ->
          {:cont, :ok}
      end
    end)
  end

  defp preflight_provider_request_numeric_value(value, field_name) do
    preflight_provider_request_numeric_stack([{value, 0}], 0, field_name)
  end

  defp preflight_provider_request_numeric_stack([], _visited, _field_name), do: :ok

  defp preflight_provider_request_numeric_stack(_stack, visited, _field_name)
       when visited > @max_container_entries,
       do: {:error, {:container_limit_exceeded, :provider_request}}

  defp preflight_provider_request_numeric_stack([{_term, depth} | _rest], _visited, _field_name)
       when depth > @max_container_depth,
       do: {:error, {:container_depth_exceeded, :provider_request}}

  defp preflight_provider_request_numeric_stack(
         [{%{__struct__: _struct}, _depth} | rest],
         visited,
         field_name
       ),
       do: preflight_provider_request_numeric_stack(rest, visited + 1, field_name)

  defp preflight_provider_request_numeric_stack([{tuple, _depth} | rest], visited, field_name)
       when is_tuple(tuple),
       do: preflight_provider_request_numeric_stack(rest, visited + 1, field_name)

  defp preflight_provider_request_numeric_stack([{%{} = map, depth} | rest], visited, field_name) do
    cond do
      map_size(map) > @max_map_size ->
        {:error, {:container_limit_exceeded, :provider_request}}

      invalid_map_key?(map) ->
        {:error, {:invalid_container, :provider_request}}

      true ->
        children = Enum.map(Map.values(map), &{&1, depth + 1})

        preflight_provider_request_numeric_stack(
          children ++ rest,
          visited + map_size(map),
          field_name
        )
    end
  end

  defp preflight_provider_request_numeric_stack([{list, depth} | rest], visited, field_name)
       when is_list(list) do
    case bounded_list_items(list, :provider_request, @max_list_length) do
      {:ok, items} ->
        children = Enum.map(items, &{&1, depth + 1})

        preflight_provider_request_numeric_stack(
          children ++ rest,
          visited + length(items),
          field_name
        )

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp preflight_provider_request_numeric_stack([{term, _depth} | rest], visited, field_name)
       when is_integer(term) or is_float(term) do
    if finite_number?(term) do
      preflight_provider_request_numeric_stack(rest, visited + 1, field_name)
    else
      {:error, {:invalid_field, field_name}}
    end
  end

  defp preflight_provider_request_numeric_stack([_term | rest], visited, field_name),
    do: preflight_provider_request_numeric_stack(rest, visited + 1, field_name)

  defp request_field_name(key) do
    Enum.find_value(@request_aliases, :unknown, fn {atom_key, string_key} ->
      if key == atom_key or key == string_key do
        {:ok, string_key}
      end
    end)
  end

  defp reject_unsupported_request_keys(request) do
    Enum.reduce_while(Map.keys(request), :ok, fn key, :ok ->
      if key in @request_keys do
        {:cont, :ok}
      else
        {:halt, {:error, {:unsupported_key, :provider_request}}}
      end
    end)
  end

  defp provider_request_epochs(request) do
    [
      alias_value(request, :starts_at_s, "starts_at_s"),
      alias_value(request, :ends_at_s, "ends_at_s")
    ]
    |> Enum.filter(&finite_number?/1)
    |> Enum.uniq()
  end

  defp request_epoch(request, atom_key, string_key) do
    case alias_value(request, atom_key, string_key) do
      value when is_integer(value) or is_float(value) ->
        if finite_number?(value) do
          {:ok, value * 1.0}
        else
          {:error, {:invalid_field, string_key}}
        end

      _value ->
        {:error, {:invalid_field, string_key}}
    end
  end

  defp reject_alias_collisions(map, aliases) do
    Enum.reduce_while(aliases, :ok, fn {atom_key, string_key}, :ok ->
      if Map.has_key?(map, atom_key) and Map.has_key?(map, string_key) do
        {:halt, {:error, {:atom_string_alias_collision, string_key}}}
      else
        {:cont, :ok}
      end
    end)
  end

  defp alias_value(map, atom_key, string_key) do
    case {Map.fetch(map, atom_key), Map.fetch(map, string_key)} do
      {{:ok, value}, :error} -> value
      {:error, {:ok, value}} -> value
      _missing_or_collision -> nil
    end
  end

  defp optional_number(opts, key, default) do
    case Keyword.get(opts, key, default) do
      value when is_integer(value) or is_float(value) ->
        if finite_number?(value) do
          {:ok, value * 1.0}
        else
          {:error, {:invalid_option, key}}
        end

      _value ->
        {:error, {:invalid_option, key}}
    end
  end

  defp validate_opts(opts) do
    with {:ok, items} <- bounded_list_items(opts, :opts, @max_opts_length),
         true <- Enum.all?(items, &keyword_entry?/1),
         true <- unique_keyword_keys?(items),
         :ok <- preflight_option_values(items),
         :ok <- reject_unsupported_options(items) do
      :ok
    else
      false -> {:error, {:invalid_option, :opts}}
      {:error, reason} -> {:error, reason}
    end
  end

  defp keyword_entry?({key, _value}) when is_atom(key), do: true
  defp keyword_entry?(_entry), do: false

  defp unique_keyword_keys?(items) do
    keys = Enum.map(items, fn {key, _value} -> key end)
    length(keys) == length(Enum.uniq(keys))
  end

  defp preflight_option_values(items) do
    Enum.reduce_while(items, :ok, fn {key, value}, :ok ->
      case preflight_option_value(key, value) do
        :ok -> {:cont, :ok}
        {:error, reason} -> {:halt, {:error, reason}}
      end
    end)
  end

  defp preflight_option_value(:earth_rotation_provider, provider),
    do: preflight_provider_spec(provider, :earth_rotation_provider)

  defp preflight_option_value(key, value) when key in @numeric_options,
    do: preflight_numeric_option(key, value)

  defp preflight_option_value(_key, value), do: preflight_container(value, :opts)

  defp preflight_numeric_option(key, value) when is_integer(value) or is_float(value) do
    if finite_number?(value), do: :ok, else: {:error, {:invalid_option, key}}
  end

  defp preflight_numeric_option(_key, value), do: preflight_container(value, :opts)

  defp validate_provider_opts(opts) do
    with {:ok, items} <- bounded_list_items(opts, :opts, @max_opts_length),
         true <- Enum.all?(items, &keyword_entry?/1),
         true <- unique_keyword_keys?(items),
         :ok <- preflight_provider_option_values(items) do
      :ok
    else
      false -> {:error, {:invalid_option, :opts}}
      {:error, reason} -> {:error, reason}
    end
  end

  defp preflight_provider_option_values(items) do
    Enum.reduce_while(items, :ok, fn {key, value}, :ok ->
      case preflight_provider_option_value(key, value) do
        :ok -> {:cont, :ok}
        {:error, reason} -> {:halt, {:error, reason}}
      end
    end)
  end

  defp preflight_provider_option_value(:dataset, %Dataset{} = dataset),
    do: preflight_exact_struct_shape(dataset, Dataset, @campaign_dataset_fields, :opts)

  defp preflight_provider_option_value(_key, value), do: preflight_container(value, :opts)

  defp preflight_provider_spec(provider, _field) when is_atom(provider), do: :ok

  defp preflight_provider_spec({provider, provider_opts}, _field)
       when is_atom(provider) and is_list(provider_opts),
       do: validate_provider_opts(provider_opts)

  defp preflight_provider_spec(_provider, field), do: {:error, {:invalid_option, field}}

  defp reject_unsupported_options(items) do
    Enum.reduce_while(items, :ok, fn {key, _value}, :ok ->
      if key in @allowed_options do
        {:cont, :ok}
      else
        {:halt, {:error, {:unsupported_option, key}}}
      end
    end)
  end

  defp preflight_exact_struct_shape(struct, module, fields, field) do
    expected_keys = MapSet.new([:__struct__ | fields])

    cond do
      Map.get(struct, :__struct__) != module ->
        {:error, {:invalid_container, field}}

      MapSet.new(Map.keys(struct)) != expected_keys ->
        {:error, {:invalid_container, field}}

      true ->
        :ok
    end
  end

  defp preflight_container(term, field) do
    preflight_container([{term, 0}], 0, field)
  end

  defp preflight_container([], _visited, _field), do: :ok

  defp preflight_container(_stack, visited, field) when visited > @max_container_entries,
    do: {:error, {:container_limit_exceeded, field}}

  defp preflight_container([{_term, depth} | _rest], _visited, field)
       when depth > @max_container_depth do
    {:error, {:container_depth_exceeded, field}}
  end

  defp preflight_container([{%{__struct__: _struct}, _depth} | _rest], _visited, field),
    do: {:error, {:invalid_container, field}}

  defp preflight_container([{tuple, _depth} | _rest], _visited, field) when is_tuple(tuple),
    do: {:error, {:invalid_container, field}}

  defp preflight_container([{%{} = map, depth} | rest], visited, field) do
    cond do
      map_size(map) > @max_map_size ->
        {:error, {:container_limit_exceeded, field}}

      invalid_map_key?(map) ->
        {:error, {:invalid_container, field}}

      true ->
        with :ok <- reject_generic_alias_collisions(map) do
          children = Enum.map(Map.values(map), &{&1, depth + 1})
          preflight_container(children ++ rest, visited + map_size(map), field)
        end
    end
  end

  defp preflight_container([{list, depth} | rest], visited, field) when is_list(list) do
    case bounded_list_items(list, field, @max_list_length) do
      {:ok, items} ->
        children = Enum.map(items, &{&1, depth + 1})
        preflight_container(children ++ rest, visited + length(items), field)

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp preflight_container([{term, _depth} | rest], visited, field)
       when is_nil(term) or is_boolean(term) or is_atom(term) or is_binary(term),
       do: preflight_container(rest, visited + 1, field)

  defp preflight_container([{term, _depth} | rest], visited, field)
       when is_integer(term) or is_float(term) do
    if finite_number?(term) do
      preflight_container(rest, visited + 1, field)
    else
      {:error, {:invalid_container, field}}
    end
  end

  defp preflight_container([_term | _rest], _visited, field),
    do: {:error, {:invalid_container, field}}

  defp invalid_map_key?(map) do
    Enum.any?(Map.keys(map), fn key -> not (is_atom(key) or is_binary(key)) end)
  end

  defp reject_generic_alias_collisions(%{} = map) do
    atom_key_strings =
      map
      |> Map.keys()
      |> Enum.filter(&is_atom/1)
      |> Enum.map(&Atom.to_string/1)
      |> MapSet.new()

    case Enum.find(Map.keys(map), fn key ->
           is_binary(key) and MapSet.member?(atom_key_strings, key)
         end) do
      nil -> :ok
      key -> {:error, {:atom_string_alias_collision, key}}
    end
  end

  defp bounded_list_items(list, field, limit) when is_list(list) do
    bounded_list_items(list, [], 0, field, limit)
  end

  defp bounded_list_items(_not_list, field, _limit), do: {:error, {:invalid_container, field}}

  defp bounded_list_items(_list, _acc, count, field, limit) when count > limit,
    do: {:error, {:container_limit_exceeded, field}}

  defp bounded_list_items([], acc, _count, _field, _limit), do: {:ok, Enum.reverse(acc)}

  defp bounded_list_items([head | tail], acc, count, field, limit) do
    bounded_list_items(tail, [head | acc], count + 1, field, limit)
  end

  defp bounded_list_items(_improper_tail, _acc, _count, field, _limit),
    do: {:error, {:invalid_container, field}}

  defp finite_number?(value) when is_integer(value), do: abs(value) <= @safe_number_limit

  defp finite_number?(value) when is_float(value) do
    value == value and value - value == 0.0 and abs(value) <= @safe_number_limit
  end

  defp finite_number?(_value), do: false

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

  defp validate_trajectory(%Trajectory{states: states, assumptions: assumptions}) do
    with {:ok, states} <- bounded_list_items(states, :states, @max_states),
         true <- is_map(assumptions),
         :ok <- preflight_container(assumptions, :trajectory_assumptions),
         :ok <- validate_states(states) do
      :ok
    else
      false -> {:error, {:invalid_trajectory, :assumptions}}
      {:error, reason} -> {:error, reason}
    end
  end

  defp validate_states(states) do
    states
    |> Enum.reduce_while({:ok, nil}, fn
      %StateVector{} = state, {:ok, previous_s} ->
        with :ok <- validate_state(state, :state),
             {:ok, seconds} <- state_epoch_seconds(state, :state) do
          if is_number(previous_s) and seconds <= previous_s do
            {:halt, {:error, {:invalid_trajectory, :non_increasing_epochs}}}
          else
            {:cont, {:ok, seconds}}
          end
        else
          {:error, reason} -> {:halt, {:error, reason}}
        end

      _state, {:ok, _previous_s} ->
        {:halt, {:error, {:invalid_trajectory, :state}}}
    end)
    |> case do
      {:ok, _previous_s} -> :ok
      {:error, reason} -> {:error, reason}
    end
  end

  defp validate_state_pair(before_state, after_state) do
    with :ok <- validate_state(before_state, :before_state),
         :ok <- validate_state(after_state, :after_state) do
      cond do
        not Frame.compatible?(before_state.frame, after_state.frame) ->
          {:error, :incompatible_state_frames}

        before_state.epoch.scale != after_state.epoch.scale ->
          {:error, :incompatible_epoch_scales}

        after_state.epoch.seconds_since_j2000 <= before_state.epoch.seconds_since_j2000 ->
          {:error, :non_increasing_state_epochs}

        true ->
          :ok
      end
    end
  end

  defp validate_state(
         %StateVector{
           position_km: position_km,
           velocity_km_s: velocity_km_s,
           epoch: %Epoch{scale: scale, seconds_since_j2000: seconds_since_j2000},
           frame: %Frame{name: name, center: center, orientation: orientation}
         },
         field
       ) do
    cond do
      not finite_vector?(position_km) ->
        {:error, {:invalid_state, field}}

      not finite_vector?(velocity_km_s) ->
        {:error, {:invalid_state, field}}

      scale not in [:tdb, :tai, :utc] or not finite_number?(seconds_since_j2000) ->
        {:error, {:invalid_state, field}}

      not (is_atom(name) and is_atom(center) and is_atom(orientation)) ->
        {:error, {:invalid_state, field}}

      true ->
        :ok
    end
  end

  defp validate_state(_state, field), do: {:error, {:invalid_state, field}}

  defp state_epoch_seconds(%StateVector{epoch: %Epoch{seconds_since_j2000: seconds}}, field) do
    if finite_number?(seconds) do
      {:ok, seconds * 1.0}
    else
      {:error, {:invalid_state, field}}
    end
  end

  defp finite_vector?({x, y, z}),
    do: finite_number?(x) and finite_number?(y) and finite_number?(z)

  defp finite_vector?(_vector), do: false

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

  defp crossing_events(samples, crossing, target_deg, trajectory, frame, rotation) do
    samples
    |> Enum.chunk_every(2, 1, :discard)
    |> Enum.reduce_while({:ok, []}, fn pair, {:ok, events} ->
      {:cont,
       {:ok,
        Enum.reverse(crossing_event(pair, crossing, target_deg, trajectory, frame, rotation)) ++
          events}}
    end)
    |> case do
      {:ok, events} -> {:ok, Enum.reverse(events)}
      {:error, reason} -> {:error, reason}
    end
  end

  defp annotate_events(events, trajectory) do
    Enum.reduce_while(events, {:ok, []}, fn event, {:ok, acc} ->
      case EventTiming.annotate_event(event, trajectory, :ground_track_crossings) do
        %{} = annotated -> {:cont, {:ok, [annotated | acc]}}
        {:error, reason} -> {:halt, {:error, reason}}
      end
    end)
    |> case do
      {:ok, annotated} -> {:ok, Enum.reverse(annotated)}
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
    angle_rad = earth_rotation_angle(seconds_since_j2000, rotation)

    if finite_number?(angle_rad) do
      rotate_z(position_km, -angle_rad)
      |> then(&{:ok, &1, %{}})
    else
      {:error, {:invalid_option, :earth_rotation_angle_rad}}
    end
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
    before_metadata = Map.fetch!(before, :rotation_metadata)
    after_metadata = Map.fetch!(after_sample, :rotation_metadata)
    provider_capability = Map.fetch!(rotation, :provider_capability)
    provider_coverage = Map.fetch!(provider_capability, "coverage")

    %{
      earth_rotation_provider: provider,
      earth_rotation_provider_id: Map.fetch!(before_metadata, :earth_rotation_provider_id),
      earth_rotation_model: Map.fetch!(before_metadata, :earth_rotation_model),
      earth_rotation_provider_coverage_starts_at_s: Map.fetch!(provider_coverage, "starts_at_s"),
      earth_rotation_provider_coverage_ends_at_s: Map.fetch!(provider_coverage, "ends_at_s"),
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
      before_earth_rotation_angle_rad: Map.fetch!(before_metadata, :earth_rotation_angle_rad),
      after_earth_rotation_angle_rad: Map.fetch!(after_metadata, :earth_rotation_angle_rad),
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

        if finite_number?(angle_rad) do
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

    case safe_provider_fetch(rotation.provider, :earth_rotation, opts) do
      {:ok, %{} = product} ->
        with :ok <- preflight_provider_product(product),
             :ok <- validate_provider_product(product, rotation) do
          {:ok, product}
        end

      {:error, reason} ->
        {:error, reason}

      _other ->
        {:error, {:invalid_environment_product, :earth_rotation}}
    end
  end

  defp safe_provider_fetch(provider, kind, opts) do
    provider.fetch(kind, opts)
  rescue
    _error in [
      ArgumentError,
      ArithmeticError,
      BadMapError,
      FunctionClauseError,
      KeyError,
      MatchError,
      RuntimeError,
      UndefinedFunctionError
    ] ->
      {:error, {:environment_provider_callback_failed, provider, :fetch}}
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
        {:error, reason} ->
          {:halt, {:error, reason}}

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
      {:error, reason} -> {:error, reason}
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

  defp preflight_provider_product(product) do
    with :ok <- preflight_container(product, :environment_product),
         :ok <- reject_product_alias_collisions(product, @product_aliases),
         :ok <- validate_optional_product_map(product, "provenance") do
      :ok
    end
  end

  defp fetch_product_value(%{} = product, key) do
    with {:ok, atom_key} <- product_atom_key(key),
         :ok <- reject_product_alias_collision(product, key, atom_key) do
      case Map.fetch(product, key) do
        {:ok, value} -> {:ok, value}
        :error -> Map.fetch(product, atom_key)
      end
    else
      {:error, {:unsupported_product_field, _key}} -> :error
      {:error, reason} -> {:error, reason}
    end
  end

  defp get_product_value(%{} = product, key) when is_binary(key) do
    case fetch_product_value(product, key) do
      {:ok, value} -> value
      :error -> nil
      {:error, reason} -> {:error, reason}
    end
  end

  defp reject_product_alias_collisions(product, aliases) do
    Enum.reduce_while(aliases, :ok, fn {string_key, atom_key}, :ok ->
      case reject_product_alias_collision(product, string_key, atom_key) do
        :ok -> {:cont, :ok}
        {:error, reason} -> {:halt, {:error, reason}}
      end
    end)
  end

  defp reject_product_alias_collision(product, string_key, atom_key) do
    if Map.has_key?(product, string_key) and Map.has_key?(product, atom_key) do
      {:error, {:atom_string_alias_collision, string_key}}
    else
      :ok
    end
  end

  defp validate_optional_product_map(product, key) do
    case get_product_value(product, key) do
      nil -> :ok
      %{} -> :ok
      {:error, reason} -> {:error, reason}
      _value -> {:error, {:invalid_environment_product, key}}
    end
  end

  defp product_atom_key(key) do
    Enum.find_value(@product_aliases, {:error, {:unsupported_product_field, key}}, fn
      {^key, atom_key} -> {:ok, atom_key}
      _alias -> nil
    end)
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
