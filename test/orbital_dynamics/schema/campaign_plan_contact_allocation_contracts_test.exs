defmodule OrbitalDynamics.Schema.CampaignPlanContactAllocationContractsTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.Schema

  setup do
    artifact =
      "study_results/leo_constellation_campaign.json"
      |> read_json!()
      |> Map.fetch!("campaign_plan")

    %{artifact: artifact}
  end

  test "validates the checked-in V1 contact allocation report", %{artifact: artifact} do
    assert {:ok, %{"schema_contract" => "campaign_plan.v1"}} =
             Schema.validate_artifact(artifact)
  end

  test "keeps the contact allocation report optional", %{artifact: artifact} do
    artifact = Map.delete(artifact, "contact_allocation_report")

    assert {:ok, %{"schema_contract" => "campaign_plan.v1"}} =
             Schema.validate_artifact(artifact)
  end

  test "rejects non-V1 allocation context", %{artifact: artifact} do
    invalid_cases = [
      {"$.contact_allocation_report.model",
       put_in(artifact, ["contact_allocation_report", "model"], "legacy_allocation")},
      {"$.contact_allocation_report.source",
       put_in(artifact, ["contact_allocation_report", "source"], "legacy.candidates")}
    ]

    for {expected_path, invalid} <- invalid_cases do
      assert {:error, report} = Schema.validate_artifact(invalid)
      assert Enum.any?(report["errors"], &(&1["path"] == expected_path))
    end
  end

  test "rejects invalid allocation report fields", %{artifact: artifact} do
    invalid_cases = [
      {"$.contact_allocation_report.input_contact_count",
       put_in(artifact, ["contact_allocation_report", "input_contact_count"], -1)},
      {"$.contact_allocation_report.allocated_contact_count",
       put_in(artifact, ["contact_allocation_report", "allocated_contact_count"], "1")},
      {"$.contact_allocation_report.rows[0].allocation_status",
       put_in(
         artifact,
         ["contact_allocation_report", "rows", Access.at(0), "allocation_status"],
         "legacy"
       )},
      {"$.contact_allocation_report.model_limits",
       put_in(artifact, ["contact_allocation_report", "model_limits"], ["legacy_limit"])}
    ]

    for {expected_path, invalid} <- invalid_cases do
      assert {:error, report} = Schema.validate_artifact(invalid)
      assert Enum.any?(report["errors"], &(&1["path"] == expected_path))
    end
  end

  test "rejects malformed report and row shapes without crashing", %{artifact: artifact} do
    invalid_report = Map.put(artifact, "contact_allocation_report", [])

    invalid_row =
      put_in(artifact, ["contact_allocation_report", "rows"], ["not-a-row"])

    assert {:error, report_shape} = Schema.validate_artifact(invalid_report)
    assert Enum.any?(report_shape["errors"], &(&1["path"] == "$.contact_allocation_report"))

    assert {:error, row_shape} = Schema.validate_artifact(invalid_row)

    assert Enum.any?(
             row_shape["errors"],
             &(&1["path"] == "$.contact_allocation_report.rows[0]")
           )
  end

  defp read_json!(path) do
    path
    |> File.read!()
    |> :json.decode()
  end
end
