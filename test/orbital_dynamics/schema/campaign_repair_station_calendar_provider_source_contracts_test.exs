defmodule OrbitalDynamics.Schema.CampaignRepairStationCalendarProviderSourceContractsTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.Schema

  setup do
    artifact = read_json!("study_results/leo_constellation_campaign_repair_v2.json")
    source_provider = read_json!("study_results/station_calendar_provider_v1.json")

    %{
      artifact: Map.put(artifact, "source_station_calendar_provider", source_provider)
    }
  end

  test "validates the optional V2 source station-calendar provider", %{artifact: artifact} do
    assert {:ok, %{"schema_contract" => "campaign_repair.v2"}} =
             Schema.validate_artifact(artifact)

    assert {:ok, %{"schema_contract" => "station_calendar_provider.v1"}} =
             artifact
             |> Map.fetch!("source_station_calendar_provider")
             |> Schema.validate_artifact()

    assert {:ok, %{"schema_contract" => "campaign_repair.v2"}} =
             artifact
             |> Map.delete("source_station_calendar_provider")
             |> Schema.validate_artifact()
  end

  test "rejects provider drift at the distinct V2 source path", %{artifact: artifact} do
    missing_trust_boundary =
      artifact
      |> update_in(
        ["source_station_calendar_provider"],
        &(&1 |> Map.delete("trust_boundary") |> Map.delete("provenance"))
      )

    assert {:error, trust_report} = Schema.validate_artifact(missing_trust_boundary)

    assert Enum.any?(
             trust_report["errors"],
             &(&1["path"] == "$.source_station_calendar_provider.trust_boundary")
           )

    invalid_shape = Map.put(artifact, "source_station_calendar_provider", [])

    assert {:error, shape_report} = Schema.validate_artifact(invalid_shape)

    assert Enum.any?(
             shape_report["errors"],
             &(&1["path"] == "$.source_station_calendar_provider")
           )
  end

  test "exports the source station-calendar provider property" do
    assert {:ok, schema} = Schema.json_schema("campaign_repair.v2")

    assert get_in(schema, ["properties", "source_station_calendar_provider", "type"]) ==
             "object"

    assert get_in(schema, ["$defs", "station_calendar_provider.v1", "type"]) == "object"
  end

  defp read_json!(path) do
    path
    |> File.read!()
    |> :json.decode()
  end
end
