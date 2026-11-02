defmodule OrbitalDynamics.MissionAnalysis.BaselineCheckTest do
  use ExUnit.Case, async: true
  alias OrbitalDynamics.MissionAnalysis.{BaselineCheck, ReferenceMission}

  test "pinned independent baseline agrees across orbit and spherical geometry" do
    assert {:ok, report} = BaselineCheck.verify()
    assert report["status"] == "pass"
    assert report["sample_count"] == 301
    assert report["shadow_mismatch_count"] == 0
    assert Enum.all?(report["measurements"], fn {_, m} -> m["passed"] end)
    assert report["measurements"]["position_m"]["max_absolute_error"] < 1

    assert report["baseline_configuration"] ==
             ReferenceMission.load!("studies/reference_illumination.json")

    assert {:ok, ^report} = BaselineCheck.verify()
  end

  test "modified reference numbers and source manifest fail content admission" do
    path = Path.join(System.tmp_dir!(), "mission-baseline-#{System.unique_integer([:positive])}")
    File.cp_r!(BaselineCheck.bundle_path(), path)
    on_exit(fn -> File.rm_rf!(path) end)
    output = Path.join(path, "reference-output.csv")
    original = File.read!(output)
    File.write!(output, original <> "\n")
    assert {:error, {:baseline_check_failed, message}} = BaselineCheck.verify(path)
    assert message =~ "content mismatch"
    File.write!(output, original)
    File.write!(Path.join(path, "SHA256SUMS"), "changed")
    assert {:error, {:baseline_check_failed, message}} = BaselineCheck.verify(path)
    assert message =~ "manifest identity mismatch"
  end
end
