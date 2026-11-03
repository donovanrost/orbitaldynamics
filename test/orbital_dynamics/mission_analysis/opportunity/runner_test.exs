defmodule OrbitalDynamics.MissionAnalysis.Opportunity.RunnerTest do
  use ExUnit.Case, async: true
  alias OrbitalDynamics.{Epoch, Frame, StateVector, Trajectory}
  alias OrbitalDynamics.MissionAnalysis
  alias OrbitalDynamics.MissionAnalysis.{Asset, Request, Evaluation, WindowRefinement}
  alias OrbitalDynamics.MissionAnalysis.Opportunity.{Policy, Functions}

  defmodule Model do
    @behaviour OrbitalDynamics.MissionAnalysis.Model
    def capabilities, do: %{"id" => "arbitrary-mission"}

    def prepare(request, _, _) do
      token = make_ref()
      send(self(), {:prepared, token})
      {:ok, {token, request.subject}, %{"model" => "analytic-linear-constraints"}}
    end

    def evaluate(state, _, {token, opts}) do
      t = state.epoch.seconds_since_j2000
      send(self(), {:evaluated, token, t})

      checks =
        for {id, v} <- [
              {"access_open", t - 10.3},
              {"access_close", 80.7 - t},
              {"night_open", t - 20.4},
              {"night_close", 90.1 - t}
            ] do
          v =
            if opts["hidden"] == true and id == "night_open",
              do: if(t > 10.62 and t < 10.63, do: -1, else: 1),
              else: v

          strict = opts["mislabel"] == true and id == "night_open"
          unknown = opts["unknown"] == true and id == "night_open" and t >= 45 and t <= 55

          %{
            "id" => id,
            "passed" => not unknown and if(strict, do: v > 0, else: v >= 0),
            "margin" => if(unknown, do: :null, else: v),
            "margin_unit" => "s",
            "margin_comparison" => if(strict, do: "strict_min", else: "min")
          }
        end

      {:ok, Evaluation.new!(checks, %{})}
    end

    def opportunity_functions(session, source, lookback) do
      specs = for id <- ~w(access_open access_close night_open night_close), do: {id, "s", 1.0e-9}
      opts = elem(session, 1)

      cond do
        opts["omit"] ->
          {:ok, Functions.from_evaluation(__MODULE__, session, source, lookback, tl(specs))}

        opts["mislabel"] ->
          {:ok,
           Enum.map(specs, fn {id, unit, tol} ->
             OrbitalDynamics.EventSearch.Function.new!(
               id,
               fn state ->
                 t = state.epoch.seconds_since_j2000

                 v =
                   case id do
                     "access_open" -> t - 10.3
                     "access_close" -> 80.7 - t
                     "night_open" -> t - 20.4
                     "night_close" -> 90.1 - t
                   end

                 {:ok, v, nil, %{}}
               end,
               units: unit,
               value_tolerance: tol,
               condition: :nonnegative
             )
           end)}

        opts["lie"] ->
          {:ok,
           Enum.map(specs, fn {id, unit, tol} ->
             OrbitalDynamics.EventSearch.Function.new!(id, fn _ -> {:ok, 1, nil, %{}} end,
               units: unit,
               value_tolerance: tol,
               condition: :nonnegative
             )
           end)}

        true ->
          {:ok, Functions.from_evaluation(__MODULE__, session, source, lookback, specs)}
      end
    end
  end

  defmodule Unsupported do
    @behaviour OrbitalDynamics.MissionAnalysis.Model
    def capabilities, do: %{"id" => "without-scalars"}
    def prepare(_, _, _), do: {:ok, nil, %{}}
    def evaluate(_, _, _), do: {:ok, Evaluation.new!([%{"id" => "check", "passed" => true}], %{})}
  end

  defp state(t),
    do:
      StateVector.new!(
        {2000, t, 0},
        {0, 1, 0},
        Epoch.new!(t, :tai),
        Frame.new!(:toy, :toy, :inertial)
      )

  defp policy(opts \\ []),
    do:
      Policy.new!(
        Keyword.merge(
          [
            max_check_step_s: 5,
            time_tolerance_s: 0.0001,
            max_iterations: 64,
            max_evaluations: 10000,
            entry_margin_s: 2,
            exit_margin_s: 3
          ],
          opts
        )
      )

  defp run(subject \\ %{}, opts \\ []) do
    model = Keyword.get(opts, :model, Model)

    asset =
      Asset.new!(
        "asset",
        %Trajectory{scenario_id: "toy", states: [state(0), state(100)], assumptions: %{}},
        %{model => %{}},
        %{}
      )

    request =
      Request.new!("request", model, subject,
        activity_type: "service",
        starts_at_s: 0,
        ends_at_s: 100,
        duration_s: 10,
        time_scale: :tai,
        value: 1,
        parameters: %{},
        resource_costs: %{}
      )

    sampler = Keyword.get(opts, :sampler, fn _, t -> {:ok, state(t)} end)

    refinement =
      WindowRefinement.new!(
        state_at: sampler,
        tracking_lookback_s: 1,
        time_tolerance_s: 0.001,
        max_extra_evaluations: 100
      )

    MissionAnalysis.run([asset], [request], nil,
      max_sample_gap_s: 100,
      asset_separation_s: 0,
      window_refinement: refinement,
      opportunity_search: Keyword.get(opts, :policy, policy())
    )
  end

  test "generic constraint intersection schedules from inward bounds plus one application of mission margins" do
    assert {:ok, r} = run()
    assert [o] = r["opportunities"]
    assert o["starts_at_s"] > 22.4 and o["starts_at_s"] < 22.401
    assert o["ends_at_s"] < 77.7 and o["ends_at_s"] > 77.699
    e = o["window_evidence"]
    assert e["limiting_constraints"] == %{"entry" => ["night_open"], "exit" => ["access_close"]}
    assert e["entry_margin_s"] == 2
    assert e["exit_margin_s"] == 3
    assert [a] = r["activities"]
    assert a["starts_at_s"] == o["starts_at_s"]
    assert a["opportunity_evidence"] == e
    assert Enum.all?(a["endpoint_samples"], & &1["feasible"])
    [analysis] = r["analyses"]
    assert analysis["opportunity_evidence"]["total_evaluation_count"] <= 10000
    assert analysis["opportunity_evidence"]["endpoint_budget_counts"]["function_evaluations"] == 2
    assert_receive {:prepared, token}
    refute_receive {:prepared, _}
    assert_receive {:evaluated, ^token, _}
  end

  test "unknown margins and missing source spans split known windows without bridging" do
    for opts <- [
          [],
          [
            sampler: fn _, t ->
              if t >= 45 and t <= 55, do: {:unknown, :source_gap}, else: {:ok, state(t)}
            end
          ]
        ] do
      assert {:ok, r} = run(%{"unknown" => true}, opts)
      assert length(r["opportunities"]) == 2
      assert Enum.all?(r["opportunities"], &(&1["ends_at_s"] < 45 or &1["starts_at_s"] > 55))
      [analysis] = r["analyses"]
      assert analysis["opportunity_evidence"]["status"] == "partial_under_search_policy"
      assert analysis["opportunity_evidence"]["excluded_unknown_intervals"] != []
    end
  end

  test "margins removing a window and unavailable model declarations remain explained" do
    assert {:ok, r} = run(%{}, policy: policy(entry_margin_s: 40, exit_margin_s: 40))
    assert r["activities"] == []
    [a] = r["analyses"]

    assert Enum.any?(
             a["opportunity_evidence"]["windows"],
             &(&1["reason"] == "removed_by_mission_timing_margins")
           )

    assert {:ok, r} = run(%{}, model: Unsupported)
    assert r["opportunities"] == []
    assert hd(r["requests"])["reasons"] == ["model_opportunity_constraints_unavailable"]
  end

  test "bounded callbacks and provider errors abort and clean shared search context" do
    assert {:error, {:model_error, "asset", "request", :event_search_evaluation_budget_exhausted}} =
             run(%{}, policy: policy(max_evaluations: 5))

    assert OrbitalDynamics.EventSearch.Context.current() == nil

    assert {:error, {:model_error, "asset", "request", :provider_down}} =
             run(%{}, sampler: fn _, _ -> {:error, :provider_down} end)
  end

  test "every model check must be declared and optimistic custom functions cannot bypass the full model" do
    assert {:error, {:model_error, "asset", "request", {:invalid_event_search, message}}} =
             run(%{"omit" => true})

    assert message =~ "cover every model check"

    assert {:error, {:model_error, "asset", "request", {:invalid_event_search, message}}} =
             run(%{"lie" => true})

    assert message =~ "disagrees with complete model check"

    assert {:error, {:model_error, "asset", "request", {:invalid_event_search, message}}} =
             run(%{"mislabel" => true})

    assert message =~ "strict declaration disagrees"
  end

  test "endpoint probes share the same bounded search allowance and restore accounting context" do
    alias OrbitalDynamics.EventSearch.{Source, Function, Context}
    alias OrbitalDynamics.MissionAnalysis.Opportunity.Endpoints

    source =
      Source.new!(
        fn t -> {:ok, state(t)} end,
        Epoch.new!(0, :tai),
        Epoch.new!(100, :tai),
        state(0).frame,
        %{}
      )

    evaluation =
      Function.new!(
        "eval",
        fn _ -> {:ok, 1, nil, %{"feasible" => true, "checks" => [], "metrics" => %{}}} end,
        units: "1",
        value_tolerance: 0
      )

    windows = [%{"status" => "accepted", "starts_at_s" => 10, "ends_at_s" => 20}]

    assert {:error, :event_search_evaluation_budget_exhausted} =
             Endpoints.check(windows, evaluation, source, 2)

    assert Context.current() == nil
  end

  test "a refinement probe exposing another constraint's hidden failure vetoes the whole observed candidate" do
    assert {:ok, r} =
             run(%{"hidden" => true}, policy: policy(entry_margin_s: 0, exit_margin_s: 0))

    assert r["opportunities"] == []
    [analysis] = r["analyses"]
    [window] = analysis["opportunity_evidence"]["windows"]
    assert window["reason"] == "observed_model_contradiction"
    assert_in_delta window["first_contradiction"]["epoch_s"], 10.625, 1.0e-12

    assert Enum.any?(
             window["first_contradiction"]["checks"],
             &(&1["id"] == "night_open" and not &1["passed"])
           )

    assert Enum.any?(
             analysis["opportunity_evidence"]["event_search"]["function_observations"],
             &(&1["epoch_s"] == 10.625 and &1["metadata"]["feasible"] == false)
           )
  end

  test "the same runner composes imaging constraints on an explicit non-Earth scene" do
    alias OrbitalDynamics.{CentralBody, Target}
    alias OrbitalDynamics.MissionAnalysis.{SphericalScene, Environments.Fixed}
    alias OrbitalDynamics.MissionAnalysis.Models.Imaging
    frame = Frame.new!(:toy, :toy, :inertial)

    sampler = fn _, t ->
      {:ok, StateVector.new!({2, 0, 0}, {0, 0, 0}, Epoch.new!(t, :tai), frame)}
    end

    {:ok, first} = sampler.(nil, 0)
    {:ok, last} = sampler.(nil, 100)

    payload = %{
      "field_of_view_deg" => 1,
      "pixels_across" => 1000,
      "max_off_nadir_deg" => 80,
      "max_tracking_rate_deg_s" => 2
    }

    asset =
      Asset.new!(
        "camera",
        %Trajectory{scenario_id: "imaging", states: [first, last], assumptions: %{}},
        %{Imaging => payload},
        %{}
      )

    target = Target.new!("site", 0, 0)

    request =
      Request.new!("image", Imaging, target,
        activity_type: "image",
        starts_at_s: 0,
        ends_at_s: 100,
        duration_s: 10,
        time_scale: :tai,
        value: 1,
        parameters: %{
          "minimum_elevation_deg" => 10,
          "minimum_target_sun_elevation_deg" => 0,
          "maximum_gsd_m" => 1,
          "target_radius_km" => 0.001
        },
        resource_costs: %{}
      )

    environment =
      Fixed.new!(frame, Epoch.new!(0, :tai),
        sun_direction: {1, 0, 0},
        rotation_rate_rad_s: 0,
        rotation_angle_rad: 0,
        starts_at_s: 0,
        ends_at_s: 100
      )

    scene =
      SphericalScene.new!(
        CentralBody.new!(:toy, 1, equatorial_radius_km: 1),
        frame,
        :tai,
        {Fixed, environment}
      )

    refinement =
      WindowRefinement.new!(
        state_at: sampler,
        tracking_lookback_s: 1,
        time_tolerance_s: 0.001,
        max_extra_evaluations: 100
      )

    assert {:ok, r} =
             MissionAnalysis.run([asset], [request], scene,
               max_sample_gap_s: 100,
               asset_separation_s: 0,
               window_refinement: refinement,
               opportunity_search: policy(entry_margin_s: 0, exit_margin_s: 0)
             )

    assert [activity] = r["activities"]
    assert activity["type"] == "image"
    assert length(hd(r["analyses"])["opportunity_evidence"]["constraints"]) == 8
  end
end
