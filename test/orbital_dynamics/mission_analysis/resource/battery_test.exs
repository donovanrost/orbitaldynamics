defmodule OrbitalDynamics.MissionAnalysis.Resource.BatteryTest do
  use ExUnit.Case, async: true
  alias OrbitalDynamics.MissionAnalysis.Resource.Battery
  alias OrbitalDynamics.MissionAnalysis.Path.Result

  defp config do
    %{
      "initial_wh" => 200,
      "capacity_wh" => 300,
      "reserve_wh" => 20,
      "charge_efficiency" => 0.8,
      "discharge_efficiency" => 0.9,
      "phase_load_w" => %{"hold" => 0},
      "generation" => %{"kind" => "constant", "power_w" => 0}
    }
  end

  defp input(load),
    do: %{epoch_s: 0, phase: "hold", mode: %{"parameters" => %{"power_load_w" => load}}}

  test "watt-second conversion and distinct charge/discharge efficiencies are analytic" do
    c = config()
    assert {:ok, c, _} = Battery.prepare(nil, nil, c)
    assert {:ok, drained, result} = Battery.step(Battery.initial(c), input(90), 3600, c)
    assert_in_delta drained["energy_wh"], 100, 1.0e-12
    assert Result.status(result) == "supported"
    charging = put_in(c, ["generation", "power_w"], 200)
    assert {:ok, filled, result} = Battery.step(drained, input(0), 3600, charging)
    assert_in_delta filled["energy_wh"], 260, 1.0e-12
    assert result.metrics["battery_power_w"] == 160
  end

  test "capacity curtailment and unmet demand preserve physical storage bounds" do
    c = put_in(config(), ["generation", "power_w"], 500)
    assert {:ok, filled, _} = Battery.step(Battery.initial(c), input(0), 3600, c)
    assert filled["energy_wh"] == 300
    assert filled["curtailed_wh"] == 375
    c = %{config() | "initial_wh" => 30}
    assert {:ok, empty, result} = Battery.step(Battery.initial(c), input(90), 1800, c)
    assert empty["energy_wh"] == 0
    assert empty["unserved_wh"] == 18
    assert Result.status(result) == "violated"
    assert_in_delta result.metrics["reserve_crossing_offset_s"], 360, 1.0e-12

    assert {:ok, _, result} =
             Battery.step(%{Battery.initial(c) | "energy_wh" => 10}, input(0), 0, c)

    assert Result.status(result) == "violated"
  end

  test "missing inputs are unknown and malformed charging declarations are rejected" do
    for c <- [
          config() |> put_in(["generation", "power_w"], :null),
          config() |> put_in(["phase_load_w"], %{})
        ] do
      assert {:ok, _, result} = Battery.step(Battery.initial(c), input(90), 10, c)
      assert Result.status(result) == "unknown"
    end

    assert_raise ArgumentError, fn ->
      Battery.prepare(nil, nil, %{config() | "charge_efficiency" => 0})
    end

    bad = %{
      config()
      | "generation" => %{
          "kind" => "piecewise_constant",
          "intervals" => [
            %{"starts_at_s" => 0, "ends_at_s" => 10, "power_w" => 5},
            %{"starts_at_s" => 9, "ends_at_s" => 20, "power_w" => 5}
          ]
        }
    }

    assert_raise ArgumentError, fn -> Battery.prepare(nil, nil, bad) end
  end
end
