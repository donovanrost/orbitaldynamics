defmodule OrbitalDynamics.Validation.OrekitJ2DragEnvelopeTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.Validation.ExternalTruth
  alias OrbitalDynamics.Validation.ExternalTruth.OrekitJ2DragEnvelope

  @case_id "external_truth.orekit_13_1_7.earth_j2_drag_bounded_envelope_v1"

  setup_all do
    assert {:ok, observations} = OrekitJ2DragEnvelope.observations()
    %{observations: observations}
  end

  test "registers the independently generated bounded envelope" do
    assert {:ok, registration} = ExternalTruth.fetch(@case_id)
    assert registration == OrekitJ2DragEnvelope.registration()
    assert registration["validation_level"] == "validated"

    assert registration["tolerances"] == %{
             "position_max_component_error_m" => 0.01,
             "velocity_max_component_error_m_s" => 1.0e-5
           }

    assert String.contains?(registration["covered_regime"], "eight")
    assert String.contains?(registration["covered_regime"], "250..800 km")
    assert String.contains?(registration["covered_regime"], "1..24 hours")
    assert String.contains?(registration["covered_regime"], "5..30 second steps")

    assert Enum.any?(
             registration["known_limits"],
             &String.contains?(&1, "broader public numeric guard envelope")
           )

    assert {:ok, report} = ExternalTruth.verify(@case_id)
    assert report["status"] == "pass"
    assert report["validation_level"] == "validated"
  end

  test "verifies every sampled state and the exact production path", %{
    observations: observations
  } do
    assert {:ok, report} = OrekitJ2DragEnvelope.compare_observations(observations)
    assert report["status"] == "pass"
    assert report["status_counts"] == %{"pass" => length(report["checks"])}
    assert {:ok, _schema_report} = OrbitalDynamics.Schema.validate_artifact(report)

    assert count_checks(report, ".state.", ".epoch_s") == 200
    assert count_checks(report, ".state.", ".position_m") == 200
    assert count_checks(report, ".state.", ".velocity_m_s") == 200

    assert max_residual(report, ".position_m") < 1.0e-4
    assert max_residual(report, ".velocity_m_s") < 1.0e-7

    assert Enum.map(observations.cases, & &1.force_branch) == [
             "point_mass_j2_drag",
             "point_mass_j2_drag",
             "point_mass_j2_drag",
             "point_mass_j2_drag",
             "point_mass_j2_drag",
             "point_mass_j2_drag",
             "point_mass_j2_zero_density_drag",
             "point_mass_zero_j2_drag"
           ]

    assert Enum.all?(observations.cases, &(length(&1.states) == 25))
  end

  test "counterfactual combined-force state errors breach the oracle", %{
    observations: observations
  } do
    mutated =
      observations
      |> update_in(
        [:cases, Access.at(2), :states, Access.at(12), :position_m, Access.at(0)],
        &(&1 + 0.02)
      )
      |> update_in(
        [:cases, Access.at(2), :states, Access.at(12), :velocity_m_s, Access.at(1)],
        &(&1 + 0.00002)
      )

    assert {:error, report} = OrekitJ2DragEnvelope.compare_observations(mutated)

    assert failed_check(
             report,
             "case.combined_nominal_400km_i51_6deg_6h_step10s.state.10800.position_m"
           )

    assert failed_check(
             report,
             "case.combined_nominal_400km_i51_6deg_6h_step10s.state.10800.velocity_m_s"
           )
  end

  test "counterfactual controlled-branch state errors breach the oracle", %{
    observations: observations
  } do
    mutated =
      observations
      |> update_in(
        [:cases, Access.at(6), :states, Access.at(24), :position_m, Access.at(2)],
        &(&1 - 0.02)
      )
      |> update_in(
        [:cases, Access.at(6), :states, Access.at(24), :velocity_m_s, Access.at(1)],
        &(&1 + 0.00002)
      )
      |> update_in(
        [:cases, Access.at(7), :states, Access.at(24), :position_m, Access.at(1)],
        &(&1 + 0.02)
      )
      |> update_in(
        [:cases, Access.at(7), :states, Access.at(24), :velocity_m_s, Access.at(0)],
        &(&1 - 0.00002)
      )

    assert {:error, report} = OrekitJ2DragEnvelope.compare_observations(mutated)

    assert failed_check(
             report,
             "case.j2_only_zero_density_500km_i45deg_6h_step10s.state.21600.position_m"
           )

    assert failed_check(
             report,
             "case.j2_only_zero_density_500km_i45deg_6h_step10s.state.21600.velocity_m_s"
           )

    assert failed_check(
             report,
             "case.drag_only_zero_j2_300km_polar_6h_step10s.state.21600.position_m"
           )

    assert failed_check(
             report,
             "case.drag_only_zero_j2_300km_polar_6h_step10s.state.21600.velocity_m_s"
           )
  end

  test "content identity rejects a modified Orekit state before comparison" do
    bundle = copy_bundle("modified-reference")
    reference_path = Path.join(bundle, "reference-output.json")

    File.write!(
      reference_path,
      reference_path
      |> File.read!()
      |> String.replace("5.42945139997107400e+06", "5.42945139997109400e+06", global: false)
    )

    assert {:error, report} = OrekitJ2DragEnvelope.verify(bundle_path: bundle)
    assert report["status"] == "fail"
    assert inspect(report) =~ "bundle_integrity_failed"
  end

  defp count_checks(report, contains, suffix) do
    Enum.count(
      report["checks"],
      &(String.contains?(&1["field"], contains) and String.ends_with?(&1["field"], suffix))
    )
  end

  defp max_residual(report, suffix) do
    report["checks"]
    |> Enum.filter(&String.ends_with?(&1["field"], suffix))
    |> Enum.map(& &1["error"])
    |> Enum.max()
  end

  defp failed_check(report, field) do
    Enum.any?(report["checks"], &(&1["field"] == field and &1["status"] == "fail"))
  end

  defp copy_bundle(label) do
    root =
      Path.join(
        System.tmp_dir!(),
        "orekit-j2-drag-envelope-#{label}-#{System.unique_integer([:positive, :monotonic])}"
      )

    destination = Path.join(root, "bundle")
    File.mkdir_p!(root)
    File.cp_r!(OrekitJ2DragEnvelope.bundle_path(), destination)

    on_exit(fn -> File.rm_rf!(root) end)
    destination
  end
end
