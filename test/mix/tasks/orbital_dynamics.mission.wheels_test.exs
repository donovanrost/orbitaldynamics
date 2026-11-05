defmodule Mix.Tasks.OrbitalDynamics.Mission.WheelsTest do
  use ExUnit.Case, async: false
  alias Mix.Tasks.OrbitalDynamics.Mission.Wheels

  test "writes passing evidence including the intentionally rejected saturation case and refuses overwrite" do
    dir = Path.join(System.tmp_dir!(), "wheels-#{System.unique_integer([:positive])}")
    on_exit(fn -> File.rm_rf!(dir) end)
    Wheels.run(["--output-dir", dir])
    result = dir |> Path.join("comparison.json") |> File.read!() |> :json.decode()
    assert result["status"] == "passed"
    assert Enum.find(result["cases"], &(&1["id"] == "saturated"))["planning_status"] == "violated"
    assert File.exists?(Path.join(dir, "unloaded.json"))
    assert_raise Mix.Error, fn -> Wheels.run(["--output-dir", dir]) end
  end

  test "requires one output directory" do
    for args <- [[], ["--output-dir", "x", "--output-dir", "y"], ["--unknown"]] do
      assert_raise Mix.Error, fn -> Wheels.run(args) end
    end
  end
end
