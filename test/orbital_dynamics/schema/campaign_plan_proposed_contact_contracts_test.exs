defmodule OrbitalDynamics.Schema.CampaignPlanProposedContactContractsTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.CampaignPlanner.DownlinkActivityNormalization
  alias OrbitalDynamics.Schema.CampaignPlanProposedContactContracts
  alias OrbitalDynamics.Schema

  setup do
    artifact =
      "study_results/leo_constellation_campaign.json"
      |> File.read!()
      |> :json.decode()
      |> Map.fetch!("campaign_plan")

    %{artifact: artifact}
  end

  test "accepts producer-derived proposed contact snapshots", %{artifact: artifact} do
    assert {:ok, %{"schema_contract" => "campaign_plan.v1"}} =
             Schema.validate_artifact(artifact)
  end

  test "rejects missing and orphaned proposed contact rows", %{artifact: artifact} do
    missing = Map.put(artifact, "proposed_contacts", [])

    orphaned =
      update_in(artifact, ["proposed_contacts"], fn contacts ->
        contacts ++ [List.first(contacts)]
      end)

    for invalid <- [missing, orphaned] do
      assert {:error, report} = Schema.validate_artifact(invalid)

      assert error?(
               report,
               "$.proposed_contacts",
               "must match candidate-derived proposed contact count"
             )
    end
  end

  test "rejects proposed contact field drift from its candidate", %{artifact: artifact} do
    invalid =
      put_in(
        artifact,
        ["proposed_contacts", Access.at(0), "ground_station_id"],
        "other_station"
      )

    assert {:error, report} = Schema.validate_artifact(invalid)

    assert error?(
             report,
             "$.proposed_contacts[0]",
             "must match candidate-derived proposed contact snapshot"
           )
  end

  test "rejects proposed contact order drift", %{artifact: artifact} do
    first_candidate = List.first(artifact["candidate_activities"])

    second_candidate =
      first_candidate
      |> Map.put("id", "leo_1_downlink_equator_prime_2")
      |> Map.put("starts_at_s", 400.0)
      |> Map.put("ends_at_s", 500.0)

    candidates = [first_candidate, second_candidate]

    contacts =
      candidates
      |> DownlinkActivityNormalization.proposed_contacts()
      |> Enum.reverse()

    issues =
      CampaignPlanProposedContactContracts.validate([], %{
        "candidate_activities" => candidates,
        "proposed_contacts" => contacts
      })

    assert Enum.sort(Enum.map(issues, & &1["path"])) == [
             "$.proposed_contacts[0]",
             "$.proposed_contacts[1]"
           ]
  end

  test "allows additional proposed-contact handoff metadata", %{artifact: artifact} do
    enriched =
      update_in(
        artifact,
        ["proposed_contacts", Access.at(0)],
        &Map.put(&1, "review_note", "candidate reviewed")
      )

    assert {:ok, %{"schema_contract" => "campaign_plan.v1"}} =
             Schema.validate_artifact(enriched)
  end

  test "allows synchronized candidate and proposed-contact enrichment", %{artifact: artifact} do
    enriched =
      artifact
      |> update_in(
        ["candidate_activities", Access.at(0)],
        &Map.put(&1, "review_note", "shared")
      )
      |> update_in(
        ["proposed_contacts", Access.at(0)],
        &Map.put(&1, "review_note", "shared")
      )

    assert {:ok, %{"schema_contract" => "campaign_plan.v1"}} =
             Schema.validate_artifact(enriched)
  end

  test "accepts empty handoffs and leaves malformed rows to field validation" do
    assert [] ==
             CampaignPlanProposedContactContracts.validate([], %{
               "candidate_activities" => [],
               "proposed_contacts" => []
             })

    assert [] ==
             CampaignPlanProposedContactContracts.validate([], %{
               "candidate_activities" => ["not-an-activity"],
               "proposed_contacts" => ["not-a-contact"]
             })
  end

  defp error?(report, path, message) do
    Enum.any?(report["errors"], &(&1["path"] == path and &1["message"] == message))
  end
end
