defmodule OrbitalDynamics.MissionAnalysis.Scheduling.ReplacementTest do
  use ExUnit.Case, async: true
  alias OrbitalDynamics.{Epoch, Frame, StateVector, Trajectory, MissionAnalysis}
  alias OrbitalDynamics.MissionAnalysis.{Asset, Request, RepeatedServiceQualityCases}
  alias OrbitalDynamics.MissionAnalysis.Scheduling
  alias OrbitalDynamics.MissionAnalysis.Scheduling.{Policy, Replacement, Commitments, Reference}
  alias OrbitalDynamics.MissionAnalysis.AssignmentQualityCases.Model

  defmodule Reverse do
    @behaviour OrbitalDynamics.MissionAnalysis.Scheduling.Strategy
    def propose(p, _, _, _), do: {:candidate, Enum.reverse(p.opportunities), %{}, nil}
  end

  defmodule TimedKeepout do
    @behaviour OrbitalDynamics.MissionAnalysis.Path.Check
    def prepare(_, _, _), do: {:ok, nil, %{}}

    def evaluate(state, pose, _, _) do
      {x, _, _} =
        OrbitalDynamics.MissionAnalysis.Attitude.Quaternion.rotate(pose.quaternion, {1, 0, 0})

      t = state.epoch.seconds_since_j2000
      status = if t >= 39 and t <= 41 and x > 0.995, do: "violated", else: "supported"

      {:ok,
       OrbitalDynamics.MissionAnalysis.Path.Result.new!(
         [%{"id" => "timed_keepout", "status" => status}],
         %{}
       )}
    end
  end

  defp protected(request, asset, start, stop),
    do: %{
      "request_id" => request,
      "asset_id" => asset,
      "starts_at_s" => start,
      "ends_at_s" => stop
    }

  defp case_config(id), do: Enum.find(RepeatedServiceQualityCases.cases(), &(&1["id"] == id))

  test "replacement closes the independent maneuver gap and retains every declared-model optimum" do
    cases = RepeatedServiceQualityCases.run!(Policy.new!(Replacement, max_trials: 4))

    assert Enum.all?(
             cases,
             &(&1["planner_value"] == &1["optimal_value"] and &1["planning_status"] == "supported")
           )

    maneuver = Enum.find(cases, &(&1["id"] == "maneuver_gap"))
    assert maneuver["planner_value"] == 15

    improvement =
      Enum.find(maneuver["scheduling_search"]["trials"], &(&1["reason"] == "value_improved"))

    assert improvement["removed_request_ids"] == ["middle"]
    assert improvement["added_request_ids"] == ["early", "late"]
    assert maneuver["scheduling_search"]["trial_count"] <= 4
  end

  test "protected central request keeps its exact placement even when removing it would yield 15" do
    pin = protected("middle", "a", 40, 50)

    report =
      RepeatedServiceQualityCases.plan!(
        case_config("maneuver_gap"),
        Policy.new!(Replacement, max_trials: 4, protected_activities: [pin])
      )

    assert [
             %{
               "request_id" => "middle",
               "asset_id" => "a",
               "starts_at_s" => 40.0,
               "ends_at_s" => 50.0,
               "protected" => true
             }
           ] =
             Enum.map(
               report["activities"],
               &Map.take(&1, ~w(request_id asset_id starts_at_s ends_at_s protected))
             )

    assert report["scheduling_search"]["final_value"] == 10
    assert report["attitude_planning"]["planning_status"] == "supported"
  end

  test "a commitment is seeded even when unconstrained greedy would assign the request elsewhere" do
    pin = protected("flexible", "b", 20, 30)

    report =
      RepeatedServiceQualityCases.plan!(
        case_config("repeated_assignment"),
        Policy.new!(Replacement, max_trials: 4, protected_activities: [pin])
      )

    assert report["scheduling_search"]["baseline_value"] == 27
    assert Commitments.intact?(report["activities"], [pin])
    assert Enum.frequencies_by(report["activities"], & &1["asset_id"]) == %{"a" => 2, "b" => 1}
  end

  test "one-trial budget and all-served retention keep the verified greedy incumbent" do
    for opts <- [[max_trials: 1], [max_trials: 4, retention: :all_served]] do
      r =
        RepeatedServiceQualityCases.plan!(
          case_config("maneuver_gap"),
          Policy.new!(Replacement, opts)
        )

      assert r["scheduling_search"]["final_value"] == 10
    end
  end

  test "incompatible protected maneuvers and battery timelines fail instead of dropping reservations" do
    c = case_config("maneuver_gap")
    pins = [protected("early", "a", 20, 30), protected("middle", "a", 40, 50)]

    assert_raise ArgumentError, ~r/protected_activity_unsupported/, fn ->
      RepeatedServiceQualityCases.plan!(
        c,
        Policy.new!(Replacement, max_trials: 4, protected_activities: pins)
      )
    end

    c = case_config("battery_limited")

    pins =
      Enum.map(
        c["requests"],
        &protected(&1["id"], "a", &1["start_s"], &1["start_s"] + &1["duration_s"])
      )

    assert_raise ArgumentError, ~r/protected_resources_unsupported/, fn ->
      RepeatedServiceQualityCases.plan!(
        c,
        Policy.new!(Replacement, max_trials: 4, protected_activities: pins)
      )
    end
  end

  defp static(pins, budget \\ 1) do
    frame = Frame.new!(:toy, :toy, :inertial)

    states =
      Enum.map([0, 10], &StateVector.new!({2000, 0, 0}, {0, 0, 0}, Epoch.new!(&1, :tai), frame))

    assets =
      for id <- ["a", "b"],
          do:
            Asset.new!(
              id,
              %Trajectory{scenario_id: "toy", states: states, assumptions: %{}},
              %{Model => %{"allowed" => if(id == "a", do: ["high", "low"], else: ["high"])}},
              %{"token" => budget}
            )

    requests =
      for {id, v} <- [{"high", 10}, {"low", 9}],
          do:
            Request.new!(id, Model, nil,
              activity_type: "service",
              starts_at_s: 0,
              ends_at_s: 10,
              duration_s: 10,
              time_scale: :tai,
              value: v,
              parameters: %{},
              resource_costs: %{"token" => 1}
            )

    MissionAnalysis.run(assets, requests, %{},
      max_sample_gap_s: 10,
      asset_separation_s: 0,
      scheduling: Policy.new!(Replacement, max_trials: 4, protected_activities: pins)
    )
  end

  test "all protected neighbors are present before checking a terminal/idle path" do
    alias OrbitalDynamics.MissionAnalysis.{RepeatedServiceQualityCases, WindowRefinement}
    service = RepeatedServiceQualityCases.Model
    frame = Frame.new!(:toy, :toy, :inertial)
    at = fn t -> StateVector.new!({2000, 0, 0}, {0, 0, 0}, Epoch.new!(t, :tai), frame) end

    asset =
      Asset.new!(
        "a",
        %Trajectory{scenario_id: "chain", states: Enum.map(0..100, at), assumptions: %{}},
        %{service => %{"allowed" => ["first", "second"]}},
        %{}
      )

    requests =
      for {id, t, angle, value} <- [{"first", 20, 90, 10}, {"second", 45, 0, 9}] do
        Request.new!(id, service, nil,
          activity_type: "service",
          starts_at_s: t,
          ends_at_s: t + 10,
          duration_s: 10,
          time_scale: :tai,
          value: value,
          parameters: %{"angle_deg" => angle},
          resource_costs: %{}
        )
      end

    path =
      OrbitalDynamics.MissionAnalysis.Path.Policy.new!(
        %{
          "a" => %{
            activity_modes: %{"first" => "work", "second" => "work"},
            transition_mode: "idle",
            modes: %{"work" => %{}, "idle" => %{}},
            rules: [%{id: "timed", module: TimedKeepout, configuration: %{}}]
          }
        },
        sample_steps_s: [2, 1],
        max_evaluations: 10000,
        max_samples_per_segment: 1000
      )

    limits = %{
      max_rate_deg_s: 10,
      max_accel_deg_s2: 5,
      settling_s: 1,
      initial: %{
        epoch: Epoch.new!(0, :tai),
        frame: frame,
        quaternion: {1, 0, 0, 0},
        angular_velocity_deg_s: {0, 0, 0}
      },
      pointing_configurations: %{service => %{}}
    }

    attitude =
      OrbitalDynamics.MissionAnalysis.Attitude.Policy.new!(%{"a" => limits},
        profile_step_s: 1,
        derivative_step_s: 0.1,
        search_step_s: 1,
        max_candidate_starts: 1,
        max_evaluations: 10000,
        path_constraints: path,
        horizon: %{
          start: Epoch.new!(0, :tai),
          stop: Epoch.new!(100, :tai),
          terminals: %{"a" => %{frame: frame, quaternion: {1, 0, 0, 0}, mode: "idle"}}
        }
      )

    refinement =
      WindowRefinement.new!(
        state_at: fn _, t -> {:ok, at.(t)} end,
        tracking_lookback_s: 1,
        time_tolerance_s: 0.01,
        max_extra_evaluations: 128
      )

    run = fn pins ->
      MissionAnalysis.run([asset], requests, nil,
        max_sample_gap_s: 1,
        asset_separation_s: 0,
        attitude: attitude,
        window_refinement: refinement,
        scheduling: Policy.new!(Replacement, max_trials: 1, protected_activities: pins)
      )
    end

    first = protected("first", "a", 20, 30)
    # Alone, first returns early to terminal0°, inside the timed keepout.
    assert {:error, {:protected_activity_unsupported, "first", :path_constraint_violated}} =
             run.([first])

    # The full chain turns later for second and avoids the timed keepout.
    pins = [first, protected("second", "a", 45, 55)]
    assert {:ok, report} = run.(pins)
    assert Commitments.intact?(report["activities"], pins)
    assert report["attitude_planning"]["planning_status"] == "supported"
  end

  test "static reservations precede greedy and debit their budget exactly once" do
    pin = protected("low", "a", 0, 10)
    assert {:ok, r} = static([pin])
    assert Commitments.intact?(r["activities"], [pin])
    assert Enum.find(r["activities"], &(&1["request_id"] == "low"))["protected"] == true
    assert r["remaining_resource_budgets"] == %{"a" => %{"token" => 0}, "b" => %{"token" => 0}}
    assert r["scheduling_search"]["baseline_value"] == 19
    assert {:error, {:invalid_mission_analysis, message}} = static([pin], 0)
    assert message =~ "static budgets"
  end

  test "unknown bindings, duration/window changes, duplicates and overlaps are rejected" do
    for pins <- [
          [protected("bad", "a", 0, 10)],
          [protected("high", "x", 0, 10)],
          [protected("high", "a", 0, 9)],
          [protected("high", "a", 1, 11)],
          [protected("high", "a", 0, 10), protected("low", "a", 0, 10)]
        ] do
      assert {:error, {:invalid_mission_analysis, _}} = static(pins)
    end

    pin = protected("high", "a", 0, 10)

    assert_raise ArgumentError, fn ->
      Policy.new!(Replacement, max_trials: 4, protected_activities: [pin, pin])
    end
  end

  test "controller rejects changed spacecraft, shifted times and duplicate protected requests independently" do
    pin = protected("high", "a", 0, 10)

    opportunities =
      for id <- ["first", "last"],
          do: %{
            "id" => id,
            "request_id" => "high",
            "asset_id" => "a",
            "starts_at_s" => 0,
            "ends_at_s" => 10
          }

    baseline = Map.put(pin, "value", 10)

    variants = [
      [%{baseline | "asset_id" => "b", "value" => 20}],
      [%{baseline | "starts_at_s" => 1, "ends_at_s" => 11, "value" => 20}],
      [baseline, %{baseline | "asset_id" => "b", "value" => 20}]
    ]

    for invalid <- variants do
      evaluator = fn order ->
        activities = if hd(order)["id"] == "first", do: [baseline], else: invalid
        {:ok, activities, [], %{}, nil}
      end

      policy =
        Policy.new!(Reverse, max_trials: 2, retention: :protected, protected_activities: [pin])

      assert {:ok, [^baseline], _, _, _, r} =
               Scheduling.run(opportunities, [%{id: "high", value: 10}], evaluator, policy)

      assert List.last(r["trials"])["reason"] == "protected_activity_changed"
    end
  end

  test "JSON adapter binds named replacement and protected placements without arbitrary modules" do
    p =
      Reference.policy!(%{
        "strategy" => "bounded_replacement",
        "max_trials" => 4,
        "protected_activities" => [protected("r", "a", 1, 2)]
      })

    assert p.strategy == Replacement
    assert p.retention == :protected
    assert length(p.protected_activities) == 1

    assert_raise ArgumentError, fn ->
      Reference.policy!(%{
        "strategy" => "bounded_replacement",
        "max_trials" => 4,
        "retention" => "unknown"
      })
    end
  end
end
