defmodule OrbitalDynamics.MissionAnalysis.AttitudePathCheckTest do
  use ExUnit.Case, async: true
  alias OrbitalDynamics.MissionAnalysis.AttitudePathCheck

  test "pinned library geometry, independent timing and quaternion ODE comparisons pass within fixed tolerances" do
    assert {:ok, report} = AttitudePathCheck.verify()
    assert report["status"] == "pass"
    assert report["expected_case_coverage_passed"]
    g = report["groups"]
    assert g["orientations"]["case_count"] == 45
    assert g["motion_construction"]["case_count"] == 18
    assert g["sampled_profile"]["case_count"] == 12
    assert g["beam_geometry"]["case_count"] == 169
    assert g["phase_ode"]["sample_epoch_coverage_passed"]
    assert g["phase_ode"]["sample_count"] > 4000
    assert g["phase_ode"]["boundary_measurements"]["status"] == "pass"

    assert Map.has_key?(
             g["phase_ode"]["boundary_measurements"]["measurements"],
             "motion_terminal_quaternion_norm"
           )

    assert Map.has_key?(
             g["phase_ode"]["boundary_measurements"]["measurements"],
             "motion_terminal_rate_deg_s"
           )

    assert g["motion_construction"]["control_input_mismatch_count"] == 0
    assert g["beam_geometry"]["cases_with_direct_witnesses"] > 0
    assert g["beam_geometry"]["direct_witness_false_clear_count"] == 0
    assert g["beam_geometry"]["modeled_cone_false_clear_count"] == 0

    for name <- ~w(grazing-center-miss partial-eclipse unknown-mode) do
      assert Enum.find(g["beam_geometry"]["cases"], &(&1["id"] == name))["expected_status_agrees"]
    end

    assert g["sampled_profile"]["max_rate_estimate_vs_analytic_deg_s"] > 0
  end

  test "edited external numbers or generator bytes fail before numerical comparisons" do
    dir =
      Path.join(System.tmp_dir!(), "attitude-path-bundle-#{System.unique_integer([:positive])}")

    File.cp_r!(AttitudePathCheck.bundle_path(), dir)
    on_exit(fn -> File.rm_rf!(dir) end)
    path = Path.join(dir, "beam-reference.csv")
    original = File.read!(path)
    File.write!(path, original <> "\n")
    assert {:error, {:attitude_path_check_failed, message}} = AttitudePathCheck.verify(dir)
    assert message =~ "content mismatch"
    File.write!(path, original)
    File.write!(Path.join(dir, "AttitudePathReference.java"), "changed")
    assert {:error, {:attitude_path_check_failed, message}} = AttitudePathCheck.verify(dir)
    assert message =~ "content mismatch"
    File.write!(Path.join(dir, "SHA256SUMS"), "changed")
    assert {:error, {:attitude_path_check_failed, message}} = AttitudePathCheck.verify(dir)
    assert message =~ "manifest identity mismatch"
  end
end
