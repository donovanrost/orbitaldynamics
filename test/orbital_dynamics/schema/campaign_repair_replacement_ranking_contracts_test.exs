defmodule OrbitalDynamics.Schema.CampaignRepairReplacementRankingContractsTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.CampaignPlanner.RepairMetadata
  alias OrbitalDynamics.Schema

  setup do
    artifact = read_json!("study_results/campaign_repair_readiness_source_handoff_v2.json")
    activity_index = Enum.find_index(artifact["activities"], &(&1["id"] == "dl_ready"))

    %{artifact: artifact, activity_index: activity_index}
  end

  test "validates current and pre-contact-pressure replacement-ranking explanations", %{
    artifact: artifact,
    activity_index: activity_index
  } do
    assert {:ok, %{"schema_contract" => "campaign_repair.v2"}} =
             Schema.validate_artifact(artifact)

    legacy_artifact =
      update_in(
        artifact,
        [
          "activities",
          Access.at(activity_index),
          "repair",
          "replacement_ranking",
          "rows",
          Access.at(0)
        ],
        &Map.delete(&1, "contact_intent_pressure_penalty")
      )

    assert {:ok, %{"schema_contract" => "campaign_repair.v2"}} =
             Schema.validate_artifact(legacy_artifact)

    fully_legacy_without_source_timing =
      update_in(
        artifact,
        ["activities", Access.at(activity_index), "repair"],
        fn repair ->
          repair
          |> Map.delete("source_activity_context")
          |> Map.delete("source_activity_id")
          |> Map.delete("source_timeline_id")
          |> Map.delete("replacement_timeline_id")
          |> Map.delete("timeline_link")
          |> update_in(["replacement_ranking", "rows"], fn rows ->
            Enum.map(rows, fn row ->
              row
              |> Map.delete("contact_intent_pressure_penalty")
              |> Map.delete("contact_contention_resolution_pressure_penalty")
            end)
          end)
        end
      )

    assert {:ok, %{"schema_contract" => "campaign_repair.v2"}} =
             Schema.validate_artifact(fully_legacy_without_source_timing)

    current_without_source_timing =
      update_in(
        artifact,
        ["activities", Access.at(activity_index), "repair"],
        &Map.delete(&1, "source_activity_context")
      )

    assert {:error, current_report} = Schema.validate_artifact(current_without_source_timing)

    assert Enum.any?(
             current_report["errors"],
             &(&1["path"] ==
                 "$.activities[#{activity_index}].repair.source_activity_context")
           )

    invalid_legacy_cost =
      fully_legacy_without_source_timing
      |> put_in_path(
        ranking_path(activity_index) <> ".rows[0].schedule_churn_penalty",
        -200.0
      )
      |> put_in_path(ranking_path(activity_index) <> ".rows[0].ranking_score", -194.0)

    assert {:error, report} = Schema.validate_artifact(invalid_legacy_cost)

    assert Enum.any?(
             report["errors"],
             &(&1["path"] ==
                 ranking_path(activity_index) <> ".rows[0].schedule_churn_penalty")
           )
  end

  test "rejects stale ranking envelopes and derived summary values", context do
    ranking_path = ranking_path(context.activity_index)
    repair_path = "$.activities[#{context.activity_index}].repair"
    row_path = ranking_path <> ".rows[0]"
    [ranking_row] = get_in_path(context.artifact, ranking_path <> ".rows")

    duplicate_candidate_artifact =
      context.artifact
      |> put_in_path(ranking_path <> ".rows", [
        ranking_row,
        ranking_row |> Map.put("rank", 2) |> Map.put("selected", false)
      ])
      |> put_in_path(ranking_path <> ".evaluated_candidate_count", 2)

    selected_second_artifact =
      context.artifact
      |> put_in_path(ranking_path <> ".rows", [
        Map.put(ranking_row, "selected", false),
        ranking_row
        |> Map.put("candidate_id", "dl_other")
        |> Map.put("rank", 2)
        |> Map.put("selected", true)
      ])
      |> put_in_path(ranking_path <> ".evaluated_candidate_count", 2)
      |> put_in_path(ranking_path <> ".selected_candidate_id", "dl_other")

    partial_current_artifact =
      context.artifact
      |> put_in_path(ranking_path <> ".rows", [
        ranking_row,
        ranking_row
        |> Map.put("candidate_id", "dl_legacy")
        |> Map.put("candidate_score", 9.0)
        |> Map.put("ranking_score", -95.0)
        |> Map.put("rank", 2)
        |> Map.put("selected", false)
        |> Map.delete("contact_intent_pressure_penalty")
      ])
      |> put_in_path(ranking_path <> ".evaluated_candidate_count", 2)

    missing_source_candidate_artifact =
      Map.put(context.artifact, "source_candidate_activities", [])

    [source_candidate] = context.artifact["source_candidate_activities"]

    ambiguous_source_candidate_artifact =
      Map.put(context.artifact, "source_candidate_activities", [
        source_candidate,
        source_candidate
      ])

    coordinated_source_activity_drift =
      context.artifact
      |> put_in_path(repair_path <> ".source_activity_id", "dl_source_drift")
      |> put_in_path(
        repair_path <> ".timeline_link.source_activity_id",
        "dl_source_drift"
      )

    coordinated_source_timeline_drift =
      context.artifact
      |> put_in_path(repair_path <> ".source_timeline_id", "timeline:source:drift")
      |> put_in_path(
        repair_path <> ".timeline_link.source_timeline_id",
        "timeline:source:drift"
      )

    invalid_cases = [
      {ranking_path <> ".model",
       put_in_path(context.artifact, ranking_path <> ".model", "legacy_replacement_ranking")},
      {ranking_path <> ".selection_scope",
       put_in_path(context.artifact, ranking_path <> ".selection_scope", "all_candidates")},
      {ranking_path <> ".global_optimization",
       put_in_path(context.artifact, ranking_path <> ".global_optimization", true)},
      {ranking_path <> ".evaluated_candidate_count",
       put_in_path(context.artifact, ranking_path <> ".evaluated_candidate_count", 2)},
      {ranking_path <> ".rows",
       put_in_path(context.artifact, ranking_path <> ".rows[0].rank", 2)},
      {ranking_path <> ".rows",
       put_in_path(context.artifact, ranking_path <> ".rows[0].selected", false)},
      {ranking_path <> ".rows", duplicate_candidate_artifact},
      {ranking_path <> ".rows", selected_second_artifact},
      {ranking_path <> ".rows[1].contact_intent_pressure_penalty", partial_current_artifact},
      {row_path <> ".candidate_id", missing_source_candidate_artifact},
      {row_path <> ".candidate_id", ambiguous_source_candidate_artifact},
      {ranking_path <> ".rows[0]",
       put_in_path(context.artifact, ranking_path <> ".rows", ["invalid_row"])},
      {ranking_path <> ".selected_candidate_id",
       put_in_path(context.artifact, ranking_path <> ".selected_candidate_id", "dl_other")},
      {ranking_path <> ".selected_candidate_id",
       put_in_path(context.artifact, "$.activities[#{context.activity_index}].id", "dl_drift")},
      {ranking_path <> ".selected_candidate_id",
       update_in(
         context.artifact,
         ["activities", Access.at(context.activity_index)],
         &Map.delete(&1, "id")
       )},
      {repair_path <> ".source_activity_id",
       delete_in_path(context.artifact, repair_path <> ".source_activity_id")},
      {repair_path <> ".source_timeline_id",
       delete_in_path(context.artifact, repair_path <> ".source_timeline_id")},
      {repair_path <> ".replacement_timeline_id",
       delete_in_path(context.artifact, repair_path <> ".replacement_timeline_id")},
      {repair_path <> ".timeline_link",
       delete_in_path(context.artifact, repair_path <> ".timeline_link")},
      {repair_path <> ".timeline_link.source_activity_id",
       delete_in_path(context.artifact, repair_path <> ".timeline_link.source_activity_id")},
      {repair_path <> ".timeline_link.replacement_activity_id",
       delete_in_path(
         context.artifact,
         repair_path <> ".timeline_link.replacement_activity_id"
       )},
      {repair_path <> ".timeline_link.source_timeline_id",
       delete_in_path(context.artifact, repair_path <> ".timeline_link.source_timeline_id")},
      {repair_path <> ".timeline_link.replacement_timeline_id",
       delete_in_path(
         context.artifact,
         repair_path <> ".timeline_link.replacement_timeline_id"
       )},
      {repair_path <> ".source_activity_context.timeline_identity",
       delete_in_path(
         context.artifact,
         repair_path <> ".source_activity_context.timeline_identity"
       )},
      {repair_path <> ".source_activity_context.timeline_identity.activity_id",
       coordinated_source_activity_drift},
      {repair_path <> ".source_activity_context.timeline_identity.timeline_id",
       coordinated_source_timeline_drift},
      {repair_path <> ".replacement_timeline_id",
       put_in_path(
         context.artifact,
         repair_path <> ".replacement_timeline_id",
         "timeline:drift"
       )},
      {repair_path <> ".timeline_link.replacement_activity_id",
       put_in_path(
         context.artifact,
         repair_path <> ".timeline_link.replacement_activity_id",
         "dl_drift"
       )},
      {repair_path <> ".timeline_link.source_timeline_id",
       put_in_path(
         context.artifact,
         repair_path <> ".timeline_link.source_timeline_id",
         "timeline:source:drift"
       )}
    ]

    for {expected_path, invalid} <- invalid_cases do
      assert {:error, report} = Schema.validate_artifact(invalid)
      assert Enum.any?(report["errors"], &(&1["path"] == expected_path))
    end
  end

  test "replays current ranking tie-break order while preserving legacy order", context do
    ranking_path = ranking_path(context.activity_index)

    higher_churn_selected =
      add_unselected_candidate(context, "dl_lower_churn", 490.0, 9.9)

    assert {:error, current_report} = Schema.validate_artifact(higher_churn_selected)

    assert Enum.any?(
             current_report["errors"],
             &(&1["path"] == ranking_path <> ".rows")
           )

    fully_legacy_order =
      update_in(
        higher_churn_selected,
        [
          "activities",
          Access.at(context.activity_index),
          "repair",
          "replacement_ranking",
          "rows"
        ],
        fn rows ->
          Enum.map(rows, fn row ->
            Map.drop(row, [
              "contact_intent_pressure_penalty",
              "contact_contention_resolution_pressure_penalty"
            ])
          end)
        end
      )

    assert {:ok, %{"schema_contract" => "campaign_repair.v2"}} =
             Schema.validate_artifact(fully_legacy_order)
  end

  test "binds current selected activity to its source candidate snapshot", context do
    ranking_path = ranking_path(context.activity_index)
    row_path = ranking_path <> ".rows[0]"

    coordinated_source_ranking_drift =
      context.artifact
      |> put_in_path("$.source_candidate_activities[0].starts_at_s", 490.0)
      |> put_in_path("$.source_candidate_activities[0].ends_at_s", 550.0)
      |> put_in_path(row_path <> ".schedule_churn_s", 390.0)
      |> put_in_path(row_path <> ".schedule_move_penalty", -3.9)
      |> put_in_path(row_path <> ".ranking_score", -93.9)

    expected_path = "$.activities[#{context.activity_index}]"

    assert {:error, current_report} =
             Schema.validate_artifact(coordinated_source_ranking_drift)

    assert Enum.any?(
             current_report["errors"],
             &(&1["path"] == expected_path)
           )

    legacy_drift =
      update_in(
        coordinated_source_ranking_drift,
        [
          "activities",
          Access.at(context.activity_index),
          "repair",
          "replacement_ranking",
          "rows",
          Access.at(0)
        ],
        &Map.drop(&1, [
          "contact_intent_pressure_penalty",
          "contact_contention_resolution_pressure_penalty"
        ])
      )

    assert {:ok, %{"schema_contract" => "campaign_repair.v2"}} =
             Schema.validate_artifact(legacy_drift)
  end

  test "binds current repair churn to the selected replacement-ranking row", context do
    repair_path = "$.activities[#{context.activity_index}].repair"

    selected_row =
      context.artifact
      |> get_in_path(ranking_path(context.activity_index) <> ".rows")
      |> Enum.find(& &1["selected"])

    churn_drift =
      put_in_path(
        context.artifact,
        repair_path <> ".schedule_churn_s",
        selected_row["schedule_churn_s"] + 1.0
      )

    assert {:error, report} = Schema.validate_artifact(churn_drift)

    assert Enum.any?(
             report["errors"],
             &(&1["path"] == repair_path <> ".schedule_churn_s" and
                 &1["message"] ==
                   "must match the selected replacement-ranking row schedule_churn_s")
           )
  end

  test "binds current repair action to the corresponding producer delta", context do
    action_path = "$.activities[#{context.activity_index}].repair.action"
    action_drift = put_in_path(context.artifact, action_path, "replaced")

    assert {:error, report} = Schema.validate_artifact(action_drift)

    assert Enum.any?(
             report["errors"],
             &(&1["path"] == action_path and
                 &1["message"] ==
                   "must match the corresponding Repair delta repair_action")
           )
  end

  test "binds current repair reason to the corresponding producer delta", context do
    reason_path = "$.activities[#{context.activity_index}].repair.reason"
    reason_drift = put_in_path(context.artifact, reason_path, "stale_reason")

    assert {:error, report} = Schema.validate_artifact(reason_drift)

    assert Enum.any?(
             report["errors"],
             &(&1["path"] == reason_path and
                 &1["message"] == "must match the corresponding Repair delta reason")
           )
  end

  test "binds current repair approval flag to the corresponding producer delta", context do
    approval_path =
      "$.activities[#{context.activity_index}].repair.requires_approval"

    approval_drift = put_in_path(context.artifact, approval_path, false)

    assert {:error, report} = Schema.validate_artifact(approval_drift)

    assert Enum.any?(
             report["errors"],
             &(&1["path"] == approval_path and
                 &1["message"] ==
                   "must match the corresponding Repair delta requires_approval")
           )
  end

  test "binds current source context to the source-plan activity projection", context do
    source_context_path =
      "$.activities[#{context.activity_index}].repair.source_activity_context"

    duration_drift =
      put_in_path(context.artifact, source_context_path <> ".duration_s", 61.0)

    assert {:error, report} = Schema.validate_artifact(duration_drift)

    assert Enum.any?(
             report["errors"],
             &(&1["path"] == source_context_path and
                 &1["message"] == "must match the source-plan activity context projection")
           )

    without_source_plan_evidence =
      Map.delete(context.artifact, "source_timeline_feedback_report")

    assert {:ok, %{"schema_contract" => "campaign_repair.v2"}} =
             Schema.validate_artifact(without_source_plan_evidence)
  end

  test "binds current repair source context to the corresponding producer delta", context do
    source_context_path =
      "$.activities[#{context.activity_index}].repair.source_activity_context"

    context_drift =
      context.artifact
      |> Map.delete("source_timeline_feedback_report")
      |> put_in_path(source_context_path <> ".duration_s", 61.0)

    assert {:error, report} = Schema.validate_artifact(context_drift)

    assert Enum.any?(
             report["errors"],
             &(&1["path"] == source_context_path and
                 &1["message"] ==
                   "must match the corresponding Repair delta source_activity_context")
           )
  end

  test "rejects temporally ineligible current ranking candidates", context do
    ranking_path = ranking_path(context.activity_index)
    candidate_path = ranking_path <> ".rows[1].candidate_id"

    already_started = add_unselected_candidate(context, "dl_started", 160.0, -100.0)
    outside_horizon = add_unselected_candidate(context, "dl_outside", 600.0, -100.0)

    for invalid <- [already_started, outside_horizon] do
      assert {:error, report} = Schema.validate_artifact(invalid)
      assert Enum.any?(report["errors"], &(&1["path"] == candidate_path))
    end

    legacy_started =
      update_in(
        already_started,
        [
          "activities",
          Access.at(context.activity_index),
          "repair",
          "replacement_ranking",
          "rows"
        ],
        fn rows ->
          Enum.map(rows, fn row ->
            Map.drop(row, [
              "contact_intent_pressure_penalty",
              "contact_contention_resolution_pressure_penalty"
            ])
          end)
        end
      )

    assert {:ok, %{"schema_contract" => "campaign_repair.v2"}} =
             Schema.validate_artifact(legacy_started)
  end

  test "requires complete viable candidate membership in isolated current rankings", context do
    ranking_path = ranking_path(context.activity_index)
    omitted_candidate = add_source_candidate(context, "dl_unranked", 520.0, 9.0)

    assert {:error, report} = Schema.validate_artifact(omitted_candidate)

    assert Enum.any?(
             report["errors"],
             &(&1["path"] == ranking_path <> ".rows" and
                 &1["message"] ==
                   "must contain exactly the uniquely identified viable source candidates in the replayable repair intent")
           )

    legacy_omission =
      update_in(
        omitted_candidate,
        [
          "activities",
          Access.at(context.activity_index),
          "repair",
          "replacement_ranking",
          "rows"
        ],
        fn rows ->
          Enum.map(rows, fn row ->
            Map.drop(row, [
              "contact_intent_pressure_penalty",
              "contact_contention_resolution_pressure_penalty"
            ])
          end)
        end
      )

    assert {:ok, %{"schema_contract" => "campaign_repair.v2"}} =
             Schema.validate_artifact(legacy_omission)

    without_source_plan_evidence =
      Map.delete(omitted_candidate, "source_timeline_feedback_report")

    assert {:ok, %{"schema_contract" => "campaign_repair.v2"}} =
             Schema.validate_artifact(without_source_plan_evidence)
  end

  test "rejects the preserved repair source as a current replacement candidate", context do
    ranking_path = ranking_path(context.activity_index)

    source_activity_id =
      get_in_path(
        context.artifact,
        "$.activities[#{context.activity_index}].repair.source_activity_id"
      )

    self_replacement =
      add_unselected_candidate(context, source_activity_id, 520.0, -100.0)

    assert {:error, report} = Schema.validate_artifact(self_replacement)

    assert Enum.any?(
             report["errors"],
             &(&1["path"] == ranking_path <> ".rows[1].candidate_id" and
                 &1["message"] ==
                   "must not identify the preserved repair source activity as its own replacement")
           )

    legacy_self_replacement =
      update_in(
        self_replacement,
        [
          "activities",
          Access.at(context.activity_index),
          "repair",
          "replacement_ranking",
          "rows"
        ],
        fn rows ->
          Enum.map(rows, fn row ->
            Map.drop(row, [
              "contact_intent_pressure_penalty",
              "contact_contention_resolution_pressure_penalty"
            ])
          end)
        end
      )

    assert {:ok, %{"schema_contract" => "campaign_repair.v2"}} =
             Schema.validate_artifact(legacy_self_replacement)
  end

  test "binds current downlink candidates to the preserved repair intent", context do
    ranking_path = ranking_path(context.activity_index)
    candidate_path = ranking_path <> ".rows[1].candidate_id"

    wrong_scenario =
      context
      |> add_unselected_candidate("dl_wrong_scenario", 520.0, -100.0)
      |> update_source_candidate("dl_wrong_scenario", &Map.put(&1, "scenario_id", "leo_2"))

    wrong_station =
      context
      |> add_unselected_candidate("dl_wrong_station", 520.0, -100.0)
      |> update_source_candidate(
        "dl_wrong_station",
        &Map.put(&1, "ground_station_id", "polar_north")
      )

    wrong_kind =
      context
      |> add_unselected_candidate("dl_wrong_kind", 520.0, -100.0)
      |> update_source_candidate(
        "dl_wrong_kind",
        &Map.put(&1, "type", "future_activity")
      )

    for invalid <- [wrong_scenario, wrong_station, wrong_kind] do
      assert {:error, report} = Schema.validate_artifact(invalid)
      assert Enum.any?(report["errors"], &(&1["path"] == candidate_path))
    end

    for legacy_source <- [wrong_station, wrong_kind] do
      legacy =
        update_in(
          legacy_source,
          [
            "activities",
            Access.at(context.activity_index),
            "repair",
            "replacement_ranking",
            "rows"
          ],
          fn rows ->
            Enum.map(rows, fn row ->
              Map.drop(row, [
                "contact_intent_pressure_penalty",
                "contact_contention_resolution_pressure_penalty"
              ])
            end)
          end
        )

      assert {:ok, %{"schema_contract" => "campaign_repair.v2"}} =
               Schema.validate_artifact(legacy)
    end
  end

  test "binds unscored current candidates to the producer zero-score fallback", context do
    row_path = ranking_path(context.activity_index) <> ".rows[1]"

    unscored_candidate =
      context
      |> add_unselected_candidate("dl_unscored", 520.0, 0.0)
      |> update_source_candidate(
        "dl_unscored",
        &Map.drop(&1, ["score", "score_terms"])
      )

    assert {:ok, %{"schema_contract" => "campaign_repair.v2"}} =
             Schema.validate_artifact(unscored_candidate)

    score_drift =
      unscored_candidate
      |> put_in_path(row_path <> ".candidate_score", -100.0)
      |> put_in_path(row_path <> ".ranking_score", -204.2)

    assert {:error, report} = Schema.validate_artifact(score_drift)

    assert Enum.any?(
             report["errors"],
             &(&1["path"] == row_path <> ".candidate_score" and
                 &1["message"] == "must match the exact embedded source candidate score")
           )
  end

  test "binds source candidate scores to their embedded score terms", context do
    score_term_drift =
      context.artifact
      |> put_in_path("$.source_candidate_activities[0].score_terms.contact_value", 999.0)
      |> put_in_path("$.activities[#{context.activity_index}].score_terms.contact_value", 999.0)

    assert {:error, report} = Schema.validate_artifact(score_term_drift)

    assert Enum.any?(
             report["errors"],
             &(&1["path"] == "$.source_candidate_activities[0].score" and
                 &1["message"] == "must equal numeric score_terms sum")
           )
  end

  test "rejects empty or malformed optional pressure evidence", context do
    row_path = ranking_path(context.activity_index) <> ".rows[0]"

    invalid_cases = [
      {row_path <> ".station_calendar_pressure_sources",
       put_in_path(context.artifact, row_path <> ".station_calendar_pressure_sources", [])},
      {row_path <> ".station_calendar_pressure_sources",
       put_in_path(context.artifact, row_path <> ".station_calendar_pressure_sources", [
         "unknown.source"
       ])},
      {row_path <> ".contact_intent_pressure_penalty",
       put_in_path(context.artifact, row_path <> ".contact_intent_pressure_penalty", "invalid")},
      {row_path <> ".contact_intent_pressure_statuses",
       put_in_path(context.artifact, row_path <> ".contact_intent_pressure_statuses", [])},
      {row_path <> ".contact_intent_pressure_statuses",
       put_in_path(context.artifact, row_path <> ".contact_intent_pressure_statuses", [
         "unknown_status"
       ])},
      {row_path <> ".contact_intent_pressure_statuses",
       put_in_path(context.artifact, row_path <> ".contact_intent_pressure_statuses", [
         "cadence_import_missing",
         "blocked_by_policy"
       ])},
      {row_path <> ".contact_intent_pressure_statuses",
       put_in_path(context.artifact, row_path <> ".contact_intent_pressure_statuses", [
         "blocked_by_policy"
       ])},
      {row_path <> ".link_capacity_pressure_shortfall_mb",
       put_in_path(context.artifact, row_path <> ".link_capacity_pressure_shortfall_mb", 0.0)},
      {row_path <> ".link_capacity_pressure_required_downlink_mb",
       put_in_path(
         context.artifact,
         row_path <> ".link_capacity_pressure_required_downlink_mb",
         -1.0
       )},
      {row_path <> ".link_capacity_pressure_selected_capacity_adjusted_throughput_mb",
       put_in_path(
         context.artifact,
         row_path <> ".link_capacity_pressure_selected_capacity_adjusted_throughput_mb",
         -1.0
       )},
      {row_path <> ".resource_projection_pressure_risk_indicators",
       put_in_path(
         context.artifact,
         row_path <> ".resource_projection_pressure_risk_indicators",
         []
       )},
      {row_path <> ".resource_projection_pressure_risk_indicators[0].reason",
       put_in_path(
         context.artifact,
         row_path <> ".resource_projection_pressure_risk_indicators",
         [
           %{
             "type" => "payload_unavailable",
             "severity" => "high",
             "spacecraft_id" => "leo_1"
           }
         ]
       )},
      {row_path <> ".resource_projection_pressure_risk_indicators[0].candidate_id",
       put_in_path(
         context.artifact,
         row_path <> ".resource_projection_pressure_risk_indicators",
         [
           %{
             "type" => "payload_unavailable",
             "severity" => "high",
             "reason" => "payload unavailable",
             "candidate_id" => "different_candidate",
             "spacecraft_id" => "leo_1"
           }
         ]
       )},
      {row_path <> ".resource_projection_pressure_risk_indicators[0].candidate_id",
       put_in_path(
         context.artifact,
         row_path <> ".resource_projection_pressure_risk_indicators",
         [
           %{
             "type" => "payload_unavailable",
             "severity" => "high",
             "reason" => "payload unavailable",
             "candidate_id" => "bad id",
             "spacecraft_id" => "leo_1"
           }
         ]
       )}
    ]

    for {expected_path, invalid} <- invalid_cases do
      assert {:error, report} = Schema.validate_artifact(invalid)
      assert Enum.any?(report["errors"], &(&1["path"] == expected_path))
    end
  end

  test "rejects inconsistent ranking arithmetic, priority, evidence, and order", context do
    ranking_path = ranking_path(context.activity_index)
    row_path = ranking_path <> ".rows[0]"
    [ranking_row] = get_in_path(context.artifact, ranking_path <> ".rows")
    ranking_score = ranking_row["ranking_score"]

    score_order_artifact =
      context.artifact
      |> put_in_path(ranking_path <> ".rows", [
        ranking_row,
        ranking_row
        |> Map.put("candidate_id", "dl_higher_score")
        |> Map.put("candidate_score", 11.0)
        |> Map.put("ranking_score", -93.0)
        |> Map.put("rank", 2)
        |> Map.put("selected", false)
      ])
      |> put_in_path(ranking_path <> ".evaluated_candidate_count", 2)

    priority_order_artifact =
      context.artifact
      |> put_in_path(ranking_path <> ".rows", [
        ranking_row,
        ranking_row
        |> Map.put("candidate_id", "dl_semantic")
        |> Map.put("semantic_candidate_diff_match", true)
        |> Map.put("candidate_diff_priority", 0)
        |> Map.put("rank", 2)
        |> Map.put("selected", false)
      ])
      |> put_in_path(ranking_path <> ".evaluated_candidate_count", 2)

    invalid_cases = [
      {row_path <> ".ranking_score",
       put_in_path(context.artifact, row_path <> ".ranking_score", -93.0)},
      {row_path <> ".candidate_score",
       context.artifact
       |> put_in_path(row_path <> ".candidate_score", 11.0)
       |> put_in_path(row_path <> ".ranking_score", -93.0)},
      {row_path <> ".candidate_diff_priority",
       put_in_path(context.artifact, row_path <> ".semantic_candidate_diff_match", true)},
      {row_path <> ".schedule_churn_penalty",
       context.artifact
       |> put_in_path(row_path <> ".schedule_churn_penalty", -200.0)
       |> put_in_path(row_path <> ".ranking_score", -194.0)},
      {row_path <> ".schedule_move_penalty",
       context.artifact
       |> put_in_path(row_path <> ".schedule_move_penalty", -8.0)
       |> put_in_path(row_path <> ".ranking_score", -98.0)},
      {row_path <> ".schedule_churn_s",
       context.artifact
       |> put_in_path(row_path <> ".schedule_churn_s", 500.0)
       |> put_in_path(row_path <> ".schedule_move_penalty", -5.0)
       |> put_in_path(row_path <> ".ranking_score", -95.0)},
      {row_path <> ".station_calendar_pressure_sources",
       context.artifact
       |> put_in_path(row_path <> ".station_calendar_pressure_penalty", -1.0)
       |> put_in_path(row_path <> ".ranking_score", -95.0)},
      {row_path <> ".station_calendar_pressure_penalty",
       context.artifact
       |> put_in_path(row_path <> ".station_calendar_pressure_penalty", -1.0)
       |> put_in_path(row_path <> ".station_calendar_pressure_sources", [
         "campaign_repair.source_station_calendar_report.affected_contacts"
       ])
       |> put_in_path(row_path <> ".ranking_score", -95.0)},
      {row_path <> ".contact_intent_pressure_statuses",
       context.artifact
       |> put_in_path(row_path <> ".contact_intent_pressure_penalty", -1.0)
       |> put_in_path(row_path <> ".ranking_score", ranking_score - 1.0)},
      {row_path <> ".contact_intent_pressure_penalty",
       context.artifact
       |> put_in_path(row_path <> ".contact_intent_pressure_penalty", -1.0)
       |> put_in_path(row_path <> ".contact_intent_pressure_statuses", ["blocked_by_policy"])
       |> put_in_path(row_path <> ".ranking_score", ranking_score - 1.0)},
      {row_path <> ".link_capacity_pressure_shortfall_mb",
       context.artifact
       |> put_in_path(row_path <> ".link_capacity_pressure_penalty", -1.0)
       |> put_in_path(row_path <> ".ranking_score", -95.0)},
      {row_path <> ".link_capacity_pressure_penalty",
       context.artifact
       |> put_in_path(row_path <> ".link_capacity_pressure_penalty", -2.0)
       |> put_in_path(row_path <> ".link_capacity_pressure_shortfall_mb", 1.0)
       |> put_in_path(row_path <> ".ranking_score", -96.0)},
      {row_path <> ".resource_projection_pressure_risk_indicators",
       context.artifact
       |> put_in_path(row_path <> ".resource_projection_pressure_penalty", -1.0)
       |> put_in_path(row_path <> ".ranking_score", -95.0)},
      {row_path <> ".resource_projection_pressure_penalty",
       context.artifact
       |> put_in_path(row_path <> ".resource_projection_pressure_penalty", -2.0)
       |> put_in_path(row_path <> ".resource_projection_pressure_risk_indicators", [
         %{
           "type" => "payload_unavailable",
           "severity" => "high",
           "reason" => "payload unavailable",
           "spacecraft_id" => "leo_1"
         }
       ])
       |> put_in_path(row_path <> ".ranking_score", -96.0)},
      {ranking_path <> ".rows", score_order_artifact},
      {ranking_path <> ".rows", priority_order_artifact}
    ]

    for {expected_path, invalid} <- invalid_cases do
      assert {:error, report} = Schema.validate_artifact(invalid)
      assert Enum.any?(report["errors"], &(&1["path"] == expected_path))
    end
  end

  defp ranking_path(activity_index),
    do: "$.activities[#{activity_index}].repair.replacement_ranking"

  defp add_unselected_candidate(context, candidate_id, starts_at_s, candidate_score) do
    ranking_path = ranking_path(context.activity_index)
    [selected_row] = get_in_path(context.artifact, ranking_path <> ".rows")

    source_start =
      get_in_path(
        context.artifact,
        "$.activities[#{context.activity_index}].repair.source_activity_context.starts_at_s"
      )

    churn_s = abs(starts_at_s - source_start)
    move_cost = context.artifact["scoring_policy"]["schedule_move_cost_weight"]
    move_penalty = -(churn_s * move_cost)

    row =
      selected_row
      |> Map.put("candidate_id", candidate_id)
      |> Map.put("candidate_score", candidate_score)
      |> Map.put("schedule_churn_s", churn_s)
      |> Map.put("schedule_move_penalty", move_penalty)
      |> Map.put("ranking_score", ranking_score(selected_row, candidate_score, move_penalty))
      |> Map.put("rank", 2)
      |> Map.put("selected", false)

    context
    |> add_source_candidate(candidate_id, starts_at_s, candidate_score)
    |> put_in_path(ranking_path <> ".rows", [selected_row, row])
    |> put_in_path(ranking_path <> ".evaluated_candidate_count", 2)
  end

  defp add_source_candidate(context, candidate_id, starts_at_s, candidate_score) do
    [source_candidate] = context.artifact["source_candidate_activities"]

    candidate =
      source_candidate
      |> Map.put("id", candidate_id)
      |> Map.put("starts_at_s", starts_at_s)
      |> Map.put("ends_at_s", starts_at_s + source_candidate["duration_s"])
      |> Map.put("score", candidate_score)
      |> Map.put("score_terms", %{"contact_value" => candidate_score})
      |> put_in(["cadence_import", "external_id"], candidate_id)

    context.artifact
    |> Map.put("source_candidate_activities", [source_candidate, candidate])
    |> put_in(["repair_metadata", "candidate_window_count"], 2)
    |> put_candidate_source_count(2)
  end

  defp put_candidate_source_count(artifact, count) do
    artifact =
      artifact
      |> put_in(["repair_metadata", "candidate_source", "candidate_count"], count)
      |> put_in(["assumptions", "candidate_source", "candidate_count"], count)
      |> put_in(["provenance", "candidate_source", "candidate_count"], count)

    candidate_source = get_in(artifact, ["repair_metadata", "candidate_source"])

    repair_id =
      RepairMetadata.id(
        %{"plan_id" => artifact["source_plan_id"]},
        artifact["realized_state_snapshot"],
        artifact["current_epoch_s"],
        candidate_source
      )

    artifact
    |> put_in(["repair_metadata", "repair_id"], repair_id)
    |> put_in(["operator_review_package", "provenance", "candidate_source"], candidate_source)
    |> put_in(["operator_review_package", "source_artifact_id"], repair_id)
    |> put_in(["cadence_import_manifest", "source_artifact_id"], repair_id)
    |> put_in(
      ["cadence_import_manifest", "provenance", "source_artifact_id"],
      repair_id
    )
    |> put_in(["cadence_import_manifest", "provenance", "source_repair_id"], repair_id)
  end

  defp ranking_score(selected_row, candidate_score, move_penalty) do
    candidate_score +
      move_penalty +
      Enum.sum([
        selected_row["schedule_churn_penalty"],
        selected_row["station_calendar_pressure_penalty"],
        selected_row["contact_intent_pressure_penalty"],
        selected_row["contact_contention_resolution_pressure_penalty"],
        selected_row["link_capacity_pressure_penalty"],
        selected_row["resource_projection_pressure_penalty"]
      ])
  end

  defp update_source_candidate(artifact, candidate_id, update) do
    Map.update!(artifact, "source_candidate_activities", fn candidates ->
      Enum.map(candidates, fn
        %{"id" => ^candidate_id} = candidate -> update.(candidate)
        candidate -> candidate
      end)
    end)
  end

  defp put_in_path(artifact, path, value) do
    put_in(artifact, path_keys(path), value)
  end

  defp delete_in_path(artifact, path) do
    keys = path_keys(path)
    {field, parent_keys} = List.pop_at(keys, -1)

    update_in(artifact, parent_keys, &Map.delete(&1, field))
  end

  defp get_in_path(artifact, path), do: get_in(artifact, path_keys(path))

  defp path_keys(path) do
    path
    |> String.trim_leading("$.")
    |> String.split(".")
    |> Enum.flat_map(&path_segment/1)
  end

  defp path_segment(segment) do
    case Regex.run(~r/^([^\[]+)\[(\d+)\]$/, segment) do
      [_, key, index] -> [key, Access.at(String.to_integer(index))]
      nil -> [segment]
    end
  end

  defp read_json!(path) do
    path
    |> File.read!()
    |> :json.decode()
  end
end
