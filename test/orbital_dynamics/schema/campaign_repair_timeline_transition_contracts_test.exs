defmodule OrbitalDynamics.Schema.CampaignRepairTimelineTransitionContractsTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.Schema

  setup do
    %{artifact: read_json!("study_results/campaign_repair_readiness_source_handoff_v2.json")}
  end

  test "validates checked V2 repair timeline-transition reports", %{artifact: artifact} do
    older_artifact = read_json!("study_results/leo_constellation_campaign_repair_v2.json")

    for checked <- [artifact, older_artifact] do
      assert {:ok, %{"schema_contract" => "campaign_repair.v2"}} =
               Schema.validate_artifact(checked)
    end
  end

  test "keeps the timeline-transition report optional", %{artifact: artifact} do
    artifact = Map.delete(artifact, "timeline_transition_application_report")

    assert {:ok, %{"schema_contract" => "campaign_repair.v2"}} =
             Schema.validate_artifact(artifact)
  end

  test "rejects nested transition count, source, and activity drift", %{artifact: artifact} do
    invalid_cases = [
      {"$.timeline_transition_application_report.application_count",
       put_in(artifact, ["timeline_transition_application_report", "application_count"], 3)},
      {"$.timeline_transition_application_report.source",
       put_in(
         artifact,
         ["timeline_transition_application_report", "source"],
         "campaign_plan.timeline_transition_application"
       )},
      {"$.timeline_transition_application_report.replacement_activity_count",
       put_in(
         artifact,
         ["timeline_transition_application_report", "replacement_activity_count"],
         2
       )}
    ]

    for {expected_path, invalid} <- invalid_cases do
      assert {:error, report} = Schema.validate_artifact(invalid)
      assert Enum.any?(report["errors"], &(&1["path"] == expected_path))
    end
  end

  test "rejects repair metadata transition count drift", %{artifact: artifact} do
    invalid_cases = [
      {"$.repair_metadata.transition_selected_activity_count",
       put_in(artifact, ["repair_metadata", "transition_selected_activity_count"], 1)},
      {"$.repair_metadata.transition_application_review_required_count",
       put_in(
         artifact,
         ["repair_metadata", "transition_application_review_required_count"],
         1
       )}
    ]

    for {expected_path, invalid} <- invalid_cases do
      assert {:error, report} = Schema.validate_artifact(invalid)
      assert Enum.any?(report["errors"], &(&1["path"] == expected_path))
    end
  end

  defp read_json!(path) do
    path
    |> File.read!()
    |> :json.decode()
  end
end
