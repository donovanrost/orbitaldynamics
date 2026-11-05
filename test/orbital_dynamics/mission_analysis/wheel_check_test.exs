defmodule OrbitalDynamics.MissionAnalysis.WheelCheckTest do
  use ExUnit.Case, async: true
  alias OrbitalDynamics.MissionAnalysis.WheelCheck

  test "independent body-frame ODE matches production momentum and motor demand at both cadences" do
    assert {:ok, r} = WheelCheck.verify()
    assert r["status"] == "passed"
    assert length(r["rows"]) == 16
    assert Enum.all?(r["rows"], & &1["passed"])
    assert Enum.count(r["rows"], &(&1["actual_status"] == "violated")) == 4
    assert Enum.all?(r["rows"], &(&1["reference_zero_torque_conservation_error_nms"] < 1.0e-8))
    changing = Enum.filter(r["rows"], &(&1["case_id"] == "changing_axis_disturbance"))
    [coarse, fine] = changing
    assert fine["momentum_error_nms"] < coarse["momentum_error_nms"] / 8
  end

  test "modified reference bytes or a rewritten inventory are rejected before comparison" do
    dir = Path.join(System.tmp_dir!(), "wheel-reference-#{System.unique_integer([:positive])}")
    on_exit(fn -> File.rm_rf!(dir) end)
    File.cp_r!(WheelCheck.bundle_path(), dir)
    File.write!(Path.join(dir, "reference.json"), "\n", [:append])
    assert {:error, {:wheel_reference_failed, message}} = WheelCheck.verify(dir)
    assert message =~ "content mismatch"
    File.write!(Path.join(dir, "SHA256SUMS"), "changed")
    assert {:error, {:wheel_reference_failed, message}} = WheelCheck.verify(dir)
    assert message =~ "manifest identity"
  end
end
