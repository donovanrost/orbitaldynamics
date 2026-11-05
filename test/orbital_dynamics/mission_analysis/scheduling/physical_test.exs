defmodule OrbitalDynamics.MissionAnalysis.Scheduling.PhysicalTest do
  use ExUnit.Case, async: true
  alias OrbitalDynamics.{Epoch, Frame, StateVector, Trajectory, MissionAnalysis}
  alias OrbitalDynamics.MissionAnalysis.{Asset, Request, Evaluation, WindowRefinement}
  alias OrbitalDynamics.MissionAnalysis.Scheduling.{Policy, Reassignment}

  defmodule Model do
    @behaviour OrbitalDynamics.MissionAnalysis.Model
    def capabilities, do: %{"id" => "assignment-with-physical-checks"}

    def prepare(r, c, _) do
      send(self(), {:model_prepared, r.id})
      {:ok, r.id in c["allowed"], %{}}
    end

    def evaluate(_, _, allowed),
      do: {:ok, Evaluation.new!([%{"id" => "available", "passed" => allowed}], %{})}

    def pointing(s, _, _),
      do: {:ok, OrbitalDynamics.MissionAnalysis.Attitude.Pointing.new!(s.frame, {1, 0, 0, 0})}

    def activity_mode(_, _),
      do:
        {:ok,
         OrbitalDynamics.MissionAnalysis.Path.Result.new!(
           [%{"id" => "mode", "status" => "supported"}],
           %{}
         )}
  end

  defmodule Guard do
    @behaviour OrbitalDynamics.MissionAnalysis.Path.Check
    def prepare(asset, _, c) do
      key = {__MODULE__, asset.id}
      revision = Process.get(key, 0) + 1
      Process.put(key, revision)
      send(self(), {:guard_prepared, asset.id, revision})
      {:ok, {c, revision}, %{"captured_revision" => revision}}
    end

    def evaluate(_, _, mode, {c, revision}) do
      status =
        cond do
          revision > 1 -> "unknown"
          mode["name"] == "work" -> c["activity_status"]
          true -> "supported"
        end

      {:ok,
       OrbitalDynamics.MissionAnalysis.Path.Result.new!(
         [%{"id" => "guard", "status" => status}],
         %{}
       )}
    end
  end

  defmodule BatteryProbe do
    @behaviour OrbitalDynamics.MissionAnalysis.Resource.Model
    alias OrbitalDynamics.MissionAnalysis.Resource.Battery

    def prepare(asset, context, c) do
      key = {__MODULE__, asset.id}
      revision = Process.get(key, 0) + 1
      Process.put(key, revision)
      send(self(), {:battery_prepared, asset.id, revision})
      Battery.prepare(asset, context, if(revision > 1, do: Map.put(c, "initial_wh", 0), else: c))
    end

    defdelegate initial(s), to: Battery
    defdelegate boundaries(s), to: Battery
    defdelegate step(s, input, dt, session), to: Battery
  end

  defp frame, do: Frame.new!(:toy, :toy, :inertial)
  defp state(t), do: StateVector.new!({2000, 0, 0}, {0, 0, 0}, Epoch.new!(t, :tai), frame())

  defp run(opts \\ []) do
    assets =
      for id <- ["a", "b"] do
        Asset.new!(
          id,
          %Trajectory{scenario_id: "toy", states: Enum.map(0..30, &state/1), assumptions: %{}},
          %{Model => %{"allowed" => if(id == "a", do: ["high", "low"], else: ["high"])}},
          %{"tokens" => 1}
        )
      end

    requests =
      for {id, value} <- [{"high", 10}, {"low", 9}] do
        Request.new!(id, Model, nil,
          activity_type: "service",
          starts_at_s: 5,
          ends_at_s: 20,
          duration_s: 10,
          time_scale: :tai,
          value: value,
          parameters: %{},
          resource_costs: %{"tokens" => 1}
        )
      end

    path_assets =
      for id <- ["a", "b"], into: %{} do
        {id,
         %{
           activity_modes: %{"high" => "work", "low" => "work"},
           transition_mode: "idle",
           modes: %{"work" => %{"power_load_w" => 360}, "idle" => %{"power_load_w" => 0}},
           rules: [
             %{
               id: "guard",
               module: Guard,
               configuration: %{
                 "activity_status" =>
                   if(id == "b",
                     do: Keyword.get(opts, :path_status, "supported"),
                     else: "supported"
                   )
               }
             }
           ]
         }}
      end

    path =
      OrbitalDynamics.MissionAnalysis.Path.Policy.new!(path_assets,
        sample_steps_s: [2, 1],
        max_evaluations: 10000,
        max_samples_per_segment: 1000
      )

    resources =
      for id <- ["a", "b"], into: %{} do
        config = %{
          "initial_wh" => if(id == "b", do: Keyword.get(opts, :b_energy, 20), else: 20),
          "capacity_wh" => 30,
          "reserve_wh" => 8,
          "charge_efficiency" => 1,
          "discharge_efficiency" => 1,
          "phase_load_w" =>
            Map.new(
              ~w(activity brake hold slew_accelerate slew_cruise slew_decelerate settle ramp_to_tracking),
              &{&1, 0}
            ),
          "generation" => %{"kind" => "constant", "power_w" => 0}
        }

        {id,
         [%{id: "battery", module: BatteryProbe, configuration: config, exclusive_cost_keys: []}]}
      end

    resources =
      OrbitalDynamics.MissionAnalysis.Resource.Policy.new!(resources,
        sample_steps_s: [2, 1],
        max_intervals_per_asset: 1000,
        max_evaluations: 10000
      )

    limits =
      for id <- ["a", "b"], into: %{} do
        {id,
         %{
           max_rate_deg_s: 10,
           max_accel_deg_s2: 5,
           settling_s: 0,
           initial: %{
             epoch: Epoch.new!(0, :tai),
             frame: frame(),
             quaternion: {1, 0, 0, 0},
             angular_velocity_deg_s: {0, 0, 0}
           },
           pointing_configurations: %{Model => %{}}
         }}
      end

    horizon = %{
      start: Epoch.new!(0, :tai),
      stop: Epoch.new!(30, :tai),
      terminals:
        Map.new(["a", "b"], &{&1, %{frame: frame(), quaternion: {1, 0, 0, 0}, mode: "idle"}})
    }

    attitude =
      OrbitalDynamics.MissionAnalysis.Attitude.Policy.new!(limits,
        profile_step_s: 1,
        derivative_step_s: 0.1,
        search_step_s: 1,
        max_candidate_starts: 32,
        max_evaluations: 10000,
        path_constraints: path,
        resources: resources,
        horizon: horizon
      )

    refinement =
      WindowRefinement.new!(
        state_at: fn _, t -> {:ok, state(t)} end,
        tracking_lookback_s: 1,
        time_tolerance_s: 0.01,
        max_extra_evaluations: 128
      )

    MissionAnalysis.run(assets, requests, nil,
      max_sample_gap_s: 1,
      asset_separation_s: 0,
      window_refinement: refinement,
      attitude: attitude,
      scheduling: Keyword.get(opts, :scheduling, Policy.new!(Reassignment, max_trials: 4))
    )
  end

  test "physical reassignment improves value with frozen preparations and full battery/terminal replay" do
    assert {:ok, report} = run()
    assert report["scheduling_search"]["baseline_value"] == 10
    assert report["scheduling_search"]["final_value"] == 19
    assert report["attitude_planning"]["planning_status"] == "supported"

    assert Enum.sort(Enum.map(report["activities"], &{&1["request_id"], &1["asset_id"]})) == [
             {"high", "b"},
             {"low", "a"}
           ]

    for id <- ["a", "b"] do
      assert_received {:guard_prepared, ^id, 1}
      assert_received {:battery_prepared, ^id, 1}
      refute_received {:guard_prepared, ^id, _}
      refute_received {:battery_prepared, ^id, _}
      asset = report["attitude_planning"]["resource_feasibility"]["assets"][id]
      assert asset["status"] == "supported"

      assert_in_delta hd(asset["models"])["state_comparison"]["final_state_range"]["energy_wh"][
                        "min"
                      ],
                      19,
                      1.0e-10
    end

    assert length(
             for {:model_prepared, _} <- Process.info(self(), :messages) |> elem(1), do: :prepared
           ) == 4

    assert Enum.all?(report["activities"], fn a ->
             Enum.all?(a["endpoint_samples"], & &1["feasible"])
           end)
  end

  test "independent analyses with the same captured state produce identical complete search evidence" do
    first = Task.async(fn -> run() end)
    second = Task.async(fn -> run() end)
    assert {:ok, report} = Task.await(first)
    assert {:ok, ^report} = Task.await(second)
  end

  test "protected lower-priority work holds a non-grid time and forces greedy onto the other asset" do
    pin = %{"request_id" => "low", "asset_id" => "a", "starts_at_s" => 9.25, "ends_at_s" => 19.25}

    search =
      Policy.new!(OrbitalDynamics.MissionAnalysis.Scheduling.Replacement,
        max_trials: 4,
        protected_activities: [pin]
      )

    assert {:ok, report} = run(scheduling: search)
    assert report["scheduling_search"]["final_value"] == 19

    assert OrbitalDynamics.MissionAnalysis.Scheduling.Commitments.intact?(report["activities"], [
             pin
           ])

    assert report["attitude_planning"]["planning_status"] == "supported"
    assert Enum.find(report["activities"], &(&1["request_id"] == "low"))["protected"]
    assert Enum.find(report["activities"], &(&1["request_id"] == "high"))["asset_id"] == "b"
  end

  test "battery reserve prevents a statically attractive reassignment" do
    assert {:ok, report} = run(b_energy: 8.5)
    assert report["scheduling_search"]["final_value"] == 10
    assert report["attitude_planning"]["planning_status"] == "supported"
    assert report["scheduling_search"]["trial_count"] == 2
  end

  test "violated and unknown path evidence cannot improve the accepted plan" do
    for status <- ["violated", "unknown"] do
      # Each trial here is an independent analysis and captures its own revision.
      for id <- ["a", "b"] do
        Process.delete({Guard, id})
        Process.delete({BatteryProbe, id})
      end

      assert {:ok, report} = run(path_status: status)
      assert report["scheduling_search"]["final_value"] == 10
      assert report["attitude_planning"]["planning_status"] == "supported"
    end
  end
end
