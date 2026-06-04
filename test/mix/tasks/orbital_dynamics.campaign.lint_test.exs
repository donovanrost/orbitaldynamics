defmodule Mix.Tasks.OrbitalDynamics.Campaign.LintTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureIO

  test "prints a passing repair request lint report without running repair" do
    on_exit(fn -> Mix.Task.reenable("orbital_dynamics.campaign.lint") end)

    output =
      capture_io(fn ->
        Mix.Task.run("orbital_dynamics.campaign.lint", [
          "--type",
          "repair",
          "--request",
          "studies/leo_constellation_campaign_repair_v2.json"
        ])
      end)

    assert output =~ "OrbitalDynamics campaign request lint"
    assert output =~ "type: repair"
    assert output =~ "status: pass"
    assert output =~ "source contract: campaign_plan.v1"
    refute output =~ "OrbitalDynamics campaign run"
  end

  test "prints a passing JSON strategy request lint report" do
    on_exit(fn -> Mix.Task.reenable("orbital_dynamics.campaign.lint") end)

    output =
      capture_io(fn ->
        Mix.Task.run("orbital_dynamics.campaign.lint", [
          "--type",
          "strategy",
          "--request",
          "studies/leo_constellation_campaign_strategy_v3.json",
          "--format",
          "json"
        ])
      end)

    assert %{
             "schema_contract" => "campaign_request_lint.v1",
             "validation_mode" => "campaign_request_lint",
             "semantic_validator" =>
               "OrbitalDynamics.CampaignPlanner.request_validation_report/3",
             "type" => "strategy",
             "request" => %{
               "path" => "studies/leo_constellation_campaign_strategy_v3.json",
               "sha256" => sha256
             },
             "source_plan" => %{
               "status" => "pass",
               "source" => "source_plan_ref",
               "schema_contract" => "campaign_plan.v1",
               "plan_id" => "campaign_plan:leo_constellation_campaign:2026-05-14T00:00:00Z"
             },
             "status" => "pass",
             "error_count" => 0,
             "errors" => []
           } = output |> String.trim() |> :json.decode()

    assert is_binary(sha256)
    assert byte_size(sha256) == 64
  end

  test "writes a passing campaign request lint artifact" do
    output_path =
      Path.join(
        System.tmp_dir!(),
        "orbital_dynamics_campaign_request_lint_#{System.unique_integer([:positive])}.json"
      )

    on_exit(fn ->
      File.rm(output_path)
      Mix.Task.reenable("orbital_dynamics.campaign.lint")
    end)

    capture_io(fn ->
      Mix.Task.run("orbital_dynamics.campaign.lint", [
        "--type",
        "repair",
        "--request",
        "studies/leo_constellation_campaign_repair_v2.json",
        "--output",
        output_path
      ])
    end)

    assert %{
             "schema_contract" => "campaign_request_lint.v1",
             "validation_mode" => "campaign_request_lint",
             "type" => "repair",
             "request" => %{
               "path" => "studies/leo_constellation_campaign_repair_v2.json"
             },
             "source_plan" => %{
               "status" => "pass",
               "schema_contract" => "campaign_plan.v1"
             },
             "status" => "pass",
             "error_count" => 0
           } =
             output_path
             |> File.read!()
             |> :json.decode()
  end

  test "checked-in repair request lint artifact matches fresh request evidence" do
    checked_in =
      "study_results/campaign_request_lint_v1.json"
      |> File.read!()
      |> :json.decode()

    fresh =
      OrbitalDynamics.campaign_request_validation_report(
        "repair",
        "studies/leo_constellation_campaign_repair_v2.json"
      )

    assert checked_in["schema_contract"] == "campaign_request_lint.v1"
    assert checked_in["status"] == fresh["status"]
    assert checked_in["error_count"] == fresh["error_count"]
    assert checked_in["type"] == fresh["type"]
    assert checked_in["request"] == fresh["request"]

    assert Map.take(checked_in["source_plan"], [
             "artifact_key",
             "plan_id",
             "requested_path",
             "schema_contract",
             "sha256",
             "source",
             "status"
           ]) ==
             Map.take(fresh["source_plan"], [
               "artifact_key",
               "plan_id",
               "requested_path",
               "schema_contract",
               "sha256",
               "source",
               "status"
             ])
  end

  test "raises for missing source plan references after printing structured errors" do
    request_path =
      Path.join(
        System.tmp_dir!(),
        "orbital_dynamics_campaign_lint_missing_source_#{System.unique_integer([:positive])}.json"
      )

    on_exit(fn ->
      File.rm(request_path)
      Mix.Task.reenable("orbital_dynamics.campaign.lint")
    end)

    File.write!(
      request_path,
      :json.encode(%{
        "request_type" => "campaign_plan_repair",
        "source_plan_ref" => %{"path" => "missing/source_plan.json"}
      })
    )

    output =
      capture_io(fn ->
        assert_raise Mix.Error, ~r/campaign request lint failed/, fn ->
          Mix.Task.run("orbital_dynamics.campaign.lint", [
            "--type",
            "repair",
            "--request",
            request_path
          ])
        end
      end)

    assert output =~ "status: fail"
    assert output =~ "error: source_plan_ref_error $.source_plan_ref"
    assert output =~ "source_plan_ref.path does not exist"
  end

  test "writes failing campaign request lint artifact before raising" do
    request_path =
      Path.join(
        System.tmp_dir!(),
        "orbital_dynamics_campaign_lint_output_fail_#{System.unique_integer([:positive])}.json"
      )

    output_path =
      Path.join(
        System.tmp_dir!(),
        "orbital_dynamics_campaign_lint_fail_report_#{System.unique_integer([:positive])}.json"
      )

    on_exit(fn ->
      File.rm(request_path)
      File.rm(output_path)
      Mix.Task.reenable("orbital_dynamics.campaign.lint")
    end)

    File.write!(
      request_path,
      :json.encode(%{
        "request_type" => "campaign_plan_repair",
        "source_plan_ref" => %{"path" => "missing/source_plan.json"}
      })
    )

    capture_io(fn ->
      assert_raise Mix.Error, ~r/campaign request lint failed/, fn ->
        Mix.Task.run("orbital_dynamics.campaign.lint", [
          "--type",
          "repair",
          "--request",
          request_path,
          "--output",
          output_path
        ])
      end
    end)

    assert %{
             "schema_contract" => "campaign_request_lint.v1",
             "status" => "fail",
             "error_count" => 1,
             "errors" => [
               %{
                 "code" => "source_plan_ref_error",
                 "path" => "$.source_plan_ref"
               }
             ]
           } =
             output_path
             |> File.read!()
             |> :json.decode()
  end

  test "rejects unsupported output formats" do
    on_exit(fn -> Mix.Task.reenable("orbital_dynamics.campaign.lint") end)

    assert_raise Mix.Error, ~r/--format must be text or json/, fn ->
      Mix.Task.run("orbital_dynamics.campaign.lint", [
        "--type",
        "repair",
        "--request",
        "unused.json",
        "--format",
        "yaml"
      ])
    end
  end
end
