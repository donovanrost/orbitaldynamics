defmodule OrbitalDynamics.RuntimeTelemetryTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.RuntimeTelemetry

  test "captures runtime deltas for the local node" do
    current_node = node()
    before_snapshot = RuntimeTelemetry.snapshot([current_node])

    Enum.each(1..1_000, fn value ->
      _ = value * value
    end)

    after_snapshot = RuntimeTelemetry.snapshot([current_node])
    diff = RuntimeTelemetry.diff(before_snapshot, after_snapshot)

    assert %{^current_node => telemetry} = diff
    assert telemetry.available == true
    assert is_integer(telemetry.elapsed_ms)
    assert is_integer(telemetry.reductions_delta)
    assert is_integer(telemetry.memory_total_bytes_after)
    assert Map.has_key?(telemetry, :scheduler_utilization)
  end
end
