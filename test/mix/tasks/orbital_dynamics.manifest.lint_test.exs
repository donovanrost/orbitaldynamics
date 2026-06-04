defmodule Mix.Tasks.OrbitalDynamics.Manifest.LintTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureIO

  test "prints a passing manifest lint report without running the study" do
    manifest_path = Path.join(System.tmp_dir!(), "orbital_dynamics_manifest_lint_pass.json")

    on_exit(fn ->
      File.rm(manifest_path)
      Mix.Task.reenable("orbital_dynamics.manifest.lint")
    end)

    File.write!(manifest_path, json_manifest())

    output =
      capture_io(fn ->
        Mix.Task.run("orbital_dynamics.manifest.lint", ["--manifest", manifest_path])
      end)

    assert output =~ "OrbitalDynamics manifest lint"
    assert output =~ "status: pass"
    assert output =~ "errors: 0"
    assert output =~ "warnings: 0"
    assert output =~ "study: manifest_lint"
    assert output =~ "scenarios: 1"
    assert output =~ "outputs: trajectories,eclipses"
  end

  test "raises for invalid manifests and prints structured error reason" do
    manifest_path = Path.join(System.tmp_dir!(), "orbital_dynamics_manifest_lint_fail.json")

    on_exit(fn ->
      File.rm(manifest_path)
      Mix.Task.reenable("orbital_dynamics.manifest.lint")
    end)

    File.write!(manifest_path, ~s({"schema_version":1,"study_id":"missing_scenarios"}))

    output =
      capture_io(fn ->
        assert_raise Mix.Error, ~r/manifest lint failed/, fn ->
          Mix.Task.run("orbital_dynamics.manifest.lint", ["--manifest", manifest_path])
        end
      end)

    assert output =~ "status: fail"
    assert output =~ "errors: 1"
    assert output =~ "warnings: 0"
    assert output =~ "error: missing_field $.scenarios required field is missing: scenarios"
  end

  test "prints a passing JSON manifest lint report" do
    manifest_path = Path.join(System.tmp_dir!(), "orbital_dynamics_manifest_lint_json_pass.json")

    on_exit(fn ->
      File.rm(manifest_path)
      Mix.Task.reenable("orbital_dynamics.manifest.lint")
    end)

    File.write!(manifest_path, json_manifest())

    output =
      capture_io(fn ->
        Mix.Task.run("orbital_dynamics.manifest.lint", [
          "--manifest",
          manifest_path,
          "--format",
          "json"
        ])
      end)

    assert %{
             "schema_contract" => "study_manifest_lint.v1",
             "manifest_schema_contract" => "study_manifest.v1",
             "semantic_validator" =>
               "OrbitalDynamics.Study.Manifest.from_map/1 + OrbitalDynamics.StudyRunner.validate_run_inputs/2",
             "lint_task" => "mix orbital_dynamics.manifest.lint --manifest PATH",
             "schema_export_command" =>
               "mix orbital_dynamics.manifest.schema.export --output schemas/study_manifest.v1.schema.json",
             "supported" => %{
               "outputs" => supported_outputs,
               "propagators" => supported_propagators
             },
             "status" => "pass",
             "study_id" => "manifest_lint",
             "scenario_count" => 1,
             "outputs" => ["trajectories", "eclipses"],
             "error_count" => 0,
             "warning_count" => 0,
             "errors" => []
           } = output |> String.trim() |> :json.decode()

    assert "target_visibility" in supported_outputs
    assert "j2_exla_cpu" in supported_propagators
  end

  test "writes a passing manifest lint report" do
    manifest_path =
      Path.join(System.tmp_dir!(), "orbital_dynamics_manifest_lint_output_pass.json")

    output_path = Path.join(System.tmp_dir!(), "orbital_dynamics_manifest_lint_report.json")

    on_exit(fn ->
      File.rm(manifest_path)
      File.rm(output_path)
      Mix.Task.reenable("orbital_dynamics.manifest.lint")
    end)

    File.write!(manifest_path, json_manifest())

    capture_io(fn ->
      Mix.Task.run("orbital_dynamics.manifest.lint", [
        "--manifest",
        manifest_path,
        "--output",
        output_path
      ])
    end)

    assert %{
             "schema_contract" => "study_manifest_lint.v1",
             "manifest_schema_contract" => "study_manifest.v1",
             "status" => "pass",
             "study_id" => "manifest_lint",
             "manifest" => %{"path" => ^manifest_path},
             "scenario_count" => 1,
             "error_count" => 0,
             "warning_count" => 0,
             "errors" => []
           } =
             output_path
             |> File.read!()
             |> :json.decode()
  end

  test "prints a failing JSON manifest lint report before raising" do
    manifest_path = Path.join(System.tmp_dir!(), "orbital_dynamics_manifest_lint_json_fail.json")

    on_exit(fn ->
      File.rm(manifest_path)
      Mix.Task.reenable("orbital_dynamics.manifest.lint")
    end)

    File.write!(manifest_path, ~s({"schema_version":1,"study_id":"missing_scenarios"}))

    output =
      capture_io(fn ->
        assert_raise Mix.Error, ~r/manifest lint failed/, fn ->
          Mix.Task.run("orbital_dynamics.manifest.lint", [
            "--manifest",
            manifest_path,
            "--format",
            "json"
          ])
        end
      end)

    assert %{
             "status" => "fail",
             "error_count" => 1,
             "warning_count" => 0,
             "errors" => [
               %{
                 "code" => "missing_field",
                 "path" => "$.scenarios",
                 "message" => "required field is missing: scenarios"
               }
             ]
           } = output |> String.trim() |> :json.decode()
  end

  test "writes failing manifest lint report before raising" do
    manifest_path =
      Path.join(System.tmp_dir!(), "orbital_dynamics_manifest_lint_output_fail.json")

    output_path = Path.join(System.tmp_dir!(), "orbital_dynamics_manifest_lint_fail_report.json")

    on_exit(fn ->
      File.rm(manifest_path)
      File.rm(output_path)
      Mix.Task.reenable("orbital_dynamics.manifest.lint")
    end)

    File.write!(manifest_path, ~s({"schema_version":1,"study_id":"missing_scenarios"}))

    capture_io(fn ->
      assert_raise Mix.Error, ~r/manifest lint failed/, fn ->
        Mix.Task.run("orbital_dynamics.manifest.lint", [
          "--manifest",
          manifest_path,
          "--output",
          output_path
        ])
      end
    end)

    assert %{
             "status" => "fail",
             "manifest" => %{"path" => ^manifest_path},
             "error_count" => 1,
             "warning_count" => 0,
             "errors" => [
               %{
                 "code" => "missing_field",
                 "path" => "$.scenarios",
                 "message" => "required field is missing: scenarios"
               }
             ]
           } =
             output_path
             |> File.read!()
             |> :json.decode()
  end

  test "rejects unsupported output formats" do
    on_exit(fn -> Mix.Task.reenable("orbital_dynamics.manifest.lint") end)

    assert_raise Mix.Error, ~r/--format must be text or json/, fn ->
      Mix.Task.run("orbital_dynamics.manifest.lint", [
        "--manifest",
        "unused.json",
        "--format",
        "xml"
      ])
    end
  end

  defp json_manifest do
    %{
      "schema_version" => 1,
      "study_id" => "manifest_lint",
      "central_body" => "earth",
      "propagator" => "two_body",
      "outputs" => ["trajectories", "eclipses"],
      "sun_direction" => [1.0, 0.0, 0.0],
      "scenarios" => [
        %{
          "generator" => "circular_leo",
          "count" => 1,
          "duration_s" => 120.0,
          "output_step_s" => 60.0,
          "id_prefix" => "manifest_lint"
        }
      ]
    }
    |> :json.encode()
    |> IO.iodata_to_binary()
  end
end
