defmodule OrbitalDynamics.Validation.EventSearch.ReferenceCheckTest do
  use ExUnit.Case, async: true
  alias OrbitalDynamics.Validation.EventSearch.{Comparison, FiniteSunCheck, ReferenceBundle}
  alias OrbitalDynamics.Validation.ExternalTruth.OrekitLeoCase

  setup_all do
    assert {:ok, report} = FiniteSunCheck.verify()
    %{report: report}
  end

  test "independent cases cover total and annular contacts, fractions and the actual solar consumer",
       %{report: report} do
    assert report["status"] == "pass"
    assert report["tool"] == "Orekit 13.1.7 / Hipparchus 4.0.3"
    assert Enum.map(report["cases"], & &1["id"]) == ["total", "annular"]
    assert Enum.sum(Enum.map(report["cases"], & &1["sample_count"])) == 672

    for c <- report["cases"] do
      assert c["expected_case_coverage_passed"]
      assert c["max_fraction_error"] <= 1.0e-8
      assert c["max_power_error_w"] <= 1.0e-5
      assert c["max_angle_error_rad"] <= 1.0e-10
      assert c["ambiguous_contact_label_count"] == 4

      for key <- ["catalog_contacts", "solar_consumer_contacts"] do
        assert Enum.sum(Enum.map(c[key], & &1["reference_count"])) == 4
        assert Enum.all?(c[key], &(&1["status"] == "pass"))
      end

      assert Enum.any?(
               c["samples"],
               &(&1["reference_regime"] == "penumbra" and not &1["contact_label_ambiguous"])
             )
    end
  end

  test "mismatches cannot pass through truncated, nearest or empty comparisons" do
    reference = [%{"type" => "aos", "epoch_s" => 10}, %{"type" => "los", "epoch_s" => 20}]

    observation = fn type, t ->
      %{
        "type" => type,
        "epoch_s" => t,
        "bracket_start_s" => t - 1.0e-7,
        "bracket_end_s" => t + 1.0e-7
      }
    end

    good = [observation.("aos", 10), observation.("los", 20)]
    assert Comparison.compare(reference, good, 0.001, 1.0e-6)["status"] == "pass"

    for bad <- [[], tl(good), good ++ [observation.("aos", 30)], Enum.reverse(good)] do
      r = Comparison.compare(reference, bad, 0.001, 1.0e-6)
      assert r["status"] == "fail"
      refute r["identity_passed"]
    end

    assert Comparison.compare(
             reference,
             [observation.("aos", 10.002), hd(tl(good))],
             0.001,
             1.0e-6
           )["status"] == "fail"

    wide = put_in(good, [Access.at(0), "bracket_end_s"], 11)
    assert Comparison.compare(reference, wide, 0.001, 1.0e-6)["status"] == "fail"
    missing = [Map.delete(hd(good), "bracket_start_s"), List.last(good)]
    assert Comparison.compare(reference, missing, 0.001, 1.0e-6)["status"] == "fail"
  end

  test "the frozen bundle rejects changed data and a rewritten manifest" do
    dir = Path.join(System.tmp_dir!(), "event-reference-#{System.unique_integer([:positive])}")
    File.cp_r!(ReferenceBundle.bundle_path(), dir)
    on_exit(fn -> File.rm_rf!(dir) end)
    path = Path.join(dir, "reference-output.json")
    File.write!(path, File.read!(path) <> " ")
    assert {:error, {:finite_sun_reference_failed, message}} = FiniteSunCheck.verify(dir)
    assert message =~ "content mismatch"
    manifest = Path.join(dir, "SHA256SUMS")

    File.write!(
      manifest,
      String.replace(File.read!(manifest), "reference-output.json", "replacement.json")
    )

    assert {:error, {:finite_sun_reference_failed, message}} = FiniteSunCheck.verify(dir)
    assert message =~ "manifest digest mismatch"
  end

  test "existing external data is admitted without executing or reusing historical detector results" do
    assert {:ok, bundle} = OrekitLeoCase.reference_bundle()
    assert length(bundle.reference["states"]) == 2161
    assert length(bundle.reference["events"]["access"]) == 4
    assert length(bundle.reference["events"]["eclipse"]) == 8

    assert bundle.identity["result_sha256"] ==
             "88f0ab20bd24a78bda74cfa8091f9e0546e85eee0e2c4719bde988ad2c66649f"

    assert bundle.config["integrator_step_s"] == "10.0"
  end

  test "requested output and integration controls cannot silently label a different trajectory" do
    alias OrbitalDynamics.{Epoch, Frame, StateVector, Trajectory}
    alias OrbitalDynamics.Validation.EventSearch.LeoCheck

    states =
      for t <- 0..2160,
          do:
            StateVector.new!(
              {7000, 0, 0},
              {0, 7.5, 0},
              Epoch.new!(t * 10, :tdb),
              Frame.earth_inertial_j2000()
            )

    trajectory = %Trajectory{scenario_id: "grid", states: states, assumptions: %{max_step_s: 2.5}}
    assert LeoCheck.sampling_controls(trajectory, 2.5, 10)["status"] == "pass"
    assert LeoCheck.sampling_controls(trajectory, 2.5, 5)["status"] == "fail"
    assert LeoCheck.sampling_controls(trajectory, 5, 10)["status"] == "fail"
  end
end
