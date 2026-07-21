defmodule OrbitalDynamics.Benchmark.ScenarioFixtureTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.Benchmark.ScenarioFixture

  test "builds deterministic circular LEO scenarios" do
    scenarios =
      ScenarioFixture.circular_leo(
        count: 4,
        duration_s: 600.0,
        output_step_s: 60.0,
        id_prefix: "fixture"
      )

    assert Enum.map(scenarios, & &1.id) == [
             :fixture_1,
             :fixture_2,
             :fixture_3,
             :fixture_4
           ]

    assert Enum.map(scenarios, & &1.spacecraft.id) == [
             :fixture_sat_1,
             :fixture_sat_2,
             :fixture_sat_3,
             :fixture_sat_4
           ]

    assert Enum.map(scenarios, & &1.duration_s) == [600.0, 600.0, 600.0, 600.0]
    assert Enum.map(scenarios, & &1.output_step_s) == [60.0, 60.0, 60.0, 60.0]

    scenarios
    |> Enum.map(& &1.initial_state.position_km)
    |> Enum.zip([
      {7_000.0, 0.0, 0.0},
      {0.0, 7_000.0, 0.0},
      {-7_000.0, 0.0, 0.0},
      {0.0, -7_000.0, 0.0}
    ])
    |> Enum.each(fn {actual, expected} ->
      assert_close_tuple(actual, expected, 1.0e-9)
    end)
  end

  test "rejects invalid fixture options" do
    assert_raise ArgumentError, "count must be a positive integer", fn ->
      ScenarioFixture.circular_leo(count: 0)
    end

    assert_raise ArgumentError, "id_prefix must be a non-empty string", fn ->
      ScenarioFixture.circular_leo(id_prefix: "")
    end
  end

  test "preserves generated spacecraft ballistic properties" do
    assert [scenario] =
             ScenarioFixture.circular_leo(
               count: 1,
               propellant_mass_kg: 20.0,
               area_m2: 4.0,
               drag_coefficient: 2.2
             )

    assert scenario.spacecraft.dry_mass_kg == 250.0
    assert scenario.spacecraft.propellant_mass_kg == 20.0
    assert scenario.spacecraft.area_m2 == 4.0
    assert scenario.spacecraft.drag_coefficient == 2.2

    assert_raise ArgumentError, "area_m2 must be nil or non-negative", fn ->
      ScenarioFixture.circular_leo(area_m2: -1.0)
    end
  end

  defp assert_close_tuple({ax, ay, az}, {ex, ey, ez}, tolerance) do
    delta = :math.sqrt(:math.pow(ax - ex, 2) + :math.pow(ay - ey, 2) + :math.pow(az - ez, 2))
    assert delta <= tolerance
  end
end
