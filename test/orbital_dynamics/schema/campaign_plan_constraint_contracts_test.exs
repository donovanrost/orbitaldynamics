defmodule OrbitalDynamics.Schema.CampaignPlanConstraintContractsTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.Schema

  setup do
    artifact =
      "study_results/leo_constellation_campaign.json"
      |> read_json!()
      |> Map.fetch!("campaign_plan")

    %{artifact: artifact}
  end

  test "validates the checked-in V1 constraint report", %{artifact: artifact} do
    assert {:ok, %{"schema_contract" => "campaign_plan.v1"}} =
             Schema.validate_artifact(artifact)
  end

  test "keeps the constraint report optional", %{artifact: artifact} do
    artifact = Map.delete(artifact, "constraint_report")

    assert {:ok, %{"schema_contract" => "campaign_plan.v1"}} =
             Schema.validate_artifact(artifact)
  end

  test "rejects non-V1 constraint context", %{artifact: artifact} do
    invalid_cases = [
      {"$.constraint_report.model",
       put_in(
         artifact,
         ["constraint_report", "model"],
         "campaign_repair_local_constraint_summary"
       )},
      {"$.constraint_report.assumptions.constraint_model",
       put_in(
         artifact,
         ["constraint_report", "assumptions", "constraint_model"],
         "campaign_repair_local_constraints"
       )},
      {"$.constraint_report.assumptions.source",
       put_in(
         artifact,
         ["constraint_report", "assumptions", "source"],
         "legacy.constraints"
       )}
    ]

    for {expected_path, invalid} <- invalid_cases do
      assert {:error, report} = Schema.validate_artifact(invalid)
      assert Enum.any?(report["errors"], &(&1["path"] == expected_path))
    end
  end

  test "rejects internally inconsistent constraint reports", %{artifact: artifact} do
    invalid_cases = [
      {"$.row_count", put_in(artifact, ["constraint_report", "row_count"], 99)},
      {"$.status_counts",
       put_in(
         artifact,
         ["constraint_report", "status_counts"],
         %{"pass" => 0, "fail" => 4, "warning" => 0}
       )},
      {"$.rows[0].operator",
       put_in(artifact, ["constraint_report", "rows", Access.at(0), "operator"], "~=")},
      {"$.model_limits",
       put_in(artifact, ["constraint_report", "model_limits"], ["legacy_limit"])}
    ]

    for {expected_path, invalid} <- invalid_cases do
      assert {:error, report} = Schema.validate_artifact(invalid)
      assert Enum.any?(report["errors"], &(&1["path"] == expected_path))
    end
  end

  test "rejects malformed report and row shapes without crashing", %{artifact: artifact} do
    invalid_report = Map.put(artifact, "constraint_report", [])

    invalid_row =
      put_in(artifact, ["constraint_report", "rows"], ["not-a-row"])

    assert {:error, report_shape} = Schema.validate_artifact(invalid_report)
    assert Enum.any?(report_shape["errors"], &(&1["path"] == "$.constraint_report"))

    assert {:error, row_shape} = Schema.validate_artifact(invalid_row)
    assert Enum.any?(row_shape["errors"], &(&1["path"] == "$.rows[0]"))
  end

  defp read_json!(path) do
    path
    |> File.read!()
    |> :json.decode()
  end
end
