defmodule OrbitalDynamics.MissionAnalysis.Resource.ThermalTest do
  use ExUnit.Case, async: true
  alias OrbitalDynamics.MissionAnalysis.Resource.Thermal
  alias OrbitalDynamics.MissionAnalysis.Path.Result

  defp config,
    do: %{
      "initial_temperature_k" => 300,
      "heat_capacity_j_k" => 100,
      "sink_temperature_k" => 290,
      "conductance_w_k" => 1,
      "minimum_temperature_k" => 280,
      "maximum_temperature_k" => 320,
      "phase_heat_w" => %{"hold" => 0}
    }

  defp input(q, extra \\ 0),
    do: %{
      phase: "hold",
      mode: %{"parameters" => %{"thermal_heat_w" => q, "thermal_rejection_w_k" => extra}}
    }

  defp session(c), do: elem(Thermal.prepare(nil, nil, c), 1)

  test "adiabatic heating, exponential cooling and heat equilibrium have known answers" do
    c = Map.put(config(), "conductance_w_k", 0)
    s = session(c)
    {:ok, next, r} = Thermal.step(Thermal.initial(s), input(20), 50, s)
    assert_in_delta next["temperature_k"], 310, 1.0e-12
    assert Result.status(r) == "supported"
    s = session(config())
    {:ok, next, _} = Thermal.step(Thermal.initial(s), input(0), 100, s)
    assert_in_delta next["temperature_k"], 290 + 10 / :math.exp(1), 1.0e-12
    {:ok, next, _} = Thermal.step(Thermal.initial(s), input(10), 100, s)
    assert_in_delta next["temperature_k"], 300, 1.0e-12
  end

  test "constant-interval partitioning preserves temperature and energy balance" do
    s = session(config())
    initial = Thermal.initial(s)
    {:ok, whole, r} = Thermal.step(initial, input(20), 80, s)

    split =
      Enum.reduce(1..80, initial, fn _, state ->
        {:ok, next, _} = Thermal.step(state, input(20), 1, s)
        next
      end)

    assert_in_delta whole["temperature_k"], split["temperature_k"], 1.0e-11

    assert_in_delta r.metrics["stored_heat_change_j"] + r.metrics["integrated_rejected_heat_j"],
                    r.metrics["integrated_heat_input_j"],
                    1.0e-10

    weak = session(Map.put(config(), "conductance_w_k", 1.0e-14))
    {:ok, next, _} = Thermal.step(initial, input(10), 1, weak)
    assert_in_delta next["temperature_k"], 300.1, 1.0e-11
  end

  test "hot/cold violations include the initial point, and cooldown increases heat rejection" do
    s = session(config())
    initial = Thermal.initial(s)
    {:ok, _, r} = Thermal.step(initial, input(100), 100, s)
    assert Result.status(r) == "violated"
    {:ok, warm, _} = Thermal.step(initial, input(0), 20, s)
    {:ok, cool, _} = Thermal.step(initial, input(0, 4), 20, s)
    assert cool["temperature_k"] < warm["temperature_k"]
    {:ok, _, r} = Thermal.step(%{"temperature_k" => 279}, input(100), 20, s)
    assert Result.status(r) == "violated"
  end

  test "unknown heat/state stays unknown and invalid parameters fail closed" do
    s = session(config())
    {:ok, _, r} = Thermal.step(Thermal.initial(s), input(:null), 1, s)
    assert Result.status(r) == "unknown"
    {:ok, _, r} = Thermal.step(%{"temperature_k" => :null}, input(0), 1, s)
    assert Result.status(r) == "unknown"
    assert_raise ArgumentError, fn -> session(Map.put(config(), "heat_capacity_j_k", 0)) end
    assert_raise ArgumentError, fn -> session(Map.put(config(), "minimum_temperature_k", 400)) end
  end
end
