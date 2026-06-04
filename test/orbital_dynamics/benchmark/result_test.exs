defmodule OrbitalDynamics.Benchmark.ResultTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.Benchmark.Result
  alias OrbitalDynamics.Propagators.TwoBody

  test "derives throughput metadata" do
    assert %Result{
             metadata: %{
               scenarios_per_second: 500.0,
               samples_per_second: 5_000.0
             }
           } =
             Result.new!(%{
               id: :baseline,
               mode: :scalar_direct,
               backend: TwoBody,
               scenario_count: 10,
               sample_count: 100,
               failure_count: 0,
               elapsed_us: 20_000,
               options: [max_step_s: 10.0],
               metadata: %{validation_level: :educational}
             })
  end

  test "rejects invalid metric fields" do
    assert_raise ArgumentError, "elapsed_us must be a non-negative integer", fn ->
      Result.new!(%{
        id: :baseline,
        mode: :scalar_direct,
        backend: TwoBody,
        scenario_count: 10,
        sample_count: 100,
        failure_count: 0,
        elapsed_us: -1
      })
    end
  end
end
