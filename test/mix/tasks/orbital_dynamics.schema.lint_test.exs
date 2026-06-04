defmodule Mix.Tasks.OrbitalDynamics.Schema.LintTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureIO

  test "prints a passing schema lint report" do
    input_path = Path.join(System.tmp_dir!(), "orbital_dynamics_schema_lint_pass.json")

    on_exit(fn ->
      File.rm(input_path)
      Mix.Task.reenable("orbital_dynamics.schema.lint")
    end)

    File.write!(input_path, :json.encode(campaign_artifact()))

    output =
      capture_io(fn ->
        Mix.Task.run("orbital_dynamics.schema.lint", ["--input", input_path])
      end)

    assert output =~ "OrbitalDynamics schema lint"
    assert output =~ "contract: campaign_plan.v1"
    assert output =~ "status: pass"
    assert output =~ "errors: 0"
  end

  test "prints a passing JSON schema validation report" do
    input_path = Path.join(System.tmp_dir!(), "orbital_dynamics_schema_lint_json_pass.json")

    on_exit(fn ->
      File.rm(input_path)
      Mix.Task.reenable("orbital_dynamics.schema.lint")
    end)

    File.write!(input_path, :json.encode(campaign_artifact()))

    output =
      capture_io(fn ->
        Mix.Task.run("orbital_dynamics.schema.lint", [
          "--input",
          input_path,
          "--format",
          "json"
        ])
      end)

    assert %{
             "schema_contract" => "schema_validation_report.v1",
             "validation_mode" => "artifact_file",
             "validated_contract" => "campaign_plan.v1",
             "status" => "pass",
             "error_count" => 0,
             "warning_count" => 0,
             "errors" => []
           } = output |> String.trim() |> :json.decode()
  end

  test "writes a schema validation report artifact" do
    input_path = Path.join(System.tmp_dir!(), "orbital_dynamics_schema_lint_output_pass.json")
    output_path = Path.join(System.tmp_dir!(), "orbital_dynamics_schema_validation_report.json")

    on_exit(fn ->
      File.rm(input_path)
      File.rm(output_path)
      Mix.Task.reenable("orbital_dynamics.schema.lint")
    end)

    File.write!(input_path, :json.encode(campaign_artifact()))

    capture_io(fn ->
      Mix.Task.run("orbital_dynamics.schema.lint", [
        "--input",
        input_path,
        "--output",
        output_path
      ])
    end)

    assert %{
             "schema_contract" => "schema_validation_report.v1",
             "validation_mode" => "artifact_file",
             "validated_contract" => "campaign_plan.v1",
             "artifact_path" => ^input_path,
             "status" => "pass",
             "error_count" => 0
           } =
             output_path
             |> File.read!()
             |> :json.decode()

    assert {:ok, %{"schema_contract" => "schema_validation_report.v1"}} =
             OrbitalDynamics.Schema.lint_file(output_path,
               schema_contract: "schema_validation_report.v1"
             )
  end

  test "raises for invalid artifacts and prints contract paths" do
    input_path = Path.join(System.tmp_dir!(), "orbital_dynamics_schema_lint_fail.json")

    on_exit(fn ->
      File.rm(input_path)
      Mix.Task.reenable("orbital_dynamics.schema.lint")
    end)

    File.write!(input_path, :json.encode(Map.delete(campaign_artifact(), "plan_id")))

    output =
      capture_io(fn ->
        assert_raise Mix.Error, ~r/schema lint failed/, fn ->
          Mix.Task.run("orbital_dynamics.schema.lint", ["--input", input_path])
        end
      end)

    assert output =~ "status: fail"
    assert output =~ "error $.plan_id: is required"
    assert output =~ "fix $.plan_id: Populate this required field for campaign_plan.v1"
  end

  test "prints a failing JSON schema validation report before raising" do
    input_path = Path.join(System.tmp_dir!(), "orbital_dynamics_schema_lint_json_fail.json")

    on_exit(fn ->
      File.rm(input_path)
      Mix.Task.reenable("orbital_dynamics.schema.lint")
    end)

    File.write!(input_path, :json.encode(Map.delete(campaign_artifact(), "plan_id")))

    output =
      capture_io(fn ->
        assert_raise Mix.Error, ~r/schema lint failed/, fn ->
          Mix.Task.run("orbital_dynamics.schema.lint", [
            "--input",
            input_path,
            "--format",
            "json"
          ])
        end
      end)

    assert %{
             "schema_contract" => "schema_validation_report.v1",
             "validated_contract" => "campaign_plan.v1",
             "status" => "fail",
             "error_count" => 1,
             "errors" => [
               %{
                 "severity" => "error",
                 "path" => "$.plan_id",
                 "message" => "is required"
               }
             ],
             "remediation" => [
               %{
                 "path" => "$.plan_id",
                 "category" => "missing_required_field",
                 "source_message" => "is required"
               }
             ]
           } = output |> String.trim() |> :json.decode()
  end

  test "writes failing schema validation report before raising" do
    input_path = Path.join(System.tmp_dir!(), "orbital_dynamics_schema_lint_output_fail.json")
    output_path = Path.join(System.tmp_dir!(), "orbital_dynamics_schema_validation_fail.json")

    on_exit(fn ->
      File.rm(input_path)
      File.rm(output_path)
      Mix.Task.reenable("orbital_dynamics.schema.lint")
    end)

    File.write!(input_path, :json.encode(Map.delete(campaign_artifact(), "plan_id")))

    capture_io(fn ->
      assert_raise Mix.Error, ~r/schema lint failed/, fn ->
        Mix.Task.run("orbital_dynamics.schema.lint", [
          "--input",
          input_path,
          "--output",
          output_path
        ])
      end
    end)

    assert %{
             "schema_contract" => "schema_validation_report.v1",
             "validated_contract" => "campaign_plan.v1",
             "status" => "fail",
             "error_count" => 1,
             "errors" => [
               %{
                 "path" => "$.plan_id",
                 "message" => "is required"
               }
             ],
             "remediation_count" => 1,
             "remediation" => [
               %{
                 "path" => "$.plan_id",
                 "category" => "missing_required_field"
               }
             ]
           } =
             output_path
             |> File.read!()
             |> :json.decode()
  end

  test "lints all artifact contracts in a directory" do
    input_dir = Path.join(System.tmp_dir!(), "orbital_dynamics_schema_lint_all_pass")
    output_path = Path.join(System.tmp_dir!(), "orbital_dynamics_schema_lint_all_pass.json")

    on_exit(fn ->
      File.rm_rf(input_dir)
      File.rm(output_path)
      Mix.Task.reenable("orbital_dynamics.schema.lint")
    end)

    File.mkdir_p!(input_dir)
    File.write!(Path.join(input_dir, "campaign.json"), :json.encode(campaign_artifact()))

    File.write!(
      Path.join(input_dir, "policy_decision.json"),
      :json.encode(%{
        "schema_contract" => "policy_decision.v1",
        "classification" => "auto_approvable"
      })
    )

    File.write!(Path.join(input_dir, "result_artifact.json"), :json.encode(result_artifact()))

    File.write!(
      Path.join(input_dir, "study_benchmark.json"),
      :json.encode(study_benchmark_artifact())
    )

    File.write!(
      Path.join(input_dir, "manifest_reference.json"),
      :json.encode(manifest_field_reference())
    )

    output =
      capture_io(fn ->
        Mix.Task.run("orbital_dynamics.schema.lint", [
          "--all",
          "--input-dir",
          input_dir,
          "--output",
          output_path
        ])
      end)

    assert output =~ "OrbitalDynamics schema lint"
    assert output =~ "directory: #{input_dir}"
    assert output =~ "files: 5"
    assert output =~ "artifacts: 5"
    assert output =~ "skipped: 0"
    assert output =~ "status: pass"
    assert output =~ "contract=campaign_plan.v1 status=pass"
    assert output =~ "contract=policy_decision.v1 status=pass"
    assert output =~ "contract=result_artifact.v1 status=pass"
    assert output =~ "contract=study_benchmark.v1 status=pass"
    assert output =~ "contract=manifest_field_reference.v1 status=pass"

    assert {:ok, %{"schema_contract" => "schema_validation_batch_report.v1"}} =
             OrbitalDynamics.Schema.lint_file(output_path,
               schema_contract: "schema_validation_batch_report.v1"
             )
  end

  test "lints declared executable schema contracts without a bespoke inferrer" do
    input_dir = Path.join(System.tmp_dir!(), "orbital_dynamics_schema_lint_declared_contract")

    on_exit(fn ->
      File.rm_rf(input_dir)
      Mix.Task.reenable("orbital_dynamics.schema.lint")
    end)

    File.mkdir_p!(input_dir)

    File.write!(
      Path.join(input_dir, "planned_activity.json"),
      :json.encode(planned_activity_artifact())
    )

    output =
      capture_io(fn ->
        Mix.Task.run("orbital_dynamics.schema.lint", [
          "--all",
          "--input-dir",
          input_dir
        ])
      end)

    assert output =~ "files: 1"
    assert output =~ "artifacts: 1"
    assert output =~ "skipped: 0"
    assert output =~ "contract=planned_activity.v1 status=pass"
  end

  test "reports unsupported requested contracts instead of crashing" do
    input_path =
      Path.join(System.tmp_dir!(), "orbital_dynamics_schema_lint_unknown_contract.json")

    on_exit(fn ->
      File.rm(input_path)
      Mix.Task.reenable("orbital_dynamics.schema.lint")
    end)

    File.write!(
      input_path,
      :json.encode(%{"schema_contract" => "unknown_contract.v1"})
    )

    output =
      capture_io(fn ->
        assert_raise Mix.Error, ~r/schema lint failed/, fn ->
          Mix.Task.run("orbital_dynamics.schema.lint", [
            "--input",
            input_path,
            "--contract",
            "unknown_contract.v1"
          ])
        end
      end)

    assert output =~ "contract: unknown_contract.v1"
    assert output =~ "status: fail"
    assert output =~ "error $: unknown schema contract: unknown_contract.v1"
  end

  test "prints a failing all-directory JSON report before raising" do
    input_dir = Path.join(System.tmp_dir!(), "orbital_dynamics_schema_lint_all_fail")

    on_exit(fn ->
      File.rm_rf(input_dir)
      Mix.Task.reenable("orbital_dynamics.schema.lint")
    end)

    File.mkdir_p!(input_dir)
    File.write!(Path.join(input_dir, "campaign.json"), :json.encode(campaign_artifact()))

    File.write!(
      Path.join(input_dir, "invalid_campaign.json"),
      :json.encode(Map.delete(campaign_artifact(), "plan_id"))
    )

    output =
      capture_io(fn ->
        assert_raise Mix.Error, ~r/schema lint failed/, fn ->
          Mix.Task.run("orbital_dynamics.schema.lint", [
            "--all",
            "--input-dir",
            input_dir,
            "--format",
            "json"
          ])
        end
      end)

    assert %{
             "schema_contract" => "schema_validation_batch_report.v1",
             "validation_mode" => "artifact_directory",
             "input_dir" => ^input_dir,
             "file_count" => 2,
             "artifact_count" => 2,
             "skipped_count" => 0,
             "skipped_artifacts" => [],
             "status" => "fail",
             "status_counts" => %{"fail" => 1, "pass" => 1},
             "error_count" => 1,
             "remediation_count" => 1,
             "reports" => reports
           } = report = output |> String.trim() |> :json.decode()

    assert Enum.any?(reports, fn %{"path" => path, "report" => report} ->
             String.ends_with?(path, "invalid_campaign.json") and
               report["validated_contract"] == "campaign_plan.v1" and
               report["status"] == "fail"
           end)

    assert {:ok, %{"schema_contract" => "schema_validation_batch_report.v1"}} =
             OrbitalDynamics.Schema.validate_artifact(report)
  end

  test "rejects unsupported schema lint output formats" do
    on_exit(fn -> Mix.Task.reenable("orbital_dynamics.schema.lint") end)

    assert_raise Mix.Error, ~r/--format must be text or json/, fn ->
      Mix.Task.run("orbital_dynamics.schema.lint", [
        "--input",
        "unused.json",
        "--format",
        "yaml"
      ])
    end
  end

  defp campaign_artifact do
    %{
      "schema_version" => 1,
      "generated_at" => "2026-05-14T00:00:00Z",
      "planner" => "OrbitalDynamics.CampaignPlanner.V1",
      "plan_id" => "campaign_plan:test:2026-05-14T00:00:00Z",
      "study_id" => "test",
      "planning_horizon" => %{},
      "activities" => [],
      "proposed_contacts" => [],
      "contact_intents" => [],
      "candidate_activities" => [],
      "ranked_timelines" => [],
      "warnings" => [],
      "assumptions" => %{},
      "provenance" => %{},
      "ranking_explanation" => %{}
    }
  end

  defp planned_activity_artifact do
    %{
      "schema_contract" => "planned_activity.v1",
      "id" => "observe_target_a",
      "type" => "observe",
      "scenario_id" => "leo_1",
      "target_id" => "target_a",
      "starts_at_s" => 120.0,
      "ends_at_s" => 180.0
    }
  end

  defp result_artifact do
    artifact = %{
      "schema_version" => 1,
      "generated_at" => "2026-05-14T00:00:00Z",
      "study_id" => "result_wrapper",
      "run" => %{},
      "assumptions" => %{},
      "metadata" => %{},
      "trajectories" => [],
      "access_windows" => [],
      "eclipse_intervals" => [],
      "target_visibility_windows" => [],
      "ground_track_crossings" => [],
      "errors" => [],
      "execution_report" => %{
        "schema_contract" => "execution_report.v1",
        "study_id" => "result_wrapper",
        "status" => "completed",
        "execution_mode" => "local_tasks",
        "scenario_count" => 0,
        "completed_scenario_count" => 0,
        "failed_scenario_count" => 0,
        "event_result_count" => 0,
        "failed_scenarios" => [],
        "assumptions" => %{}
      }
    }

    Map.put(artifact, "payload_metrics", %{
      "schema_contract" => "result_payload_metrics.v1",
      "encoding" => "erlang_json_compact_utf8",
      "artifact_body_bytes" => json_bytes(artifact),
      "top_level_key_count" => map_size(artifact),
      "sections" =>
        artifact
        |> Enum.sort_by(fn {key, _value} -> key end)
        |> Map.new(fn {key, value} ->
          {key, %{"bytes" => json_bytes(value), "row_count" => payload_row_count(value)}}
        end)
    })
  end

  defp json_bytes(value) do
    value
    |> :json.encode()
    |> IO.iodata_to_binary()
    |> byte_size()
  end

  defp payload_row_count(value) when is_list(value), do: length(value)
  defp payload_row_count(%{"rows" => rows}) when is_list(rows), do: length(rows)
  defp payload_row_count(_value), do: :null

  defp study_benchmark_artifact do
    %{
      "schema_version" => 1,
      "generated_at" => "2026-05-14T00:00:00Z",
      "manifest" => %{
        "path" => "study_manifests/raise_apogee_search.json",
        "sha256" => "demo"
      },
      "benchmark_options" => %{
        "modes" => ["local_tasks"],
        "repetitions" => 1
      },
      "results" => [
        %{
          "id" => "raise_apogee_search_local_r1",
          "mode" => "local_tasks",
          "duration_ms" => 10.0,
          "execution_mode" => "local_tasks",
          "failure_count" => 0,
          "matches_baseline" => true,
          "repetitions" => 1,
          "scenario_count" => 1,
          "trajectory_count" => 1,
          "per_node_trajectory_counts" => %{"local" => 1},
          "output_signature" => %{"scenario_ids" => ["raise_apogee_search"]}
        }
      ]
    }
  end

  defp manifest_field_reference do
    OrbitalDynamics.Study.Manifest.field_reference()
  end
end
