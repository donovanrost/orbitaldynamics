defmodule Mix.Tasks.OrbitalDynamics.Campaign.RunTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureIO

  alias OrbitalDynamics.Schema

  test "runs a checked-in V2 repair request and writes a schema-valid artifact" do
    output_path =
      Path.join(
        System.tmp_dir!(),
        "orbital_dynamics_campaign_repair_task_#{System.unique_integer([:positive])}.json"
      )

    on_exit(fn ->
      File.rm(output_path)
      Mix.Task.reenable("orbital_dynamics.campaign.run")
    end)

    output =
      capture_io(fn ->
        Mix.Task.run("orbital_dynamics.campaign.run", [
          "--type",
          "repair",
          "--request",
          "studies/leo_constellation_campaign_repair_v2.json",
          "--output",
          output_path
        ])
      end)

    assert output =~ "OrbitalDynamics campaign run"
    assert output =~ "type: repair"
    assert output =~ "contract: campaign_repair.v2"
    assert output =~ "status: pass"

    artifact = output_path |> File.read!() |> :json.decode()

    assert artifact["schema_version"] == 2

    assert artifact["source_plan_id"] ==
             "campaign_plan:leo_constellation_campaign:2026-05-14T00:00:00Z"

    assert {:ok, %{"schema_contract" => "campaign_repair.v2", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "runs a checked-in V3 strategy request and writes a schema-valid artifact" do
    output_path =
      Path.join(
        System.tmp_dir!(),
        "orbital_dynamics_campaign_strategy_task_#{System.unique_integer([:positive])}.json"
      )

    on_exit(fn ->
      File.rm(output_path)
      Mix.Task.reenable("orbital_dynamics.campaign.run")
    end)

    output =
      capture_io(fn ->
        Mix.Task.run("orbital_dynamics.campaign.run", [
          "--type",
          "strategy",
          "--request",
          "studies/leo_constellation_campaign_strategy_v3.json",
          "--output",
          output_path
        ])
      end)

    assert output =~ "OrbitalDynamics campaign run"
    assert output =~ "type: strategy"
    assert output =~ "contract: campaign_strategy.v3"
    assert output =~ "status: pass"

    artifact = output_path |> File.read!() |> :json.decode()

    assert artifact["schema_version"] == 3
    assert Enum.any?(artifact["branches"], &(&1["branch_id"] == "operator_station_outage"))

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "prints a machine-readable JSON summary" do
    output_path =
      Path.join(
        System.tmp_dir!(),
        "orbital_dynamics_campaign_repair_task_json_#{System.unique_integer([:positive])}.json"
      )

    on_exit(fn ->
      File.rm(output_path)
      Mix.Task.reenable("orbital_dynamics.campaign.run")
    end)

    output =
      capture_io(fn ->
        Mix.Task.run("orbital_dynamics.campaign.run", [
          "--type",
          "repair",
          "--request",
          "studies/leo_constellation_campaign_repair_v2.json",
          "--output",
          output_path,
          "--format",
          "json"
        ])
      end)

    assert %{
             "type" => "repair",
             "request" => "studies/leo_constellation_campaign_repair_v2.json",
             "output" => ^output_path,
             "artifact_id" => "campaign_plan:leo_constellation_campaign:2026-05-14T00:00:00Z",
             "schema_contract" => "campaign_repair.v2",
             "status" => "pass",
             "warning_count" => 0
           } = output |> String.trim() |> :json.decode()

    assert File.exists?(output_path)
  end

  test "rejects unsupported campaign run types" do
    on_exit(fn -> Mix.Task.reenable("orbital_dynamics.campaign.run") end)

    assert_raise Mix.Error, ~r/--type must be repair or strategy/, fn ->
      Mix.Task.run("orbital_dynamics.campaign.run", [
        "--type",
        "plan",
        "--request",
        "unused.json",
        "--output",
        "unused.json"
      ])
    end
  end

  test "preflights campaign requests before writing artifacts" do
    request_path =
      Path.join(
        System.tmp_dir!(),
        "orbital_dynamics_campaign_run_bad_request_#{System.unique_integer([:positive])}.json"
      )

    output_path =
      Path.join(
        System.tmp_dir!(),
        "orbital_dynamics_campaign_run_bad_output_#{System.unique_integer([:positive])}.json"
      )

    on_exit(fn ->
      File.rm(request_path)
      File.rm(output_path)
      Mix.Task.reenable("orbital_dynamics.campaign.run")
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
          Mix.Task.run("orbital_dynamics.campaign.run", [
            "--type",
            "repair",
            "--request",
            request_path,
            "--output",
            output_path
          ])
        end
      end)

    assert output =~ "OrbitalDynamics campaign request lint"
    assert output =~ "status: fail"
    assert output =~ "source_plan_ref.path does not exist"
    refute File.exists?(output_path)
  end

  test "rejects unsupported campaign run output formats" do
    on_exit(fn -> Mix.Task.reenable("orbital_dynamics.campaign.run") end)

    assert_raise Mix.Error, ~r/--format must be text or json/, fn ->
      Mix.Task.run("orbital_dynamics.campaign.run", [
        "--type",
        "repair",
        "--request",
        "unused.json",
        "--output",
        "unused.json",
        "--format",
        "yaml"
      ])
    end
  end
end
