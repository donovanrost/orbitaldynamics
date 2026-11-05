defmodule Mix.Tasks.OrbitalDynamics.Mission.MaintenanceBenchmarkTest do
  use ExUnit.Case, async: false
  alias Mix.Tasks.OrbitalDynamics.Mission.MaintenanceBenchmark, as: Task

  test "one/two spacecraft are feasible and shared hard caps return no unverified plan" do
    dir = Path.join(System.tmp_dir!(), "maintenance-work-#{System.unique_integer([:positive])}")
    on_exit(fn -> File.rm_rf!(dir) end)
    Task.run(["--output-dir", dir])
    r = dir |> Path.join("benchmark.json") |> File.read!() |> :json.decode()
    assert r["status"] == "passed"
    [one, one_cap, two, two_cap] = r["rows"]
    assert one["service_value"] == 10 and two["service_value"] == 20

    assert two["work_accounting"]["total_evaluations"] >
             one["work_accounting"]["total_evaluations"]

    for row <- [one_cap, two_cap] do
      assert row["planning_status"] == "no_verified_plan"
      assert row["work_accounting"]["total_evaluations"] == 1000
    end

    assert_raise Mix.Error, fn -> Task.run(["--output-dir", dir]) end
    assert_raise Mix.Error, fn -> Task.run([]) end
  end
end
