defmodule OrbitalDynamics.FrameTransform do
  @moduledoc """
  Explicit provider-backed Earth inertial/body-fixed state transforms.

  This is a narrow educational transform between the existing Earth J2000
  inertial label and the provider-defined Earth-fixed label. Callers must build
  and pass one immutable provider policy; there is no default or globally
  configured Earth-rotation provider.

  The provider supplies rotation angle and angular rate at the state's `:tdb`
  epoch. Position is rotated about Earth's z-axis. Velocity includes the
  rotating-frame transport term, not just the position rotation matrix.
  """

  alias OrbitalDynamics.{CentralBody, Environment, Epoch, Frame, StateVector, Vector3}

  @position_absolute_tolerance_km 1.0e-9
  @velocity_absolute_tolerance_km_s 1.0e-12
  @round_trip_relative_scale_factor 1.0e-12
  @maximum_position_component_km 1.0e9
  @maximum_velocity_component_km_s 2.0e4
  @maximum_epoch_magnitude_s 1.0e12
  @maximum_earth_rotation_angle_magnitude_rad 1.0e12
  @maximum_earth_rotation_rate_magnitude_rad_s 2.0

  defmodule ProviderPolicy do
    @moduledoc """
    Immutable caller-supplied Earth-rotation provider selection.

    Construct policies with `OrbitalDynamics.FrameTransform.provider_policy/2`
    so provider capability, finite coverage, source, and source revision are
    captured once before transforming states. The integrity value is an
    internal same-runtime content binding, not a stable external serialization.
    """

    @enforce_keys [
      :provider,
      :provider_opts,
      :capability,
      :source_revision,
      :integrity_sha256
    ]
    defstruct @enforce_keys

    @type t :: %__MODULE__{
            provider: module(),
            provider_opts: keyword(),
            capability: map(),
            source_revision: String.t(),
            integrity_sha256: String.t()
          }
  end

  @doc """
  Declares the supported transform envelope and fidelity limits.
  """
  def capabilities do
    %{
      model: :earth_j2000_provider_defined_earth_fixed_state_transform,
      validation_level: :educational,
      supported_bodies: [:earth],
      supported_time_scales: [:tdb],
      supported_frame_pairs: [
        %{source: :eci_j2000, target: :earth_body_fixed},
        %{source: :earth_body_fixed, target: :eci_j2000}
      ],
      provider_policy: :explicit_immutable_caller_supplied,
      provider_policy_integrity: :sha256_same_runtime_content_binding,
      provider_requirements: [
        :offline,
        :earth_rotation_angle_rad,
        :earth_rotation_rate_rad_s,
        :epoch_coverage,
        :source_revision
      ],
      supported_numeric_envelope: %{
        bound_policy: :inclusive,
        scope: :per_call_input_and_provider_product,
        transformed_state_re_admission: :not_guaranteed,
        state: %{
          position_component_abs_max_km: @maximum_position_component_km,
          velocity_component_abs_max_km_s: @maximum_velocity_component_km_s,
          epoch_abs_max_s_since_j2000: @maximum_epoch_magnitude_s
        },
        provider_product: %{
          earth_rotation_angle_abs_max_rad: @maximum_earth_rotation_angle_magnitude_rad,
          earth_rotation_rate_abs_max_rad_s:
            @maximum_earth_rotation_rate_magnitude_rad_s
        }
      },
      round_trip_tolerances: %{
        position_km: @position_absolute_tolerance_km,
        velocity_km_s: @velocity_absolute_tolerance_km_s,
        model: :absolute_floor_plus_realized_scale,
        position_absolute_floor_km: @position_absolute_tolerance_km,
        velocity_absolute_floor_km_s: @velocity_absolute_tolerance_km_s,
        relative_scale_factor: @round_trip_relative_scale_factor
      },
      public_facades: [:frame_transform_provider_policy, :transform_state_frame],
      outputs: [:state, :transform_evidence, :round_trip_tolerance_evidence],
      known_limits: [
        :earth_only,
        :tdb_seconds_since_j2000_only,
        :z_axis_rotation_only,
        :provider_defined_earth_fixed_orientation,
        :no_time_scale_conversion,
        :no_precession_nutation_or_polar_motion,
        :no_authoritative_eop_source,
        :offline_providers_only,
        :input_envelope_not_closed_under_transform,
        :not_flight_certified
      ]
    }
  end

  @doc """
  Captures one explicit Earth-rotation provider policy.

  Options are:

    * `:provider_opts` - keyword options passed to the provider capability and
      fetch callbacks
    * `:source_revision` - required non-empty revision for the supplied source

  Network-backed providers are deliberately rejected by this foundation.
  """
  def provider_policy(provider, opts \\ [])

  def provider_policy(provider, opts) when is_atom(provider) and is_list(opts) do
    with :ok <- validate_keyword_options(opts),
         provider_opts = Keyword.get(opts, :provider_opts, []),
         :ok <- validate_provider_options(provider_opts),
         {:ok, source_revision} <- source_revision(opts),
         {:ok, capability} <-
           Environment.configured_provider_capability(provider, provider_opts),
         :ok <- validate_provider_fetch(provider),
         :ok <- validate_offline_provider(capability),
         :ok <- validate_provider_time_scale(capability) do
      {:ok,
       %ProviderPolicy{
         provider: provider,
         provider_opts: provider_opts,
         capability: capability,
         source_revision: source_revision,
         integrity_sha256:
           policy_integrity_sha256(provider, provider_opts, capability, source_revision)
       }}
    else
      {:error, {:invalid_option, _field} = reason} -> {:error, reason}
      {:error, {:missing_option, _field} = reason} -> {:error, reason}
      {:error, {:unsupported_provider_time_scale, _scale} = reason} -> {:error, reason}
      {:error, reason} -> {:error, {:invalid_earth_rotation_provider, reason}}
    end
  end

  def provider_policy(_provider, _opts),
    do: {:error, {:invalid_option, :earth_rotation_provider}}

  @doc """
  Transforms one Earth state between J2000 inertial and provider-defined
  Earth-fixed coordinates.

  The returned map contains the transformed `StateVector` and deterministic,
  inspectable provider, velocity-term, and realized round-trip evidence.
  """
  def transform(state, target_frame, central_body, provider_policy)

  def transform(
        %StateVector{} = state,
        %Frame{} = target_frame,
        %CentralBody{} = central_body,
        %ProviderPolicy{} = policy
      ) do
    with :ok <- validate_state(state),
         :ok <- validate_central_body(central_body),
         :ok <- validate_epoch(state),
         :ok <- validate_source_frame(state.frame),
         :ok <- validate_target_frame(target_frame),
         {:ok, direction} <- transform_direction(state.frame, target_frame),
         :ok <- validate_policy(policy),
         :ok <- validate_policy_request(policy, state, central_body),
         {:ok, rotation_product} <- fetch_rotation(policy, state),
         {:ok, angle_rad, rate_rad_s} <- validate_rotation_product(rotation_product, policy),
         transformed_state =
           apply_transform(state, target_frame, direction, angle_rad, rate_rad_s),
         round_trip =
           round_trip_evidence(state, transformed_state, direction, angle_rad, rate_rad_s),
         :ok <- validate_round_trip(round_trip) do
      {:ok,
       %{
         state: transformed_state,
         evidence:
           evidence(
             state,
             target_frame,
             central_body,
             policy,
             rotation_product,
             direction,
             angle_rad,
             rate_rad_s,
             transformed_state,
             round_trip
           )
       }}
    end
  end

  def transform(_state, _target_frame, _central_body, _provider_policy),
    do: {:error, {:invalid_input, :frame_transform}}

  defp validate_keyword_options(opts) do
    if Keyword.keyword?(opts),
      do: :ok,
      else: {:error, {:invalid_option, :options}}
  end

  defp validate_provider_options(opts) do
    if is_list(opts) and Keyword.keyword?(opts),
      do: :ok,
      else: {:error, {:invalid_option, :provider_opts}}
  end

  defp source_revision(opts) do
    case Keyword.get(opts, :source_revision) do
      value when is_binary(value) ->
        if valid_source_revision?(value),
          do: {:ok, value},
          else: {:error, {:invalid_option, :source_revision}}

      nil ->
        {:error, {:missing_option, :source_revision}}

      _value ->
        {:error, {:invalid_option, :source_revision}}
    end
  end

  defp validate_provider_fetch(provider) do
    if Code.ensure_loaded?(provider) and function_exported?(provider, :fetch, 2),
      do: :ok,
      else: {:error, {:invalid_option, :earth_rotation_provider}}
  end

  defp validate_offline_provider(%{"network_access" => false}), do: :ok
  defp validate_offline_provider(%{"network_access" => true}), do: {:error, :network_access}
  defp validate_offline_provider(_capability), do: {:error, :network_access_policy}

  defp validate_provider_time_scale(%{"coverage" => %{"time_scale" => "seconds_since_j2000"}}),
    do: :ok

  defp validate_provider_time_scale(%{"coverage" => coverage}),
    do: {:error, {:unsupported_provider_time_scale, Map.get(coverage, "time_scale")}}

  defp validate_provider_time_scale(_capability),
    do: {:error, {:unsupported_provider_time_scale, nil}}

  defp valid_source_revision?(value) when is_binary(value) do
    String.valid?(value) and String.trim(value) != ""
  end

  defp valid_source_revision?(_value), do: false

  defp validate_state(%StateVector{
         position_km: position_km,
         velocity_km_s: velocity_km_s,
         epoch: %Epoch{seconds_since_j2000: seconds_since_j2000},
         frame: %Frame{}
       }) do
    cond do
      not Vector3.valid?(position_km) or not Vector3.valid?(velocity_km_s) or
          not number?(seconds_since_j2000) ->
        {:error, {:invalid_state, :state_vector}}

      not vector_components_within?(position_km, @maximum_position_component_km) ->
        {:error, {:unsupported_state, :position_km}}

      not vector_components_within?(velocity_km_s, @maximum_velocity_component_km_s) ->
        {:error, {:unsupported_state, :velocity_km_s}}

      not number_in_symmetric_range?(seconds_since_j2000, @maximum_epoch_magnitude_s) ->
        {:error, {:unsupported_time, :seconds_since_j2000}}

      true ->
        :ok
    end
  end

  defp validate_state(%StateVector{}), do: {:error, {:invalid_state, :state_vector}}

  defp validate_source_frame(%Frame{} = frame) do
    if valid_frame?(frame),
      do: :ok,
      else: {:error, {:invalid_state, :frame}}
  end

  defp validate_target_frame(%Frame{} = frame) do
    if valid_frame?(frame),
      do: :ok,
      else: {:error, {:invalid_input, :target_frame}}
  end

  defp validate_central_body(%CentralBody{} = central_body) do
    case Map.fetch(central_body, :name) do
      {:ok, name} when is_atom(name) ->
        if name == :earth do
          with :ok <- validate_positive_central_body_field(central_body, :mu_km3_s2),
               :ok <-
                 validate_nil_or_positive_central_body_field(
                   central_body,
                   :equatorial_radius_km
                 ),
               :ok <- validate_nil_or_non_negative_central_body_field(central_body, :j2) do
            :ok
          end
        else
          {:error, {:unsupported_central_body, name}}
        end

      _missing_or_invalid_name ->
        {:error, {:invalid_central_body, :name}}
    end
  end

  defp validate_positive_central_body_field(central_body, field) do
    case Map.fetch(central_body, field) do
      {:ok, value} ->
        if positive_number?(value),
          do: :ok,
          else: {:error, {:invalid_central_body, field}}

      :error ->
        {:error, {:invalid_central_body, field}}
    end
  end

  defp validate_nil_or_positive_central_body_field(central_body, field) do
    case Map.fetch(central_body, field) do
      {:ok, nil} -> :ok

      {:ok, value} ->
        if positive_number?(value),
          do: :ok,
          else: {:error, {:invalid_central_body, field}}

      :error -> {:error, {:invalid_central_body, field}}
    end
  end

  defp validate_nil_or_non_negative_central_body_field(central_body, field) do
    case Map.fetch(central_body, field) do
      {:ok, nil} ->
        :ok

      {:ok, value} ->
        if non_negative_number?(value),
          do: :ok,
          else: {:error, {:invalid_central_body, field}}

      :error ->
        {:error, {:invalid_central_body, field}}
    end
  end

  defp validate_epoch(%StateVector{epoch: %Epoch{scale: :tdb}}), do: :ok

  defp validate_epoch(%StateVector{epoch: %Epoch{scale: scale}}),
    do: {:error, {:unsupported_time_scale, scale}}

  defp validate_epoch(_state), do: {:error, {:invalid_state, :state_vector}}

  defp transform_direction(source_frame, target_frame) do
    inertial = Frame.earth_inertial_j2000()
    earth_fixed = Frame.earth_fixed()

    cond do
      Frame.compatible?(source_frame, inertial) and Frame.compatible?(target_frame, earth_fixed) ->
        {:ok, :earth_inertial_j2000_to_provider_defined_earth_fixed}

      Frame.compatible?(source_frame, earth_fixed) and Frame.compatible?(target_frame, inertial) ->
        {:ok, :provider_defined_earth_fixed_to_earth_inertial_j2000}

      true ->
        {:error,
         {:unsupported_frame_transform, {frame_name(source_frame), frame_name(target_frame)}}}
    end
  end

  defp frame_name(%Frame{name: name}), do: name

  defp valid_frame?(%Frame{name: name, center: center, orientation: orientation})
       when is_atom(name) and is_atom(center) and is_atom(orientation),
       do: true

  defp valid_frame?(_frame), do: false

  defp validate_policy(%ProviderPolicy{} = policy) do
    provider = Map.get(policy, :provider)
    provider_opts = Map.get(policy, :provider_opts)
    capability = Map.get(policy, :capability)
    source_revision = Map.get(policy, :source_revision)
    integrity_sha256 = Map.get(policy, :integrity_sha256)

    cond do
      not is_atom(provider) ->
        {:error, {:invalid_provider_policy, :provider}}

      not is_list(provider_opts) or not Keyword.keyword?(provider_opts) ->
        {:error, {:invalid_provider_policy, :provider_opts}}

      not valid_source_revision?(source_revision) ->
        {:error, {:invalid_provider_policy, :source_revision}}

      Environment.validate_provider_capability(capability) != :ok ->
        {:error, {:invalid_provider_policy, :capability}}

      integrity_sha256 !=
          policy_integrity_sha256(provider, provider_opts, capability, source_revision) ->
        {:error, {:invalid_provider_policy, :integrity_sha256}}

      true ->
        with :ok <- validate_provider_fetch(provider),
             :ok <- validate_offline_provider(capability),
             :ok <- validate_provider_time_scale(capability) do
          :ok
        else
          {:error, reason} -> {:error, {:invalid_provider_policy, reason}}
        end
    end
  end

  defp validate_policy_request(%ProviderPolicy{capability: capability}, state, central_body) do
    request = %{
      starts_at_s: state.epoch.seconds_since_j2000,
      ends_at_s: state.epoch.seconds_since_j2000,
      body: central_body.name,
      output: :earth_rotation
    }

    cond do
      not Environment.provider_supports_request?(capability, request) ->
        if Environment.provider_covers_time_span?(capability, request) do
          {:error, {:unsupported_environment_request, :earth_rotation}}
        else
          {:error, {:unsupported_provider_coverage, state.epoch.seconds_since_j2000 * 1.0}}
        end

      true ->
        :ok
    end
  end

  defp fetch_rotation(%ProviderPolicy{} = policy, state) do
    opts =
      Keyword.put(
        policy.provider_opts,
        :seconds_since_j2000,
        state.epoch.seconds_since_j2000
      )

    case policy.provider.fetch(:earth_rotation, opts) do
      {:ok, %{} = product} -> {:ok, product}
      {:error, reason} -> {:error, reason}
      _other -> {:error, {:invalid_environment_product, :earth_rotation}}
    end
  end

  defp validate_rotation_product(product, policy) do
    with :ok <- matching_product_field(product, policy.capability, "provider_id", "id"),
         :ok <- matching_product_field(product, policy.capability, "model", "model"),
         {:ok, angle_rad} <-
           numeric_product_field(
             product,
             "earth_rotation_angle_rad",
             @maximum_earth_rotation_angle_magnitude_rad
           ),
         {:ok, rate_rad_s} <-
           numeric_product_field(
             product,
             "earth_rotation_rate_rad_s",
             @maximum_earth_rotation_rate_magnitude_rad_s
           ) do
      {:ok, angle_rad, rate_rad_s}
    end
  end

  defp matching_product_field(product, capability, product_field, capability_field) do
    product_atom_field = product_atom_field(product_field)
    value = Map.get(product, product_field) || Map.get(product, product_atom_field)

    if is_binary(value) and value == capability[capability_field],
      do: :ok,
      else: {:error, {:invalid_environment_product, product_atom_field}}
  end

  defp numeric_product_field(product, field, maximum_magnitude) do
    product_atom_field = product_atom_field(field)
    value = Map.get(product, field) || Map.get(product, product_atom_field)

    cond do
      not number?(value) ->
        {:error, {:invalid_environment_product, product_atom_field}}

      not number_in_symmetric_range?(value, maximum_magnitude) ->
        {:error, {:unsupported_environment_product, product_atom_field}}

      true ->
        {:ok, value * 1.0}
    end
  end

  defp product_atom_field("provider_id"), do: :provider_id
  defp product_atom_field("model"), do: :model
  defp product_atom_field("earth_rotation_angle_rad"), do: :earth_rotation_angle_rad
  defp product_atom_field("earth_rotation_rate_rad_s"), do: :earth_rotation_rate_rad_s

  defp apply_transform(
         state,
         target_frame,
         :earth_inertial_j2000_to_provider_defined_earth_fixed,
         angle_rad,
         rate_rad_s
       ) do
    position_km = rotate_z(state.position_km, -angle_rad)
    rotated_velocity_km_s = rotate_z(state.velocity_km_s, -angle_rad)
    transport_term_km_s = rotation_transport_term(position_km, rate_rad_s)

    StateVector.new!(
      position_km,
      Vector3.subtract(rotated_velocity_km_s, transport_term_km_s),
      state.epoch,
      target_frame
    )
  end

  defp apply_transform(
         state,
         target_frame,
         :provider_defined_earth_fixed_to_earth_inertial_j2000,
         angle_rad,
         rate_rad_s
       ) do
    transport_term_km_s = rotation_transport_term(state.position_km, rate_rad_s)

    StateVector.new!(
      rotate_z(state.position_km, angle_rad),
      state.velocity_km_s
      |> Vector3.add(transport_term_km_s)
      |> rotate_z(angle_rad),
      state.epoch,
      target_frame
    )
  end

  defp round_trip_evidence(source, transformed, direction, angle_rad, rate_rad_s) do
    inverse_direction = inverse_direction(direction)

    round_trip_state =
      apply_transform(transformed, source.frame, inverse_direction, angle_rad, rate_rad_s)

    position_error_km =
      round_trip_state.position_km
      |> Vector3.subtract(source.position_km)
      |> Vector3.norm()

    velocity_error_km_s =
      round_trip_state.velocity_km_s
      |> Vector3.subtract(source.velocity_km_s)
      |> Vector3.norm()

    position_scale_km =
      maximum_vector_norm([
        source.position_km,
        transformed.position_km,
        round_trip_state.position_km
      ])

    velocity_scale_km_s =
      max(
        maximum_vector_norm([
          source.velocity_km_s,
          transformed.velocity_km_s,
          round_trip_state.velocity_km_s
        ]),
        abs(rate_rad_s) * position_scale_km
      )

    position_tolerance_km =
      max(
        @position_absolute_tolerance_km,
        @round_trip_relative_scale_factor * position_scale_km
      )

    velocity_tolerance_km_s =
      max(
        @velocity_absolute_tolerance_km_s,
        @round_trip_relative_scale_factor * velocity_scale_km_s
      )

    %{
      position_error_km: position_error_km,
      velocity_error_km_s: velocity_error_km_s,
      tolerance_model: :absolute_floor_plus_realized_scale,
      position_scale_km: position_scale_km,
      velocity_scale_km_s: velocity_scale_km_s,
      position_absolute_floor_km: @position_absolute_tolerance_km,
      velocity_absolute_floor_km_s: @velocity_absolute_tolerance_km_s,
      relative_scale_factor: @round_trip_relative_scale_factor,
      position_tolerance_km: position_tolerance_km,
      velocity_tolerance_km_s: velocity_tolerance_km_s,
      within_tolerance:
        position_error_km <= position_tolerance_km and
          velocity_error_km_s <= velocity_tolerance_km_s
    }
  end

  defp inverse_direction(:earth_inertial_j2000_to_provider_defined_earth_fixed),
    do: :provider_defined_earth_fixed_to_earth_inertial_j2000

  defp inverse_direction(:provider_defined_earth_fixed_to_earth_inertial_j2000),
    do: :earth_inertial_j2000_to_provider_defined_earth_fixed

  defp validate_round_trip(%{within_tolerance: true}), do: :ok

  defp validate_round_trip(round_trip),
    do: {:error, {:round_trip_tolerance_exceeded, round_trip}}

  defp evidence(
         state,
         target_frame,
         central_body,
         policy,
         rotation_product,
         direction,
         angle_rad,
         rate_rad_s,
         transformed_state,
         round_trip
       ) do
    earth_fixed_position =
      case direction do
        :earth_inertial_j2000_to_provider_defined_earth_fixed ->
          transformed_state.position_km

        :provider_defined_earth_fixed_to_earth_inertial_j2000 ->
          state.position_km
      end

    velocity_operation =
      case direction do
        :earth_inertial_j2000_to_provider_defined_earth_fixed ->
          :subtract_omega_cross_earth_fixed_position_after_rotation

        :provider_defined_earth_fixed_to_earth_inertial_j2000 ->
          :add_omega_cross_earth_fixed_position_before_rotation
      end

    %{
      model: capabilities().model,
      validation_level: capabilities().validation_level,
      direction: direction,
      central_body: central_body.name,
      epoch: %{
        seconds_since_j2000: state.epoch.seconds_since_j2000 * 1.0,
        time_scale: state.epoch.scale
      },
      source_frame: frame_evidence(state.frame),
      target_frame: frame_evidence(target_frame),
      rotation: %{
        earth_rotation_angle_rad: angle_rad,
        earth_rotation_rate_rad_s: rate_rad_s,
        position_rotation_rad:
          if(direction == :earth_inertial_j2000_to_provider_defined_earth_fixed,
            do: -angle_rad,
            else: angle_rad
          )
      },
      velocity: %{
        model: :rotating_frame_transport_term,
        operation: velocity_operation,
        angular_velocity_rad_s: {0.0, 0.0, rate_rad_s},
        transport_term_km_s: rotation_transport_term(earth_fixed_position, rate_rad_s)
      },
      provider: %{
        id: policy.capability["id"],
        model: policy.capability["model"],
        source: policy.capability["source"],
        source_revision: policy.source_revision,
        coverage: policy.capability["coverage"],
        interpolation:
          Map.get(rotation_product, "interpolation") || policy.capability["interpolation"],
        network_access: policy.capability["network_access"],
        validation_level: policy.capability["validation_level"],
        known_limits: policy.capability["known_limits"]
      },
      round_trip: round_trip,
      known_limits: capabilities().known_limits
    }
  end

  defp frame_evidence(frame) do
    %{name: frame.name, center: frame.center, orientation: frame.orientation}
  end

  defp rotation_transport_term(position_km, rate_rad_s) do
    Vector3.cross({0.0, 0.0, rate_rad_s}, position_km)
  end

  defp maximum_vector_norm(vectors) do
    Enum.reduce(vectors, 1.0, fn vector, maximum ->
      max(maximum, Vector3.norm(vector))
    end)
  end

  defp rotate_z({x, y, z}, angle_rad) do
    cos_angle = :math.cos(angle_rad)
    sin_angle = :math.sin(angle_rad)

    {
      cos_angle * x - sin_angle * y,
      sin_angle * x + cos_angle * y,
      z * 1.0
    }
  end

  defp policy_integrity_sha256(provider, provider_opts, capability, source_revision) do
    {provider, provider_opts, capability, source_revision}
    |> :erlang.term_to_binary([:deterministic])
    |> then(&:crypto.hash(:sha256, &1))
    |> Base.encode16(case: :lower)
  end

  defp vector_components_within?({x, y, z}, maximum_magnitude) do
    number_in_symmetric_range?(x, maximum_magnitude) and
      number_in_symmetric_range?(y, maximum_magnitude) and
      number_in_symmetric_range?(z, maximum_magnitude)
  end

  defp vector_components_within?(_vector, _maximum_magnitude), do: false

  defp number_in_symmetric_range?(value, maximum_magnitude) when is_integer(value),
    do: value >= -maximum_magnitude and value <= maximum_magnitude

  defp number_in_symmetric_range?(value, maximum_magnitude) when is_float(value),
    do: value == value and value >= -maximum_magnitude and value <= maximum_magnitude

  defp number_in_symmetric_range?(_value, _maximum_magnitude), do: false

  defp positive_number?(value) when is_integer(value), do: value > 0
  defp positive_number?(value) when is_float(value), do: value == value and value > 0.0
  defp positive_number?(_value), do: false

  defp non_negative_number?(value) when is_integer(value), do: value >= 0
  defp non_negative_number?(value) when is_float(value), do: value == value and value >= 0.0
  defp non_negative_number?(_value), do: false

  defp number?(value), do: is_integer(value) or is_float(value)
end
