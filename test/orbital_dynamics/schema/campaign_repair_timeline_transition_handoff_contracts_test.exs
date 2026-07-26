defmodule OrbitalDynamics.Schema.CampaignRepairTimelineTransitionHandoffContractsTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.{CampaignPlanner, Schema}

  @repair_transition_source "campaign_repair.timeline_transition_application_report.applications"

  setup do
    %{
      repair: read_json!("study_results/leo_constellation_campaign_repair_v2.json"),
      readiness_repair:
        read_json!("study_results/campaign_repair_readiness_source_handoff_v2.json")
    }
  end

  test "validates checked Repair timeline-transition review handoffs", context do
    for artifact <- [context.repair, context.readiness_repair] do
      assert {:ok, %{"schema_contract" => "campaign_repair.v2"}} =
               Schema.validate_artifact(artifact)
    end
  end

  test "keeps additive timeline-transition review handoffs optional", %{
    readiness_repair: repair
  } do
    assert {:ok, %{"schema_contract" => "campaign_repair.v2"}} =
             repair
             |> Map.drop(["operator_review_package", "cadence_import_manifest"])
             |> Schema.validate_artifact()

    review_index = transition_review_index(repair)
    cadence_index = transition_import_index(repair)

    older =
      repair
      |> update_in(
        ["operator_review_package", "rows", Access.at(review_index)],
        &Map.delete(&1, "source_timeline_application")
      )
      |> update_in(
        ["cadence_import_manifest", "rows", Access.at(cadence_index)],
        fn row ->
          row
          |> Map.delete("source_timeline_application")
          |> update_in(["source_review_row"], &Map.delete(&1, "source_timeline_application"))
        end
      )

    assert {:ok, %{"schema_contract" => "campaign_repair.v2"}} =
             Schema.validate_artifact(older)
  end

  test "does not require handoffs for non-review transition applications" do
    prior_plan =
      "study_results/leo_constellation_campaign.json"
      |> read_json!()
      |> Map.fetch!("campaign_plan")

    repair =
      CampaignPlanner.repair(%{
        prior_plan: prior_plan,
        realized_state: %{activities: []},
        current_epoch_s: 0.0,
        remaining_horizon: %{"starts_at_s" => 0.0, "ends_at_s" => 86_400.0},
        generated_at: ~U[2026-05-14 00:00:00Z]
      })

    applications = get_in(repair, ["timeline_transition_application_report", "applications"])

    assert applications != []
    refute Enum.any?(applications, &Map.get(&1, "requires_operator_review", false))

    assert {:ok, %{"schema_contract" => "campaign_repair.v2"}} =
             Schema.validate_artifact(repair)
  end

  test "rejects Repair timeline-transition review handoff drift", %{
    readiness_repair: repair
  } do
    review_index = transition_review_index(repair)
    cadence_index = transition_import_index(repair)

    review_count_drift =
      put_in(
        repair,
        ["operator_review_package", "rows", Access.at(review_index), "source"],
        "campaign_repair.source_timeline_transition_application_report.applications"
      )

    cadence_count_drift =
      put_in(
        repair,
        [
          "cadence_import_manifest",
          "rows",
          Access.at(cadence_index),
          "source_review_row",
          "source"
        ],
        "campaign_repair.source_timeline_transition_application_report.applications"
      )

    review_copy_drift =
      update_in(
        repair,
        [
          "operator_review_package",
          "rows",
          Access.at(review_index),
          "source_timeline_application"
        ],
        &Map.put(&1, "rank", 99)
      )

    cadence_copy_drift =
      update_in(
        repair,
        ["cadence_import_manifest", "rows", Access.at(cadence_index)],
        fn row ->
          row
          |> update_in(["source_timeline_application"], &Map.put(&1, "rank", 99))
          |> update_in(
            ["source_review_row", "source_timeline_application"],
            &Map.put(&1, "rank", 99)
          )
        end
      )

    invalid_cases = [
      {"$.operator_review_package.rows", review_count_drift},
      {"$.cadence_import_manifest.rows", cadence_count_drift},
      {"$.operator_review_package.rows[#{review_index}].source_timeline_application",
       review_copy_drift},
      {"$.cadence_import_manifest.rows[#{cadence_index}].source_timeline_application",
       cadence_copy_drift},
      {"$.cadence_import_manifest.rows[#{cadence_index}].source_review_row.source_timeline_application",
       cadence_copy_drift}
    ]

    for {expected_path, invalid} <- invalid_cases do
      assert {:error, report} = Schema.validate_artifact(invalid)
      assert Enum.any?(report["errors"], &(&1["path"] == expected_path))
    end
  end

  defp transition_review_index(repair) do
    Enum.find_index(
      get_in(repair, ["operator_review_package", "rows"]),
      &(Map.get(&1, "review_type") == "timeline_diff_review" and
          Map.get(&1, "source") == @repair_transition_source)
    )
  end

  defp transition_import_index(repair) do
    Enum.find_index(
      get_in(repair, ["cadence_import_manifest", "rows"]),
      &(Map.get(&1, "source_review_type") == "timeline_diff_review" and
          get_in(&1, ["source_review_row", "source"]) == @repair_transition_source)
    )
  end

  defp read_json!(path) do
    path
    |> File.read!()
    |> :json.decode()
  end
end
