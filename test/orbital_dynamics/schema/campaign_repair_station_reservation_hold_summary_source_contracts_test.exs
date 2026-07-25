defmodule OrbitalDynamics.Schema.CampaignRepairStationReservationHoldSummarySourceContractsTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.Schema

  setup do
    artifact = read_json!("study_results/leo_constellation_campaign_repair_v2.json")
    source_summary = read_json!("study_results/station_reservation_hold_summary_v1.json")

    %{
      artifact: Map.put(artifact, "source_station_reservation_hold_summary", source_summary)
    }
  end

  test "validates the optional V2 source station reservation hold summary", %{
    artifact: artifact
  } do
    assert {:ok, %{"schema_contract" => "campaign_repair.v2"}} =
             Schema.validate_artifact(artifact)

    assert {:ok, %{"schema_contract" => "station_reservation_hold_summary.v1"}} =
             artifact
             |> Map.fetch!("source_station_reservation_hold_summary")
             |> Schema.validate_artifact()

    assert {:ok, %{"schema_contract" => "campaign_repair.v2"}} =
             artifact
             |> Map.delete("source_station_reservation_hold_summary")
             |> Schema.validate_artifact()
  end

  test "rejects V2 source station reservation hold drift at the source path", %{
    artifact: artifact
  } do
    invalid_count =
      put_in(
        artifact,
        ["source_station_reservation_hold_summary", "reservation_hold_count"],
        99
      )

    assert {:error, count_report} = Schema.validate_artifact(invalid_count)

    assert Enum.any?(
             count_report["errors"],
             &(&1["path"] ==
                 "$.source_station_reservation_hold_summary.reservation_hold_count")
           )

    invalid_shape = Map.put(artifact, "source_station_reservation_hold_summary", [])

    assert {:error, shape_report} = Schema.validate_artifact(invalid_shape)

    assert Enum.any?(
             shape_report["errors"],
             &(&1["path"] == "$.source_station_reservation_hold_summary")
           )
  end

  test "exports the source station reservation hold property" do
    assert {:ok, schema} = Schema.json_schema("campaign_repair.v2")

    assert get_in(
             schema,
             ["properties", "source_station_reservation_hold_summary", "type"]
           ) == "object"

    assert get_in(schema, ["$defs", "station_reservation_hold_summary.v1", "type"]) ==
             "object"
  end

  defp read_json!(path) do
    path
    |> File.read!()
    |> :json.decode()
  end
end
