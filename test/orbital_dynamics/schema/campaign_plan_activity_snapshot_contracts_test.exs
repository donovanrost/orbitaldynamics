defmodule OrbitalDynamics.Schema.CampaignPlanActivitySnapshotContractsTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.Schema.CampaignPlanActivitySnapshotContracts
  alias OrbitalDynamics.Schema

  setup do
    artifact =
      "study_results/leo_constellation_campaign.json"
      |> File.read!()
      |> :json.decode()
      |> Map.fetch!("campaign_plan")

    %{artifact: artifact}
  end

  test "accepts producer-selected activity snapshots", %{artifact: artifact} do
    assert {:ok, %{"schema_contract" => "campaign_plan.v1"}} =
             Schema.validate_artifact(artifact)
  end

  test "rejects selected activity drift from first ranked timeline", %{artifact: artifact} do
    invalid = put_snapshot_value(artifact, :selected, 12.5)

    assert {:error, report} = Schema.validate_artifact(invalid)

    assert error?(
             report,
             "$.activities[0]",
             "must match first ranked timeline activity snapshot"
           )
  end

  test "rejects ranked activity drift from selection and candidate", %{artifact: artifact} do
    invalid = put_snapshot_value(artifact, :ranked, 12.5)

    assert {:error, report} = Schema.validate_artifact(invalid)

    assert error?(
             report,
             "$.activities[0]",
             "must match first ranked timeline activity snapshot"
           )

    assert error?(
             report,
             "$.ranked_timelines[0].activities[0]",
             "must match candidate activity snapshot"
           )
  end

  test "rejects synchronized selected and ranked drift from candidate", %{artifact: artifact} do
    invalid =
      artifact
      |> put_snapshot_value(:selected, 12.5)
      |> put_snapshot_value(:ranked, 12.5)

    assert {:error, report} = Schema.validate_artifact(invalid)

    refute error?(
             report,
             "$.activities[0]",
             "must match first ranked timeline activity snapshot"
           )

    assert error?(
             report,
             "$.ranked_timelines[0].activities[0]",
             "must match candidate activity snapshot"
           )
  end

  test "rejects candidate drift from ranked snapshot", %{artifact: artifact} do
    invalid = put_snapshot_value(artifact, :candidate, 12.5)

    assert {:error, report} = Schema.validate_artifact(invalid)

    assert error?(
             report,
             "$.ranked_timelines[0].activities[0]",
             "must match candidate activity snapshot"
           )
  end

  test "rejects ranked activity without candidate reference", %{artifact: artifact} do
    invalid =
      update_in(artifact, ["candidate_activities"], fn candidates ->
        Enum.reject(candidates, &(&1["id"] == "leo_1_observe_target_a_1"))
      end)

    assert {:error, report} = Schema.validate_artifact(invalid)

    assert error?(
             report,
             "$.ranked_timelines[0].activities[0]",
             "must reference candidate activity by id"
           )
  end

  test "rejects duplicate candidate activity identities", %{artifact: artifact} do
    duplicate = List.first(artifact["candidate_activities"])
    candidates = artifact["candidate_activities"] ++ [duplicate]

    invalid =
      artifact
      |> Map.put("candidate_activities", candidates)
      |> Map.put("optimizer_contract", optimizer_contract(artifact, candidates))

    assert {:error, report} = Schema.validate_artifact(invalid)

    assert error?(
             report,
             "$.candidate_activities",
             ~s(must not contain duplicate IDs: ["#{duplicate["id"]}"])
           )
  end

  test "rejects duplicate activity identities within a ranked timeline", %{
    artifact: artifact
  } do
    [selected] = artifact["activities"]

    issues =
      CampaignPlanActivitySnapshotContracts.validate([], %{
        "candidate_activities" => [selected],
        "ranked_timelines" => [%{"activities" => [selected, selected]}],
        "activities" => [selected, selected]
      })

    assert %{
             "path" => "$.ranked_timelines[0].activities",
             "message" => ~s(must not contain duplicate IDs: ["#{selected["id"]}"]),
             "severity" => "error"
           } in issues
  end

  test "leaves malformed duplicate IDs to field-level validators" do
    malformed = %{"id" => "bad id"}

    issues =
      CampaignPlanActivitySnapshotContracts.validate([], %{
        "candidate_activities" => [malformed, malformed],
        "ranked_timelines" => [%{"activities" => [malformed, malformed]}],
        "activities" => [malformed, malformed]
      })

    assert issues == []
  end

  test "accepts empty activity identity collections" do
    assert [] ==
             CampaignPlanActivitySnapshotContracts.validate([], %{
               "candidate_activities" => [],
               "ranked_timelines" => [%{"activities" => []}],
               "activities" => []
             })
  end

  test "keeps synchronized additional activity metadata compatible", %{artifact: artifact} do
    enriched =
      artifact
      |> update_in(["activities", Access.at(0)], &Map.put(&1, "review_note", "shared"))
      |> update_in(
        ["candidate_activities", Access.at(1)],
        &Map.put(&1, "review_note", "shared")
      )
      |> update_in(
        ["ranked_timelines", Access.at(0), "activities", Access.at(0)],
        &Map.put(&1, "review_note", "shared")
      )

    assert {:ok, %{"schema_contract" => "campaign_plan.v1"}} =
             Schema.validate_artifact(enriched)
  end

  defp put_snapshot_value(artifact, :selected, value) do
    put_in(
      artifact,
      ["activities", Access.at(0), "source_window", "max_elevation_deg"],
      value
    )
  end

  defp put_snapshot_value(artifact, :ranked, value) do
    put_in(
      artifact,
      [
        "ranked_timelines",
        Access.at(0),
        "activities",
        Access.at(0),
        "source_window",
        "max_elevation_deg"
      ],
      value
    )
  end

  defp put_snapshot_value(artifact, :candidate, value) do
    put_in(
      artifact,
      ["candidate_activities", Access.at(1), "source_window", "max_elevation_deg"],
      value
    )
  end

  defp optimizer_contract(artifact, candidates) do
    OrbitalDynamics.Optimizer.greedy_timeline_contract(
      candidates,
      artifact["ranked_timelines"],
      plan_id: artifact["plan_id"],
      constraints: get_in(artifact, ["assumptions", "constraints"]),
      scoring_policy: get_in(artifact, ["assumptions", "scoring_policy"])
    )
  end

  defp error?(report, path, message) do
    Enum.any?(report["errors"], &(&1["path"] == path and &1["message"] == message))
  end
end
