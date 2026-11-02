defmodule OrbitalDynamics.MissionAnalysis.RunnerTest do
  use ExUnit.Case, async: true
  alias OrbitalDynamics.{Epoch, Frame, StateVector, Trajectory}
  alias OrbitalDynamics.MissionAnalysis
  alias OrbitalDynamics.MissionAnalysis.{Asset, Evaluation, Request}

  defmodule ToyModel do
    @behaviour OrbitalDynamics.MissionAnalysis.Model
    def capabilities, do: %{"id" => "toy"}
    def prepare(%{subject: :bad_prepare}, _, _), do: {:ok, :missing_assumptions}
    def prepare(request, config, context), do: {:ok, {request.subject, config}, context}
    def evaluate(_state, _, {:broken, _}), do: {:error, :unavailable_environment}
    def evaluate(_, _, {:forged, _}), do: {:ok, %Evaluation{checks: [], metrics: %{}}}

    def evaluate(state, _, {excluded, _}) do
      {:ok,
       Evaluation.new!(
         [%{"id" => "available", "passed" => state.epoch.seconds_since_j2000 not in excluded}],
         %{"count" => 1}
       )}
    end
  end

  defp asset(times, budgets \\ %{"energy_wh" => 10}) do
    frame = Frame.new!(:toy_inertial, :toy, :toy_axes)

    states =
      Enum.map(times, &StateVector.new!({2000, 0, 0}, {0, 1, 0}, Epoch.new!(&1, :tai), frame))

    Asset.new!(
      "a",
      %Trajectory{scenario_id: "toy", states: states, assumptions: %{}},
      %{ToyModel => %{}},
      budgets
    )
  end

  defp request(id, opts \\ []) do
    Request.new!(id, ToyModel, Keyword.get(opts, :subject, []),
      activity_type: "generic_activity",
      starts_at_s: 0,
      ends_at_s: 100,
      duration_s: Keyword.get(opts, :duration, 20),
      time_scale: :tai,
      value: Keyword.get(opts, :value, 1),
      parameters: %{},
      resource_costs: Keyword.get(opts, :costs, %{"energy_wh" => 2})
    )
  end

  defp run(assets, requests, opts \\ []) do
    MissionAnalysis.run(
      assets,
      requests,
      %{"model_assumption" => "opaque context"},
      Keyword.merge([max_sample_gap_s: 10, asset_separation_s: 5], opts)
    )
  end

  test "opaque non-Earth model shares deterministic scheduling, separation and budgets" do
    a = asset(Enum.to_list(0..100//10))
    low = request("low")
    high = request("high", value: 10)
    {:ok, report} = run([a], [low, high])

    assert Enum.map(report["activities"], &{&1["request_id"], &1["starts_at_s"], &1["ends_at_s"]}) ==
             [{"high", 0.0, 20.0}, {"low", 25.0, 45.0}]

    assert report["remaining_resource_budgets"]["a"]["energy_wh"] == 6
    assert report["execution_boundary"] == "analysis_only_no_command_execution"
    assert {:ok, ^report} = run([a], [low, high])
    {:ok, reordered} = run([a], [high, low])
    assert reordered["activities"] == report["activities"]
  end

  test "cannot bridge missing samples or failed samples and cannot extrapolate" do
    {:ok, report} = run([asset([0, 10, 40, 50])], [request("r")])
    assert report["opportunities"] == []
    {:ok, report} = run([asset([0, 10, 20, 30, 40])], [request("r", subject: [20], duration: 10)])

    assert Enum.map(report["opportunities"], &{&1["starts_at_s"], &1["ends_at_s"]}) == [
             {0.0, 10.0},
             {30.0, 40.0}
           ]

    {:ok, report} = run([asset([0, 10])], [request("r", subject: [0], duration: 1)])
    assert report["opportunities"] == []
  end

  test "budget exhaustion and undeclared resources leave explicit decisions" do
    {:ok, report} = run([asset([0, 10, 20, 30, 40], %{"energy_wh" => 1})], [request("r")])
    assert report["activities"] == []
    assert hd(report["selection_decisions"])["reason"] == "insufficient_resource_budget"
    {:ok, report} = run([asset([0, 10, 20], %{})], [request("r")])
    assert hd(report["selection_decisions"])["reason"] == "undeclared_resource_budget"
  end

  test "missing capability is distinct from model failure" do
    assert {:error, {:model_error, "a", "r", :invalid_model_preparation}} =
             run([asset([0, 10, 20])], [request("r", subject: :bad_prepare)])

    a = %{asset([0, 10, 20]) | capabilities: %{}}
    {:ok, report} = run([a], [request("r")])
    assert hd(report["analyses"])["status"] == "capability_unavailable"

    assert {:error, {:model_error, "a", "r", :unavailable_environment}} =
             run([asset([0, 10, 20])], [request("r", subject: :broken)])

    assert {:error, {:invalid_mission_analysis, _}} =
             run([asset([0, 10, 20])], [request("r", subject: :forged)])
  end

  test "rejects unordered states, duplicate identity, mixed frames and scales" do
    a = asset([0, 10, 20])
    r = request("r")
    assert {:error, _} = run([a], [r, r])
    assert {:error, _} = run([a, a], [r])
    assert {:error, _} = run([asset([0, 20, 10])], [r])
    assert {:error, _} = run([asset([0, 0, 10])], [r])
    [s | tail] = a.trajectory.states

    mixed = %{
      a
      | trajectory: %{a.trajectory | states: [%{s | frame: Frame.earth_inertial_j2000()} | tail]}
    }

    assert {:error, _} = run([mixed], [r])
    assert {:error, _} = run([a], [%{r | time_scale: :utc}])
    assert {:error, _} = run([a], [r], max_sample_gap_s: 0)
  end
end
