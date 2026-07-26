defmodule OrbitalDynamics.Schema.CampaignRepairReplacementRankingContractsTest do
  use ExUnit.Case, async: true

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

    legacy_without_source_timing =
      update_in(
        artifact,
        ["activities", Access.at(activity_index), "repair"],
        &Map.delete(&1, "source_activity_context")
      )

    assert {:ok, %{"schema_contract" => "campaign_repair.v2"}} =
             Schema.validate_artifact(legacy_without_source_timing)

    invalid_legacy_cost =
      legacy_without_source_timing
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

  defp put_in_path(artifact, path, value) do
    put_in(artifact, path_keys(path), value)
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
