defmodule OrbitalDynamics.MissionAnalysis.Resource.SolarPlanningTest do
  use ExUnit.Case, async: true
  alias OrbitalDynamics.{CentralBody, Epoch, Frame, StateVector, Trajectory}
  alias OrbitalDynamics.MissionAnalysis

  alias OrbitalDynamics.MissionAnalysis.{
    Asset,
    Request,
    WindowRefinement,
    SphericalScene,
    Environments.Fixed
  }

  alias OrbitalDynamics.MissionAnalysis.Attitude.{Pointing, Quaternion}
  alias OrbitalDynamics.MissionAnalysis.Resource.{Battery, SolarDiagnostics}

  defmodule Model do
    @behaviour OrbitalDynamics.MissionAnalysis.Model
    def capabilities, do: %{"id" => "toy-fixed-attitude"}
    def prepare(r, _, _), do: {:ok, r.parameters, %{}}

    def evaluate(_, _, _),
      do:
        {:ok,
         OrbitalDynamics.MissionAnalysis.Evaluation.new!(
           [%{"id" => "eligible", "passed" => true}],
           %{}
         )}

    def activity_mode(_, _),
      do:
        {:ok,
         OrbitalDynamics.MissionAnalysis.Path.Result.new!(
           [%{"id" => "mode", "status" => "supported"}],
           %{}
         )}

    def pointing(state, c, _),
      do: {:ok, Pointing.new!(state.frame, Quaternion.increment({0, 0, c["angle"]}))}
  end

  defmodule Guard do
    @behaviour OrbitalDynamics.MissionAnalysis.Path.Check
    def prepare(_, _, _), do: {:ok, nil, %{}}

    def evaluate(_, _, _, _),
      do:
        {:ok,
         OrbitalDynamics.MissionAnalysis.Path.Result.new!(
           [%{"id" => "guard", "status" => "supported"}],
           %{}
         )}
  end

  defp frame, do: Frame.new!(:toy, :toy, :inertial)

  defp state(t) do
    theta = 2 * :math.pi() * t / 120

    StateVector.new!(
      {2 * :math.cos(theta), 2 * :math.sin(theta), 0},
      {-:math.pi() / 30 * :math.sin(theta), :math.pi() / 30 * :math.cos(theta), 0},
      Epoch.new!(t, :tai),
      frame()
    )
  end

  defp scene(stop) do
    env =
      Fixed.new!(frame(), Epoch.new!(0, :tai),
        starts_at_s: 0,
        ends_at_s: stop,
        sun_direction: {1, 0, 0},
        rotation_rate_rad_s: 0,
        rotation_angle_rad: 0
      )

    SphericalScene.new!(
      CentralBody.new!(:toy, :math.pi() * :math.pi() / 450, equatorial_radius_km: 1),
      frame(),
      :tai,
      {Fixed, env}
    )
  end

  defp run(requests \\ [], opts \\ []) do
    asset =
      Asset.new!(
        "toy",
        %Trajectory{scenario_id: "solar", states: Enum.map(0..120, &state/1), assumptions: %{}},
        %{Model => %{}},
        %{"tokens" => 1}
      )

    path =
      OrbitalDynamics.MissionAnalysis.Path.Policy.new!(
        %{
          "toy" => %{
            activity_modes: Map.new(requests, &{&1.id, "on"}),
            transition_mode: "on",
            modes: %{"on" => %{"power_load_w" => 100}},
            rules: [%{id: "guard", module: Guard, configuration: %{}}]
          }
        },
        sample_steps_s: [10, 1],
        max_evaluations: 100_000,
        max_samples_per_segment: 1000
      )

    config = %{
      "initial_wh" => Keyword.get(opts, :initial, 100),
      "capacity_wh" => 1000,
      "reserve_wh" => Keyword.get(opts, :reserve, 0),
      "charge_efficiency" => 1,
      "discharge_efficiency" => 1,
      "phase_load_w" =>
        Map.new(
          ~w(activity brake hold slew_accelerate slew_cruise slew_decelerate settle ramp_to_tracking),
          &{&1, 0}
        ),
      "generation" => %{
        "kind" => "solar_array",
        "shadow_model" => "cylindrical_point_sun",
        "solar_irradiance_w_m2" => 1000,
        "bus_efficiency" => 0.8,
        "panels" => [
          %{"id" => "array", "area_m2" => 2, "efficiency" => 0.25, "normal_body" => [1, 0, 0]}
        ]
      }
    }

    resources =
      OrbitalDynamics.MissionAnalysis.Resource.Policy.new!(
        %{
          "toy" => [
            %{
              id: "battery",
              module: Battery,
              configuration: config,
              exclusive_cost_keys: ["energy_wh"]
            }
          ]
        },
        sample_steps_s: Keyword.get(opts, :steps, [17, 7, 1]),
        max_intervals_per_asset: 1000,
        max_evaluations: 100_000
      )

    initial = %{
      epoch: Epoch.new!(0, :tai),
      frame: frame(),
      quaternion: {1, 0, 0, 0},
      angular_velocity_deg_s: {0, 0, 0}
    }

    policy =
      OrbitalDynamics.MissionAnalysis.Attitude.Policy.new!(
        %{
          "toy" => %{
            max_rate_deg_s: 90,
            max_accel_deg_s2: 90,
            settling_s: 0,
            initial: initial,
            pointing_configurations: %{Model => %{}}
          }
        },
        profile_step_s: 1,
        derivative_step_s: 0.1,
        search_step_s: 1,
        max_candidate_starts: 128,
        max_evaluations: 100_000,
        horizon: %{
          start: Epoch.new!(0, :tai),
          stop: Epoch.new!(120, :tai),
          terminals: %{
            "toy" => %{
              frame: frame(),
              quaternion: Keyword.get(opts, :terminal, {1, 0, 0, 0}),
              mode: "on"
            }
          }
        },
        path_constraints: path,
        resources: resources
      )

    refinement =
      WindowRefinement.new!(
        state_at: fn _, t -> {:ok, state(t)} end,
        tracking_lookback_s: 1,
        time_tolerance_s: 0.01,
        max_extra_evaluations: 128
      )

    MissionAnalysis.run([asset], requests, scene(Keyword.get(opts, :coverage, 120)),
      max_sample_gap_s: 1,
      asset_separation_s: 0,
      window_refinement: refinement,
      attitude: policy
    )
  end

  defp model(report),
    do: report["attitude_planning"]["resource_feasibility"]["assets"]["toy"]["models"] |> hd()

  test "eclipse entry/exit brackets and energy converge toward independent analytic circle values" do
    assert {:ok, report} = run()
    m = model(report)
    assert m["status"] == "supported"
    # The exact cylindrical eclipse lasts20s;100s of400W generation minus
    # 120s of100W consumption gives +7.777...Wh, without clipping or losses.
    exact = 100 + (400 * 100 - 100 * 120) / 3600
    fine = List.last(m["levels"])
    assert_in_delta fine["final_state"]["energy_wh"], exact, 1.0e-10
    assert m["state_comparison"]["final_state_range"]["energy_wh"]["spread"] > 0.4
    annotated = SolarDiagnostics.annotate(report)
    [diag] = annotated["solar_generation_diagnostics"]["models"]

    for level <- diag["levels"] do
      [entry, exit] = level["shadow_transition_brackets"]
      assert entry["from_sunlit"] and not entry["to_sunlit"]
      assert not exit["from_sunlit"] and exit["to_sunlit"]
      assert entry["earlier_sample_s"] <= 50 and entry["later_sample_s"] >= 50
      assert exit["earlier_sample_s"] <= 70 and exit["later_sample_s"] >= 70
      assert level["observed_power_range_w"] == %{"min" => 0.0, "max" => 400.0}
    end
  end

  test "terminal pointing changes generation during the maneuver and the entire hold" do
    assert {:ok, face} = run([], steps: [1])
    assert {:ok, away} = run([], steps: [1], terminal: Quaternion.increment({0, 0, 180}))
    face_energy = hd(model(face)["levels"])["final_state"]["energy_wh"]
    away_level = hd(model(away)["levels"])
    assert face_energy - away_level["final_state"]["energy_wh"] > 10

    assert Enum.any?(
             away_level["samples"],
             &(&1["phase"] == "slew_accelerate" and &1["metrics"]["generation_w"] > 100)
           )

    final_sample = List.last(away_level["samples"])
    assert final_sample["phase"] == "hold"
    assert final_sample["metrics"]["generation_w"] == 0
  end

  test "panel pointing can veto an otherwise physically eligible candidate" do
    request = fn angle ->
      Request.new!("r", Model, :opaque,
        activity_type: "test",
        starts_at_s: 3,
        ends_at_s: 13,
        duration_s: 10,
        time_scale: :tai,
        value: 1,
        parameters: %{"angle" => angle},
        resource_costs: %{"tokens" => 1}
      )
    end

    assert {:ok, facing} = run([request.(0)], initial: 1, reserve: 0.9)
    assert length(facing["activities"]) == 1
    assert {:ok, away} = run([request.(180)], initial: 1, reserve: 0.9)
    assert away["activities"] == []
    assert hd(away["selection_decisions"])["reason"] == "planning_start_grid_infeasible"

    assert hd(hd(away["selection_decisions"])["attitude_assessment"]["attempts"])["reason"] ==
             ":resource_feasibility_violated"

    assert model(away)["status"] == "supported"
  end

  test "environment coverage boundaries stop propagation and cannot yield a complete comparison" do
    assert {:ok, report} = run([], coverage: 60)
    m = model(report)
    assert m["status"] == "unknown"
    assert m["state_comparison"]["status"] == "incomplete"

    for level <- m["levels"] do
      assert level["final_state"] == :null
      assert level["evaluated_through_s"] == 60
      assert hd(level["uncovered_intervals"])["starts_at_s"] == 60
    end
  end
end
