defmodule OrbitalDynamics.Schema.CampaignRepairProviderCounterofferSourceContractsTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.Schema

  setup do
    artifact = read_json!("study_results/leo_constellation_campaign_repair_v2.json")
    source_report = provider_counteroffer_report()

    %{artifact: Map.put(artifact, "source_provider_counteroffer_report", source_report)}
  end

  test "validates the optional V2 source provider-counteroffer report", %{artifact: artifact} do
    assert {:ok, %{"schema_contract" => "campaign_repair.v2"}} =
             Schema.validate_artifact(artifact)

    assert {:ok, %{"schema_contract" => "provider_counteroffer_report.v1"}} =
             artifact
             |> Map.fetch!("source_provider_counteroffer_report")
             |> Schema.validate_artifact()

    assert {:ok, %{"schema_contract" => "campaign_repair.v2"}} =
             artifact
             |> Map.delete("source_provider_counteroffer_report")
             |> Schema.validate_artifact()
  end

  test "rejects V2 source provider-counteroffer drift at the source path", %{
    artifact: artifact
  } do
    invalid_model =
      put_in(
        artifact,
        ["source_provider_counteroffer_report", "model"],
        "legacy_provider_counteroffer_model"
      )

    assert {:error, model_report} = Schema.validate_artifact(invalid_model)

    assert Enum.any?(
             model_report["errors"],
             &(&1["path"] == "$.source_provider_counteroffer_report.model")
           )

    invalid_shape = Map.put(artifact, "source_provider_counteroffer_report", [])

    assert {:error, shape_report} = Schema.validate_artifact(invalid_shape)

    assert Enum.any?(
             shape_report["errors"],
             &(&1["path"] == "$.source_provider_counteroffer_report")
           )
  end

  test "exports the source provider-counteroffer property" do
    assert {:ok, schema} = Schema.json_schema("campaign_repair.v2")

    assert get_in(schema, ["properties", "source_provider_counteroffer_report", "type"]) ==
             "object"

    assert get_in(schema, ["$defs", "provider_counteroffer_report.v1", "type"]) ==
             "object"
  end

  defp provider_counteroffer_report do
    OrbitalDynamics.provider_counteroffer_report(
      [
        %{
          id: :provider_counteroffer_window,
          provider_id: :ops_calendar,
          ground_station_id: :dss_14,
          starts_at_s: 130.0,
          ends_at_s: 170.0,
          counteroffer_id: :provider_offer_1,
          counteroffer_status: :proposed,
          counteroffer_reason_code: :provider_shifted_window,
          counteroffer_cost_delta: 125.5,
          counteroffer_lock_deadline_s: 150.0,
          counteroffer_starts_at_s: 160.0,
          counteroffer_ends_at_s: 210.0
        }
      ],
      source: :candidate_refresh_v2_handoff
    )
  end

  defp read_json!(path) do
    path
    |> File.read!()
    |> :json.decode()
  end
end
