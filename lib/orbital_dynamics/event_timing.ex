defmodule OrbitalDynamics.EventTiming do
  @moduledoc """
  Detector-wide event timing tolerance metadata.

  Canonical standalone analysis searches use `OrbitalDynamics.EventSearch`,
  with explicit source fidelity, discovery controls and per-target root brackets.
  The metadata below belongs to the existing study/artifact pipeline.

  Those event detectors are sampled detectors with linear boundary
  interpolation as the compatibility default. Access-window callers may opt
  into detector-local root refinement on an interpolated state path. This
  module retains the conservative default policy; the access detector adds its
  tighter local root bracket and explicit interpolation limits without claiming
  dense propagation or general external validation. A separate exact-case
  contract binds the checked Orekit J2-drag access result without widening that
  claim to other detector inputs or providers.
  """

  alias OrbitalDynamics.{Epoch, StateVector, Trajectory}

  @max_states 10_000
  @max_opts_length 64
  @max_container_depth 8
  @max_container_entries 2_048
  @max_list_length 1_024
  @max_map_size 128
  @safe_number_limit 1.0e15
  @epoch_scales [:tdb, :tai, :utc]
  @metadata_vector_keys [
    "sun_direction",
    "before_sun_direction",
    "after_sun_direction",
    "sun_direction_at_start_sample",
    "sun_direction_at_end_sample"
  ]
  @orekit_access_case_id "external_truth.orekit_13_1_7.earth_j2_drag_rk4_10s_access_eclipse_6h"
  @orekit_access_bundle_identity %{
    manifest_sha256: "f4dbcf59007ac1552bb447d13aa9166b7846d393e7fc23d1d60a04fa841e91cd",
    source_manifest_sha256: "4b6e875b2cbee2c20e83b268c5b07cedeb8c6ff96ce36a2de7dbf9741a217c93",
    result_sha256: "88f0ab20bd24a78bda74cfa8091f9e0546e85eee0e2c4719bde988ad2c66649f"
  }
  @orekit_access_case_input %{
    reference_tool: %{name: "Apache Orekit", version: "13.1.7"},
    frame: "EME2000",
    epoch: "2000-01-01T12:00:00_TDB",
    time_scale: "TDB_J2000_RELATIVE_SECONDS",
    horizon_s: 21_600.0,
    output_step_s: 10.0,
    initial_position_m: [7_000_000.0, 0.0, 0.0],
    initial_velocity_m_s: [0.0, 4_687.21425101214, 5_913.792592089408],
    mu_m3_s2: 398_600_441_800_000.0,
    equatorial_radius_m: 6_378_136.3,
    j2: 1.08262668e-3,
    atmosphere_model: "SimpleExponentialAtmosphere",
    atmosphere_reference_altitude_m: 400_000.0,
    atmosphere_reference_density_kg_m3: 3.89e-12,
    atmosphere_scale_height_m: 60_000.0,
    body_flattening: 0.0,
    earth_orientation_model: "constant_z_axis_rotation_from_zero_angle_at_case_epoch",
    earth_rotation_rate_rad_s: 7.292115e-5,
    earth_rotation_angle_at_epoch_rad: 0.0,
    eop_source: "none",
    station_latitude_deg: 0.0,
    station_longitude_deg: -60.0,
    station_altitude_m: 0.0,
    minimum_elevation_deg: 5.0,
    atmospheric_refraction: "none",
    terrain_mask: "none",
    reference_root_threshold_s: 1.0e-9,
    reference_root_max_iterations: 100
  }
  @orekit_access_path_identity %{
    propagator: "OrbitalDynamics.Propagators.J2Drag",
    force_model: :earth_j2_atmospheric_drag,
    force_models: [:point_mass_two_body, :j2, :atmospheric_drag],
    force_composition: :single_acceleration_sum_per_rk4_stage,
    numerical_method: :rk4_fixed_step,
    frame: :eci_j2000,
    epoch_scale: :tdb,
    output_step_s: 10.0,
    max_step_s: 10.0,
    atmosphere_provider_id: "environment.provider.atmosphere.exponential_reference",
    atmosphere_source_revision: "exponential-reference.v1",
    earth_rotation_provider_id: "environment.provider.earth_rotation.constant_rate",
    earth_rotation_source_revision: "constant-earth-rotation.v1",
    earth_rotation_rate_rad_s: 7.292115e-5,
    spacecraft_mass_kg: 120.0,
    drag_area_m2: 4.0,
    drag_coefficient: 2.2,
    access_detector: "OrbitalDynamics.EventDetectors.AccessWindows",
    access_root_tolerance_s: 1.0e-6,
    access_root_max_iterations: 64,
    access_boundaries: :aos_los_bracketed_bisection
  }
  @orekit_access_coverage %{starts_at_s: 0.0, ends_at_s: 21_600.0, sample_count: 2_161}
  @orekit_access_reference_boundaries [
    %{type: "aos", epoch_s: 11_226.953193089854},
    %{type: "los", epoch_s: 11_828.755210512007},
    %{type: "aos", epoch_s: 17_310.375092284656},
    %{type: "los", epoch_s: 17_864.992814967594}
  ]
  @orekit_access_error_tolerance_s 1.0e-3
  @orekit_access_root_tolerance_s 1.0e-6
  @orekit_access_root_max_iterations 64
  @orekit_access_input_bracket_s 10.0
  # All admitted epochs are within 0..21_600 seconds. One nanosecond is a
  # conservative ceiling over binary64 rounding from the detector's affine
  # interpolation while remaining three orders tighter than the root bound.
  @orekit_access_epoch_float_tolerance_s 1.0e-9
  # Absolute bracket endpoints can be as large as 21_600 seconds. Binary64
  # spacing there is 2^-38 seconds (about 3.638e-12), so 4e-12 admits at most
  # one endpoint-subtraction ULP while remaining far below one bisection step.
  @orekit_access_bracket_float_tolerance_s 4.0e-12
  @orekit_access_convergence_keys [
    :boundary,
    :edge,
    :interpolation,
    :refinement_model,
    :root_solver,
    :root_function,
    :root_scope,
    :root_solved,
    :validation_level,
    :confidence,
    :convergence,
    :requested_root_tolerance_s,
    :event_time_tolerance_s,
    :event_time_bracket_s,
    :input_event_time_bracket_s,
    :before_epoch_s,
    :after_epoch_s,
    :before_sample_index,
    :after_sample_index,
    :root_bracket_before_epoch_s,
    :root_bracket_after_epoch_s,
    :root_bracket_before_margin_deg,
    :root_bracket_after_margin_deg,
    :root_estimate_margin_deg,
    :root_iterations,
    :root_function_evaluations,
    :root_max_iterations,
    :model_limits
  ]
  @orekit_access_root_model_limits [
    :cubic_hermite_state_interpolation_between_samples,
    :not_dense_propagator_output,
    :single_bracketed_crossing_selected,
    :constant_earth_rotation_access_geometry,
    :not_externally_validated,
    :not_flight_fidelity
  ]
  @orekit_access_claim_limits [
    :exact_single_orekit_13_1_7_case_only,
    :four_boundaries_over_0_to_21600_tdb_seconds,
    :cubic_hermite_between_10_second_propagator_samples,
    :multiple_crossings_within_sample_not_resolved,
    :constant_earth_rotation_without_eop,
    :no_terrain_mask,
    :no_refraction_model,
    :no_continuous_combination_claim,
    :exact_interpolated_root_work_counts_not_admitted,
    :not_flight_certification,
    :not_operational_acceptance
  ]

  @doc false
  def orekit_access_contract_authority do
    %{
      input: %{
        case_id: @orekit_access_case_id,
        bundle_identity: @orekit_access_bundle_identity,
        case_input: @orekit_access_case_input,
        path_identity: @orekit_access_path_identity,
        coverage: @orekit_access_coverage,
        reference_boundaries: @orekit_access_reference_boundaries
      },
      error_tolerance_s: @orekit_access_error_tolerance_s,
      epoch_float_tolerance_s: @orekit_access_epoch_float_tolerance_s,
      convergence_keys: @orekit_access_convergence_keys,
      root_model_limits: @orekit_access_root_model_limits,
      claim_limits: @orekit_access_claim_limits
    }
  end

  @doc """
  Evaluates the bounded propagator-coupled access timing error contract.

  This contract admits only the checked Orekit 13.1.7 six-hour J2-drag case.
  It binds the checked source/result identities, exact physical and numerical
  inputs, propagated coverage, internal detector path, and four AOS/LOS
  boundaries. Every observed boundary must retain AccessWindows first-stop
  bisection or exact-sample convergence evidence from the cubic-Hermite path
  before its absolute timing error is compared with the existing 1 ms
  external-reference bound. Exact-interpolated work counts are not admitted
  because the current metadata retains no penultimate bracket that proves them.

  The returned evidence does not widen the exact-case claim to other states,
  stations, cadences, providers, terrain/refraction models, EOP sources, or
  continuous parameter combinations.
  """
  def propagator_coupled_access_error_contract(%{} = input) do
    with :ok <- preflight_metadata(input),
         :ok <- validate_access_contract_shape(input),
         :ok <- validate_access_contract_identity(input),
         {:ok, observed_boundaries} <-
           validate_access_observed_boundaries(input.observed_boundaries) do
      access_error_contract_evidence(input, observed_boundaries)
    end
  end

  def propagator_coupled_access_error_contract(_input),
    do: {:error, {:invalid_access_timing_contract, :input}}

  @doc """
  Builds timing policy metadata for a detected event.
  """
  def policy(trajectory, detector, opts \\ [])

  def policy(%Trajectory{} = trajectory, detector, opts) do
    with :ok <- validate_opts(opts),
         {:ok, max_sample_step_s} <- max_sample_step_s(trajectory) do
      interpolation = Keyword.get(opts, :interpolation, :linear_sample_crossing)

      %{
        event_timing_policy: :sampled_state_linear_boundary,
        event_detector: detector,
        interpolation: interpolation,
        event_time_tolerance_s: max_sample_step_s,
        max_sample_step_s: max_sample_step_s,
        confidence: confidence(max_sample_step_s, interpolation)
      }
    end
  end

  def policy(_trajectory, _detector, opts) do
    with :ok <- validate_opts(opts), do: {:error, {:invalid_option, :trajectory}}
  end

  @doc """
  Builds local timing metadata for a refined boundary bracket.

  `policy/3` describes the whole trajectory cadence. Refined event boundaries
  also need the local before/after sample width, because a dense region in an
  otherwise sparse trajectory has a tighter timing bound than the trajectory
  maximum.
  """
  def boundary_policy(before_epoch, after_epoch, opts \\ [])

  def boundary_policy(before_epoch, after_epoch, opts) do
    with :ok <- validate_opts(opts),
         {:ok, before_s} <- epoch_seconds(before_epoch, :before_epoch),
         {:ok, after_s} <- epoch_seconds(after_epoch, :after_epoch) do
      interpolation = Keyword.get(opts, :interpolation, :linear_sample_crossing)
      bracket_s = abs(after_s - before_s) * 1.0

      %{
        event_timing_policy: :sampled_state_linear_boundary,
        interpolation: interpolation,
        event_time_tolerance_s: bracket_s,
        event_time_bracket_s: bracket_s,
        before_epoch_s: before_s,
        after_epoch_s: after_s,
        root_solved: false,
        confidence: confidence(bracket_s, interpolation)
      }
    end
  end

  @doc """
  Adds event timing policy metadata to an event.
  """
  def annotate_event(event, trajectory, detector, opts \\ [])

  def annotate_event(%{} = event, %Trajectory{} = trajectory, detector, opts) do
    with :ok <- validate_opts(opts),
         {:ok, metadata} <- event_metadata(event),
         %{} = timing_policy <- policy(trajectory, detector, opts) do
      Map.put(event, :metadata, Map.merge(timing_policy, metadata))
    else
      {:error, reason} -> {:error, reason}
    end
  end

  def annotate_event(_event, _trajectory, _detector, opts) do
    with :ok <- validate_opts(opts), do: {:error, {:invalid_option, :event}}
  end

  defp event_metadata(%{metadata: metadata}) when is_map(metadata) do
    with :ok <- preflight_metadata(metadata) do
      {:ok, metadata}
    end
  end

  defp event_metadata(%{metadata: nil}), do: {:ok, %{}}
  defp event_metadata(%{metadata: _metadata}), do: {:error, {:invalid_event, :metadata}}
  defp event_metadata(_event), do: {:ok, %{}}

  defp max_sample_step_s(%Trajectory{states: states}) do
    with {:ok, states} <- bounded_list_items(states, :states, @max_states),
         :ok <- validate_state_epochs(states) do
      max_state_step_s(states)
    end
  end

  defp max_state_step_s([]), do: {:ok, 0.0}
  defp max_state_step_s([_state]), do: {:ok, 0.0}

  defp max_state_step_s(states) do
    max_step_s =
      states
      |> Enum.map(& &1.epoch.seconds_since_j2000)
      |> Enum.chunk_every(2, 1, :discard)
      |> Enum.map(fn [before_s, after_s] -> abs(after_s - before_s) end)
      |> Enum.max(fn -> 0.0 end)
      |> Kernel.*(1.0)

    {:ok, max_step_s}
  end

  defp confidence(max_sample_step_s, _interpolation) when max_sample_step_s == 0.0,
    do: :exact_sample_only

  defp confidence(_max_sample_step_s, :linear_sample_crossing), do: :bounded_by_sample_cadence
  defp confidence(_max_sample_step_s, _interpolation), do: :sampled

  defp validate_access_contract_shape(input) do
    expected_keys = [
      :bundle_identity,
      :case_id,
      :case_input,
      :coverage,
      :observed_boundaries,
      :path_identity,
      :reference_boundaries
    ]

    if Enum.sort(Map.keys(input)) == Enum.sort(expected_keys),
      do: :ok,
      else: {:error, {:invalid_access_timing_contract, :shape}}
  end

  defp validate_access_contract_identity(input) do
    identities = [
      {:case_id, @orekit_access_case_id, input.case_id},
      {:bundle_identity, @orekit_access_bundle_identity, input.bundle_identity},
      {:case_input, @orekit_access_case_input, input.case_input},
      {:path_identity, @orekit_access_path_identity, input.path_identity},
      {:coverage, @orekit_access_coverage, input.coverage},
      {:reference_boundaries, @orekit_access_reference_boundaries, input.reference_boundaries}
    ]

    case Enum.find(identities, fn {_field, expected, observed} -> expected != observed end) do
      nil -> :ok
      {field, _expected, _observed} -> {:error, {:unsupported_access_timing_contract, field}}
    end
  end

  defp validate_access_observed_boundaries(boundaries) do
    with {:ok, boundaries} <- bounded_list_items(boundaries, :observed_boundaries, 4),
         true <- length(boundaries) == 4,
         :ok <- validate_access_boundary_rows(boundaries),
         true <-
           boundaries
           |> Enum.map(& &1.epoch_s)
           |> strictly_increasing_numbers?() do
      {:ok, boundaries}
    else
      false -> {:error, {:invalid_access_timing_contract, :observed_boundaries}}
      {:error, reason} -> {:error, reason}
    end
  end

  defp validate_access_boundary_rows(boundaries) do
    boundaries
    |> Enum.zip(@orekit_access_reference_boundaries)
    |> Enum.with_index(1)
    |> Enum.reduce_while(:ok, fn {{observed, reference}, index}, :ok ->
      case validate_access_boundary_row(observed, reference.type, index) do
        :ok -> {:cont, :ok}
        {:error, reason} -> {:halt, {:error, reason}}
      end
    end)
  end

  defp validate_access_boundary_row(%{} = row, expected_type, index) do
    cond do
      Enum.sort(Map.keys(row)) != [:convergence, :epoch_s, :type] ->
        invalid_access_boundary(index, :shape)

      row.type != expected_type ->
        invalid_access_boundary(index, :type)

      not finite_number?(row.epoch_s) ->
        invalid_access_boundary(index, :epoch_s)

      row.epoch_s < @orekit_access_coverage.starts_at_s or
          row.epoch_s > @orekit_access_coverage.ends_at_s ->
        invalid_access_boundary(index, :coverage)

      true ->
        validate_access_convergence(row.convergence, expected_type, row.epoch_s, index)
    end
  end

  defp validate_access_boundary_row(_row, _expected_type, index),
    do: invalid_access_boundary(index, :shape)

  defp validate_access_convergence(%{} = convergence, type, epoch_s, index) do
    expected_boundary = if(type == "aos", do: :aos, else: :los)
    expected_edge = if(type == "aos", do: :start, else: :end)

    cond do
      Enum.sort(Map.keys(convergence)) != Enum.sort(@orekit_access_convergence_keys) ->
        invalid_access_boundary(index, :convergence_shape)

      convergence.boundary != expected_boundary or convergence.edge != expected_edge ->
        invalid_access_boundary(index, :boundary_identity)

      convergence.interpolation != :cubic_hermite_state or
        convergence.refinement_model != :aos_los_bracketed_bisection or
        convergence.root_solver != :bisection or
        convergence.root_function != :elevation_margin_deg or
          convergence.root_scope != :cubic_hermite_interpolated_state_geometry ->
        invalid_access_boundary(index, :solver_identity)

      convergence.root_solved != true or convergence.validation_level != :analysis or
        convergence.confidence != :bounded_root_in_interpolated_state or
          convergence.convergence not in [:time_bracket, :exact_sample] ->
        invalid_access_boundary(index, :convergence)

      convergence.requested_root_tolerance_s != @orekit_access_root_tolerance_s or
        convergence.root_max_iterations != @orekit_access_root_max_iterations or
          convergence.input_event_time_bracket_s != @orekit_access_input_bracket_s ->
        invalid_access_boundary(index, :solver_bounds)

      convergence.model_limits != @orekit_access_root_model_limits ->
        invalid_access_boundary(index, :model_limits)

      not valid_access_root_numbers?(convergence) ->
        invalid_access_boundary(index, :root_numerics)

      not valid_access_sample_bracket?(convergence) ->
        invalid_access_boundary(index, :sample_bracket_identity)

      convergence.before_epoch_s < @orekit_access_coverage.starts_at_s or
        convergence.after_epoch_s > @orekit_access_coverage.ends_at_s or
        convergence.root_bracket_before_epoch_s < @orekit_access_coverage.starts_at_s or
          convergence.root_bracket_after_epoch_s > @orekit_access_coverage.ends_at_s ->
        invalid_access_boundary(index, :root_bracket_coverage)

      convergence.root_bracket_before_epoch_s <
        convergence.before_epoch_s - @orekit_access_epoch_float_tolerance_s or
          convergence.root_bracket_after_epoch_s >
            convergence.after_epoch_s + @orekit_access_epoch_float_tolerance_s ->
        invalid_access_boundary(index, :root_bracket_outside_sample_bracket)

      convergence.event_time_tolerance_s > @orekit_access_root_tolerance_s or
          convergence.event_time_bracket_s > 2.0 * @orekit_access_root_tolerance_s ->
        invalid_access_boundary(index, :root_tolerance)

      not near?(
        convergence.event_time_bracket_s,
        2.0 * convergence.event_time_tolerance_s,
        1.0e-12
      ) ->
        invalid_access_boundary(index, :root_tolerance_consistency)

      not near?(
        convergence.root_bracket_after_epoch_s - convergence.root_bracket_before_epoch_s,
        convergence.event_time_bracket_s,
        @orekit_access_bracket_float_tolerance_s
      ) ->
        invalid_access_boundary(index, :root_bracket_width)

      epoch_s <
        convergence.root_bracket_before_epoch_s -
          @orekit_access_epoch_float_tolerance_s or
          epoch_s >
            convergence.root_bracket_after_epoch_s +
              @orekit_access_epoch_float_tolerance_s ->
        invalid_access_boundary(index, :root_estimate_outside_bracket)

      true ->
        validate_access_convergence_semantics(convergence, expected_boundary, epoch_s, index)
    end
  end

  defp validate_access_convergence(_convergence, _type, _epoch_s, index),
    do: invalid_access_boundary(index, :convergence_shape)

  defp valid_access_root_numbers?(convergence) do
    numeric_fields = [
      :event_time_tolerance_s,
      :event_time_bracket_s,
      :input_event_time_bracket_s,
      :before_epoch_s,
      :after_epoch_s,
      :root_bracket_before_epoch_s,
      :root_bracket_after_epoch_s,
      :root_bracket_before_margin_deg,
      :root_bracket_after_margin_deg,
      :root_estimate_margin_deg
    ]

    Enum.all?(numeric_fields, &finite_number?(Map.get(convergence, &1))) and
      convergence.event_time_tolerance_s >= 0.0 and
      convergence.event_time_bracket_s >= 0.0 and
      convergence.root_bracket_before_epoch_s <= convergence.root_bracket_after_epoch_s and
      is_integer(convergence.before_sample_index) and
      is_integer(convergence.after_sample_index) and
      is_integer(convergence.root_iterations) and convergence.root_iterations >= 0 and
      convergence.root_iterations <= @orekit_access_root_max_iterations and
      is_integer(convergence.root_function_evaluations) and
      convergence.root_function_evaluations >= convergence.root_iterations + 2
  end

  defp valid_access_sample_bracket?(convergence) do
    before_index = convergence.before_sample_index
    after_index = convergence.after_sample_index
    starts_at_s = @orekit_access_coverage.starts_at_s
    sample_count = @orekit_access_coverage.sample_count

    before_index >= 0 and after_index == before_index + 1 and after_index < sample_count and
      convergence.before_epoch_s < convergence.after_epoch_s and
      near?(
        convergence.after_epoch_s - convergence.before_epoch_s,
        @orekit_access_input_bracket_s,
        @orekit_access_epoch_float_tolerance_s
      ) and
      near?(
        convergence.before_epoch_s,
        starts_at_s + before_index * @orekit_access_input_bracket_s,
        @orekit_access_epoch_float_tolerance_s
      ) and
      near?(
        convergence.after_epoch_s,
        starts_at_s + after_index * @orekit_access_input_bracket_s,
        @orekit_access_epoch_float_tolerance_s
      )
  end

  defp validate_access_convergence_semantics(
         %{convergence: :time_bracket} = convergence,
         expected_boundary,
         epoch_s,
         index
       ) do
    midpoint_s =
      convergence.root_bracket_before_epoch_s +
        (convergence.root_bracket_after_epoch_s -
           convergence.root_bracket_before_epoch_s) / 2.0

    cond do
      convergence.event_time_bracket_s <= 0.0 or
          convergence.event_time_tolerance_s <= 0.0 ->
        invalid_access_boundary(index, :time_bracket_width)

      not near?(epoch_s, midpoint_s, @orekit_access_epoch_float_tolerance_s) ->
        invalid_access_boundary(index, :root_estimate_not_midpoint)

      convergence.root_iterations <= 0 or
          convergence.root_function_evaluations != convergence.root_iterations + 3 ->
        invalid_access_boundary(index, :iteration_evaluation_semantics)

      not valid_access_time_bracket_recurrence?(convergence) ->
        invalid_access_boundary(index, :time_bracket_recurrence)

      not strict_access_margin_bracket?(
        convergence.root_bracket_before_margin_deg,
        convergence.root_bracket_after_margin_deg,
        expected_boundary
      ) ->
        invalid_access_boundary(index, :root_margin_bracket)

      true ->
        :ok
    end
  end

  defp validate_access_convergence_semantics(
         %{convergence: :exact_sample} = convergence,
         _expected_boundary,
         epoch_s,
         index
       ) do
    exact_sample_epoch? =
      epoch_s == convergence.before_epoch_s or epoch_s == convergence.after_epoch_s

    cond do
      convergence.event_time_tolerance_s != 0.0 or
        convergence.event_time_bracket_s != 0.0 or
        convergence.root_bracket_before_epoch_s != convergence.root_bracket_after_epoch_s or
        epoch_s != convergence.root_bracket_before_epoch_s or
        convergence.root_bracket_before_margin_deg != 0.0 or
        convergence.root_bracket_after_margin_deg != 0.0 or
          convergence.root_estimate_margin_deg != 0.0 ->
        invalid_access_boundary(index, :exact_root_zero_width)

      convergence.root_iterations != 0 or convergence.root_function_evaluations != 2 or
          not exact_sample_epoch? ->
        invalid_access_boundary(index, :iteration_evaluation_semantics)

      true ->
        :ok
    end
  end

  defp valid_access_time_bracket_recurrence?(convergence) do
    expected_width_s =
      bisected_width_s(
        convergence.input_event_time_bracket_s,
        convergence.root_iterations
      )

    expected_half_width_s = expected_width_s / 2.0

    # AccessWindows derives both reported widths in fraction space, where this
    # dyadic recurrence is exact; only absolute-epoch endpoint subtraction uses
    # the one-ULP allowance above.
    convergence.event_time_bracket_s == expected_width_s and
      convergence.event_time_tolerance_s == expected_half_width_s and
      expected_half_width_s <= convergence.requested_root_tolerance_s and
      expected_width_s > convergence.requested_root_tolerance_s
  end

  defp bisected_width_s(width_s, 0), do: width_s

  defp bisected_width_s(width_s, remaining_iterations),
    do: bisected_width_s(width_s / 2.0, remaining_iterations - 1)

  defp strict_access_margin_bracket?(before_margin, after_margin, :aos),
    do: before_margin < 0.0 and after_margin > 0.0

  defp strict_access_margin_bracket?(before_margin, after_margin, :los),
    do: before_margin > 0.0 and after_margin < 0.0

  defp strictly_increasing_numbers?([first | rest]) do
    {_last, increasing?} =
      Enum.reduce(rest, {first, true}, fn value, {previous, increasing?} ->
        {value, increasing? and value > previous}
      end)

    increasing?
  end

  defp strictly_increasing_numbers?(_values), do: false

  defp near?(left, right, tolerance), do: abs(left - right) <= tolerance

  defp invalid_access_boundary(index, field),
    do: {:error, {:invalid_access_timing_contract, {:observed_boundary, index, field}}}

  defp access_error_contract_evidence(input, observed_boundaries) do
    boundary_errors =
      @orekit_access_reference_boundaries
      |> Enum.zip(observed_boundaries)
      |> Enum.with_index(1)
      |> Enum.map(fn {{reference, observed}, index} ->
        absolute_error_s = abs(reference.epoch_s - observed.epoch_s)

        %{
          index: index,
          type: reference.type,
          reference_epoch_s: reference.epoch_s,
          observed_epoch_s: observed.epoch_s,
          absolute_error_s: absolute_error_s,
          within_tolerance: absolute_error_s <= @orekit_access_error_tolerance_s
        }
      end)

    maximum_error_s = boundary_errors |> Enum.map(& &1.absolute_error_s) |> Enum.max()
    convergence_rows = Enum.map(observed_boundaries, & &1.convergence)

    evidence = %{
      schema: "propagator_coupled_access_timing_error_contract.v1",
      case_id: @orekit_access_case_id,
      status: if(maximum_error_s <= @orekit_access_error_tolerance_s, do: :pass, else: :fail),
      validation_level: :validated,
      bundle_identity: input.bundle_identity,
      exact_case_input: input.case_input,
      path_identity: input.path_identity,
      coverage:
        input.coverage
        |> Map.put(:reference_boundary_count, length(@orekit_access_reference_boundaries))
        |> Map.put(:observed_boundary_count, length(observed_boundaries)),
      convergence: %{
        boundary_count: length(convergence_rows),
        converged_boundary_count: Enum.count(convergence_rows, & &1.root_solved),
        requested_root_tolerance_s: @orekit_access_root_tolerance_s,
        maximum_achieved_root_error_bound_s:
          convergence_rows |> Enum.map(& &1.event_time_tolerance_s) |> Enum.max(),
        maximum_final_root_bracket_s:
          convergence_rows |> Enum.map(& &1.event_time_bracket_s) |> Enum.max(),
        total_root_iterations: convergence_rows |> Enum.map(& &1.root_iterations) |> Enum.sum(),
        total_root_function_evaluations:
          convergence_rows |> Enum.map(& &1.root_function_evaluations) |> Enum.sum(),
        boundaries: convergence_rows
      },
      tolerance: %{
        metric: :absolute_event_time_error_s,
        allowed_maximum_s: @orekit_access_error_tolerance_s,
        observed_maximum_s: maximum_error_s
      },
      boundary_errors: boundary_errors,
      bounded_claim: :exact_orekit_propagator_coupled_access_boundaries,
      known_limits: @orekit_access_claim_limits
    }

    if evidence.status == :pass,
      do: {:ok, evidence},
      else: {:error, {:access_timing_error_exceeds_tolerance, evidence}}
  end

  defp validate_state_epochs(states) do
    states
    |> Enum.reduce_while({:ok, nil}, fn
      %StateVector{epoch: epoch}, {:ok, previous_s} ->
        case epoch_seconds(epoch, :state_epoch) do
          {:ok, seconds} ->
            if is_number(previous_s) and seconds < previous_s do
              {:halt, {:error, {:invalid_trajectory, :nonmonotonic_epochs}}}
            else
              {:cont, {:ok, seconds}}
            end

          {:error, _reason} ->
            {:halt, {:error, {:invalid_trajectory, :epoch_seconds_since_j2000}}}
        end

      _state, {:ok, _previous_s} ->
        {:halt, {:error, {:invalid_trajectory, :state}}}
    end)
    |> case do
      {:ok, _last_s} -> :ok
      {:error, reason} -> {:error, reason}
    end
  end

  defp epoch_seconds(%Epoch{} = epoch, field) do
    if exact_epoch_shape?(epoch) do
      scale = Map.fetch!(epoch, :scale)
      seconds = Map.fetch!(epoch, :seconds_since_j2000)

      if scale in @epoch_scales and finite_number?(seconds) do
        {:ok, seconds * 1.0}
      else
        {:error, {:invalid_epoch, field}}
      end
    else
      {:error, {:invalid_epoch, field}}
    end
  end

  defp epoch_seconds(%{__struct__: _struct}, field), do: {:error, {:invalid_epoch, field}}
  defp epoch_seconds(%{}, field), do: {:error, {:invalid_epoch, field}}

  defp epoch_seconds(_epoch, field), do: {:error, {:invalid_epoch, field}}

  defp exact_epoch_shape?(epoch) do
    map_size(epoch) == 3 and Map.has_key?(epoch, :scale) and
      Map.has_key?(epoch, :seconds_since_j2000)
  end

  defp validate_opts(opts) do
    with {:ok, items} <- bounded_list_items(opts, :opts, @max_opts_length),
         true <- Enum.all?(items, &keyword_entry?/1),
         true <- unique_keyword_keys?(items),
         :ok <- preflight_option_values(items) do
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
    values = Enum.map(items, fn {_key, value} -> value end)
    preflight_container(values, :opts)
  end

  defp preflight_metadata(metadata) do
    preflight_metadata([{metadata, 0, nil}], 0)
  end

  defp preflight_metadata([], _visited), do: :ok

  defp preflight_metadata(_stack, visited) when visited > @max_container_entries,
    do: {:error, {:container_limit_exceeded, :metadata}}

  defp preflight_metadata([{_term, depth, _key_name} | _rest], _visited)
       when depth > @max_container_depth,
       do: {:error, {:container_depth_exceeded, :metadata}}

  defp preflight_metadata([{%{__struct__: _struct}, _depth, _key_name} | _rest], _visited),
    do: {:error, {:invalid_container, :metadata}}

  defp preflight_metadata([{tuple, _depth, key_name} | rest], visited) when is_tuple(tuple) do
    if key_name in @metadata_vector_keys and finite_vector_tuple?(tuple) do
      preflight_metadata(rest, visited + tuple_size(tuple))
    else
      {:error, {:invalid_container, :metadata}}
    end
  end

  defp preflight_metadata([{%{} = map, depth, _key_name} | rest], visited) do
    cond do
      map_size(map) > @max_map_size ->
        {:error, {:container_limit_exceeded, :metadata}}

      invalid_map_key?(map) ->
        {:error, {:invalid_container, :metadata}}

      true ->
        with :ok <- reject_generic_alias_collisions(map) do
          children =
            Enum.map(map, fn {key, value} -> {value, depth + 1, metadata_key_name(key)} end)

          preflight_metadata(children ++ rest, visited + map_size(map))
        end
    end
  end

  defp preflight_metadata([{list, depth, _key_name} | rest], visited) when is_list(list) do
    case bounded_list_items(list, :metadata, @max_list_length) do
      {:ok, items} ->
        children = Enum.map(items, &{&1, depth + 1, nil})
        preflight_metadata(children ++ rest, visited + length(items))

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp preflight_metadata([{term, _depth, _key_name} | rest], visited)
       when is_nil(term) or is_boolean(term) or is_atom(term) or is_binary(term) do
    preflight_metadata(rest, visited + 1)
  end

  defp preflight_metadata([{term, _depth, _key_name} | rest], visited)
       when is_integer(term) or is_float(term) do
    if finite_number?(term) do
      preflight_metadata(rest, visited + 1)
    else
      {:error, {:invalid_container, :metadata}}
    end
  end

  defp preflight_metadata([_term | _rest], _visited),
    do: {:error, {:invalid_container, :metadata}}

  defp metadata_key_name(key) when is_atom(key), do: Atom.to_string(key)
  defp metadata_key_name(key) when is_binary(key), do: key
  defp metadata_key_name(_key), do: nil

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
       when is_nil(term) or is_boolean(term) or is_atom(term) or is_binary(term) do
    preflight_container(rest, visited + 1, field)
  end

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
    keys = Map.keys(map)

    atom_key_strings =
      keys
      |> Enum.filter(&is_atom/1)
      |> Enum.map(&Atom.to_string/1)
      |> MapSet.new()

    case Enum.find(keys, fn key -> is_binary(key) and MapSet.member?(atom_key_strings, key) end) do
      nil -> :ok
      key -> {:error, {:atom_string_alias_collision, key}}
    end
  end

  defp finite_vector_tuple?({x, y, z}),
    do: finite_number?(x) and finite_number?(y) and finite_number?(z)

  defp finite_vector_tuple?(_tuple), do: false

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
end
