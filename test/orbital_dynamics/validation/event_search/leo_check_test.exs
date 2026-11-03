defmodule OrbitalDynamics.Validation.EventSearch.LeoCheckTest do
  use ExUnit.Case, async: true
  @moduletag :integration
  @moduletag timeout: 180_000
  alias OrbitalDynamics.Validation.EventSearch.LeoCheck

  test "production search matches frozen independent events with separately checked propagation and interpolation" do
    assert {:ok, report} = LeoCheck.verify()
    assert report["status"] == "pass"
    assert report["reference_state_count"] == 2161
    assert length(report["interpolation_and_root_precision"]) == 2
    assert length(report["propagation_and_output_sensitivity"]) == 4

    for row <-
          report["interpolation_and_root_precision"] ++
            report["propagation_and_output_sensitivity"] do
      assert row["access"]["reference_count"] == 4
      assert row["eclipse"]["reference_count"] == 8
      assert row["access"]["max_absolute_error_s"] < 0.001
      assert row["eclipse"]["max_absolute_error_s"] < 0.001
      assert row["status"] == "pass"
    end

    for row <- report["propagation_and_output_sensitivity"] do
      assert row["state_residuals"]["status"] == "pass"
      assert row["runtime_parameters"]["status"] == "pass"
      assert row["sampling_controls"]["status"] == "pass"
      expected_count = if row["output_step_s"] == 5, do: 4321, else: 2161
      assert row["sampling_controls"]["observed_state_count"] == expected_count
      assert row["state_residuals"]["matched_epoch_count"] == 2161
      expected_step = if row["integration_step_s"] == 10, do: 10, else: 2.5
      assert row["reference_integrator_step_s"] == expected_step
    end
  end
end
