defmodule OrbitalDynamics.MissionAnalysis.Attitude.ProfileTest do
  use ExUnit.Case, async: true
  alias OrbitalDynamics.{Epoch, Frame, StateVector, Trajectory}
  alias OrbitalDynamics.MissionAnalysis.{Asset, Request}
  alias OrbitalDynamics.MissionAnalysis.Attitude.{Pointing, Policy, Profile, Quaternion}

  defmodule Analytic do
    def pointing(state, p, _) do
      t = state.epoch.seconds_since_j2000 - p.origin
      q = Quaternion.increment({0, 0, 2 * t + 0.25 * t * t})
      # Deliberately flip quaternion representation at some samples.
      q =
        if rem(trunc(abs(t) * 10), 2) == 0, do: q |> Tuple.to_list() |> Enum.map(&(-&1)), else: q

      {:ok, Pointing.new!(state.frame, q)}
    end
  end

  defp inputs(origin, h) do
    frame = Frame.new!(:toy, :toy, :inertial)
    state = fn t -> StateVector.new!({2000, 0, 0}, {0, 0, 0}, Epoch.new!(t, :tai), frame) end

    a =
      Asset.new!(
        "a",
        %Trajectory{
          scenario_id: "analytic",
          states: [state.(origin), state.(origin + 100)],
          assumptions: %{}
        },
        %{Analytic => %{}},
        %{}
      )

    r =
      Request.new!("r", Analytic, :opaque,
        activity_type: "activity",
        starts_at_s: origin,
        ends_at_s: origin + 100,
        duration_s: 10,
        time_scale: :tai,
        value: 1,
        parameters: %{},
        resource_costs: %{}
      )

    limits = %{
      max_rate_deg_s: 20,
      max_accel_deg_s2: 2,
      settling_s: 0,
      initial: :unknown,
      pointing_configurations: %{Analytic => %{}}
    }

    p =
      Policy.new!(%{"a" => limits},
        profile_step_s: 1,
        derivative_step_s: h,
        search_step_s: 1,
        max_candidate_starts: 10,
        max_evaluations: 100
      )

    {a, r, p, fn _, t -> {:ok, state.(t)} end}
  end

  test "quaternion finite differences recover analytic inertial rates and acceleration across sign changes" do
    {a, r, p, state_at} = inputs(0, 0.1)

    assert {:ok, point, cache} =
             Profile.sample(a, r, %{origin: 0}, 10, %{}, p, state_at, %{
               values: %{},
               evaluations: 0
             })

    assert_in_delta point["rate_deg_s"], 7, 1.0e-9
    assert_in_delta point["accel_deg_s2"], 0.5, 1.0e-8
    assert {:ok, ^point, reused} = Profile.sample(a, r, %{origin: 0}, 10, %{}, p, state_at, cache)
    assert reused.evaluations == cache.evaluations
  end

  test "unresolvable derivative epochs remain unknown rather than implying zero motion" do
    {a, r, p, state_at} = inputs(820_497_600, 1.0e-15)
    cache = %{values: %{}, evaluations: 0}

    assert {:unknown, :attitude_derivative_epoch_precision_exhausted, ^cache} =
             Profile.sample(a, r, %{origin: 820_497_600}, 820_497_610, %{}, p, state_at, cache)
  end

  test "small quaternion increments retain small nonzero rotation evidence" do
    assert_in_delta elem(Quaternion.rotation_vector(Quaternion.increment({0, 0, 1.0e-13})), 2),
                    1.0e-13,
                    1.0e-25
  end
end
