defmodule OrbitalDynamics.MissionAnalysis.TradeStudyTest do
  use ExUnit.Case, async: true
  alias OrbitalDynamics.{Epoch, Frame, StateVector, Trajectory}
  alias OrbitalDynamics.MissionAnalysis
  alias OrbitalDynamics.MissionAnalysis.{Asset, Evaluation, Request, TradeStudy}

  defmodule Model do
    def capabilities, do: %{"id" => "trade-toy"}
    def prepare(r, payload, _), do: {:ok, {r.parameters, payload}, %{}}

    def evaluate(state, _, {p, payload}) do
      checks = for name <- ~w(available other), do: %{"id" => name, "passed" => p[name]}

      {:ok,
       Evaluation.new!(checks, %{
         "quantity_w" => state.epoch.seconds_since_j2000 + payload["seed"],
         "flag" => true
       })}
    end
  end

  defp base,
    do: %{
      "budget" => 5,
      "duration" => 10,
      "available" => true,
      "other" => true,
      "array" => [%{"key" => 1}]
    }

  defp axis(id, path, values),
    do: %{
      "id" => id,
      "cases" =>
        Enum.with_index(values, fn value, i ->
          %{"id" => "v#{i}", "updates" => [%{"path" => path, "value" => value}]}
        end)
    }

  defp evaluate(config, options \\ []) do
    if config["budget"] == 3 do
      {:error, :intentional_case_error}
    else
      frame = Frame.new!(:toy, :toy, :inertial)

      states =
        Enum.map(
          0..40//10,
          &StateVector.new!({2000, 0, 0}, {0, 0, 0}, Epoch.new!(&1, :tai), frame)
        )

      trajectory = %Trajectory{scenario_id: "toy", states: states, assumptions: %{}}

      assets =
        for {id, seed} <- [{"a", 0}, {"b", 1000}],
            do:
              Asset.new!(id, trajectory, %{Model => %{"seed" => seed}}, %{
                "energy_wh" => config["budget"]
              })

      r =
        Request.new!("r", Model, :opaque,
          activity_type: "activity",
          starts_at_s: 0,
          ends_at_s: 100,
          duration_s: config["duration"],
          time_scale: :tai,
          value: 1,
          parameters: Map.take(config, ~w(available other)),
          resource_costs: %{"energy_wh" => 2}
        )

      MissionAnalysis.run(
        assets,
        [r],
        nil,
        Keyword.merge([max_sample_gap_s: 10, asset_separation_s: 0], options)
      )
    end
  end

  defp run(axes, evaluator \\ &evaluate/1),
    do: TradeStudy.run!(base(), axes, evaluator, study_id: "toy-study", max_cases: 20)

  test "Cartesian replay separates duration support, resource rejection and evaluation errors" do
    axes = [axis("budget", ["budget"], [1, 3, 5]), axis("duration", ["duration"], [10, 50])]
    report = run(axes)
    assert report == run(axes)
    assert report["case_count"] == 6
    assert report["error_case_count"] == 2
    [limited, short_window, error1, error2, scheduled, _] = report["cases"]
    assert limited["summary"]["supported_request_count"] == 1
    assert limited["summary"]["scheduled_request_count"] == 0
    [r] = limited["summary"]["requests"]
    assert r["physical_status"] == "duration_supported"
    assert r["scheduling_reasons"] == ["insufficient_resource_budget"]
    assert short_window["summary"]["supported_request_count"] == 0
    assert hd(short_window["summary"]["requests"])["longest_eligible_run_span_s"] == 40
    assert error1["status"] == "error"
    assert error2["status"] == "error"
    refute Map.has_key?(error1, "summary")
    assert scheduled["summary"]["scheduled_duration_s"] == 10

    assert hd(scheduled["summary"]["requests"])["selected_interval_sample_metric_ranges"][
             "quantity_w"
           ]["max"] == 10

    assert hd(scheduled["summary"]["requests"])["eligible_metric_ranges"]["quantity_w"]["max"] ==
             1040

    assert scheduled["analysis_provenance"]["time_system"]["scale"] == "tai"
    assert TradeStudy.csv(report) =~ "intentional_case_error"
    assert TradeStudy.metric_csv(report) =~ "quantity_w"
    assert TradeStudy.check_csv(report) =~ "sole_failure_samples"
    assert TradeStudy.markdown(report) =~ "Supported requests"
  end

  test "check counts are nonexclusive, sole failures are explicit and absent samples are errors" do
    axes = [axis("a", ["available"], [false]), axis("b", ["other"], [false, true])]
    [both, sole] = run(axes)["cases"]
    both = hd(both["summary"]["requests"])
    sole = hd(sole["summary"]["requests"])
    assert both["check_diagnostics"]["available"]["failed_sample_count"] == 10
    assert both["check_diagnostics"]["available"]["sole_failed_check_sample_count"] == 0
    assert sole["check_diagnostics"]["available"]["sole_failed_check_sample_count"] == 10
    assert both["eligible_metric_ranges"] == %{}
    report = run([axis("b", ["budget"], [5])], &evaluate(&1, include_samples: false))
    {:ok, omitted} = evaluate(base(), include_samples: false)
    assert_raise ArgumentError, ~r/include_samples/, fn -> TradeStudy.summarize(omitted) end
    assert report["baseline"]["status"] == "error"
    assert hd(report["cases"])["error"] =~ "include_samples"
  end

  test "validates complete grids before evaluator calls, including overlapping and missing paths" do
    never = fn _ -> flunk("invalid grids must not evaluate") end
    good = axis("one", ["array", 0, "key"], [2])
    assert_raise ArgumentError, fn -> run([%{good | "id" => "bad id"}], never) end

    for axes <- [
          [good, good],
          [axis("x", ["missing"], [1])],
          [axis("x", ["array", 1, "key"], [1])],
          [axis("x", ["array"], [[]]), axis("y", ["array", 0, "key"], [2])],
          [axis("x", ["array", 0, "key"], Enum.to_list(1..21))]
        ] do
      assert_raise ArgumentError, fn -> run(axes, never) end
    end
  end

  test "correlated updates change existing list/map paths together" do
    a = %{
      "id" => "coupled",
      "cases" => [
        %{
          "id" => "both",
          "updates" => [
            %{"path" => ["array", 0, "key"], "value" => 7},
            %{"path" => ["budget"], "value" => 9}
          ]
        }
      ]
    }

    evaluator = fn config ->
      send(self(), {:seen, config})
      evaluate(config)
    end

    run([a], evaluator)
    assert_receive {:seen, baseline}
    assert baseline == base()
    assert_receive {:seen, %{"budget" => 9, "array" => [%{"key" => 7}]}}
  end
end
