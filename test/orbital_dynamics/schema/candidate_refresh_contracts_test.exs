defmodule OrbitalDynamics.Schema.CandidateRefreshContractsTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.Schema

  test "validates the embedded remaining horizon timing contract" do
    artifact = candidate_refresh_artifact()

    assert {:ok, %{"schema_contract" => "candidate_refresh.v1"}} =
             Schema.validate_artifact(artifact)

    assert {:ok, %{"schema_contract" => "candidate_refresh.v1"}} =
             artifact
             |> put_in(
               ["remaining_horizon"],
               Map.merge(artifact["remaining_horizon"], %{
                 "schema_contract" => "remaining_horizon.v1",
                 "duration_s" => 600.0
               })
             )
             |> Schema.validate_artifact()

    invalid_cases = [
      {Map.delete(artifact["remaining_horizon"], "starts_at_s"),
       "$.remaining_horizon.starts_at_s"},
      {Map.put(artifact["remaining_horizon"], "output_step_s", 0.0),
       "$.remaining_horizon.output_step_s"},
      {Map.put(artifact["remaining_horizon"], "output_step_s", 601.0),
       "$.remaining_horizon.output_step_s"},
      {Map.put(artifact["remaining_horizon"], "schema_contract", "unexpected.v1"),
       "$.remaining_horizon.schema_contract"},
      {Map.put(artifact["remaining_horizon"], "duration_s", 599.0),
       "$.remaining_horizon.duration_s"}
    ]

    Enum.each(invalid_cases, fn {remaining_horizon, path} ->
      assert {:error, report} =
               artifact
               |> Map.put("remaining_horizon", remaining_horizon)
               |> Schema.validate_artifact()

      assert Enum.any?(report["errors"], &(&1["path"] == path))
    end)

    assert {:error, report} =
             artifact
             |> Map.put("remaining_horizon", [])
             |> Schema.validate_artifact()

    assert Enum.any?(report["errors"], &(&1["path"] == "$.remaining_horizon"))
  end

  test "exports a typed embedded remaining horizon schema" do
    assert {:ok, schema} = Schema.json_schema("candidate_refresh.v1")
    remaining_horizon = get_in(schema, ["properties", "remaining_horizon"])

    assert remaining_horizon["required"] == ["starts_at_s", "ends_at_s", "output_step_s"]
    assert get_in(remaining_horizon, ["properties", "starts_at_s", "type"]) == "number"
    assert get_in(remaining_horizon, ["properties", "ends_at_s", "type"]) == "number"

    assert get_in(remaining_horizon, ["properties", "output_step_s", "exclusiveMinimum"]) ==
             0

    assert get_in(remaining_horizon, ["properties", "schema_contract", "const"]) ==
             "remaining_horizon.v1"
  end

  test "validates the accepted planning-state fleet reference" do
    artifact = candidate_refresh_artifact()

    assert {:ok, %{"schema_contract" => "candidate_refresh.v1"}} =
             artifact
             |> update_in(["accepted_planning_state"], fn accepted_state ->
               Map.merge(accepted_state, %{
                 "accepted_at" => "2026-05-14T00:00:00Z",
                 "maneuver_execution_delta_count" => 0,
                 "source_family" => "fleet_snapshot"
               })
             end)
             |> Schema.validate_artifact()

    invalid_cases = [
      {Map.delete(artifact["accepted_planning_state"], "snapshot_id"),
       "$.accepted_planning_state.snapshot_id"},
      {Map.put(artifact["accepted_planning_state"], "snapshot_id", "invalid id"),
       "$.accepted_planning_state.snapshot_id"},
      {Map.put(artifact["accepted_planning_state"], "spacecraft_state_count", -1),
       "$.accepted_planning_state.spacecraft_state_count"},
      {Map.put(artifact["accepted_planning_state"], "accepted_at", 5),
       "$.accepted_planning_state.accepted_at"},
      {Map.put(artifact["accepted_planning_state"], "maneuver_execution_delta_count", -1),
       "$.accepted_planning_state.maneuver_execution_delta_count"}
    ]

    Enum.each(invalid_cases, fn {accepted_state, path} ->
      assert {:error, report} =
               artifact
               |> Map.put("accepted_planning_state", accepted_state)
               |> Schema.validate_artifact()

      assert Enum.any?(report["errors"], &(&1["path"] == path))
    end)
  end

  test "exports a typed accepted planning-state reference schema" do
    assert {:ok, schema} = Schema.json_schema("candidate_refresh.v1")
    accepted_state = get_in(schema, ["properties", "accepted_planning_state"])

    assert accepted_state["required"] == ["snapshot_id", "spacecraft_state_count"]
    assert get_in(accepted_state, ["properties", "snapshot_id", "pattern"])

    assert get_in(accepted_state, ["properties", "spacecraft_state_count"]) == %{
             "type" => "integer",
             "minimum" => 0
           }

    assert get_in(accepted_state, ["properties", "maneuver_execution_delta_count"]) == %{
             "type" => "integer",
             "minimum" => 0
           }
  end

  test "exports nested candidate refresh source-window lineage schema" do
    assert {:ok, schema} = Schema.json_schema("candidate_refresh.v1")

    lineage_schema = get_in(schema, ["properties", "source_window_lineage", "items"])

    assert lineage_schema["type"] == "object"

    assert lineage_schema["required"] == [
             "candidate_activity_id",
             "source_window_id",
             "source_window_type",
             "scenario_id"
           ]

    assert get_in(lineage_schema, ["properties", "candidate_activity_id", "pattern"]) ==
             Schema.identity_policy()["stable_id_pattern"]

    assert get_in(lineage_schema, ["properties", "source_window_id", "pattern"]) ==
             Schema.identity_policy()["stable_id_pattern"]

    assert get_in(lineage_schema, ["properties", "source_window_type", "type"]) == "string"

    assert get_in(lineage_schema, ["properties", "collection_id", "pattern"]) ==
             Schema.identity_policy()["stable_id_pattern"]

    assert get_in(lineage_schema, ["properties", "source_activity_ids", "items", "pattern"]) ==
             Schema.identity_policy()["stable_id_pattern"]

    assert get_in(lineage_schema, [
             "properties",
             "source_window",
             "properties",
             "required_downlink_mb",
             "minimum"
           ]) == 0

    assert get_in(lineage_schema, [
             "properties",
             "source_window",
             "properties",
             "downlink_completion_ratio",
             "maximum"
           ]) == 1
  end

  test "exports nested candidate refresh source-report provenance schema" do
    assert {:ok, schema} = Schema.json_schema("candidate_refresh.v1")

    summary_schema =
      get_in(schema, [
        "properties",
        "provenance",
        "properties",
        "source_reports",
        "additionalProperties"
      ])

    assert summary_schema["type"] == "object"

    assert get_in(summary_schema, [
             "properties",
             "resource_availability_pressure_count",
             "minimum"
           ]) == 0

    assert get_in(summary_schema, [
             "properties",
             "resource_availability_reason_counts",
             "additionalProperties",
             "minimum"
           ]) == 0

    assert get_in(summary_schema, [
             "properties",
             "resource_availability_reason_ids",
             "items",
             "type"
           ]) == "string"

    assert get_in(summary_schema, [
             "properties",
             "station_availability_reason_ids",
             "items",
             "type"
           ]) == "string"

    assert get_in(summary_schema, [
             "properties",
             "station_availability_reason_counts",
             "additionalProperties",
             "minimum"
           ]) == 0

    assert get_in(summary_schema, [
             "properties",
             "unavailable_resource_reason_ids",
             "items",
             "type"
           ]) == "string"

    assert get_in(summary_schema, [
             "properties",
             "resource_blocking_dimension_counts",
             "additionalProperties",
             "minimum"
           ]) == 0

    assert get_in(summary_schema, [
             "properties",
             "invalid_resource_summary_input_ids",
             "items",
             "type"
           ]) == "string"

    assert get_in(summary_schema, [
             "properties",
             "invalid_contact_input_ids",
             "items",
             "type"
           ]) == "string"

    assert get_in(summary_schema, [
             "properties",
             "invalid_activity_input_count",
             "minimum"
           ]) == 0

    assert get_in(summary_schema, [
             "properties",
             "invalid_activity_input_reason_counts",
             "additionalProperties",
             "minimum"
           ]) == 0

    assert get_in(summary_schema, [
             "properties",
             "invalid_activity_input_reasons",
             "items",
             "type"
           ]) == "string"

    publication_lineage_fields = [
      "source_report_timeline_publication_impacted_source_activity_ids",
      "source_report_timeline_publication_impacted_source_timeline_ids",
      "source_report_timeline_publication_dependent_activity_ids",
      "source_report_timeline_publication_dependent_timeline_ids",
      "source_report_timeline_publication_source_dependent_activity_ids",
      "source_report_timeline_publication_source_dependent_timeline_ids",
      "source_report_timeline_publication_replacement_dependent_activity_ids",
      "source_report_timeline_publication_replacement_dependent_timeline_ids"
    ]

    for field <- publication_lineage_fields do
      assert get_in(schema, ["properties", field, "type"]) == "array"

      assert get_in(schema, ["properties", field, "items", "pattern"]) ==
               Schema.identity_policy()["stable_id_pattern"]
    end

    assert get_in(schema, [
             "properties",
             "source_report_timeline_publication_downstream_invalidation_reason_counts",
             "additionalProperties",
             "minimum"
           ]) == 0

    assert get_in(schema, [
             "properties",
             "source_report_timeline_publication_invalidated_downstream_product_ids_by_reason",
             "additionalProperties",
             "items",
             "pattern"
           ]) == Schema.identity_policy()["stable_id_pattern"]

    named_freshness_schema =
      get_in(schema, [
        "properties",
        "provenance",
        "properties",
        "source_reports",
        "properties",
        "freshness_report"
      ])

    assert named_freshness_schema["type"] == "object"

    assert get_in(named_freshness_schema, [
             "properties",
             "stale_reason_count",
             "minimum"
           ]) == 0

    assert get_in(named_freshness_schema, [
             "properties",
             "status_counts",
             "additionalProperties",
             "minimum"
           ]) == 0

    assert get_in(named_freshness_schema, [
             "properties",
             "stale_reasons",
             "items",
             "type"
           ]) == "string"

    named_objective_satisfaction_schema =
      get_in(schema, [
        "properties",
        "provenance",
        "properties",
        "source_reports",
        "properties",
        "objective_satisfaction_report"
      ])

    named_objective_tradeoff_schema =
      get_in(schema, [
        "properties",
        "provenance",
        "properties",
        "source_reports",
        "properties",
        "objective_tradeoff_report"
      ])

    named_score_term_schema =
      get_in(schema, [
        "properties",
        "provenance",
        "properties",
        "source_reports",
        "properties",
        "score_term_report"
      ])

    Enum.each(
      [
        named_objective_satisfaction_schema,
        named_objective_tradeoff_schema,
        named_score_term_schema
      ],
      fn named_schema ->
        assert named_schema["type"] == "object"

        assert get_in(named_schema, [
                 "properties",
                 "downlink_gap_row_count",
                 "minimum"
               ]) == 0

        assert get_in(named_schema, [
                 "properties",
                 "source_activity_id_counts",
                 "additionalProperties",
                 "minimum"
               ]) == 0
      end
    )

    assert get_in(named_objective_satisfaction_schema, [
             "properties",
             "objective_type_counts",
             "additionalProperties",
             "minimum"
           ]) == 0

    assert get_in(named_score_term_schema, [
             "properties",
             "term_key_counts",
             "additionalProperties",
             "minimum"
           ]) == 0

    named_refresh_budget_schema =
      get_in(schema, [
        "properties",
        "provenance",
        "properties",
        "source_reports",
        "properties",
        "refresh_budget_report"
      ])

    assert named_refresh_budget_schema["type"] == "object"

    assert get_in(named_refresh_budget_schema, [
             "properties",
             "input_candidate_count",
             "minimum"
           ]) == 0

    assert get_in(named_refresh_budget_schema, [
             "properties",
             "invalid_candidate_limit_policy_reason_counts",
             "additionalProperties",
             "minimum"
           ]) == 0

    assert get_in(named_refresh_budget_schema, [
             "properties",
             "kept_candidate_ids",
             "items",
             "pattern"
           ]) == Schema.identity_policy()["stable_id_pattern"]

    assert get_in(schema, [
             "properties",
             "provenance",
             "properties",
             "run_input_sources",
             "additionalProperties",
             "items",
             "type"
           ]) == "string"
  end

  test "validates CandidateRefresh run-input source provenance" do
    artifact =
      candidate_refresh_artifact()
      |> put_in(
        ["provenance", "run_input_sources"],
        %{"campaign_request" => ["studies/leo_campaign.json"]}
      )

    assert {:ok, %{"schema_contract" => "candidate_refresh.v1"}} =
             Schema.validate_artifact(artifact)

    invalid_sources =
      put_in(
        artifact,
        ["provenance", "run_input_sources", "campaign_request", Access.at(0)],
        42
      )

    assert {:error, report} = Schema.validate_artifact(invalid_sources)

    assert Enum.any?(
             report["errors"],
             &(&1["path"] == "$.provenance.run_input_sources.campaign_request[0]")
           )
  end

  test "validates named candidate refresh objective-gap source-report provenance schemas" do
    artifact =
      candidate_refresh_artifact()
      |> put_in(
        ["provenance", "source_reports"],
        %{
          "objective_satisfaction_report" => %{
            "paths" => ["source_objective_satisfaction_report"],
            "contract" => "objective_satisfaction_report.v1",
            "count" => 1,
            "row_count" => 3,
            "gap_row_count" => 3,
            "downlink_gap_row_count" => 1,
            "target_gap_row_count" => 1,
            "collection_latency_gap_row_count" => 1,
            "status_counts" => %{"partial" => 2, "unmet" => 1},
            "objective_type_counts" => %{"downlink_completion" => 1},
            "ground_station_counts" => %{"equator_prime" => 1},
            "target_counts" => %{"target_alpha" => 1},
            "collection_counts" => %{"collection_day_1" => 1},
            "source_activity_id_counts" => %{"dl_gap_activity" => 1}
          },
          "objective_tradeoff_report" => %{
            "paths" => ["source_objective_tradeoff_report"],
            "contract" => "objective_tradeoff_report.v1",
            "count" => 1,
            "row_count" => 2,
            "downlink_gap_row_count" => 1,
            "target_gap_row_count" => 1,
            "collection_latency_gap_row_count" => 0,
            "ground_station_counts" => %{"equator_prime" => 1},
            "target_counts" => %{"target_alpha" => 1},
            "collection_counts" => %{},
            "source_activity_id_counts" => %{"tradeoff_gap_activity" => 1}
          },
          "score_term_report" => %{
            "paths" => ["source_score_term_report"],
            "contract" => "score_term_report.v1",
            "count" => 1,
            "row_count" => 3,
            "downlink_gap_row_count" => 1,
            "target_gap_row_count" => 1,
            "collection_latency_gap_row_count" => 1,
            "term_key_counts" => %{"downlink_shortfall_mb" => 1},
            "ground_station_counts" => %{"equator_prime" => 1},
            "target_counts" => %{"target_alpha" => 1},
            "collection_counts" => %{"collection_day_1" => 1},
            "source_activity_id_counts" => %{"score_gap_activity" => 1}
          }
        }
      )

    assert {:ok, %{"schema_contract" => "candidate_refresh.v1"}} =
             Schema.validate_artifact(artifact)

    invalid_objective_gap_count =
      put_in(
        artifact,
        [
          "provenance",
          "source_reports",
          "objective_satisfaction_report",
          "gap_row_count"
        ],
        -1
      )

    assert {:error, invalid_objective_gap_count_report} =
             Schema.validate_artifact(invalid_objective_gap_count)

    assert Enum.any?(
             invalid_objective_gap_count_report["errors"],
             &(&1["path"] ==
                 "$.provenance.source_reports.objective_satisfaction_report.gap_row_count")
           )

    invalid_tradeoff_activity_count =
      put_in(
        artifact,
        [
          "provenance",
          "source_reports",
          "objective_tradeoff_report",
          "source_activity_id_counts",
          "tradeoff_gap_activity"
        ],
        -1
      )

    assert {:error, invalid_tradeoff_activity_count_report} =
             Schema.validate_artifact(invalid_tradeoff_activity_count)

    assert Enum.any?(
             invalid_tradeoff_activity_count_report["errors"],
             &(&1["path"] ==
                 "$.provenance.source_reports.objective_tradeoff_report.source_activity_id_counts.tradeoff_gap_activity")
           )

    invalid_score_term_count =
      put_in(
        artifact,
        [
          "provenance",
          "source_reports",
          "score_term_report",
          "term_key_counts",
          "downlink_shortfall_mb"
        ],
        -1
      )

    assert {:error, invalid_score_term_count_report} =
             Schema.validate_artifact(invalid_score_term_count)

    assert Enum.any?(
             invalid_score_term_count_report["errors"],
             &(&1["path"] ==
                 "$.provenance.source_reports.score_term_report.term_key_counts.downlink_shortfall_mb")
           )
  end

  test "validates named candidate refresh freshness source-report provenance schema" do
    artifact =
      candidate_refresh_artifact()
      |> put_in(
        ["provenance", "source_reports"],
        %{
          "freshness_report" => %{
            "paths" => ["mission_state.source_freshness_report"],
            "contract" => "freshness_report.v1",
            "count" => 1,
            "row_count" => 1,
            "status_counts" => %{"stale" => 1},
            "stale_reason_count" => 1,
            "stale_reasons" => ["accepted_snapshot_older_than_policy"],
            "stale_reason_counts" => %{"accepted_snapshot_older_than_policy" => 1},
            "unknown_reason_count" => 1,
            "unknown_reasons" => ["missing_generated_at"],
            "unknown_reason_counts" => %{"missing_generated_at" => 1},
            "trust_boundary_status" => "declared",
            "trust_boundaries" => ["ops_freshness"]
          }
        }
      )

    assert {:ok, %{"schema_contract" => "candidate_refresh.v1"}} =
             Schema.validate_artifact(artifact)

    invalid_status_count =
      put_in(
        artifact,
        [
          "provenance",
          "source_reports",
          "freshness_report",
          "status_counts",
          "stale"
        ],
        -1
      )

    assert {:error, invalid_status_count_report} =
             Schema.validate_artifact(invalid_status_count)

    assert Enum.any?(
             invalid_status_count_report["errors"],
             &(&1["path"] ==
                 "$.provenance.source_reports.freshness_report.status_counts.stale")
           )

    invalid_reason_count =
      put_in(
        artifact,
        [
          "provenance",
          "source_reports",
          "freshness_report",
          "stale_reason_count"
        ],
        -1
      )

    assert {:error, invalid_reason_count_report} =
             Schema.validate_artifact(invalid_reason_count)

    assert Enum.any?(
             invalid_reason_count_report["errors"],
             &(&1["path"] ==
                 "$.provenance.source_reports.freshness_report.stale_reason_count")
           )

    invalid_reason =
      put_in(
        artifact,
        [
          "provenance",
          "source_reports",
          "freshness_report",
          "stale_reasons",
          Access.at(0)
        ],
        42
      )

    assert {:error, invalid_reason_report} = Schema.validate_artifact(invalid_reason)

    assert Enum.any?(
             invalid_reason_report["errors"],
             &(&1["path"] == "$.provenance.source_reports.freshness_report.stale_reasons[0]")
           )
  end

  test "validates named candidate refresh refresh-budget source-report provenance schema" do
    artifact =
      candidate_refresh_artifact()
      |> put_in(
        ["provenance", "source_reports"],
        %{
          "refresh_budget_report" => %{
            "paths" => ["mission_state.source_refresh_budget_report"],
            "contract" => "refresh_budget_report.v1",
            "count" => 1,
            "row_count" => 1,
            "input_candidate_count" => 4,
            "kept_candidate_count" => 2,
            "dropped_candidate_count" => 2,
            "invalid_candidate_limit_policy_count" => 1,
            "invalid_candidate_limit_policy_reason_counts" => %{
              "max_candidate_activities_must_be_integer" => 1
            },
            "kept_candidate_ids" => ["candidate_a", "candidate_b"],
            "dropped_candidate_ids" => ["candidate_c", "candidate_d"],
            "trust_boundary_status" => "declared",
            "trust_boundaries" => ["ops_refresh_budget"]
          }
        }
      )

    assert {:ok, %{"schema_contract" => "candidate_refresh.v1"}} =
             Schema.validate_artifact(artifact)

    invalid_reason_count =
      put_in(
        artifact,
        [
          "provenance",
          "source_reports",
          "refresh_budget_report",
          "invalid_candidate_limit_policy_reason_counts",
          "max_candidate_activities_must_be_integer"
        ],
        -1
      )

    assert {:error, invalid_reason_count_report} =
             Schema.validate_artifact(invalid_reason_count)

    assert Enum.any?(
             invalid_reason_count_report["errors"],
             &(&1["path"] ==
                 "$.provenance.source_reports.refresh_budget_report.invalid_candidate_limit_policy_reason_counts.max_candidate_activities_must_be_integer")
           )

    invalid_candidate_id =
      put_in(
        artifact,
        [
          "provenance",
          "source_reports",
          "refresh_budget_report",
          "kept_candidate_ids",
          Access.at(0)
        ],
        "bad candidate id"
      )

    assert {:error, invalid_candidate_id_report} = Schema.validate_artifact(invalid_candidate_id)

    assert Enum.any?(
             invalid_candidate_id_report["errors"],
             &(&1["path"] ==
                 "$.provenance.source_reports.refresh_budget_report.kept_candidate_ids[0]")
           )
  end

  test "exports nested candidate refresh invalidated candidate schema" do
    assert {:ok, schema} = Schema.json_schema("candidate_refresh.v1")

    invalidated_schema = get_in(schema, ["properties", "invalidated_candidates", "items"])

    assert invalidated_schema["type"] == "object"
    assert invalidated_schema["required"] == ["id", "invalidated_reason"]

    assert get_in(invalidated_schema, ["properties", "id", "pattern"]) ==
             Schema.identity_policy()["stable_id_pattern"]

    assert get_in(invalidated_schema, ["properties", "replacement_candidate_id", "pattern"]) ==
             Schema.identity_policy()["stable_id_pattern"]

    assert get_in(invalidated_schema, ["properties", "source_window_id", "pattern"]) ==
             Schema.identity_policy()["stable_id_pattern"]

    assert get_in(invalidated_schema, ["properties", "semantic_change_reasons", "items", "type"]) ==
             "string"
  end

  test "exports nested candidate refresh candidate activity schema" do
    assert {:ok, schema} = Schema.json_schema("candidate_refresh.v1")

    activity_schema = get_in(schema, ["properties", "candidate_activities", "items"])

    assert activity_schema["type"] == "object"

    assert activity_schema["required"] == [
             "id",
             "type",
             "scenario_id",
             "starts_at_s",
             "ends_at_s",
             "duration_s",
             "score",
             "score_terms",
             "source_window_id",
             "source_window"
           ]

    assert get_in(activity_schema, ["properties", "id", "pattern"]) ==
             Schema.identity_policy()["stable_id_pattern"]

    assert get_in(activity_schema, ["properties", "scenario_id", "pattern"]) ==
             Schema.identity_policy()["stable_id_pattern"]

    assert get_in(activity_schema, ["properties", "target_id", "pattern"]) ==
             Schema.identity_policy()["stable_id_pattern"]

    assert get_in(activity_schema, ["properties", "ground_station_id", "pattern"]) ==
             Schema.identity_policy()["stable_id_pattern"]

    assert get_in(activity_schema, ["properties", "source_window_id", "pattern"]) ==
             Schema.identity_policy()["stable_id_pattern"]

    assert get_in(activity_schema, ["properties", "schema_contract", "const"]) ==
             "candidate_activity.v1"

    assert get_in(activity_schema, ["properties", "spacecraft_id", "pattern"]) ==
             Schema.identity_policy()["stable_id_pattern"]

    assert get_in(activity_schema, ["properties", "collection_id", "pattern"]) ==
             Schema.identity_policy()["stable_id_pattern"]

    assert get_in(activity_schema, ["properties", "payload_id", "pattern"]) ==
             Schema.identity_policy()["stable_id_pattern"]

    assert get_in(activity_schema, ["properties", "instrument_id", "pattern"]) ==
             Schema.identity_policy()["stable_id_pattern"]

    assert get_in(activity_schema, ["properties", "product_ids", "items", "pattern"]) ==
             Schema.identity_policy()["stable_id_pattern"]

    assert get_in(activity_schema, ["properties", "score_terms", "type"]) == "object"
    assert get_in(activity_schema, ["properties", "source_window", "type"]) == "object"

    assert get_in(activity_schema, ["properties", "target_priority", "type"]) == "number"

    assert get_in(activity_schema, ["properties", "observation_objective_count", "type"]) ==
             "integer"

    assert get_in(activity_schema, ["properties", "observation_objective_types", "items", "type"]) ==
             "string"

    assert get_in(activity_schema, [
             "properties",
             "collection_latency_objective_count",
             "type"
           ]) == "integer"

    assert get_in(activity_schema, [
             "properties",
             "collection_latency_objective_types",
             "items",
             "type"
           ]) == "string"

    assert get_in(activity_schema, ["properties", "required_downlink_mb", "minimum"]) == 0

    assert get_in(activity_schema, ["properties", "station_contention_status", "type"]) ==
             "string"

    assert get_in(activity_schema, ["properties", "station_reservation_id", "pattern"]) ==
             Schema.identity_policy()["stable_id_pattern"]

    assert get_in(activity_schema, ["properties", "station_reserved_by", "type"]) == "string"

    assert get_in(activity_schema, ["properties", "station_reservation_status", "type"]) ==
             "string"

    assert get_in(activity_schema, ["properties", "eclipse_overlap_fraction"]) == %{
             "type" => "number",
             "minimum" => 0.0,
             "maximum" => 1.0
           }

    assert get_in(activity_schema, ["properties", "lighting_condition_detail", "type"]) ==
             "string"

    assert get_in(activity_schema, ["properties", "lighting_detail_model", "type"]) == "string"

    assert get_in(activity_schema, ["properties", "lighting_confidence", "type"]) == [
             "number",
             "string"
           ]

    assert get_in(activity_schema, [
             "properties",
             "source_window",
             "properties",
             "id",
             "pattern"
           ]) == Schema.identity_policy()["stable_id_pattern"]

    assert get_in(activity_schema, ["properties", "direction", "enum"]) == [
             "downlink",
             "uplink",
             "command",
             "tracking",
             "health_check"
           ]
  end

  test "exports nested candidate refresh contact intent and resource summary schemas" do
    assert {:ok, schema} = Schema.json_schema("candidate_refresh.v1")

    assert get_in(schema, ["properties", "warnings", "items", "type"]) == "string"

    validation_record_schema = get_in(schema, ["properties", "validation_records", "items"])

    assert get_in(validation_record_schema, ["properties", "id", "pattern"]) ==
             Schema.identity_policy()["stable_id_pattern"]

    assert get_in(validation_record_schema, ["properties", "evidence", "items", "type"]) ==
             "string"

    assert get_in(validation_record_schema, ["properties", "known_limits", "items", "type"]) ==
             "string"

    assert Enum.any?(
             validation_record_schema["allOf"],
             &(get_in(&1, ["if", "properties", "id", "const"]) == "propagator.two_body" and
                 get_in(&1, ["then", "properties", "model", "const"]) == "point_mass_two_body")
           )

    intent_schema = get_in(schema, ["properties", "contact_intents", "items"])

    assert intent_schema["required"] == [
             "schema_contract",
             "id",
             "activity_id",
             "scenario_id",
             "ground_station_id",
             "direction",
             "starts_at_s",
             "ends_at_s"
           ]

    assert get_in(intent_schema, ["properties", "schema_contract", "const"]) ==
             "contact_intent.v1"

    assert get_in(intent_schema, ["properties", "ground_station_id", "pattern"]) ==
             Schema.identity_policy()["stable_id_pattern"]

    assert get_in(intent_schema, ["properties", "timeline_id", "pattern"]) ==
             Schema.identity_policy()["stable_id_pattern"]

    assert get_in(intent_schema, [
             "properties",
             "timeline_identity",
             "properties",
             "timeline_id",
             "pattern"
           ]) == Schema.identity_policy()["stable_id_pattern"]

    assert get_in(intent_schema, ["properties", "station_reservation_id", "pattern"]) ==
             Schema.identity_policy()["stable_id_pattern"]

    assert get_in(intent_schema, ["properties", "station_contention_status", "type"]) == "string"

    assert get_in(intent_schema, ["properties", "direction", "enum"]) == [
             "downlink",
             "uplink",
             "command",
             "tracking",
             "health_check"
           ]

    assert get_in(intent_schema, [
             "properties",
             "approval_requirements",
             "items",
             "properties",
             "schema_contract",
             "const"
           ]) == "approval_requirement.v1"

    assert get_in(intent_schema, [
             "properties",
             "approval_rule_matches",
             "items",
             "properties",
             "rule_id",
             "pattern"
           ]) == Schema.identity_policy()["stable_id_pattern"]

    resource_schema = get_in(schema, ["properties", "resource_summaries", "items"])

    assert resource_schema["required"] == ["schema_contract", "spacecraft_id"]

    assert get_in(resource_schema, ["properties", "schema_contract", "const"]) ==
             "resource_summary.v1"

    assert get_in(resource_schema, ["properties", "spacecraft_id", "pattern"]) ==
             Schema.identity_policy()["stable_id_pattern"]

    assert get_in(resource_schema, ["properties", "payload_available", "type"]) == "boolean"
    assert get_in(resource_schema, ["properties", "storage_capacity_mb", "type"]) == "number"
    assert get_in(resource_schema, ["properties", "storage_capacity_mb", "minimum"]) == 0.0
    assert get_in(resource_schema, ["properties", "battery_capacity_wh", "type"]) == "number"

    assert get_in(resource_schema, ["properties", "battery_capacity_wh", "minimum"]) == 0.0

    assert get_in(resource_schema, ["properties", "battery_state_of_charge", "maximum"]) == 1.0
    assert get_in(resource_schema, ["properties", "thermal_margin_c", "type"]) == "number"
    assert get_in(resource_schema, ["properties", "spacecraft_available", "type"]) == "boolean"
    assert get_in(resource_schema, ["properties", "source_quality", "type"]) == "string"
    assert get_in(resource_schema, ["properties", "trust_boundary", "type"]) == "string"

    assert get_in(resource_schema, [
             "properties",
             "suppressed_activity_types",
             "items",
             "type"
           ]) == "string"

    assert get_in(resource_schema, [
             "properties",
             "incompatible_activity_types",
             "items",
             "type"
           ]) == "string"
  end

  test "validates candidate refresh contact and resource filter reports" do
    artifact = candidate_refresh_artifact()

    assert {:ok, %{"schema_contract" => "candidate_refresh.v1"}} =
             Schema.validate_artifact(artifact)

    invalid_feedback =
      put_in(artifact, ["operational_feedback"], %{
        "image_quality_score" => %{"target_a" => 1.2},
        "image_quality_status" => %{"target_a" => 5}
      })

    assert {:error, report} = Schema.validate_artifact(invalid_feedback)

    assert Enum.any?(
             report["errors"],
             &(&1["path"] == "$.operational_feedback.image_quality_score.target_a")
           )

    assert Enum.any?(
             report["errors"],
             &(&1["path"] == "$.operational_feedback.image_quality_status.target_a")
           )

    invalid_resource =
      put_in(
        artifact,
        ["resource_filter_report", "suppressed_candidates", Access.at(0)],
        %{"id" => "bad", "type" => "observe", "scenario_id" => "leo_1"}
      )

    assert {:error, report} = Schema.validate_artifact(invalid_resource)

    assert Enum.any?(
             report["errors"],
             &(&1["path"] ==
                 "$.resource_filter_report.suppressed_candidates[0].suppressed_reason")
           )

    invalid_contact =
      put_in(
        artifact,
        ["contact_filter_report", "suppressed_candidates", Access.at(0)],
        %{"id" => "bad", "type" => "downlink", "scenario_id" => "leo_1"}
      )

    assert {:error, report} = Schema.validate_artifact(invalid_contact)

    assert Enum.any?(
             report["errors"],
             &(&1["path"] ==
                 "$.contact_filter_report.suppressed_candidates[0].suppressed_reason")
           )

    invalid_diff =
      put_in(
        artifact,
        ["candidate_diff_report", "new_candidates", Access.at(0)],
        %{"id" => "bad", "type" => "observe", "scenario_id" => "leo_1"}
      )

    assert {:error, report} = Schema.validate_artifact(invalid_diff)

    assert Enum.any?(
             report["errors"],
             &(&1["path"] == "$.candidate_diff_report.new_candidates[0].diff_reason")
           )

    invalid_freshness =
      put_in(artifact, ["freshness_report", "status"], "maybe_current")

    assert {:error, report} = Schema.validate_artifact(invalid_freshness)

    assert Enum.any?(
             report["errors"],
             &(&1["path"] == "$.freshness_report.status")
           )

    invalid_refresh_budget =
      artifact
      |> Map.put(
        "refresh_budget_report",
        read_json!("study_results/refresh_budget_report_v1.json")
      )
      |> put_in(["refresh_budget_report", "kept_candidate_count"], 99)

    assert {:error, report} = Schema.validate_artifact(invalid_refresh_budget)

    assert Enum.any?(
             report["errors"],
             &(&1["path"] == "$.refresh_budget_report.kept_candidate_count")
           )

    invalid_lineage =
      put_in(
        artifact,
        ["source_window_lineage", Access.at(0)],
        %{
          "candidate_activity_id" => "observe_1",
          "source_window_id" => "window_1",
          "scenario_id" => "leo_1"
        }
      )

    assert {:error, report} = Schema.validate_artifact(invalid_lineage)

    assert Enum.any?(
             report["errors"],
             &(&1["path"] == "$.source_window_lineage[0].source_window_type")
           )

    invalid_invalidated_candidate =
      put_in(
        artifact,
        ["invalidated_candidates", Access.at(0)],
        %{"id" => "old_observe_1"}
      )

    assert {:error, report} = Schema.validate_artifact(invalid_invalidated_candidate)

    assert Enum.any?(
             report["errors"],
             &(&1["path"] == "$.invalidated_candidates[0].invalidated_reason")
           )
  end

  test "validates standalone candidate refresh nested fixtures" do
    fixtures = [
      {"study_results/candidate_diff_row_v1.json", "candidate_diff_row.v1"},
      {"study_results/freshness_report_v1.json", "freshness_report.v1"},
      {"study_results/invalidated_candidate_v1.json", "invalidated_candidate.v1"},
      {"study_results/refresh_budget_report_v1.json", "refresh_budget_report.v1"},
      {"study_results/refreshed_window_v1.json", "refreshed_window.v1"},
      {"study_results/remaining_horizon_v1.json", "remaining_horizon.v1"},
      {"study_results/candidate_activity_v1.json", "candidate_activity.v1"},
      {"study_results/candidate_diff_report_v1.json", "candidate_diff_report.v1"},
      {"study_results/source_window_lineage_v1.json", "source_window_lineage.v1"}
    ]

    Enum.each(fixtures, fn {path, contract} ->
      assert {:ok, %{"schema_contract" => ^contract}} =
               path
               |> read_json!()
               |> Schema.validate_artifact()
    end)

    invalid_diff =
      "study_results/candidate_diff_row_v1.json"
      |> read_json!()
      |> Map.put("diff_reason", "surprising_change")

    assert {:error, diff_report} = Schema.validate_artifact(invalid_diff)
    assert Enum.any?(diff_report["errors"], &(&1["path"] == "$.diff_reason"))

    candidate_diff_report = read_json!("study_results/candidate_diff_report_v1.json")

    assert {:ok, candidate_diff_schema} = Schema.json_schema("candidate_diff_report.v1")
    assert {:ok, candidate_diff_row_schema} = Schema.json_schema("candidate_diff_row.v1")
    assert {:ok, candidate_activity_schema} = Schema.json_schema("candidate_activity.v1")
    assert {:ok, freshness_schema} = Schema.json_schema("freshness_report.v1")
    assert {:ok, refresh_budget_schema} = Schema.json_schema("refresh_budget_report.v1")
    assert {:ok, refreshed_window_schema} = Schema.json_schema("refreshed_window.v1")

    Enum.each(["cloud_cover_fraction", "blur_score"], fn field ->
      assert get_in(candidate_activity_schema, ["properties", field]) == %{
               "type" => "number",
               "minimum" => 0.0,
               "maximum" => 1.0
             }
    end)

    assert get_in(candidate_diff_row_schema, ["properties", "collection_id", "pattern"]) ==
             Schema.identity_policy()["stable_id_pattern"]

    assert get_in(candidate_diff_row_schema, [
             "properties",
             "source_activity_ids",
             "items",
             "pattern"
           ]) == Schema.identity_policy()["stable_id_pattern"]

    assert get_in(candidate_diff_row_schema, [
             "properties",
             "downlink_completion_ratio",
             "maximum"
           ]) == 1

    assert get_in(candidate_diff_schema, ["properties", "model_limits", "items", "enum"]) ==
             OrbitalDynamics.CandidateRefresh.model_limits()

    assert get_in(freshness_schema, ["properties", "model_limits", "const"]) ==
             OrbitalDynamics.CandidateRefresh.model_limits()

    assert get_in(refresh_budget_schema, ["properties", "model_limits", "const"]) ==
             OrbitalDynamics.CandidateRefresh.model_limits()

    assert get_in(candidate_diff_schema, ["properties", "model", "const"]) ==
             "candidate_id_set_diff_with_semantic_change_reasons"

    assert get_in(refresh_budget_schema, [
             "properties",
             "model",
             "const"
           ]) == "deterministic_candidate_limit_after_filters"

    assert get_in(refresh_budget_schema, [
             "properties",
             "input_candidate_count",
             "minimum"
           ]) == 0

    assert get_in(refresh_budget_schema, [
             "properties",
             "max_candidate_activities",
             "minimum"
           ]) == 0

    assert get_in(candidate_diff_schema, [
             "properties",
             "source_window_lineage",
             "items",
             "properties",
             "candidate_activity_id",
             "pattern"
           ]) == Schema.identity_policy()["stable_id_pattern"]

    assert get_in(candidate_diff_schema, ["properties", "prior_candidate_count"]) == %{
             "type" => "integer",
             "minimum" => 0
           }

    assert get_in(candidate_diff_schema, ["properties", "refreshed_candidate_count"]) == %{
             "type" => "integer",
             "minimum" => 0
           }

    assert get_in(candidate_diff_schema, ["properties", "valid_prior_candidate_count"]) == %{
             "type" => "integer",
             "minimum" => 0
           }

    assert get_in(candidate_diff_schema, ["properties", "invalid_prior_candidate_input_count"]) ==
             %{"type" => "integer", "minimum" => 0}

    assert get_in(refreshed_window_schema, ["properties", "sample_count"]) == %{
             "type" => "integer",
             "minimum" => 0
           }

    invalid_diff_limits =
      Map.put(candidate_diff_report, "model_limits", ["stale_candidate_refresh_boundary"])

    assert {:error, diff_limits_report} = Schema.validate_artifact(invalid_diff_limits)
    assert Enum.any?(diff_limits_report["errors"], &(&1["path"] == "$.model_limits"))

    invalid_freshness_limits =
      "study_results/freshness_report_v1.json"
      |> read_json!()
      |> Map.put("model_limits", ["artifact_only_no_schedule_mutation"])

    assert {:error, freshness_limits_report} =
             Schema.validate_artifact(invalid_freshness_limits)

    assert Enum.any?(
             freshness_limits_report["errors"],
             &(&1["path"] == "$.model_limits" and
                 &1["message"] == "must match candidate refresh model limits")
           )

    invalid_refresh_budget_limits =
      "study_results/refresh_budget_report_v1.json"
      |> read_json!()
      |> Map.put("model_limits", ["artifact_only_no_schedule_mutation"])

    assert {:error, refresh_budget_limits_report} =
             Schema.validate_artifact(invalid_refresh_budget_limits)

    assert Enum.any?(
             refresh_budget_limits_report["errors"],
             &(&1["path"] == "$.model_limits" and
                 &1["message"] == "must match candidate refresh model limits")
           )

    invalid_diff_model =
      Map.put(candidate_diff_report, "model", "stale_candidate_diff_model")

    assert {:error, diff_model_report} = Schema.validate_artifact(invalid_diff_model)
    assert Enum.any?(diff_model_report["errors"], &(&1["path"] == "$.model"))

    invalid_diff_lineage =
      put_in(
        candidate_diff_report,
        ["source_window_lineage", Access.at(0), "candidate_activity_id"],
        "unknown_candidate"
      )

    assert {:error, diff_lineage_report} = Schema.validate_artifact(invalid_diff_lineage)

    assert Enum.any?(
             diff_lineage_report["errors"],
             &(&1["path"] == "$.source_window_lineage[0].candidate_activity_id")
           )

    invalid_negative_diff_count = Map.put(candidate_diff_report, "prior_candidate_count", -1)

    assert {:error, negative_diff_count_report} =
             Schema.validate_artifact(invalid_negative_diff_count)

    assert Enum.any?(
             negative_diff_count_report["errors"],
             &(&1["path"] == "$.prior_candidate_count")
           )

    invalid_float_prior_count = Map.put(candidate_diff_report, "valid_prior_candidate_count", 1.0)

    assert {:error, float_prior_count_report} =
             Schema.validate_artifact(invalid_float_prior_count)

    assert Enum.any?(
             float_prior_count_report["errors"],
             &(&1["path"] == "$.valid_prior_candidate_count")
           )

    invalid_window_sample_count =
      "study_results/refreshed_window_v1.json"
      |> read_json!()
      |> Map.put("sample_count", -1)

    assert {:error, window_sample_count_report} =
             Schema.validate_artifact(invalid_window_sample_count)

    assert Enum.any?(
             window_sample_count_report["errors"],
             &(&1["path"] == "$.sample_count")
           )

    invalid_float_window_sample_count =
      "study_results/refreshed_window_v1.json"
      |> read_json!()
      |> Map.put("sample_count", 1.0)

    assert {:error, float_window_sample_count_report} =
             Schema.validate_artifact(invalid_float_window_sample_count)

    assert Enum.any?(
             float_window_sample_count_report["errors"],
             &(&1["path"] == "$.sample_count")
           )

    invalid_budget =
      "study_results/refresh_budget_report_v1.json"
      |> read_json!()
      |> Map.put("kept_candidate_count", 99)

    assert {:error, budget_report} = Schema.validate_artifact(invalid_budget)
    assert Enum.any?(budget_report["errors"], &(&1["path"] == "$.kept_candidate_count"))

    invalid_negative_budget =
      "study_results/refresh_budget_report_v1.json"
      |> read_json!()
      |> Map.put("dropped_candidate_count", -1)

    assert {:error, negative_budget_report} = Schema.validate_artifact(invalid_negative_budget)

    assert Enum.any?(
             negative_budget_report["errors"],
             &(&1["path"] == "$.dropped_candidate_count")
           )

    invalid_input_budget =
      "study_results/refresh_budget_report_v1.json"
      |> read_json!()
      |> Map.put("input_candidate_count", 99)

    assert {:error, input_budget_report} = Schema.validate_artifact(invalid_input_budget)
    assert Enum.any?(input_budget_report["errors"], &(&1["path"] == "$.input_candidate_count"))

    invalid_budget_model =
      "study_results/refresh_budget_report_v1.json"
      |> read_json!()
      |> Map.put("model", "stale_refresh_budget_model")

    assert {:error, budget_model_report} = Schema.validate_artifact(invalid_budget_model)

    assert Enum.any?(
             budget_model_report["errors"],
             &(&1["path"] == "$.model" and
                 &1["message"] ==
                   "must equal \"deterministic_candidate_limit_after_filters\"")
           )

    invalid_candidate_product =
      "study_results/candidate_activity_v1.json"
      |> read_json!()
      |> Map.put("product_ids", ["bad product id"])

    assert {:error, candidate_product_report} =
             Schema.validate_artifact(invalid_candidate_product)

    assert Enum.any?(
             candidate_product_report["errors"],
             &(&1["path"] == "$.product_ids[0]")
           )

    invalid_candidate_downlink =
      "study_results/candidate_activity_v1.json"
      |> read_json!()
      |> Map.put("required_downlink_mb", -1.0)

    assert {:error, candidate_downlink_report} =
             Schema.validate_artifact(invalid_candidate_downlink)

    assert Enum.any?(
             candidate_downlink_report["errors"],
             &(&1["path"] == "$.required_downlink_mb")
           )

    invalid_candidate_quality =
      "study_results/candidate_activity_v1.json"
      |> read_json!()
      |> Map.put("cloud_cover_fraction", -0.1)

    assert {:error, candidate_quality_report} =
             Schema.validate_artifact(invalid_candidate_quality)

    assert Enum.any?(
             candidate_quality_report["errors"],
             &(&1["path"] == "$.cloud_cover_fraction")
           )

    invalid_candidate_eclipse_overlap =
      "study_results/candidate_activity_v1.json"
      |> read_json!()
      |> Map.put("eclipse_overlap_fraction", 1.2)

    assert {:error, candidate_eclipse_overlap_report} =
             Schema.validate_artifact(invalid_candidate_eclipse_overlap)

    assert Enum.any?(
             candidate_eclipse_overlap_report["errors"],
             &(&1["path"] == "$.eclipse_overlap_fraction")
           )

    valid_candidate_numeric_lighting_confidence =
      "study_results/candidate_activity_v1.json"
      |> read_json!()
      |> Map.put("lighting_confidence", 0.72)

    assert {:ok, %{"schema_contract" => "candidate_activity.v1"}} =
             Schema.validate_artifact(valid_candidate_numeric_lighting_confidence)

    invalid_candidate_lighting_confidence =
      "study_results/candidate_activity_v1.json"
      |> read_json!()
      |> Map.put("lighting_confidence", false)

    assert {:error, candidate_lighting_confidence_report} =
             Schema.validate_artifact(invalid_candidate_lighting_confidence)

    assert Enum.any?(
             candidate_lighting_confidence_report["errors"],
             &(&1["path"] == "$.lighting_confidence")
           )
  end

  defp read_json!(path) do
    path
    |> File.read!()
    |> :json.decode()
  end

  defp candidate_refresh_artifact do
    %{
      "schema_version" => 1,
      "schema_contract" => "candidate_refresh.v1",
      "artifact_type" => "candidate_refresh",
      "generated_at" => "2026-05-14T00:00:00Z",
      "planner" => "OrbitalDynamics.CandidateRefresh.V1",
      "refresh_id" => "candidate_refresh:test",
      "study_id" => "test",
      "snapshot_id" => "ops-state-1",
      "current_epoch_s" => 0.0,
      "remaining_horizon" => %{
        "starts_at_s" => 0.0,
        "ends_at_s" => 600.0,
        "output_step_s" => 60.0
      },
      "accepted_planning_state" => %{
        "snapshot_id" => "ops-state-1",
        "spacecraft_state_count" => 1
      },
      "refreshed_windows" => %{
        "access_windows" => [],
        "target_visibility_windows" => [],
        "eclipse_intervals" => []
      },
      "candidate_activities" => [],
      "contact_intents" => [],
      "contact_filter_report" => %{
        "schema_contract" => "contact_filter_report.v1",
        "model" => "thin_ground_network_availability_filter",
        "input_candidate_count" => 1,
        "kept_candidate_count" => 0,
        "suppressed_candidate_count" => 1,
        "suppressed_candidates" => [
          %{
            "id" => "downlink_1",
            "type" => "downlink",
            "scenario_id" => "leo_1",
            "starts_at_s" => 10.0,
            "ends_at_s" => 20.0,
            "suppressed_reason" => "ground_station_unavailable"
          }
        ]
      },
      "resource_summaries" => [],
      "resource_filter_report" => %{
        "schema_contract" => "resource_filter_report.v1",
        "model" => "resource_summary_availability_and_margin_filter",
        "input_candidate_count" => 1,
        "kept_candidate_count" => 0,
        "suppressed_candidate_count" => 1,
        "suppressed_candidates" => [
          %{
            "id" => "observe_1",
            "type" => "observe",
            "scenario_id" => "leo_1",
            "starts_at_s" => 10.0,
            "ends_at_s" => 20.0,
            "suppressed_reason" => "payload_unavailable"
          }
        ]
      },
      "candidate_diff_report" => %{
        "schema_contract" => "candidate_diff_report.v1",
        "model" => "candidate_id_set_diff_with_semantic_change_reasons",
        "prior_candidate_count" => 1,
        "refreshed_candidate_count" => 1,
        "retained_candidate_count" => 0,
        "new_candidate_count" => 1,
        "invalidated_candidate_count" => 1,
        "retained_candidates" => [],
        "new_candidates" => [
          %{
            "id" => "observe_1",
            "type" => "observe",
            "scenario_id" => "leo_1",
            "starts_at_s" => 10.0,
            "ends_at_s" => 20.0,
            "diff_reason" => "not_present_in_prior_candidate_set"
          }
        ],
        "invalidated_candidates" => [
          %{
            "id" => "old_observe_1",
            "invalidated_reason" => "not_present_in_refreshed_candidate_set"
          }
        ]
      },
      "freshness_report" => %{
        "schema_contract" => "freshness_report.v1",
        "model" => "accepted_snapshot_horizon_and_quality_freshness",
        "generated_at" => "2026-05-14T00:00:00Z",
        "accepted_at" => "2026-05-14T00:00:00Z",
        "current_epoch_s" => 0.0,
        "horizon_starts_at_s" => 0.0,
        "accepted_snapshot_age_s" => 0.0,
        "horizon_start_offset_s" => 0.0,
        "max_snapshot_age_s" => 86_400.0,
        "max_horizon_start_offset_s" => 1.0,
        "accepted_state_quality_level" => "planning_accepted",
        "allowed_state_quality_levels" => ["accepted", "planning_accepted"],
        "state_quality_status" => "accepted",
        "status" => "current",
        "stale_reasons" => [],
        "unknown_reasons" => [],
        "model_limits" => OrbitalDynamics.CandidateRefresh.model_limits()
      },
      "invalidated_candidates" => [
        %{
          "id" => "old_observe_1",
          "type" => "observe",
          "scenario_id" => "leo_1",
          "starts_at_s" => 0.0,
          "ends_at_s" => 60.0,
          "invalidated_reason" => "not_present_in_refreshed_candidate_set",
          "source_window_id" => "old_window_1"
        }
      ],
      "validation_records" => [],
      "warnings" => [],
      "assumptions" => %{},
      "provenance" => %{},
      "source_window_lineage" => [
        %{
          "candidate_activity_id" => "observe_1",
          "source_window_id" => "window:leo_1:target_visibility:1",
          "source_window_type" => "target_visibility",
          "scenario_id" => "leo_1"
        }
      ]
    }
  end
end
