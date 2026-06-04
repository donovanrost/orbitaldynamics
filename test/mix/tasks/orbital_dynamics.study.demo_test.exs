defmodule Mix.Tasks.OrbitalDynamics.Study.DemoTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureIO

  test "runs demo with fixed run metadata" do
    output_path =
      Path.join(
        System.tmp_dir!(),
        "orbital_dynamics_demo_task_result_#{System.unique_integer([:positive])}.json"
      )

    on_exit(fn ->
      File.rm(output_path)
      Mix.Task.reenable("orbital_dynamics.study.demo")
    end)

    output =
      capture_io(fn ->
        Mix.Task.run("orbital_dynamics.study.demo", [
          "--output",
          output_path,
          "--run-id",
          "leo_access_demo-fixed-run",
          "--generated-at",
          "2026-05-14T00:00:00Z"
        ])
      end)

    assert output =~ "OrbitalDynamics LEO access and eclipse demo"
    assert output =~ "study: leo_access_demo"
    assert output =~ "wrote: #{output_path}"

    artifact = output_path |> File.read!() |> :json.decode()

    assert artifact["generated_at"] == "2026-05-14T00:00:00Z"
    assert artifact["run"]["id"] == "leo_access_demo-fixed-run"
    assert artifact["execution_report"]["run_id"] == "leo_access_demo-fixed-run"

    assert artifact["assumptions"]["backend_selection_policy"]["backend_acceptance_policy"] ==
             "backend_acceptance_policy.v1"

    assert artifact["execution_report"]["assumptions"]["backend_selection_policy"][
             "backend_acceptance_policy"
           ] == "backend_acceptance_policy.v1"

    assert get_in(artifact, [
             "assumptions",
             "backend_selection_policy",
             "backend_acceptance_evidence",
             "tier"
           ]) == "reference_default"

    assert get_in(artifact, [
             "execution_report",
             "assumptions",
             "backend_selection_policy",
             "backend_acceptance_evidence",
             "tier"
           ]) == "reference_default"
  end

  test "rejects invalid generated timestamps" do
    on_exit(fn -> Mix.Task.reenable("orbital_dynamics.study.demo") end)

    assert_raise Mix.Error, ~r/invalid --generated-at/, fn ->
      Mix.Task.run("orbital_dynamics.study.demo", [
        "--generated-at",
        "not-a-date"
      ])
    end
  end
end
