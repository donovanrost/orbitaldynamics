defmodule OrbitalDynamics.MissionAnalysis.RepeatedServiceQualityCases do
  @moduledoc """
  Fixed-time synthetic repeated-service cases with an independently enumerated
  ideal maneuver/battery oracle. Production planning uses the normal attitude,
  path, horizon and battery runners. The oracle uses scalar angles and piecewise
  energy arithmetic, never the production feasibility evaluator. Its exactness
  applies only to these finite declared models and fixed activity intervals.
  """
  alias OrbitalDynamics.{Epoch, Frame, StateVector, Trajectory, MissionAnalysis}
  alias OrbitalDynamics.MissionAnalysis.{Asset, Evaluation, Request, WindowRefinement}
  alias OrbitalDynamics.MissionAnalysis.Attitude.{Pointing, Quaternion}
  alias OrbitalDynamics.MissionAnalysis.Path.Result

  defmodule Model do
    @moduledoc false
    @behaviour OrbitalDynamics.MissionAnalysis.Model
    def capabilities, do: %{"id" => "fixed_time_repeated_service"}

    def prepare(r, c, _),
      do: {:ok, %{allowed: r.id in c["allowed"], angle: r.parameters["angle_deg"]}, %{}}

    def evaluate(_, _, s),
      do: {:ok, Evaluation.new!([%{"id" => "allowed", "passed" => s.allowed}], %{})}

    def pointing(state, s, _),
      do: {:ok, Pointing.new!(state.frame, Quaternion.increment({0, 0, s.angle}))}

    def activity_mode(_, _),
      do: {:ok, Result.new!([%{"id" => "service_mode", "status" => "supported"}], %{})}
  end

  defmodule Guard do
    @moduledoc false
    @behaviour OrbitalDynamics.MissionAnalysis.Path.Check
    def prepare(_, _, _), do: {:ok, nil, %{}}

    def evaluate(_, _, _, _),
      do: {:ok, Result.new!([%{"id" => "declared_clear", "status" => "supported"}], %{})}
  end

  def cases do
    base = %{
      "initial_wh" => 4,
      "capacity_wh" => 5.5,
      "reserve_wh" => 2,
      "generation_w" => 360,
      "activity_load_w" => 1080,
      "max_rate_deg_s" => 10,
      "max_accel_deg_s2" => 5,
      "settling_s" => 1,
      "horizon_end_s" => 100
    }

    requests = fn angles, last_start ->
      Enum.zip([{"early", 20, 8}, {"middle", 40, 10}, {"late", last_start, 7}], angles)
      |> Enum.map(fn {{id, t, v}, angle} ->
        %{
          "id" => id,
          "start_s" => t,
          "duration_s" => 10,
          "value" => v,
          "angle_deg" => angle,
          "allowed_assets" => ["a"]
        }
      end)
    end

    [
      Map.merge(base, %{
        "id" => "repeated_assignment",
        "assets" => ["a", "b"],
        "requests" => [
          %{
            "id" => "flexible",
            "start_s" => 20,
            "duration_s" => 10,
            "value" => 10,
            "angle_deg" => 0,
            "allowed_assets" => ["a", "b"]
          },
          %{
            "id" => "restricted",
            "start_s" => 20,
            "duration_s" => 10,
            "value" => 9,
            "angle_deg" => 0,
            "allowed_assets" => ["a"]
          },
          %{
            "id" => "followup",
            "start_s" => 60,
            "duration_s" => 10,
            "value" => 8,
            "angle_deg" => 90,
            "allowed_assets" => ["a"]
          }
        ]
      }),
      Map.merge(base, %{
        "id" => "maneuver_gap",
        "assets" => ["a"],
        "requests" => requests.([0, 90, 0], 60)
      }),
      Map.merge(base, %{
        "id" => "battery_limited",
        "assets" => ["a"],
        "requests" => requests.([0, 0, 0], 60)
      }),
      Map.merge(base, %{
        "id" => "battery_recovery",
        "assets" => ["a"],
        "requests" => requests.([0, 0, 0], 80)
      })
    ]
  end

  def run!(scheduling \\ nil) do
    for config <- cases() do
      {us, report} = :timer.tc(fn -> plan!(config, scheduling) end)
      reference = oracle(config)
      value = Enum.sum(Enum.map(report["activities"], & &1["value"]))

      %{
        "id" => config["id"],
        "configuration" => config,
        "planner_value" => value,
        "optimal_value" => reference["optimal_value"],
        "absolute_gap" => reference["optimal_value"] - value,
        "oracle" => reference,
        "planning_status" => report["attitude_planning"]["planning_status"],
        "activities" =>
          Enum.map(
            report["activities"],
            &Map.take(&1, ~w(request_id asset_id starts_at_s ends_at_s value))
          ),
        "runtime_ms" => us / 1000,
        "scheduling_search" => Map.get(report, "scheduling_search", :null),
        "scope" => "exact_for_declared_fixed_time_scalar_angle_and_ideal_battery_model_only"
      }
    end
  end

  def plan!(c, scheduling) do
    frame = Frame.new!(:quality_inertial, :synthetic, :synthetic)
    state = fn t -> StateVector.new!({2000, 0, 0}, {0, 0, 0}, Epoch.new!(t, :tai), frame) end

    assets =
      for id <- c["assets"] do
        allowed = for r <- c["requests"], id in r["allowed_assets"], do: r["id"]

        Asset.new!(
          id,
          %Trajectory{
            scenario_id: c["id"],
            states: Enum.map(0..c["horizon_end_s"], state),
            assumptions: %{}
          },
          %{Model => %{"allowed" => allowed}},
          %{}
        )
      end

    requests =
      for r <- c["requests"] do
        Request.new!(r["id"], Model, nil,
          activity_type: "service",
          starts_at_s: r["start_s"],
          ends_at_s: r["start_s"] + r["duration_s"],
          duration_s: r["duration_s"],
          time_scale: :tai,
          value: r["value"],
          parameters: %{"angle_deg" => r["angle_deg"]},
          resource_costs: %{}
        )
      end

    path =
      OrbitalDynamics.MissionAnalysis.Path.Policy.new!(
        Map.new(c["assets"], fn id ->
          {id,
           %{
             activity_modes: Map.new(c["requests"], &{&1["id"], "service"}),
             transition_mode: "recovery",
             modes: %{
               "service" => %{"power_load_w" => c["activity_load_w"]},
               "recovery" => %{"power_load_w" => 0}
             },
             rules: [%{id: "clear", module: Guard, configuration: %{}}]
           }}
        end),
        sample_steps_s: [2, 1],
        max_evaluations: 10000,
        max_samples_per_segment: 1000
      )

    resources =
      OrbitalDynamics.MissionAnalysis.Resource.Policy.new!(
        Map.new(c["assets"], fn id ->
          {id,
           [
             %{
               id: "battery",
               module: OrbitalDynamics.MissionAnalysis.Resource.Battery,
               exclusive_cost_keys: [],
               configuration: %{
                 "initial_wh" => c["initial_wh"],
                 "capacity_wh" => c["capacity_wh"],
                 "reserve_wh" => c["reserve_wh"],
                 "charge_efficiency" => 1,
                 "discharge_efficiency" => 1,
                 "phase_load_w" =>
                   Map.new(
                     ~w(activity brake hold slew_accelerate slew_cruise slew_decelerate settle ramp_to_tracking),
                     &{&1, 0}
                   ),
                 "generation" => %{"kind" => "constant", "power_w" => c["generation_w"]}
               }
             }
           ]}
        end),
        sample_steps_s: [2, 1],
        max_intervals_per_asset: 1000,
        max_evaluations: 20000
      )

    limits =
      Map.new(c["assets"], fn id ->
        {id,
         %{
           max_rate_deg_s: c["max_rate_deg_s"],
           max_accel_deg_s2: c["max_accel_deg_s2"],
           settling_s: c["settling_s"],
           initial: %{
             epoch: Epoch.new!(0, :tai),
             frame: frame,
             quaternion: {1, 0, 0, 0},
             angular_velocity_deg_s: {0, 0, 0}
           },
           pointing_configurations: %{Model => %{}}
         }}
      end)

    horizon = %{
      start: Epoch.new!(0, :tai),
      stop: Epoch.new!(c["horizon_end_s"], :tai),
      terminals:
        Map.new(c["assets"], &{&1, %{frame: frame, quaternion: {1, 0, 0, 0}, mode: "recovery"}})
    }

    attitude =
      OrbitalDynamics.MissionAnalysis.Attitude.Policy.new!(limits,
        profile_step_s: 1,
        derivative_step_s: 0.1,
        search_step_s: 1,
        max_candidate_starts: 1,
        max_evaluations: 20000,
        path_constraints: path,
        resources: resources,
        horizon: horizon
      )

    refinement =
      WindowRefinement.new!(
        state_at: fn _, t -> {:ok, state.(t)} end,
        tracking_lookback_s: 1,
        time_tolerance_s: 0.01,
        max_extra_evaluations: 128
      )

    opts = [
      max_sample_gap_s: 1,
      asset_separation_s: 0,
      attitude: attitude,
      window_refinement: refinement,
      include_samples: false
    ]

    opts = if scheduling, do: Keyword.put(opts, :scheduling, scheduling), else: opts

    case MissionAnalysis.run(assets, requests, nil, opts) do
      {:ok, r} -> r
      {:error, reason} -> raise ArgumentError, "quality planning failed: #{inspect(reason)}"
    end
  end

  @doc "Enumerates every skip/allowed-asset assignment at the declared fixed service times."
  def oracle(c) do
    validate_oracle_config!(c)
    candidates = assignments(c["requests"])

    checked =
      Enum.map(candidates, fn candidate ->
        status =
          Enum.reduce_while(c["assets"], :feasible, fn id, _ ->
            result =
              candidate
              |> Enum.filter(&(&1["asset_id"] == id))
              |> Enum.sort_by(& &1["start_s"])
              |> check_sequence(c)

            if result == :feasible, do: {:cont, :feasible}, else: {:halt, result}
          end)

        {candidate, status}
      end)

    feasible = for {a, :feasible} <- checked, do: a
    best = Enum.max_by(feasible, fn a -> Enum.sum(Enum.map(a, & &1["value"])) end)

    %{
      "optimal_value" => Enum.sum(Enum.map(best, & &1["value"])),
      "witness" => Enum.map(best, &Map.take(&1, ~w(id asset_id start_s duration_s value))),
      "enumerated_count" => length(checked),
      "feasible_count" => length(feasible),
      "rejection_reasons" =>
        checked
        |> Enum.reject(&(elem(&1, 1) == :feasible))
        |> Enum.frequencies_by(&(elem(&1, 1) |> Atom.to_string()))
    }
  end

  defp validate_oracle_config!(c) do
    numeric =
      ~w(initial_wh capacity_wh reserve_wh generation_w activity_load_w max_rate_deg_s max_accel_deg_s2 settling_s)

    unless Enum.all?(numeric, &is_number(c[&1])) and
             c["capacity_wh"] > 0 and c["reserve_wh"] >= 0 and
             c["initial_wh"] >= c["reserve_wh"] and c["initial_wh"] <= c["capacity_wh"] and
             c["generation_w"] >= 0 and c["activity_load_w"] >= 0 and
             c["max_rate_deg_s"] > 0 and c["max_accel_deg_s2"] > 0 and
             c["settling_s"] >= 0 and is_integer(c["horizon_end_s"]) and
             c["horizon_end_s"] in 1..1000 and c["horizon_end_s"] >= c["settling_s"],
           do:
             raise(
               ArgumentError,
               "oracle requires known bounded power/motion inputs and an initially valid battery reserve/capacity"
             )

    assets = c["assets"]
    requests = c["requests"]

    unless is_list(assets) and length(assets) in 1..3 and Enum.all?(assets, &is_binary/1) and
             length(Enum.uniq(assets)) == length(assets) and is_list(requests) and
             length(requests) <= 6 and
             length(Enum.uniq_by(requests, & &1["id"])) == length(requests) and
             Enum.all?(requests, fn r ->
               is_binary(r["id"]) and is_number(r["start_s"]) and r["start_s"] >= 0 and
                 is_number(r["duration_s"]) and r["duration_s"] > 0 and
                 r["start_s"] + r["duration_s"] <= c["horizon_end_s"] and
                 is_number(r["value"]) and r["value"] >= 0 and
                 is_number(r["angle_deg"]) and r["angle_deg"] >= 0 and r["angle_deg"] <= 90 and
                 is_list(r["allowed_assets"]) and Enum.all?(r["allowed_assets"], &(&1 in assets)) and
                 length(Enum.uniq(r["allowed_assets"])) == length(r["allowed_assets"])
             end),
           do:
             raise(
               ArgumentError,
               "oracle accepts at most six fixed-time requests, three assets and common-axis angles in 0..90 degrees"
             )
  end

  defp assignments([]), do: [[]]

  defp assignments([r | rest]) do
    tails = assignments(rest)
    tails ++ for id <- r["allowed_assets"], tail <- tails, do: [Map.put(r, "asset_id", id) | tail]
  end

  defp check_sequence(sequence, c) do
    terminal = %{"start_s" => c["horizon_end_s"], "duration_s" => 0, "angle_deg" => 0}

    Enum.reduce_while(sequence ++ [terminal], {:feasible, 0, 0, c["initial_wh"]}, fn r,
                                                                                     {:feasible,
                                                                                      previous_end,
                                                                                      angle,
                                                                                      energy} ->
      gap = r["start_s"] - previous_end
      distance = abs(r["angle_deg"] - angle)
      rate = c["max_rate_deg_s"]
      accel = c["max_accel_deg_s2"]

      motion =
        if distance <= rate * rate / accel,
          do: 2 * :math.sqrt(distance / accel),
          else: distance / rate + rate / accel

      required = motion + c["settling_s"]
      charged = min(c["capacity_wh"], energy + gap * c["generation_w"] / 3600)

      after_service =
        min(
          c["capacity_wh"],
          charged + r["duration_s"] * (c["generation_w"] - c["activity_load_w"]) / 3600
        )

      cond do
        gap < 0 ->
          {:halt, :overlap}

        gap < required ->
          {:halt, :maneuver_gap}

        min(charged, after_service) < c["reserve_wh"] ->
          {:halt, :battery_reserve}

        true ->
          {:cont, {:feasible, r["start_s"] + r["duration_s"], r["angle_deg"], after_service}}
      end
    end)
    |> case do
      {:feasible, _, _, _} -> :feasible
      reason -> reason
    end
  end
end
