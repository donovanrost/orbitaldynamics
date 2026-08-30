defmodule OrbitalDynamics.EventTimingTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.{Epoch, EventTiming, Frame, StateVector, Trajectory}

  defmodule StructProbe do
    defstruct [:scale, :seconds_since_j2000]
  end

  @safe_number_bound 1_000_000_000_000_000
  test "builds detector-wide timing policy from trajectory cadence" do
    trajectory = trajectory([0.0, 30.0, 90.0])

    assert %{
             event_timing_policy: :sampled_state_linear_boundary,
             event_detector: :access_windows,
             interpolation: :linear_sample_crossing,
             event_time_tolerance_s: 60.0,
             max_sample_step_s: 60.0,
             confidence: :bounded_by_sample_cadence
           } = EventTiming.policy(trajectory, :access_windows)
  end

  test "builds local boundary timing policy from bracket epochs" do
    [before_state, after_state] = trajectory([10.0, 25.0]).states

    assert %{
             event_timing_policy: :sampled_state_linear_boundary,
             interpolation: :linear_sample_crossing,
             event_time_tolerance_s: 15.0,
             event_time_bracket_s: 15.0,
             before_epoch_s: 10.0,
             after_epoch_s: 25.0,
             root_solved: false,
             confidence: :bounded_by_sample_cadence
           } = EventTiming.boundary_policy(before_state.epoch, after_state.epoch)
  end

  test "public boundary timing accepts only closed finite Epoch structs" do
    for scale <- [:tdb, :tai, :utc] do
      assert %{
               event_time_bracket_s: 15.0,
               before_epoch_s: 10.0,
               after_epoch_s: 25.0
             } =
               EventTiming.boundary_policy(
                 Epoch.new!(10.0, scale),
                 Epoch.new!(25.0, scale)
               )
    end

    for bad_epoch <- [
          %{seconds_since_j2000: 10.0},
          %{"seconds_since_j2000" => 10.0},
          %{"seconds_since_j2000" => 10.0, seconds_since_j2000: 10.0},
          %{__struct__: Epoch, scale: :tdb, seconds_since_j2000: 10.0, caller_shadow: true},
          %{__struct__: Epoch, scale: :tdb},
          %{__struct__: Epoch, seconds_since_j2000: 10.0},
          %StructProbe{scale: :tdb, seconds_since_j2000: 10.0},
          %Epoch{scale: :gps, seconds_since_j2000: 10.0},
          %Epoch{scale: :unknown, seconds_since_j2000: 10.0},
          %Epoch{scale: :tdb, seconds_since_j2000: 1.0e16},
          %Epoch{scale: :tdb, seconds_since_j2000: :not_numeric}
        ] do
      assert {:error, {:invalid_epoch, :before_epoch}} =
               EventTiming.boundary_policy(bad_epoch, Epoch.new!(25.0, :tdb))
    end

    assert {:error, {:invalid_trajectory, :epoch_seconds_since_j2000}} =
             EventTiming.policy(
               trajectory_with_epoch(%Epoch{
                 scale: :gps,
                 seconds_since_j2000: 0.0
               }),
               :eclipses
             )

    assert {:error, {:invalid_trajectory, :epoch_seconds_since_j2000}} =
             EventTiming.policy(
               trajectory_with_epoch(%{
                 __struct__: Epoch,
                 scale: :tdb,
                 seconds_since_j2000: 0.0,
                 caller_shadow: true
               }),
               :eclipses
             )
  end

  test "annotates event metadata without removing detector fields" do
    trajectory = trajectory([0.0, 60.0])

    event = %{
      type: :ground_station_access,
      metadata: %{ground_station_id: :equator, interpolation: :linear_sample_crossing}
    }

    assert %{
             metadata: %{
               ground_station_id: :equator,
               event_detector: :access_windows,
               event_time_tolerance_s: 60.0,
               confidence: :bounded_by_sample_cadence
             }
           } = EventTiming.annotate_event(event, trajectory, :access_windows)

    assert %{metadata: sun_metadata} =
             EventTiming.annotate_event(
               %{metadata: %{sun_direction: {1.0, 0.0, 0.0}}},
               trajectory,
               :eclipses
             )

    assert sun_metadata.sun_direction == {1.0, 0.0, 0.0}
    assert sun_metadata.event_detector == :eclipses

    vector_metadata = %{
      sun_direction: {1.0, 0.0, 0.0},
      sun_direction_at_start_sample: {1.0, 0.0, 0.0},
      sun_direction_at_end_sample: {0.0, 1.0, 0.0},
      end_boundary_detail: %{
        before_sun_direction: {1.0, 0.0, 0.0},
        after_sun_direction: {0.0, 1.0, 0.0}
      }
    }

    assert %{metadata: annotated_vector_metadata} =
             EventTiming.annotate_event(%{metadata: vector_metadata}, trajectory, :eclipses)

    assert annotated_vector_metadata.sun_direction_at_start_sample ==
             vector_metadata.sun_direction_at_start_sample

    assert annotated_vector_metadata.sun_direction_at_end_sample ==
             vector_metadata.sun_direction_at_end_sample

    assert annotated_vector_metadata.end_boundary_detail.before_sun_direction ==
             vector_metadata.end_boundary_detail.before_sun_direction

    assert annotated_vector_metadata.end_boundary_detail.after_sun_direction ==
             vector_metadata.end_boundary_detail.after_sun_direction

    assert annotated_vector_metadata.event_detector == :eclipses
  end

  test "builds the exact-case propagator-coupled access timing error contract" do
    authority = EventTiming.orekit_access_contract_authority()

    assert {:ok, evidence} =
             EventTiming.propagator_coupled_access_error_contract(access_contract_input())

    assert evidence.schema == "propagator_coupled_access_timing_error_contract.v1"
    assert evidence.status == :pass
    assert evidence.validation_level == :validated

    assert evidence.bundle_identity.result_sha256 ==
             "88f0ab20bd24a78bda74cfa8091f9e0546e85eee0e2c4719bde988ad2c66649f"

    assert evidence.exact_case_input.station_longitude_deg == -60.0
    assert evidence.path_identity.propagator == "OrbitalDynamics.Propagators.J2Drag"
    assert evidence.path_identity.access_boundaries == :aos_los_bracketed_bisection
    assert evidence.coverage.sample_count == 2_161
    assert evidence.coverage.reference_boundary_count == 4
    assert evidence.coverage.observed_boundary_count == 4
    assert evidence.convergence.boundary_count == 4
    assert evidence.convergence.converged_boundary_count == 4
    assert evidence.convergence.requested_root_tolerance_s == 1.0e-6
    assert evidence.convergence.maximum_achieved_root_error_bound_s <= 1.0e-6

    first_convergence = evidence.convergence.boundaries |> List.first()
    assert first_convergence.before_sample_index == 1_122
    assert first_convergence.after_sample_index == 1_123
    assert first_convergence.before_epoch_s == 11_220.0
    assert first_convergence.after_epoch_s == 11_230.0
    assert first_convergence.root_iterations == 23
    assert first_convergence.root_function_evaluations == 26
    assert first_convergence.event_time_bracket_s == 1.1920928955078125e-6
    assert first_convergence.event_time_tolerance_s == 5.9604644775390625e-7

    assert first_convergence.root_bracket_before_epoch_s >=
             first_convergence.before_epoch_s

    assert first_convergence.root_bracket_after_epoch_s <= first_convergence.after_epoch_s

    root_midpoint_s =
      first_convergence.root_bracket_before_epoch_s +
        (first_convergence.root_bracket_after_epoch_s -
           first_convergence.root_bracket_before_epoch_s) / 2.0

    assert abs(List.first(evidence.boundary_errors).observed_epoch_s - root_midpoint_s) <=
             authority.epoch_float_tolerance_s

    assert evidence.tolerance.allowed_maximum_s == 1.0e-3
    assert evidence.tolerance.observed_maximum_s < 1.0e-3
    assert Enum.all?(evidence.boundary_errors, & &1.within_tolerance)
    assert :no_continuous_combination_claim in evidence.known_limits
    assert :exact_interpolated_root_work_counts_not_admitted in evidence.known_limits
    assert :no_terrain_mask in evidence.known_limits
    assert :no_refraction_model in evidence.known_limits
  end

  test "admits the exact first-stop dyadic root bound without widening external error" do
    input = access_contract_input([0.0, 0.0, 0.0, 0.0])

    assert {:ok, evidence} =
             EventTiming.propagator_coupled_access_error_contract(input)

    assert evidence.convergence.maximum_achieved_root_error_bound_s ==
             5.9604644775390625e-7

    assert evidence.convergence.maximum_final_root_bracket_s == 1.1920928955078125e-6
    assert evidence.tolerance.observed_maximum_s == 0.0
    assert evidence.bounded_claim == :exact_orekit_propagator_coupled_access_boundaries
  end

  test "fails closed for unsupported identity, incomplete convergence, and excess timing error" do
    input = access_contract_input()

    assert {:error, {:unsupported_access_timing_contract, :path_identity}} =
             input
             |> put_in([:path_identity, :frame], :teme)
             |> EventTiming.propagator_coupled_access_error_contract()

    incomplete =
      update_in(
        input,
        [:observed_boundaries, Access.at(0), :convergence],
        &Map.delete(&1, :root_function_evaluations)
      )

    assert {:error,
            {:invalid_access_timing_contract, {:observed_boundary, 1, :convergence_shape}}} =
             EventTiming.propagator_coupled_access_error_contract(incomplete)

    excessive =
      update_in(input, [:observed_boundaries, Access.at(0)], fn boundary ->
        epoch_s = boundary.epoch_s + 0.002
        half_width_s = boundary.convergence.event_time_tolerance_s

        %{
          boundary
          | epoch_s: epoch_s,
            convergence: %{
              boundary.convergence
              | root_bracket_before_epoch_s: epoch_s - half_width_s,
                root_bracket_after_epoch_s: epoch_s + half_width_s
            }
        }
      end)

    assert {:error, {:access_timing_error_exceeds_tolerance, evidence}} =
             EventTiming.propagator_coupled_access_error_contract(excessive)

    assert evidence.status == :fail
    assert evidence.tolerance.observed_maximum_s > 1.0e-3
    refute List.first(evidence.boundary_errors).within_tolerance
  end

  test "rejects access boundary cardinality, order, and extra or missing keys" do
    input = access_contract_input()

    assert {:error, {:invalid_access_timing_contract, :observed_boundaries}} =
             input
             |> Map.update!(:observed_boundaries, &Enum.take(&1, 3))
             |> EventTiming.propagator_coupled_access_error_contract()

    assert {:error, {:invalid_access_timing_contract, {:observed_boundary, 1, :type}}} =
             input
             |> Map.update!(:observed_boundaries, fn [first, second | rest] ->
               [second, first | rest]
             end)
             |> EventTiming.propagator_coupled_access_error_contract()

    for malformed <- [Map.put(input, :unexpected, true), Map.delete(input, :coverage)] do
      assert {:error, {:invalid_access_timing_contract, :shape}} =
               EventTiming.propagator_coupled_access_error_contract(malformed)
    end

    for malformed <- [
          update_in(input, [:observed_boundaries, Access.at(0)], &Map.put(&1, :unexpected, true)),
          update_in(input, [:observed_boundaries, Access.at(0)], &Map.delete(&1, :type))
        ] do
      assert {:error, {:invalid_access_timing_contract, {:observed_boundary, 1, :shape}}} =
               EventTiming.propagator_coupled_access_error_contract(malformed)
    end

    for malformed <- [
          update_in(
            input,
            [:observed_boundaries, Access.at(0), :convergence],
            &Map.put(&1, :unexpected, true)
          ),
          update_in(
            input,
            [:observed_boundaries, Access.at(0), :convergence],
            &Map.delete(&1, :before_sample_index)
          )
        ] do
      assert {:error,
              {:invalid_access_timing_contract, {:observed_boundary, 1, :convergence_shape}}} =
               EventTiming.propagator_coupled_access_error_contract(malformed)
    end
  end

  test "rejects non-finite access numerics before contract comparison" do
    for {label, nonfinite} <- nonfinite_float_values() do
      malformed =
        put_in(
          access_contract_input(),
          [:observed_boundaries, Access.at(0), :epoch_s],
          nonfinite
        )

      assert {:error, {:invalid_container, :metadata}} =
               EventTiming.propagator_coupled_access_error_contract(malformed),
             "#{label} boundary epoch was admitted"
    end
  end

  test "binds final brackets to original samples and the reported midpoint" do
    input = access_contract_input([0.0, 0.0, 0.0, 0.0])

    wrong_sample_identity =
      put_in(
        input,
        [:observed_boundaries, Access.at(0), :convergence, :after_sample_index],
        1_124
      )

    assert {:error,
            {:invalid_access_timing_contract, {:observed_boundary, 1, :sample_bracket_identity}}} =
             EventTiming.propagator_coupled_access_error_contract(wrong_sample_identity)

    outside_sample =
      put_in(
        input,
        [:observed_boundaries, Access.at(0), :convergence, :root_bracket_before_epoch_s],
        11_219.999_999
      )

    assert {:error,
            {:invalid_access_timing_contract,
             {:observed_boundary, 1, :root_bracket_outside_sample_bracket}}} =
             EventTiming.propagator_coupled_access_error_contract(outside_sample)

    off_midpoint =
      update_in(input, [:observed_boundaries, Access.at(0)], fn boundary ->
        Map.update!(boundary, :epoch_s, &(&1 + 0.25e-6))
      end)

    assert {:error,
            {:invalid_access_timing_contract,
             {:observed_boundary, 1, :root_estimate_not_midpoint}}} =
             EventTiming.propagator_coupled_access_error_contract(off_midpoint)
  end

  test "binds time-bracket work counts and admits only provable exact-sample roots" do
    input = access_contract_input([0.0, 0.0, 0.0, 0.0])

    wrong_time_bracket_counts =
      update_in(
        input,
        [:observed_boundaries, Access.at(0), :convergence, :root_function_evaluations],
        &(&1 + 1)
      )

    assert {:error,
            {:invalid_access_timing_contract,
             {:observed_boundary, 1, :iteration_evaluation_semantics}}} =
             EventTiming.propagator_coupled_access_error_contract(wrong_time_bracket_counts)

    impossible_width_count =
      update_in(input, [:observed_boundaries, Access.at(0), :convergence], fn convergence ->
        %{convergence | root_iterations: 24, root_function_evaluations: 27}
      end)

    assert {:error,
            {:invalid_access_timing_contract, {:observed_boundary, 1, :time_bracket_recurrence}}} =
             EventTiming.propagator_coupled_access_error_contract(impossible_width_count)

    nonzero_exact =
      put_in(
        input,
        [:observed_boundaries, Access.at(0), :convergence, :convergence],
        :exact_sample
      )

    assert {:error,
            {:invalid_access_timing_contract, {:observed_boundary, 1, :exact_root_zero_width}}} =
             EventTiming.propagator_coupled_access_error_contract(nonzero_exact)

    endpoint_relabeling =
      update_in(input, [:observed_boundaries, Access.at(0)], fn boundary ->
        epoch_s = boundary.convergence.before_epoch_s

        %{
          boundary
          | epoch_s: epoch_s,
            convergence: %{
              boundary.convergence
              | convergence: :exact_interpolated_root,
                event_time_tolerance_s: 0.0,
                event_time_bracket_s: 0.0,
                root_bracket_before_epoch_s: epoch_s,
                root_bracket_after_epoch_s: epoch_s,
                root_bracket_before_margin_deg: 0.0,
                root_bracket_after_margin_deg: 0.0,
                root_estimate_margin_deg: 0.0,
                root_iterations: 1,
                root_function_evaluations: 3
            }
        }
      end)

    assert {:error, {:invalid_access_timing_contract, {:observed_boundary, 1, :convergence}}} =
             EventTiming.propagator_coupled_access_error_contract(endpoint_relabeling)

    exact_sample =
      update_in(input, [:observed_boundaries, Access.at(0)], fn boundary ->
        epoch_s = boundary.convergence.before_epoch_s

        %{
          boundary
          | epoch_s: epoch_s,
            convergence: %{
              boundary.convergence
              | convergence: :exact_sample,
                event_time_tolerance_s: 0.0,
                event_time_bracket_s: 0.0,
                root_bracket_before_epoch_s: epoch_s,
                root_bracket_after_epoch_s: epoch_s,
                root_bracket_before_margin_deg: 0.0,
                root_bracket_after_margin_deg: 0.0,
                root_estimate_margin_deg: 0.0,
                root_iterations: 0,
                root_function_evaluations: 2
            }
        }
      end)

    assert {:error, {:access_timing_error_exceeds_tolerance, exact_sample_evidence}} =
             EventTiming.propagator_coupled_access_error_contract(exact_sample)

    assert List.first(exact_sample_evidence.convergence.boundaries).convergence == :exact_sample

    interior_relabeling =
      update_in(exact_sample, [:observed_boundaries, Access.at(0)], fn boundary ->
        epoch_s = boundary.epoch_s + 0.5e-9

        %{
          boundary
          | epoch_s: epoch_s,
            convergence: %{
              boundary.convergence
              | root_bracket_before_epoch_s: epoch_s,
                root_bracket_after_epoch_s: epoch_s
            }
        }
      end)

    assert {:error,
            {:invalid_access_timing_contract,
             {:observed_boundary, 1, :iteration_evaluation_semantics}}} =
             EventTiming.propagator_coupled_access_error_contract(interior_relabeling)
  end

  test "public timing boundaries reject hostile input with typed errors" do
    trajectory = trajectory([0.0, 60.0])

    assert {:error, {:invalid_container, :opts}} =
             EventTiming.policy(trajectory, :eclipses, [
               {:interpolation, :linear_sample_crossing} | :tail
             ])

    assert {:error, {:invalid_container, :opts}} =
             EventTiming.policy(trajectory, :eclipses, audit_payload: %{42 => "bad key"})

    assert {:error, {:atom_string_alias_collision, "probe"}} =
             EventTiming.policy(trajectory, :eclipses, audit_payload: %{"probe" => 1, probe: 2})

    callback_probe = fn -> send(self(), :event_timing_callback_invoked) end

    for bad_value <- [
          %StructProbe{scale: :tdb, seconds_since_j2000: 0.0},
          self(),
          make_ref(),
          callback_probe,
          {:tuple, :not_json}
        ] do
      assert {:error, {:invalid_container, :opts}} =
               EventTiming.policy(trajectory, :eclipses, audit_payload: bad_value)

      refute_receive :event_timing_callback_invoked
    end

    assert {:error, {:invalid_option, :trajectory}} =
             EventTiming.policy(:not_a_trajectory, :eclipses)

    assert {:error, {:invalid_trajectory, :nonmonotonic_epochs}} =
             EventTiming.policy(trajectory([60.0, 0.0]), :eclipses)

    assert {:error, {:invalid_container, :states}} =
             EventTiming.policy(
               %Trajectory{trajectory | states: [List.first(trajectory.states) | :tail]},
               :eclipses
             )

    assert {:error, {:invalid_epoch, :before_epoch}} =
             EventTiming.boundary_policy(
               %{seconds_since_j2000: 1.0e16},
               Epoch.new!(0.0, :tdb)
             )

    assert {:error, {:invalid_event, :metadata}} =
             EventTiming.annotate_event(%{metadata: [:bad]}, trajectory, :eclipses)

    assert {:error, {:invalid_container, :metadata}} =
             EventTiming.annotate_event(
               %{metadata: %StructProbe{scale: :tdb, seconds_since_j2000: 0.0}},
               trajectory,
               :eclipses
             )

    assert {:error, {:atom_string_alias_collision, "probe"}} =
             EventTiming.annotate_event(
               %{metadata: %{"probe" => 1, probe: 2}},
               trajectory,
               :eclipses
             )

    assert {:error, {:invalid_container, :metadata}} =
             EventTiming.annotate_event(
               %{metadata: %{"probe" => callback_probe}},
               trajectory,
               :eclipses
             )

    refute_receive :event_timing_callback_invoked

    assert {:error, {:invalid_container, :metadata}} =
             EventTiming.annotate_event(
               %{metadata: %{sun_direction: {1.0, 0.0, :bad}}},
               trajectory,
               :eclipses
             )

    assert {:error, {:invalid_container, :metadata}} =
             EventTiming.annotate_event(
               %{metadata: %{caller_vector: {1.0, 2.0, 3.0}}},
               trajectory,
               :eclipses
             )

    assert {:error, {:invalid_container, :metadata}} =
             EventTiming.annotate_event(
               %{metadata: %{activity_context: %{caller_vector: {1.0, 2.0, 3.0}}}},
               trajectory,
               :eclipses
             )

    for key <- metadata_vector_keys() do
      assert {:error, {:invalid_container, :metadata}} =
               EventTiming.annotate_event(
                 %{metadata: %{key => {@safe_number_bound + 1, 0.0, 0.0}}},
                 trajectory,
                 :eclipses
               ),
             "#{key} bound+1 vector component was admitted"

      assert {:error, {:invalid_container, :metadata}} =
               EventTiming.annotate_event(
                 %{metadata: %{key => {huge_integer(), 0.0, 0.0}}},
                 trajectory,
                 :eclipses
               ),
             "#{key} huge vector component was admitted"

      for {label, nonfinite} <- nonfinite_float_values() do
        assert {:error, {:invalid_container, :metadata}} =
                 EventTiming.annotate_event(
                   %{metadata: %{key => {nonfinite, 0.0, 0.0}}},
                   trajectory,
                   :eclipses
                 ),
               "#{label} #{key} vector component was admitted"
      end
    end

    assert {:error, {:invalid_option, :event}} =
             EventTiming.annotate_event(:not_an_event, trajectory, :eclipses)
  end

  defp access_contract_input(errors \\ [0.0002, -0.0003, 0.0004, -0.0005]) do
    authority = EventTiming.orekit_access_contract_authority()

    observed_boundaries =
      authority.input.reference_boundaries
      |> Enum.zip(errors)
      |> Enum.with_index(1)
      |> Enum.map(fn {{reference, error_s}, index} ->
        epoch_s = reference.epoch_s + error_s

        %{
          type: reference.type,
          epoch_s: epoch_s,
          convergence: access_convergence(reference.type, epoch_s, index, authority)
        }
      end)

    Map.put(authority.input, :observed_boundaries, observed_boundaries)
  end

  defp access_convergence(type, epoch_s, _index, authority) do
    sample_step_s = authority.input.case_input.output_step_s
    path_identity = authority.input.path_identity
    before_sample_index = trunc(epoch_s / sample_step_s)
    before_epoch_s = before_sample_index * sample_step_s
    after_sample_index = before_sample_index + 1
    after_epoch_s = after_sample_index * sample_step_s
    final_bracket_width_s = 1.1920928955078125e-6
    final_half_width_s = final_bracket_width_s / 2.0

    {boundary, edge, before_margin, after_margin} =
      case type do
        "aos" -> {:aos, :start, -0.001, 0.001}
        "los" -> {:los, :end, 0.001, -0.001}
      end

    %{
      boundary: boundary,
      edge: edge,
      interpolation: :cubic_hermite_state,
      refinement_model: :aos_los_bracketed_bisection,
      root_solver: :bisection,
      root_function: :elevation_margin_deg,
      root_scope: :cubic_hermite_interpolated_state_geometry,
      root_solved: true,
      validation_level: :analysis,
      confidence: :bounded_root_in_interpolated_state,
      convergence: :time_bracket,
      requested_root_tolerance_s: path_identity.access_root_tolerance_s,
      event_time_tolerance_s: final_half_width_s,
      event_time_bracket_s: final_bracket_width_s,
      input_event_time_bracket_s: sample_step_s,
      before_epoch_s: before_epoch_s,
      after_epoch_s: after_epoch_s,
      before_sample_index: before_sample_index,
      after_sample_index: after_sample_index,
      root_bracket_before_epoch_s: epoch_s - final_half_width_s,
      root_bracket_after_epoch_s: epoch_s + final_half_width_s,
      root_bracket_before_margin_deg: before_margin,
      root_bracket_after_margin_deg: after_margin,
      root_estimate_margin_deg: 0.0,
      root_iterations: 23,
      root_function_evaluations: 26,
      root_max_iterations: path_identity.access_root_max_iterations,
      model_limits: authority.root_model_limits
    }
  end

  defp trajectory(epoch_seconds) do
    %Trajectory{
      scenario_id: :event_timing_test,
      states:
        Enum.map(epoch_seconds, fn seconds ->
          StateVector.new!(
            {7000.0, 0.0, 0.0},
            {0.0, 7.5, 0.0},
            Epoch.new!(seconds, :tdb),
            Frame.earth_inertial_j2000()
          )
        end),
      assumptions: %{force_model: :manual}
    }
  end

  defp trajectory_with_epoch(epoch) do
    %Trajectory{
      scenario_id: :event_timing_test,
      states: [
        StateVector.new!(
          {7000.0, 0.0, 0.0},
          {0.0, 7.5, 0.0},
          Epoch.new!(0.0, :tdb),
          Frame.earth_inertial_j2000()
        )
        |> Map.put(:epoch, epoch)
      ],
      assumptions: %{force_model: :manual}
    }
  end

  defp metadata_vector_keys do
    [
      :sun_direction,
      :before_sun_direction,
      :after_sun_direction,
      :sun_direction_at_start_sample,
      :sun_direction_at_end_sample
    ]
  end

  defp huge_integer, do: :erlang.bsl(1, 1_000_000)

  defp nonfinite_float_values do
    [
      {"nan", <<131, 70, 127, 248, 0, 0, 0, 0, 0, 1>>},
      {"positive infinity", <<131, 70, 127, 240, 0, 0, 0, 0, 0, 0>>},
      {"negative infinity", <<131, 70, 255, 240, 0, 0, 0, 0, 0, 0>>}
    ]
    |> Enum.flat_map(fn {label, bytes} ->
      case construct_nonfinite_float(bytes) do
        {:ok, value} -> [{label, value}]
        :error -> []
      end
    end)
  end

  defp construct_nonfinite_float(bytes) do
    {:ok, :erlang.binary_to_term(bytes)}
  rescue
    _error in [ArgumentError] -> :error
  end
end
