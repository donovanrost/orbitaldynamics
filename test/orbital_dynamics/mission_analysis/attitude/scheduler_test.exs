defmodule OrbitalDynamics.MissionAnalysis.Attitude.SchedulerTest do
  use ExUnit.Case, async: true
  alias OrbitalDynamics.{Epoch, Frame, StateVector, Trajectory}
  alias OrbitalDynamics.MissionAnalysis
  alias OrbitalDynamics.MissionAnalysis.{Asset, Evaluation, Request, WindowRefinement}
  alias OrbitalDynamics.MissionAnalysis.Attitude.{Pointing, Policy, Quaternion}

  defmodule Model do
    @behaviour OrbitalDynamics.MissionAnalysis.Model
    def capabilities, do: %{"id" => "analytic-attitude"}

    def activity_mode(_, _),
      do:
        {:ok,
         OrbitalDynamics.MissionAnalysis.Path.Result.new!(
           [
             %{"id" => "service", "status" => "supported"}
           ],
           %{}
         )}

    def prepare(r, _, _), do: {:ok, r.parameters, %{}}

    def evaluate(_, _, _),
      do: {:ok, Evaluation.new!([%{"id" => "physical", "passed" => true}], %{})}

    def pointing(state, p, _) do
      case p["pointing_status"] do
        "unknown" ->
          {:unknown, :profile_undefined}

        "error" ->
          {:error, :provider_down}

        _ ->
          t = state.epoch.seconds_since_j2000
          angle = p["angle"] + p["rate"] * t + p["acceleration"] * t * t / 2
          {:ok, Pointing.new!(state.frame, Quaternion.increment({0, 0, angle}))}
      end
    end
  end

  defmodule NoPointing do
    @behaviour OrbitalDynamics.MissionAnalysis.Model
    def capabilities, do: %{"id" => "no-pointing"}
    def prepare(_, _, _), do: {:ok, nil, %{}}

    def evaluate(_, _, _),
      do: {:ok, Evaluation.new!([%{"id" => "physical", "passed" => true}], %{})}
  end

  defp frame, do: Frame.new!(:toy, :toy, :inertial)
  defp state(t), do: StateVector.new!({2000, 0, 0}, {0, 0, 0}, Epoch.new!(t, :tai), frame())

  defp asset(budget \\ 10),
    do:
      Asset.new!(
        "a",
        %Trajectory{scenario_id: "toy", states: Enum.map(0..200//5, &state/1), assumptions: %{}},
        %{Model => %{}, NoPointing => %{}},
        %{"energy_wh" => budget}
      )

  defp request(id, opts \\ []) do
    Request.new!(id, Keyword.get(opts, :model, Model), :opaque,
      activity_type: "activity",
      starts_at_s: Keyword.get(opts, :start, 1),
      ends_at_s: Keyword.get(opts, :stop, 40),
      duration_s: Keyword.get(opts, :duration, 10),
      time_scale: :tai,
      value: Keyword.get(opts, :value, 1),
      parameters: %{
        "angle" => Keyword.get(opts, :angle, 0),
        "rate" => Keyword.get(opts, :rate, 0),
        "acceleration" => Keyword.get(opts, :acceleration, 0),
        "pointing_status" => Keyword.get(opts, :pointing_status, "ok")
      },
      resource_costs: %{"energy_wh" => 1}
    )
  end

  defp initial(q \\ {1, 0, 0, 0}, time \\ 0),
    do: %{
      epoch: Epoch.new!(time, :tai),
      frame: frame(),
      quaternion: q,
      angular_velocity_deg_s: {0, 0, 0}
    }

  defp policy(opts) do
    a = %{
      max_rate_deg_s: Keyword.get(opts, :rate, 10),
      max_accel_deg_s2: Keyword.get(opts, :acceleration, 5),
      settling_s: Keyword.get(opts, :settling, 0),
      initial: Keyword.get(opts, :initial, initial()),
      pointing_configurations: %{Model => %{}, NoPointing => %{}}
    }

    Policy.new!(%{"a" => a},
      profile_step_s: 1,
      derivative_step_s: 0.1,
      search_step_s: 1,
      max_candidate_starts: Keyword.get(opts, :max_starts, 128),
      max_evaluations: Keyword.get(opts, :budget, 10000),
      path_constraints: Keyword.get(opts, :path),
      horizon: Keyword.get(opts, :horizon)
    )
  end

  defp run(requests, opts \\ []) do
    refinement =
      WindowRefinement.new!(
        state_at: fn _, t -> {:ok, state(t)} end,
        tracking_lookback_s: 1,
        time_tolerance_s: 0.01,
        max_extra_evaluations: 128
      )

    MissionAnalysis.run([asset(Keyword.get(opts, :resource_budget, 10))], requests, nil,
      max_sample_gap_s: 5,
      asset_separation_s: 0,
      window_refinement: refinement,
      attitude: policy(opts)
    )
  end

  test "explicit acquisition moves an otherwise eligible activity and creates a bounded transition" do
    assert {:ok, report} =
             run([request("r")], initial: initial(Quaternion.increment({0, 0, 90})), settling: 2)

    [a] = report["activities"]
    assert_in_delta a["starts_at_s"], 13, 1.0e-8
    [transition] = report["attitude_planning"]["transitions"]
    assert_in_delta transition["required_s"], 13, 1.0e-8
    assert transition["time_margin_s"] >= 0
    assert transition["terminal_orientation_residual_deg"] < 1.0e-9
    assert Enum.all?(a["attitude_profile"], &(&1["rate_deg_s"] < 1.0e-9))

    assert {:ok, ^report} =
             run([request("r")], initial: initial(Quaternion.increment({0, 0, 90})), settling: 2)
  end

  test "missing initial attitude or a missing profile callback remains unknown" do
    assert {:ok, report} = run([request("r")], initial: :unknown)
    assert report["activities"] == []

    assert hd(report["selection_decisions"])["attitude_assessment"]["reason"] ==
             "initial_attitude_unknown"

    assert report["attitude_planning"]["model_evaluation_count"] == 0
    assert {:ok, report} = run([request("r", model: NoPointing)])

    assert hd(report["selection_decisions"])["attitude_assessment"]["reason"] ==
             "pointing_model_unavailable"
  end

  test "tracking rate and acceleration violations block physically eligible requests" do
    assert {:ok, report} = run([request("r", rate: 15)])
    assert report["activities"] == []
    assert hd(report["selection_decisions"])["reason"] == "attitude_start_grid_infeasible"

    assert {:ok, report} =
             run([request("r", start: 10, stop: 15, duration: 2, acceleration: 0.5)],
               initial: initial({1, 0, 0, 0}, -1000),
               rate: 20,
               acceleration: 0.1
             )

    assert report["activities"] == []
    attempts = hd(report["selection_decisions"])["attitude_assessment"]["attempts"]

    assert Enum.all?(
             attempts,
             &String.contains?(&1["reason"], "tracking_acceleration_exceeds_limit")
           )
  end

  test "earlier insertion is rejected when it would invalidate an already selected successor" do
    future = request("future", start: 40, stop: 60, value: 100)
    earlier = request("earlier", start: 20, stop: 35, angle: 170)
    assert {:ok, report} = run([earlier, future])
    assert Enum.map(report["activities"], & &1["request_id"]) == ["future"]
    decision = Enum.find(report["selection_decisions"], &(&1["request_id"] == "earlier"))

    assert Enum.all?(
             decision["attitude_assessment"]["attempts"],
             &(&1["reason"] == ":outgoing_transition")
           )

    assert report["remaining_resource_budgets"]["a"]["energy_wh"] == 9
  end

  test "accepted insertion recomputes the final transition graph in chronological order" do
    future = request("future", start: 80, stop: 100, value: 100)
    earlier = request("earlier", start: 20, stop: 35, angle: 45)
    assert {:ok, report} = run([future, earlier])
    assert Enum.map(report["activities"], & &1["request_id"]) == ["earlier", "future"]
    [first, second] = report["attitude_planning"]["transitions"]
    assert first["from_activity_id"] == :null
    assert second["from_activity_id"] == hd(report["activities"])["id"]
    assert_in_delta second["slew_angle_deg"], 45, 1.0e-9
  end

  test "profile unknowns are distinct from provider errors and evaluation budget failures" do
    assert {:ok, report} = run([request("r", pointing_status: "unknown")])
    assert hd(report["selection_decisions"])["reason"] == "attitude_feasibility_unknown"

    assert {:error, {:attitude_analysis_failed, "a", "r", :provider_down}} =
             run([request("r", pointing_status: "error")])

    assert {:error, {:attitude_analysis_failed, "a", "r", :attitude_evaluation_budget_exhausted}} =
             run([request("r")], budget: 1)

    assert {:ok, report} =
             run([request("r")],
               initial: initial(Quaternion.increment({0, 0, 90})),
               max_starts: 1
             )

    assert hd(report["selection_decisions"])["attitude_assessment"]["search_truncated"]
    assert hd(report["selection_decisions"])["reason"] == "attitude_feasibility_unknown"
  end

  test "frame mismatch and missing sampler policy reject configuration; resource rejection remains separate" do
    wrong = %{initial() | frame: Frame.earth_inertial_j2000()}
    assert {:error, {:invalid_mission_analysis, _}} = run([request("r")], initial: wrong)

    assert {:error, {:invalid_mission_analysis, _}} =
             MissionAnalysis.run([asset()], [request("r")], nil,
               max_sample_gap_s: 5,
               asset_separation_s: 0,
               attitude: policy([])
             )

    assert {:ok, report} = run([request("r")], resource_budget: 0)
    assert hd(report["selection_decisions"])["reason"] == "insufficient_resource_budget"
    assert report["attitude_planning"]["model_evaluation_count"] == 0
  end

  defmodule HorizonCheck do
    @behaviour OrbitalDynamics.MissionAnalysis.Path.Check
    alias OrbitalDynamics.MissionAnalysis.Path.Result
    def prepare(_, _, config), do: {:ok, config, %{}}

    def evaluate(state, _, mode, config) do
      status =
        cond do
          mode["parameters"]["behavior"] == "unknown" -> "unknown"
          state.epoch.seconds_since_j2000 >= Map.get(config, "violate_after", 10000) -> "violated"
          true -> "supported"
        end

      {:ok, Result.new!([%{"id" => "test_guard", "status" => status}], %{})}
    end
  end

  defp horizon(stop, terminal \\ :default) do
    terminal =
      if terminal == :default,
        do: %{frame: frame(), quaternion: {1, 0, 0, 0}, mode: "terminal"},
        else: terminal

    %{start: Epoch.new!(0, :tai), stop: Epoch.new!(stop, :tai), terminals: %{"a" => terminal}}
  end

  defp path(ids, config \\ %{}, behavior \\ "known") do
    OrbitalDynamics.MissionAnalysis.Path.Policy.new!(
      %{
        "a" => %{
          activity_modes: Map.new(ids, &{&1, "active"}),
          transition_mode: "active",
          modes: %{"active" => %{"behavior" => "known"}, "terminal" => %{"behavior" => behavior}},
          rules: [%{id: "guard", module: HorizonCheck, configuration: config}]
        }
      },
      sample_steps_s: [5, 1],
      max_evaluations: 50000,
      max_samples_per_segment: 1000
    )
  end

  test "horizon reserves terminal acquisition and checks the hold through the end" do
    r = request("r", start: 20, stop: 30, angle: 90)
    assert {:ok, rejected} = run([r], horizon: horizon(35), path: path(["r"]))
    assert rejected["activities"] == []
    attempts = hd(rejected["selection_decisions"])["attitude_assessment"]["attempts"]
    assert Enum.all?(attempts, &(&1["reason"] == ":outgoing_transition"))

    assert {:ok, report} = run([r], horizon: horizon(50), path: path(["r"]))
    assert length(report["activities"]) == 1
    h = report["attitude_planning"]["horizon_coverage"]
    assert h["status"] == "supported"
    assert h["assets"]["a"]["uncovered_intervals"] == []
    plan = h["assets"]["a"]["terminal_motion"]
    assert List.last(plan["phases"])["kind"] == "hold"
    assert_in_delta List.last(plan["phases"])["starts_after_s"], 11, 1.0e-9
    pose = OrbitalDynamics.MissionAnalysis.Attitude.Motion.at(plan, 20)
    assert Quaternion.distance_deg(pose.quaternion, {1, 0, 0, 0}) < 1.0e-9
    assert OrbitalDynamics.Vector3.norm(pose.angular_velocity_deg_s) < 1.0e-9
    evidence = h["assets"]["a"]["terminal_path_evidence"]
    assert evidence["mode"] == "terminal"
    assert evidence["ends_at_s"] == 50
    assert Enum.all?(evidence["levels"], &(&1["status"] == "supported"))
  end

  test "terminal braking retains the final tracking angular velocity" do
    r = request("r", start: 20, stop: 30, rate: 2)
    assert {:ok, report} = run([r], horizon: horizon(60), path: path(["r"]))
    assert length(report["activities"]) == 1
    plan = report["attitude_planning"]["horizon_coverage"]["assets"]["a"]["terminal_motion"]
    assert_in_delta plan["brake_s"], 0.4, 1.0e-8
    assert hd(plan["phases"])["angular_velocity_inertial_deg_s"] |> List.last() > 1.99
    assert plan["terminal_rate_residual_deg_s"] < 1.0e-8
  end

  test "idle assets are screened and a late hold violation cannot pass vacuously" do
    assert {:ok, report} = run([], horizon: horizon(50), path: path([], %{"violate_after" => 45}))
    h = report["attitude_planning"]["horizon_coverage"]
    assert h["status"] == "violated"
    assert report["attitude_planning"]["path_status"] == "violated"
    assert h["assets"]["a"]["scheduled_activity_count"] == 0
    assert h["assets"]["a"]["uncovered_intervals"] != []
    assert h["assets"]["a"]["terminal_path_evidence"]["status"] == "violated"

    assert {:ok, report} =
             run([request("r", start: 20, stop: 30)],
               horizon: horizon(50),
               path: path(["r"], %{"violate_after" => 45})
             )

    assert report["activities"] == []
    assert report["attitude_planning"]["horizon_coverage"]["status"] == "violated"
  end

  test "idle braking and missing horizon evidence remain explicit" do
    moving = %{initial() | angular_velocity_deg_s: {0, 0, 2}}
    assert {:ok, report} = run([], initial: moving, horizon: horizon(50), path: path([]))
    assert report["attitude_planning"]["horizon_coverage"]["status"] == "supported"

    assert report["attitude_planning"]["horizon_coverage"]["assets"]["a"]["terminal_motion"][
             "brake_s"
           ] == 0.4

    for opts <- [
          [initial: :unknown, horizon: horizon(50), path: path([])],
          [initial: initial({1, 0, 0, 0}, -1), horizon: horizon(50), path: path([])],
          [horizon: horizon(50, :unknown), path: path([])],
          [horizon: horizon(50), path: path([], %{}, "unknown")],
          [horizon: horizon(201), path: path([])],
          [horizon: horizon(50)]
        ] do
      assert {:ok, report} = run([], opts)
      h = report["attitude_planning"]["horizon_coverage"]
      assert h["status"] == "unknown"
      assert h["assets"]["a"]["uncovered_intervals"] != []
    end
  end

  test "horizon clipping and inserted predecessors retain the terminal successor" do
    future = request("future", start: 80, stop: 100, value: 100)
    earlier = request("earlier", start: 20, stop: 35, angle: 45)

    assert {:ok, report} =
             run([future, earlier], horizon: horizon(130), path: path(["future", "earlier"]))

    assert Enum.map(report["activities"], & &1["request_id"]) == ["earlier", "future"]
    h = report["attitude_planning"]["horizon_coverage"]
    assert h["status"] == "supported"
    assert h["assets"]["a"]["terminal_motion"]["source_epoch_s"] == 90

    assert {:ok, report} =
             run([request("r", start: 60, stop: 100)], horizon: horizon(50), path: path(["r"]))

    assert report["activities"] == []
    assert report["attitude_planning"]["horizon_coverage"]["status"] == "supported"
  end

  test "an unconfigured idle fleet member keeps an otherwise supported horizon unknown" do
    b = %{asset() | id: "b"}

    refinement =
      WindowRefinement.new!(
        state_at: fn _, t -> {:ok, state(t)} end,
        tracking_lookback_s: 1,
        time_tolerance_s: 0.01,
        max_extra_evaluations: 128
      )

    p = policy(horizon: horizon(50), path: path([]))

    assert {:ok, report} =
             MissionAnalysis.run([asset(), b], [], nil,
               max_sample_gap_s: 5,
               asset_separation_s: 0,
               window_refinement: refinement,
               attitude: p
             )

    h = report["attitude_planning"]["horizon_coverage"]
    assert h["status"] == "unknown"
    assert h["assets"]["a"]["status"] == "supported"
    assert h["assets"]["b"]["status"] == "unknown"

    assert h["assets"]["b"]["terminal_path_evidence"]["reason"] ==
             "attitude_configuration_missing"

    assert h["assets"]["b"]["uncovered_intervals"] == [
             %{
               "starts_at_s" => 0,
               "ends_at_s" => 50,
               "reason" => "not_fully_supported",
               "status" => "unknown"
             }
           ]
  end

  test "terminal declarations validate frames, scales and modes without inferring an off state" do
    bad = %{frame: Frame.earth_inertial_j2000(), quaternion: {1, 0, 0, 0}, mode: "terminal"}

    assert {:error, {:invalid_mission_analysis, _}} =
             run([], horizon: horizon(50, bad), path: path([]))

    h = %{horizon(50) | stop: Epoch.new!(50, :utc)}
    assert_raise ArgumentError, fn -> policy(horizon: h) end

    for mode <- [:unknown, "undeclared-off"] do
      t = %{frame: frame(), quaternion: {1, 0, 0, 0}, mode: mode}
      assert {:ok, report} = run([], horizon: horizon(50, t), path: path([]))
      assert report["attitude_planning"]["horizon_coverage"]["status"] == "unknown"
    end
  end
end
