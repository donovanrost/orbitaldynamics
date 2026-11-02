defmodule OrbitalDynamics.MissionAnalysis.WindowRefinementTest do
  use ExUnit.Case, async: true
  alias OrbitalDynamics.{Epoch, Frame, StateVector, Trajectory}
  alias OrbitalDynamics.MissionAnalysis
  alias OrbitalDynamics.MissionAnalysis.{Asset, Evaluation, Request, WindowRefinement}
  alias OrbitalDynamics.MissionAnalysis.Models.SurfaceSupport

  defmodule Model do
    def capabilities, do: %{"id" => "analytic-time-window"}

    def prepare(request, _, _) do
      if request.parameters["capture_revision"] do
        revision = Process.get(:window_revision, 0) + 1
        Process.put(:window_revision, revision)
        {:ok, Map.put(request.parameters, "revision", revision), %{"revision" => revision}}
      else
        {:ok, request.parameters, %{}}
      end
    end

    def evaluate(state, _previous, p) do
      t = state.epoch.seconds_since_j2000

      checks = [
        SurfaceSupport.check("after_start", t >= p["start"], t, p["start"], :min, "s"),
        SurfaceSupport.check("before_end", t <= p["end"], t, p["end"], :max, "s")
      ]

      checks =
        if p["hole_start"],
          do:
            checks ++
              [%{"id" => "hole", "passed" => not (t > p["hole_start"] and t < p["hole_end"])}],
          else: checks

      {:ok, Evaluation.new!(checks, %{"clock_s" => t, "revision" => Map.get(p, "revision", 0)})}
    end
  end

  def state(t),
    do:
      StateVector.new!(
        {2000, 0, 0},
        {0, 0, 0},
        Epoch.new!(t, :tai),
        Frame.new!(:toy, :toy, :inertial)
      )

  def inputs(step \\ 10, params \\ %{"start" => 3.25, "end" => 17.75}, duration \\ 12) do
    a =
      Asset.new!(
        "a",
        %Trajectory{
          scenario_id: "analytic",
          states: Enum.map(0..30//step, &state/1),
          assumptions: %{}
        },
        %{Model => %{}},
        %{}
      )

    r =
      Request.new!("r", Model, :opaque,
        activity_type: "activity",
        starts_at_s: 0,
        ends_at_s: 30,
        duration_s: duration,
        time_scale: :tai,
        value: 1,
        parameters: params,
        resource_costs: %{}
      )

    {a, r}
  end

  def policy(fun \\ fn _, t -> {:ok, state(t)} end, budget \\ 128),
    do:
      WindowRefinement.new!(
        state_at: fun,
        tracking_lookback_s: 1,
        time_tolerance_s: 0.001,
        max_extra_evaluations: budget
      )

  def run(a, r, p),
    do:
      MissionAnalysis.run([a], [r], nil,
        max_sample_gap_s: 10,
        asset_separation_s: 0,
        window_refinement: p
      )

  test "refines a single eligible seed into inner endpoints and schedules with checked activity endpoints" do
    {a, r} = inputs()

    assert {:ok, coarse} =
             MissionAnalysis.run([a], [r], nil, max_sample_gap_s: 10, asset_separation_s: 0)

    assert coarse["activities"] == []
    assert {:ok, refined} = run(a, r, policy())
    [w] = hd(refined["analyses"])["window_evidence"]
    assert w["starts_at_s"] >= 3.25
    assert w["starts_at_s"] - 3.25 <= 0.001
    assert w["ends_at_s"] <= 17.75
    assert 17.75 - w["ends_at_s"] <= 0.001
    assert w["entry"]["width_s"] <= 0.001
    assert w["exit"]["width_s"] <= 0.001
    [activity] = refined["activities"]
    assert Enum.all?(activity["endpoint_samples"], & &1["feasible"])
    assert length(activity["endpoint_samples"]) == 2
    assert {:ok, ^refined} = run(a, r, policy())
  end

  test "scheduled endpoint checks reuse the pair's original captured session" do
    {a, r} = inputs(10, %{"start" => -1, "end" => 31, "capture_revision" => true}, 10)
    assert {:ok, report} = run(a, r, policy())
    assert Process.get(:window_revision) == 1
    assert hd(report["analyses"])["assumptions"]["revision"] == 1

    assert Enum.all?(
             hd(report["activities"])["endpoint_samples"],
             &(&1["metrics"]["revision"] == 1)
           )

    assert hd(report["activities"])["endpoint_evaluation_count"] == 2
  end

  test "budget exhaustion, sampler errors and wrong frame/epoch abort analysis" do
    {a, r} = inputs()

    assert {:error, {:model_error, "a", "r", :refinement_evaluation_budget_exhausted}} =
             run(a, r, policy(fn _, t -> {:ok, state(t)} end, 1))

    assert {:error, {:model_error, "a", "r", :missing_environment}} =
             run(a, r, policy(fn _, _ -> {:error, :missing_environment} end))

    assert {:error, {:invalid_mission_analysis, _}} =
             run(a, r, policy(fn _, t -> {:ok, state(t + 1)} end))
  end

  test "numeric epoch identity accepts integer anchors and float query bounds" do
    {a, r} = inputs(10, %{"start" => -1, "end" => 31}, 10)
    sampler = fn _, t -> {:ok, state(if(trunc(t) == t, do: trunc(t), else: t))} end
    assert {:ok, report} = run(a, r, policy(sampler))
    [window] = hd(report["analyses"])["window_evidence"]
    assert window["entry"]["kind"] == "request_or_coverage_clip"
    assert window["starts_at_s"] == 0
    assert window["ends_at_s"] == 30
  end

  test "a discovered invalid scheduled endpoint fails closed" do
    # The 7.1s exit of the activity lies in a dip missed by the 10s seeds.
    {a, r} = inputs(10, %{"start" => 1, "end" => 29, "hole_start" => 7, "hole_end" => 8}, 6.1)

    assert {:error, {:activity_endpoint_verification_failed, {:scheduled_endpoint_ineligible, _}}} =
             run(a, r, policy())
  end

  test "finer full-horizon samples expose a hidden ineligible island" do
    params = %{"start" => 0, "end" => 30, "hole_start" => 7.1, "hole_end" => 8.9}
    {a, r} = inputs(10, params, 25)
    assert {:ok, coarse} = run(a, r, policy())
    assert length(coarse["activities"]) == 1
    {fine, r} = inputs(1, params, 25)
    assert {:ok, fine} = run(fine, r, policy())
    assert fine["activities"] == []
    assert length(hd(fine["analyses"])["window_evidence"]) == 2
  end

  test "fixed lookback does not shrink during bisection and explicit gaps are not bridged" do
    {a, r} = inputs()
    parent = self()

    sampler = fn _, t ->
      send(parent, {:time, t})
      {:ok, state(t)}
    end

    assert {:ok, _} = run(a, r, policy(sampler))

    times =
      Stream.repeatedly(fn ->
        receive do
          {:time, t} -> t
        after
          0 -> :done
        end
      end)
      |> Enum.take_while(&(&1 != :done))

    assert [first | rest] = times
    assert first == 0
    assert rem(length(rest), 2) == 0

    assert Enum.chunk_every(rest, 2, 2, :discard)
           |> Enum.all?(fn [t, previous] -> previous == t - 1 end)

    # Every subsecond probe still evaluates its predecessor exactly one second earlier.
    assert Enum.any?(times, &(not (trunc(&1) == &1)))

    evaluator = fn t ->
      {:ok,
       %{
         "epoch_s" => t,
         "feasible" => true,
         "checks" => [%{"id" => "ok", "passed" => true}],
         "metrics" => %{}
       }}
    end

    samples =
      Enum.map([0, 10, 40, 50], fn t ->
        {:ok, s} = evaluator.(t)
        s
      end)

    assert {:ok, windows, _, _} = WindowRefinement.run(samples, evaluator, 0, 50, 10, policy())
    assert Enum.map(windows, &{&1["starts_at_s"], &1["ends_at_s"]}) == [{0.0, 10.0}, {40.0, 50.0}]
  end
end

defmodule OrbitalDynamics.MissionAnalysis.ResolutionStudyTest do
  use ExUnit.Case, async: true
  alias OrbitalDynamics.MissionAnalysis.ResolutionStudy
  alias OrbitalDynamics.MissionAnalysis.WindowRefinementTest, as: F

  defp levels,
    do: [
      %{"id" => "fine", "dimension" => "reference", "sample_step_s" => 1, "max_step_s" => 1},
      %{"id" => "coarse", "dimension" => "sampling", "sample_step_s" => 10, "max_step_s" => 1}
    ]

  defp run(evaluator, thresholds \\ %{}),
    do:
      ResolutionStudy.run!(levels(), evaluator,
        study_id: "analytic-resolution",
        reference_level_id: "fine",
        window_time_tolerance_s: 0.01,
        schedule_time_tolerance_s: 0.01,
        margin_thresholds: thresholds
      )

  defp evaluator(params, duration) do
    fn level ->
      {a, r} = F.inputs(level["sample_step_s"], params, duration)
      F.run(a, r, F.policy())
    end
  end

  test "finer scans expose missed dips and flag changed support and schedules" do
    e = evaluator(%{"start" => 0, "end" => 30, "hole_start" => 7.1, "hole_end" => 8.9}, 25)
    report = run(e)
    assert report == run(e)

    assert report["request_stability"] == [
             %{"request_id" => "r", "status" => "changed_across_tested_levels"}
           ]

    [_, coarse] = report["comparisons"]
    assert "duration_support_changed" in hd(coarse["requests"])["reasons"]
    assert "scheduling_status_changed" in hd(coarse["requests"])["reasons"]
  end

  test "reports sampled margins in their own units and categorical/unknown cases honestly" do
    thresholds = %{
      "after_start" => %{"unit" => "s", "minimum_headroom" => 2},
      "before_end" => %{"unit" => "wrong-unit", "minimum_headroom" => 2}
    }

    report =
      run(
        evaluator(%{"start" => -1, "end" => 31, "hole_start" => 100, "hole_end" => 101}, 10),
        thresholds
      )

    assert hd(report["request_stability"])["status"] == "stable_across_tested_levels"
    [a] = hd(hd(report["levels"])["request_evidence"])["activities"]
    m = Map.new(a["sampled_check_margins"], &{&1["check_id"], &1})
    assert m["after_start"]["minimum_sampled_margin"] == 1
    assert m["after_start"]["assessment"] == "near_declared_limit"
    assert m["before_end"]["assessment"] == "threshold_unit_mismatch"
    assert m["hole"]["assessment"] == "no_numeric_margin"
    assert a["endpoint_evidence_present"]
    assert a["duration_headroom_s"] == 20
    assert a["largest_tested_interval_s"] == 1
    assert ResolutionStudy.csv(report) =~ "integration_s"
    assert ResolutionStudy.markdown(report) =~ "stable_across_tested_levels"
  end

  test "evaluation errors are unknown comparisons and never zero-filled schedules" do
    good = evaluator(%{"start" => -1, "end" => 31}, 10)

    report =
      run(fn l -> if l["id"] == "fine", do: {:error, :provider_unavailable}, else: good.(l) end)

    assert report["error_level_count"] == 1
    assert hd(report["request_stability"])["status"] == "unknown"
    refute Map.has_key?(hd(report["levels"]), "summary")
  end

  test "two physically supported schedules with shifted endpoints are flagged" do
    report =
      run(fn l ->
        e = evaluator(%{"start" => if(l["id"] == "fine", do: 1, else: 3), "end" => 29}, 10)
        e.(l)
      end)

    reasons =
      report["comparisons"]
      |> List.last()
      |> Map.fetch!("requests")
      |> hd()
      |> Map.fetch!("reasons")

    assert "schedule_timing_changed" in reasons
    assert "window_timing_changed" in reasons
  end

  test "one-dimension controls and finest-reference choice are validated before evaluation" do
    [fine, coarse] = levels()

    opts = [
      study_id: "bad",
      reference_level_id: "fine",
      window_time_tolerance_s: 1,
      schedule_time_tolerance_s: 1,
      margin_thresholds: %{}
    ]

    never = fn _ -> flunk("invalid study evaluated") end

    assert_raise ArgumentError, fn ->
      ResolutionStudy.run!([fine, %{coarse | "max_step_s" => 5}], never, opts)
    end

    assert_raise ArgumentError, fn ->
      ResolutionStudy.run!([%{fine | "sample_step_s" => 20}, coarse], never, opts)
    end
  end
end
