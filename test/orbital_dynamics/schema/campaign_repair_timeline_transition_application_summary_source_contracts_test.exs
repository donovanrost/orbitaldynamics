defmodule OrbitalDynamics.Schema.CampaignRepairTimelineTransitionApplicationSummarySourceContractsTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.Schema

  @source_field "source_timeline_transition_application_summary"

  setup do
    artifact = read_json!("study_results/leo_constellation_campaign_repair_v2.json")
    source_summary = read_json!("study_results/timeline_transition_application_summary_v1.json")

    artifact =
      artifact
      |> Map.drop(["operator_review_package", "cadence_import_manifest"])
      |> Map.put(@source_field, source_summary)

    %{artifact: artifact}
  end

  test "validates the optional V2 source transition-application summary", %{artifact: artifact} do
    assert {:ok, %{"schema_contract" => "campaign_repair.v2"}} =
             Schema.validate_artifact(artifact)

    assert {:ok, %{"schema_contract" => "timeline_transition_application_summary.v1"}} =
             artifact
             |> Map.fetch!(@source_field)
             |> Schema.validate_artifact()

    assert {:ok, %{"schema_contract" => "campaign_repair.v2"}} =
             artifact
             |> Map.delete(@source_field)
             |> Schema.validate_artifact()
  end

  test "rejects source transition-application summary drift at the distinct V2 path", %{
    artifact: artifact
  } do
    invalid_count = put_in(artifact, [@source_field, "review_required_count"], 999)

    assert {:error, count_report} = Schema.validate_artifact(invalid_count)

    assert Enum.any?(
             count_report["errors"],
             &(&1["path"] == "$.#{@source_field}.review_required_count")
           )

    invalid_shape = Map.put(artifact, @source_field, [])

    assert {:error, shape_report} = Schema.validate_artifact(invalid_shape)
    assert Enum.any?(shape_report["errors"], &(&1["path"] == "$.#{@source_field}"))

    invalid_applications = put_in(artifact, [@source_field, "review_applications"], %{})

    assert {:error, applications_report} = Schema.validate_artifact(invalid_applications)

    assert Enum.any?(
             applications_report["errors"],
             &(&1["path"] == "$.#{@source_field}.review_applications")
           )

    invalid_application =
      put_in(artifact, [@source_field, "review_applications", Access.at(0)], "invalid")

    assert {:error, application_report} = Schema.validate_artifact(invalid_application)

    assert Enum.any?(
             application_report["errors"],
             &(&1["path"] == "$.#{@source_field}.review_applications[0]")
           )
  end

  test "exports the source transition-application summary property" do
    assert {:ok, schema} = Schema.json_schema("campaign_repair.v2")
    assert get_in(schema, ["properties", @source_field, "type"]) == "object"

    assert get_in(schema, ["$defs", "timeline_transition_application_summary.v1", "type"]) ==
             "object"
  end

  defp read_json!(path) do
    path
    |> File.read!()
    |> :json.decode()
  end
end
