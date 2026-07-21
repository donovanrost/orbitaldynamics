defmodule OrbitalDynamics.Schema.CampaignPlanContactIntentContractsTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.Communications.ContactIntent
  alias OrbitalDynamics.Schema
  alias OrbitalDynamics.Schema.CampaignPlanContactIntentContracts

  setup do
    artifact =
      "study_results/leo_constellation_campaign.json"
      |> File.read!()
      |> :json.decode()
      |> Map.fetch!("campaign_plan")

    %{artifact: artifact}
  end

  test "accepts producer-derived contact intent base snapshots", %{artifact: artifact} do
    assert {:ok, %{"schema_contract" => "campaign_plan.v1"}} =
             Schema.validate_artifact(artifact)
  end

  test "rejects missing and orphaned contact intent rows", %{artifact: artifact} do
    missing = Map.put(artifact, "contact_intents", [])

    orphaned =
      update_in(artifact, ["contact_intents"], fn intents ->
        intents ++ [List.first(intents)]
      end)

    for invalid <- [missing, orphaned] do
      assert {:error, report} = Schema.validate_artifact(invalid)

      assert error?(
               report,
               "$.contact_intents",
               "must match candidate-derived contact intent count"
             )
    end
  end

  test "rejects contact intent base field drift", %{artifact: artifact} do
    invalid =
      put_in(
        artifact,
        ["contact_intents", Access.at(0), "ground_station_id"],
        "other_station"
      )

    assert {:error, report} = Schema.validate_artifact(invalid)

    assert error?(
             report,
             "$.contact_intents[0]",
             "must match candidate-derived contact intent base snapshot"
           )
  end

  test "rejects contact intent order drift", %{artifact: artifact} do
    first_candidate = List.first(artifact["candidate_activities"])

    second_candidate =
      first_candidate
      |> Map.put("id", "leo_1_downlink_equator_prime_2")
      |> Map.put("starts_at_s", 400.0)
      |> Map.put("ends_at_s", 500.0)
      |> put_in(
        ["cadence_import", "external_id"],
        "leo_1_downlink_equator_prime_2"
      )

    candidates = [first_candidate, second_candidate]

    intents =
      candidates
      |> ContactIntent.from_activities()
      |> Enum.reverse()

    issues =
      CampaignPlanContactIntentContracts.validate([], %{
        "candidate_activities" => candidates,
        "contact_intents" => intents
      })

    assert Enum.sort(Enum.map(issues, & &1["path"])) == [
             "$.contact_intents[0]",
             "$.contact_intents[1]"
           ]
  end

  test "allows valid optional approval policy annotations", %{artifact: artifact} do
    candidates = artifact["candidate_activities"]

    policy_intents =
      ContactIntent.from_activities(candidates,
        approval_policy: %{"policy_bundle_id" => "command_contact_authority_v1"}
      )

    assert [%{"policy_decision" => %{"schema_contract" => "policy_decision.v1"}}] =
             policy_intents

    assert [] ==
             CampaignPlanContactIntentContracts.validate([], %{
               "candidate_activities" => candidates,
               "contact_intents" => policy_intents
             })
  end

  test "allows additional contact-intent handoff metadata", %{artifact: artifact} do
    enriched =
      update_in(
        artifact,
        ["contact_intents", Access.at(0)],
        &Map.put(&1, "review_note", "intent reviewed")
      )

    assert {:ok, %{"schema_contract" => "campaign_plan.v1"}} =
             Schema.validate_artifact(enriched)
  end

  test "accepts empty handoffs and leaves malformed sources to field validation", %{
    artifact: artifact
  } do
    assert [] ==
             CampaignPlanContactIntentContracts.validate([], %{
               "candidate_activities" => [],
               "contact_intents" => []
             })

    assert [] ==
             CampaignPlanContactIntentContracts.validate([], %{
               "candidate_activities" => ["not-an-activity"],
               "contact_intents" => ["not-an-intent"]
             })

    assert [] ==
             CampaignPlanContactIntentContracts.validate([], %{
               "candidate_activities" => artifact["candidate_activities"],
               "contact_intents" => [%{}]
             })

    invalid_contact_candidate =
      artifact["candidate_activities"]
      |> List.first()
      |> Map.put("type", "command")
      |> Map.put("direction", "future_invalid_direction")

    assert [] ==
             CampaignPlanContactIntentContracts.validate([], %{
               "candidate_activities" => [invalid_contact_candidate],
               "contact_intents" => []
             })
  end

  defp error?(report, path, message) do
    Enum.any?(report["errors"], &(&1["path"] == path and &1["message"] == message))
  end
end
