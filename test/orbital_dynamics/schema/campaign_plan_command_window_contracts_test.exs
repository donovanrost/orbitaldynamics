defmodule OrbitalDynamics.Schema.CampaignPlanCommandWindowContractsTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.Schema

  setup do
    artifact =
      "study_results/leo_constellation_campaign.json"
      |> read_json!()
      |> Map.fetch!("campaign_plan")

    %{artifact: artifact}
  end

  test "validates the checked-in V1 command-window report", %{artifact: artifact} do
    assert {:ok, %{"schema_contract" => "campaign_plan.v1"}} =
             Schema.validate_artifact(artifact)
  end

  test "keeps the command-window report optional", %{artifact: artifact} do
    artifact = Map.delete(artifact, "command_window_report")

    assert {:ok, %{"schema_contract" => "campaign_plan.v1"}} =
             Schema.validate_artifact(artifact)
  end

  test "rejects non-V1 command-window context", %{artifact: artifact} do
    invalid_cases = [
      {"$.command_window_report.source",
       put_in(artifact, ["command_window_report", "source"], "legacy.activities")},
      {"$.command_window_report.assumptions.source",
       put_in(
         artifact,
         ["command_window_report", "assumptions", "source"],
         "legacy selected activities"
       )},
      {"$.command_window_report.assumptions.boundary",
       put_in(
         artifact,
         ["command_window_report", "assumptions", "boundary"],
         "commands_executed"
       )}
    ]

    for {expected_path, invalid} <- invalid_cases do
      assert {:error, report} = Schema.validate_artifact(invalid)
      assert Enum.any?(report["errors"], &(&1["path"] == expected_path))
    end
  end

  test "runs standalone report and row guarantees", %{artifact: artifact} do
    artifact = Map.put(artifact, "command_window_report", campaign_report_fixture())

    invalid_cases = [
      {"$.command_window_report.window_count",
       update_in(artifact, ["command_window_report", "window_count"], &(&1 + 1))},
      {"$.command_window_report.model_limits",
       put_in(artifact, ["command_window_report", "model_limits"], ["no_command_execution"])},
      {"$.command_window_report.rows[0].window_type",
       put_in(
         artifact,
         ["command_window_report", "rows", Access.at(0), "window_type"],
         "legacy_window"
       )},
      {"$.command_window_report.rows[0].activity_id",
       put_in(
         artifact,
         ["command_window_report", "rows", Access.at(0), "activity_id"],
         "invalid activity"
       )}
    ]

    for {expected_path, invalid} <- invalid_cases do
      assert {:error, report} = Schema.validate_artifact(invalid)
      assert Enum.any?(report["errors"], &(&1["path"] == expected_path))
    end
  end

  test "rejects malformed report and row shapes without crashing", %{artifact: artifact} do
    invalid_report = Map.put(artifact, "command_window_report", [])
    invalid_row = put_in(artifact, ["command_window_report", "rows"], ["not-a-row"])
    invalid_assumptions = put_in(artifact, ["command_window_report", "assumptions"], [])

    assert {:error, report_shape} = Schema.validate_artifact(invalid_report)
    assert Enum.any?(report_shape["errors"], &(&1["path"] == "$.command_window_report"))

    assert {:error, row_shape} = Schema.validate_artifact(invalid_row)

    assert Enum.any?(
             row_shape["errors"],
             &(&1["path"] == "$.command_window_report.rows[0]")
           )

    assert {:error, assumptions_shape} = Schema.validate_artifact(invalid_assumptions)

    assert Enum.any?(
             assumptions_shape["errors"],
             &(&1["path"] == "$.command_window_report.assumptions")
           )
  end

  defp campaign_report_fixture do
    report = read_json!("study_results/command_window_report_v1.json")

    report
    |> Map.put("source", "campaign_plan.activities")
    |> put_in(["assumptions", "source"], "selected campaign_plan.activities")
  end

  defp read_json!(path) do
    path
    |> File.read!()
    |> :json.decode()
  end
end
