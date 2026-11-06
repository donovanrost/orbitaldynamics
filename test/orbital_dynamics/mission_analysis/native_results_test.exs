defmodule OrbitalDynamics.MissionAnalysis.NativeResultsTest do
  use ExUnit.Case, async: false
  alias OrbitalDynamics.MissionAnalysis.{NativeData, ReportData}
  alias OrbitalDynamics.MissionAnalysis.Path.{CheckResult, Result, Runner, Policy}

  defmodule Metric do
    defstruct [:axis, :frame]
  end

  defmodule Rule do
    def prepare(_, _, config), do: {:ok, config, %{}}

    def evaluate(_, _, _, config) do
      check = %CheckResult{
        id: "guard",
        status: if(config["forged"], do: :optimistic, else: :supported)
      }

      {:ok, %Result{checks: [check], metrics: %Metric{axis: {1, 0, 0}, frame: :body}}}
    end
  end

  test "native results preserve structs, tuples and atoms until explicit report projection" do
    metric = %Metric{axis: {1.0, 0, 0}, frame: :body}

    check = %CheckResult{
      id: "guard",
      status: :unknown,
      margin: :unknown,
      margin_unit: "deg",
      details: %{reason: :unavailable}
    }

    result = Result.new!([check], metric)
    assert result.metrics === metric
    assert result.checks === [check]
    assert Result.validate!(result) === result
    assert Result.outcome(result) == :unknown

    assert ReportData.encode(%{"checks" => result.checks, "metrics" => result.metrics}) == %{
             "checks" => [
               %{
                 "id" => "guard",
                 "status" => "unknown",
                 "margin" => :null,
                 "margin_unit" => "deg",
                 "reason" => "unavailable"
               }
             ],
             "metrics" => %{"axis" => [1.0, 0, 0], "frame" => "body"}
           }
  end

  test "fresh or modified callback data is validated without trusting the struct tag" do
    good = Result.new!([%CheckResult{id: "x", status: :supported}], %{})

    for bad <- [
          %{good | checks: [%CheckResult{id: "x", status: :safe}]},
          %{good | checks: [hd(good.checks), hd(good.checks)]},
          %{good | checks: [%CheckResult{id: "x", status: :supported, margin: 1}]},
          %{
            good
            | checks: [%CheckResult{id: "x", status: :supported, details: %{status: :safe}}]
          },
          %{good | metrics: %OrbitalDynamics.MissionAnalysis.ReportData.Completed{value: :forged}}
        ],
        do: assert_raise(ArgumentError, fn -> Result.validate!(bad) end)
  end

  test "diagnostic payload checks are deferred and cannot be bypassed by internal report objects" do
    good = Result.new!([%CheckResult{id: "x", status: :supported}], %{})

    for metrics <- [
          %{callback: fn -> :ok end},
          %{pid: self()},
          %{text: <<255>>},
          %{text: String.duplicate("x", 4_194_305)},
          %{nested: %ReportData.Completed{value: :forged}},
          %{nested: %ReportData.Pending{value: :forged, label: "forged"}}
        ] do
      value = %{good | metrics: metrics}
      assert Result.validate!(value) === value
      assert_raise ArgumentError, fn -> ReportData.encode(value) end
    end

    check = %CheckResult{id: "x", status: :supported, details: %{diagnostic: self()}}
    assert CheckResult.validate!(check) === check
    assert_raise ArgumentError, fn -> ReportData.encode(check) end
  end

  test "computational admission bounds check lists and validates identifier and unit text" do
    for checks <- [
          [],
          [%CheckResult{id: <<255>>, status: :supported}],
          [%CheckResult{id: "x", status: :supported, margin: 1, margin_unit: <<255>>}],
          [%CheckResult{id: "x", status: :supported} | :bad],
          for(i <- 1..2049, do: %CheckResult{id: "x#{i}", status: :supported})
        ] do
      assert_raise ArgumentError, fn ->
        Result.validate!(%Result{checks: checks, metrics: %{}})
      end
    end
  end

  test "raw report payload validation bounds depth, collection size and text without transforming values" do
    value = %{state: %Metric{axis: {1, 2, 3}, frame: :body}, unknown: nil}
    assert NativeData.validate!(value, "native") === value

    for bad <- [
          %{v: Enum.to_list(1..2049)},
          %{v: [1 | :bad]},
          %{v: <<255>>},
          %{v: String.duplicate("x", 4_194_305)},
          Enum.reduce(1..65, 1, fn _, x -> [x] end)
        ] do
      assert_raise ArgumentError, fn -> NativeData.validate!(bad, "native") end
    end
  end

  test "report boundary rejects ambiguous fields, opaque terms and improper lists" do
    for bad <- [%{:value => 1, "value" => 2}, %{v: self()}, [1 | :tail]],
        do: assert_raise(ArgumentError, fn -> ReportData.encode(bad) end)

    assert Result.new!(
             [%{"id" => "x", "status" => "unknown", "margin" => nil, "margin_unit" => "s"}],
             %{}
           )
           |> ReportData.encode()
           |> get_in(["checks", Access.at(0), "margin"]) == :null
  end

  test "completed evidence partitions are projected once and unwrap only at report output" do
    raw = %{axis: {1, 0, 0}, state: %Metric{frame: :body}}
    closed = ReportData.complete(raw)

    assert closed.value == %{
             "axis" => [1, 0, 0],
             "state" => %{"axis" => :null, "frame" => "body"}
           }

    assert ReportData.encode(%{"asset" => closed}) == %{"asset" => closed.value}
    assert_raise ArgumentError, fn -> NativeData.validate!(%{value: closed}, "callback") end
  end

  test "actual path admission performs no recursive payload or JSON scans; forged results fail" do
    alias OrbitalDynamics.{Epoch, Frame, StateVector, Trajectory}
    alias OrbitalDynamics.MissionAnalysis.{Asset, Attitude.Motion}
    frame = Frame.new!(:toy, :toy, :inertial)
    state = fn t -> StateVector.new!({2000, 0, 0}, {0, 0, 0}, Epoch.new!(t, :tai), frame) end

    asset =
      Asset.new!(
        "a",
        %Trajectory{scenario_id: "toy", states: [state.(0), state.(10)], assumptions: %{}},
        %{},
        %{}
      )

    pose = fn t ->
      %{
        "epoch_s" => t,
        "quaternion_wxyz" => [1, 0, 0, 0],
        "angular_velocity_inertial_deg_s" => [0, 0, 0]
      }
    end

    {:ok, plan} =
      Motion.transition(pose.(0), pose.(10), %{
        max_rate_deg_s: 10,
        max_accel_deg_s2: 10,
        settling_s: 0
      })

    prepare = fn forged ->
      p =
        Policy.new!(
          %{
            "a" => %{
              activity_modes: %{},
              transition_mode: "on",
              modes: %{"on" => %{}},
              rules: [%{id: "guard", module: Rule, configuration: %{"forged" => forged}}]
            }
          },
          sample_steps_s: [5],
          max_evaluations: 10,
          max_samples_per_segment: 10
        )

      %{path: Runner.prepare(p, %{"a" => asset}, [], nil)}
    end

    cache = prepare.(false)

    {result, calls} =
      normalized_calls(fn ->
        Runner.transition(asset, plan, "native", fn _, t -> {:ok, state.(t)} end, cache)
      end)

    assert {:ok, evidence, cache} = result
    assert cache.path.evaluations == 3
    assert calls == 0
    check = hd(hd(hd(evidence["levels"])["samples"])["rules"]) |> Map.fetch!("checks") |> hd()
    assert %CheckResult{status: :supported} = check
    forged = prepare.(true)

    assert_raise ArgumentError, fn ->
      Runner.transition(asset, plan, "native", fn _, t -> {:ok, state.(t)} end, forged)
    end
  end

  defp normalized_calls(fun) do
    alias OrbitalDynamics.Schema.JsonSafety
    Code.ensure_loaded!(JsonSafety)
    mfas = [{JsonSafety, :normalize_input!, 2}, {NativeData, :validate!, 2}]
    Enum.each(mfas, &:erlang.trace_pattern(&1, true, [:local]))
    parent = self()

    {pid, monitor} =
      spawn_monitor(fn ->
        receive do
          :run ->
            send(parent, {:value, self(), fun.()})

            receive do
              :stop -> :ok
            end
        end
      end)

    try do
      :erlang.trace(pid, true, [:call, {:tracer, self()}])
      send(pid, :run)

      value =
        receive do
          {:value, ^pid, v} -> v
          {:DOWN, ^monitor, :process, ^pid, why} -> flunk(inspect(why))
        after
          5000 -> flunk("native worker timed out")
        end

      barrier = :erlang.trace_delivered(pid)

      receive do
        {:trace_delivered, ^pid, ^barrier} -> :ok
      after
        5000 -> flunk("trace timed out")
      end

      {value, count(pid, 0)}
    after
      Enum.each(mfas, &:erlang.trace_pattern(&1, false, [:local]))
      send(pid, :stop)
      Process.demonitor(monitor, [:flush])
      if Process.alive?(pid), do: Process.exit(pid, :kill)
    end
  end

  defp count(pid, n) do
    receive do
      {:trace, ^pid, :call, {_, function, _}} when function in [:normalize_input!, :validate!] ->
        count(pid, n + 1)
    after
      0 -> n
    end
  end
end
