defmodule OrbitalDynamics.Schema.CampaignRepairCandidateRefreshProvenanceContractsTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.Schema

  @source_field "source_candidate_refresh_provenance"

  setup do
    artifact = read_json!("study_results/leo_constellation_campaign_repair_v2.json")

    provenance = %{
      "run_id" => "run:refresh:1",
      "manifest" => %{"study" => "leo_constellation"},
      "source_reports" => %{
        "freshness_report" => %{
          "paths" => ["study_results/freshness_report_v1.json"],
          "count" => 1
        }
      },
      "run_input_sources" => %{
        "campaign_request" => ["studies/leo_constellation_campaign_strategy_v3.json"]
      }
    }

    %{artifact: Map.put(artifact, @source_field, provenance)}
  end

  test "validates optional source provenance at its exact repair path", %{artifact: artifact} do
    assert {:ok, %{"schema_contract" => "campaign_repair.v2"}} =
             Schema.validate_artifact(artifact)

    assert {:ok, %{"schema_contract" => "campaign_repair.v2"}} =
             artifact
             |> Map.delete(@source_field)
             |> Schema.validate_artifact()

    invalid_count =
      put_in(
        artifact,
        [@source_field, "source_reports", "freshness_report", "count"],
        -1
      )

    assert {:error, count_report} = Schema.validate_artifact(invalid_count)

    assert Enum.any?(
             count_report["errors"],
             &(&1["path"] ==
                 "$.#{@source_field}.source_reports.freshness_report.count")
           )

    invalid_source =
      put_in(
        artifact,
        [@source_field, "run_input_sources", "campaign_request", Access.at(0)],
        42
      )

    assert {:error, source_report} = Schema.validate_artifact(invalid_source)

    assert Enum.any?(
             source_report["errors"],
             &(&1["path"] ==
                 "$.#{@source_field}.run_input_sources.campaign_request[0]")
           )

    invalid_shape = Map.put(artifact, @source_field, [])
    assert {:error, shape_report} = Schema.validate_artifact(invalid_shape)
    assert Enum.any?(shape_report["errors"], &(&1["path"] == "$.#{@source_field}"))
  end

  test "reuses the CandidateRefresh provenance schema" do
    assert {:ok, repair_schema} = Schema.json_schema("campaign_repair.v2")
    assert {:ok, refresh_schema} = Schema.json_schema("candidate_refresh.v1")

    assert repair_schema["properties"][@source_field] ==
             refresh_schema["properties"]["provenance"]

    assert get_in(repair_schema, [
             "properties",
             @source_field,
             "properties",
             "source_reports",
             "additionalProperties",
             "type"
           ]) == "object"

    assert get_in(repair_schema, [
             "properties",
             @source_field,
             "properties",
             "run_input_sources",
             "additionalProperties",
             "items",
             "type"
           ]) == "string"
  end

  defp read_json!(path) do
    path
    |> File.read!()
    |> :json.decode()
  end
end
