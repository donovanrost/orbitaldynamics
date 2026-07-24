Code.require_file("support.exs", __DIR__)

Code.require_file(
  "../../support/campaign_planner/strategy_recommendation_pressure_events_fixture.ex",
  __DIR__
)

Code.require_file(
  "../../support/campaign_planner/strategy_recommendation_pressure_expected_handoff_fixture.ex",
  __DIR__
)

defmodule OrbitalDynamics.CampaignPlanner.StrategyRecommendationPressureHandoffTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.CampaignPlanner.StrategyRecommendationPressureEventsFixture
  alias OrbitalDynamics.CampaignPlanner.StrategyRecommendationPressureExpectedHandoffFixture
  alias OrbitalDynamics.Schema

  test "strategy recommendation pressure fields propagate through review and import handoffs" do
    artifact = StrategyRecommendationPressureEventsFixture.artifact()

    expected_handoff = StrategyRecommendationPressureExpectedHandoffFixture.expected_handoff()

    branch_context_fields = [
      "branch_source_window_ids",
      "branch_source_window_count",
      "branch_source_window_bounds",
      "branch_source_window_bound_count",
      "branch_untimed_source_window_ids",
      "branch_untimed_source_window_count",
      "branch_partially_timed_source_window_ids",
      "branch_partially_timed_source_window_count",
      "branch_source_window_timing_coverage_status",
      "branch_earliest_starts_at_s",
      "branch_latest_ends_at_s",
      "branch_station_reservation_expiration_statuses"
    ]

    recommendation_branch_context =
      artifact["recommendation"]["explanation"]
      |> Enum.find(&(&1["type"] == "branch_event_summary"))
      |> Map.take(branch_context_fields)

    assert %{
             "branch_earliest_starts_at_s" => 500.0,
             "branch_latest_ends_at_s" => 1_680.0,
             "branch_source_window_ids" => source_window_ids,
             "branch_source_window_count" => 11,
             "branch_source_window_bounds" => source_window_bounds,
             "branch_source_window_bound_count" => 10,
             "branch_untimed_source_window_ids" => ["equator_prime_rejected_window"],
             "branch_untimed_source_window_count" => 1,
             "branch_partially_timed_source_window_count" => 0,
             "branch_source_window_timing_coverage_status" => "partial",
             "branch_station_reservation_expiration_statuses" => ["active"]
           } = recommendation_branch_context

    assert source_window_ids == Enum.sort(source_window_ids)
    assert length(source_window_ids) == 11
    assert length(source_window_bounds) == 10
    assert "equator_prime_rejected_window" in source_window_ids

    refute Enum.any?(
             source_window_bounds,
             &(&1["source_window_id"] == "equator_prime_rejected_window")
           )

    assert Map.new(source_window_bounds, fn bound ->
             {bound["source_window_id"],
              {bound["earliest_starts_at_s"], bound["latest_ends_at_s"]}}
           end) == %{
             "window_allocation_deferred" => {1_620.0, 1_680.0},
             "window_capacity_overflow" => {1_560.0, 1_620.0},
             "window_contact_filter_suppressed" => {1_165.0, 1_225.0},
             "window_contact_intent_selected" => {1_100.0, 1_160.0},
             "window_contention_conflict" => {1_580.0, 1_640.0},
             "window_contention_primary" => {1_580.0, 1_640.0},
             "window_equator_command" => {700.0, 730.0},
             "window_equator_contact" => {790.0, 850.0},
             "window_link_capacity" => {1_020.0, 1_080.0},
             "window_link_capacity_backup" => {1_020.0, 1_080.0}
           }

    recommendation_review_row =
      artifact["operator_review_package"]["rows"]
      |> Enum.find(&(&1["review_type"] == "strategy_recommendation"))

    emitted_expected_handoff = Map.take(expected_handoff, Map.keys(recommendation_review_row))

    assert Map.take(recommendation_review_row, Map.keys(emitted_expected_handoff)) ==
             emitted_expected_handoff

    assert Map.take(recommendation_review_row, branch_context_fields) ==
             recommendation_branch_context

    assert recommendation_review_row["branch_station_reservation_expiration_statuses"] == [
             "active"
           ]

    selected_import_row =
      artifact["cadence_import_manifest"]["rows"]
      |> Enum.find(
        &(&1["import_action"] == "import_strategy_recommendation" and &1["selected"] == true)
      )

    assert Map.take(selected_import_row, Map.keys(emitted_expected_handoff)) ==
             emitted_expected_handoff

    assert Map.take(selected_import_row, branch_context_fields) == recommendation_branch_context

    assert selected_import_row["branch_station_reservation_expiration_statuses"] == ["active"]

    review_import =
      OrbitalDynamics.cadence_import_manifest(artifact["operator_review_package"])

    review_import_row =
      review_import["rows"]
      |> Enum.find(&(&1["source_review_type"] == "strategy_recommendation"))

    assert Map.take(review_import_row, Map.keys(emitted_expected_handoff)) ==
             emitted_expected_handoff

    assert Map.take(review_import_row, branch_context_fields) == recommendation_branch_context

    assert review_import_row["branch_station_reservation_expiration_statuses"] == ["active"]

    assert Map.take(review_import_row["source_review_row"], Map.keys(emitted_expected_handoff)) ==
             emitted_expected_handoff

    assert Map.take(review_import_row["source_review_row"], branch_context_fields) ==
             recommendation_branch_context

    assert review_import_row["source_review_row"][
             "branch_station_reservation_expiration_statuses"
           ] == ["active"]

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1", "status" => "pass"}} =
             Schema.validate_artifact(review_import)

    recommendation_review_index =
      Enum.find_index(
        artifact["operator_review_package"]["rows"],
        &(&1["id"] == recommendation_review_row["id"])
      )

    missing_review_expiration =
      update_in(
        artifact["operator_review_package"],
        ["rows", Access.at(recommendation_review_index)],
        &Map.delete(&1, "branch_station_reservation_expiration_statuses")
      )

    assert {:error, missing_review_expiration_report} =
             Schema.validate_artifact(missing_review_expiration)

    assert Enum.any?(
             missing_review_expiration_report["errors"],
             &(&1["path"] ==
                 "$.rows[#{recommendation_review_index}].branch_station_reservation_expiration_statuses")
           )

    legacy_review_expiration =
      update_in(
        artifact["operator_review_package"],
        ["rows", Access.at(recommendation_review_index)],
        fn row ->
          row
          |> Map.delete("branch_station_reservation_expiration_statuses")
          |> update_in(["source_recommendation", "explanation"], fn explanation ->
            Enum.map(explanation, fn
              %{"type" => "branch_event_summary"} = summary ->
                Map.delete(summary, "branch_station_reservation_expiration_statuses")

              other ->
                other
            end)
          end)
        end
      )

    assert {:ok, _legacy_review_expiration} = Schema.validate_artifact(legacy_review_expiration)

    selected_import_index =
      Enum.find_index(
        artifact["cadence_import_manifest"]["rows"],
        &(&1["id"] == selected_import_row["id"])
      )

    stale_selected_expiration =
      update_in(
        artifact["cadence_import_manifest"],
        ["rows", Access.at(selected_import_index)],
        &Map.put(&1, "branch_station_reservation_expiration_statuses", ["expired"])
      )

    assert {:error, stale_selected_expiration_report} =
             Schema.validate_artifact(stale_selected_expiration)

    assert Enum.any?(
             stale_selected_expiration_report["errors"],
             &(&1["path"] ==
                 "$.rows[#{selected_import_index}].branch_station_reservation_expiration_statuses")
           )

    review_import_index =
      Enum.find_index(review_import["rows"], &(&1["id"] == review_import_row["id"]))

    missing_review_import_expiration =
      update_in(
        review_import,
        ["rows", Access.at(review_import_index)],
        &Map.delete(&1, "branch_station_reservation_expiration_statuses")
      )

    assert {:error, missing_review_import_expiration_report} =
             Schema.validate_artifact(missing_review_import_expiration)

    assert Enum.any?(
             missing_review_import_expiration_report["errors"],
             &(&1["path"] ==
                 "$.rows[#{review_import_index}].branch_station_reservation_expiration_statuses")
           )
  end

  test "provider request expiration risk context remains source exact across handoffs" do
    assert_risk_expiration_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "provider_reservation_request_station_reservation_expiration_statuses",
      {"contact_id", "dl_provider_review"},
      "active"
    )
  end

  test "provider request contact identity remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "provider_reservation_request_contact_ids",
      {"contact_id", "dl_provider_review"},
      "contact_id",
      ["dl_provider_review"],
      ["stale_dl_provider_review"]
    )
  end

  test "provider request source activity identity remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "provider_reservation_request_source_activity_ids",
      {"contact_id", "dl_provider_review"},
      ["source_activity_id", "source_activity_ids"],
      ["dl_provider_review"],
      ["stale_dl_provider_review"]
    )
  end

  test "provider request ground-station identity remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "provider_reservation_request_ground_station_ids",
      {"contact_id", "dl_provider_review"},
      "ground_station_id",
      ["equator_prime"],
      ["stale_equator_prime"]
    )
  end

  test "provider request direction remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "provider_reservation_request_directions",
      {"contact_id", "dl_provider_review"},
      "direction",
      ["downlink"],
      ["uplink"]
    )
  end

  test "provider request reservation identity remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "provider_reservation_request_station_reservation_ids",
      {"contact_id", "dl_provider_review"},
      "station_reservation_id",
      ["provider_reservation_review"],
      ["stale_provider_reservation_review"]
    )
  end

  test "provider request reservation owner remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "provider_reservation_request_station_reserved_by",
      {"contact_id", "dl_provider_review"},
      "station_reserved_by",
      ["partner_calendar"],
      ["stale_partner_calendar"]
    )
  end

  test "provider request reservation status remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "provider_reservation_request_station_reservation_statuses",
      {"contact_id", "dl_provider_review"},
      "station_reservation_status",
      ["confirmed"],
      ["cancelled"]
    )
  end

  test "provider request reservation match remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "provider_reservation_request_station_reservation_match_statuses",
      {"contact_id", "dl_provider_review"},
      "station_reservation_match_status",
      ["overlap"],
      ["matched"]
    )
  end

  test "provider request status remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "provider_reservation_request_statuses",
      {"contact_id", "dl_provider_review"},
      "provider_reservation_request_status",
      ["review_required"],
      ["request_ready"]
    )
  end

  test "provider request row scope remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "provider_reservation_request_row_scopes",
      {"contact_id", "dl_provider_review"},
      "provider_reservation_row_scope",
      ["review"],
      ["request"]
    )
  end

  test "provider request required action remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "provider_reservation_request_required_operator_actions",
      {"contact_id", "dl_provider_review"},
      "required_operator_action",
      ["review_provider_reservation_request"],
      ["submit_provider_reservation_request"]
    )
  end

  test "provider request assumptions remain source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "provider_reservation_request_assumption_maps",
      {"contact_id", "dl_provider_review"},
      "assumptions",
      [
        %{
          "provider_reservation_execution" => "not_performed_by_strategy_branch",
          "schedule_mutation" => "not_performed_by_strategy_branch",
          "operator_authority" => "not_granted_by_strategy_branch"
        }
      ],
      [
        %{
          "provider_reservation_execution" => "performed_by_strategy_branch",
          "schedule_mutation" => "performed_by_strategy_branch",
          "operator_authority" => "granted_by_strategy_branch"
        }
      ]
    )
  end

  test "provider request feedback source remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "provider_reservation_request_feedback_sources",
      {"contact_id", "dl_provider_review"},
      "feedback_source",
      ["mission_state.source_contact_allocation_provider_reservation_request_summary"],
      ["stale.source_contact_allocation_provider_reservation_request_summary"]
    )
  end

  test "provider request feedback scope remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "provider_reservation_request_feedback_scopes",
      {"contact_id", "dl_provider_review"},
      "feedback_scope",
      ["contact_allocation_provider_reservation_request"],
      ["stale_contact_allocation_provider_reservation_request"]
    )
  end

  test "provider request trust boundary remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "provider_reservation_request_trust_boundaries",
      {"contact_id", "dl_provider_review"},
      "trust_boundary",
      ["mission_state_provider_reservation_request_summary"],
      ["stale_mission_state_provider_reservation_request_summary"]
    )
  end

  test "capacity-pack risk contact identity remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "capacity_pack_risk_contact_ids",
      {"contact_id", "dl_capacity_overflow"},
      "contact_id",
      ["dl_capacity_overflow"],
      ["stale_dl_capacity_overflow"]
    )
  end

  test "capacity-pack risk source activity identity remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "capacity_pack_risk_source_activity_ids",
      {"contact_id", "dl_capacity_overflow"},
      ["source_activity_id", "source_activity_ids"],
      ["dl_capacity_overflow"],
      ["stale_dl_capacity_overflow"]
    )
  end

  test "capacity-pack risk ground-station identity remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "capacity_pack_risk_ground_station_ids",
      {"contact_id", "dl_capacity_overflow"},
      "ground_station_id",
      ["equator_prime"],
      ["stale_equator_prime"]
    )
  end

  test "capacity-pack risk group identity remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "capacity_pack_risk_group_ids",
      {"contact_id", "dl_capacity_overflow"},
      "capacity_pack_group_id",
      ["capacity_pack_equator_prime"],
      ["stale_capacity_pack_equator_prime"]
    )
  end

  test "capacity-pack risk status remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "capacity_pack_risk_statuses",
      {"contact_id", "dl_capacity_overflow"},
      "capacity_pack_status",
      ["deferred_by_reduced_station_capacity_pack"],
      ["stale_capacity_pack_status"]
    )
  end

  test "capacity-pack risk capacity fraction remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "capacity_pack_risk_capacity_fraction_values",
      {"contact_id", "dl_capacity_overflow"},
      "capacity_pack_capacity_fraction",
      [0.5],
      [0.75]
    )
  end

  test "capacity-pack risk used fraction remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "capacity_pack_risk_used_fraction_values",
      {"contact_id", "dl_capacity_overflow"},
      "capacity_pack_used_fraction",
      [0.5],
      [0.75]
    )
  end

  test "capacity-pack risk unused fraction remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "capacity_pack_risk_unused_fraction_values",
      {"contact_id", "dl_capacity_overflow"},
      "capacity_pack_unused_fraction",
      [0.0],
      [0.25]
    )
  end

  test "capacity-pack risk required fraction remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "capacity_pack_risk_required_capacity_fraction_values",
      {"contact_id", "dl_capacity_overflow"},
      "required_capacity_fraction",
      [0.25],
      [0.5]
    )
  end

  test "capacity-pack risk required-fraction source remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "capacity_pack_risk_required_capacity_fraction_sources",
      {"contact_id", "dl_capacity_overflow"},
      "required_capacity_fraction_source",
      ["contact_required_capacity_fraction"],
      ["stale_required_capacity_fraction_source"]
    )
  end

  test "capacity-pack risk derivation reasons remain source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "capacity_pack_risk_derivation_reasons",
      {"contact_id", "dl_capacity_overflow"},
      "derivation_reasons",
      ["contact_contention_deferred", "deferred_by_reduced_station_capacity_pack"],
      ["stale_capacity_pack_derivation"]
    )
  end

  test "capacity-pack risk feedback source remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "capacity_pack_risk_feedback_sources",
      {"contact_id", "dl_capacity_overflow"},
      "feedback_source",
      ["mission_state.source_contact_allocation_capacity_pack_summary"],
      ["stale_capacity_pack_feedback_source"]
    )
  end

  test "capacity-pack risk feedback scope remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "capacity_pack_risk_feedback_scopes",
      {"contact_id", "dl_capacity_overflow"},
      "feedback_scope",
      ["contact_contention_resolution"],
      ["stale_contact_contention_resolution"]
    )
  end

  test "capacity-pack risk trust boundary remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "capacity_pack_risk_trust_boundaries",
      {"contact_id", "dl_capacity_overflow"},
      "trust_boundary",
      ["mission_state_capacity_pack_summary"],
      ["stale_mission_state_capacity_pack_summary"]
    )
  end

  test "contention-resolution risk type remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "contact_contention_resolution_pressure_risk_types",
      {"contact_id", "dl_capacity_overflow"},
      ["type", "risk_type"],
      ["downlink_completion_gap"],
      ["stale_contention_resolution_risk"]
    )
  end

  test "contention-resolution contact identity remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "contact_contention_resolution_pressure_contact_ids",
      {"contact_id", "dl_capacity_overflow"},
      "contact_id",
      ["dl_capacity_overflow"],
      ["stale_dl_capacity_overflow"]
    )
  end

  test "contention-resolution selected-contact identity remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "contact_contention_resolution_pressure_selected_contact_ids",
      {"contact_id", "dl_capacity_overflow"},
      "selected_contact_id",
      ["dl_capacity_selected"],
      ["stale_dl_capacity_selected"]
    )
  end

  test "contention-resolution scenario identity remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "contact_contention_resolution_pressure_scenario_ids",
      {"contact_id", "dl_capacity_overflow"},
      "scenario_id",
      ["leo_1"],
      ["stale_leo_1"]
    )
  end

  test "contention-resolution spacecraft identity remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "contact_contention_resolution_pressure_spacecraft_ids",
      {"contact_id", "dl_capacity_overflow"},
      "spacecraft_id",
      ["leo_1"],
      ["stale_leo_1"]
    )
  end

  test "contention-resolution ground-station identity remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "contact_contention_resolution_pressure_ground_station_ids",
      {"contact_id", "dl_capacity_overflow"},
      "ground_station_id",
      ["equator_prime"],
      ["stale_equator_prime"]
    )
  end

  test "contention-resolution source-activity identity remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "contact_contention_resolution_pressure_source_activity_ids",
      {"contact_id", "dl_capacity_overflow"},
      ["source_activity_id", "source_activity_ids"],
      ["dl_capacity_overflow"],
      ["stale_dl_capacity_overflow"]
    )
  end

  test "contention-resolution source-window identity remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "contact_contention_resolution_pressure_source_window_ids",
      {"contact_id", "dl_capacity_overflow"},
      "source_window_id",
      ["window_capacity_overflow"],
      ["stale_window_capacity_overflow"]
    )
  end

  test "contention-resolution required-contact demand remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "contact_contention_resolution_pressure_required_contact_values",
      {"contact_id", "dl_capacity_overflow"},
      "required_contacts",
      [1],
      [2]
    )
  end

  test "contention-resolution planned-contact demand remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "contact_contention_resolution_pressure_planned_contact_values",
      {"contact_id", "dl_capacity_overflow"},
      "planned_contacts",
      [0],
      [1]
    )
  end

  test "contention-resolution required-downlink demand remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "contact_contention_resolution_pressure_required_downlink_values_mb",
      {"contact_id", "dl_capacity_overflow"},
      "required_downlink_mb",
      [47.0],
      [48.0]
    )
  end

  test "contention-resolution planned-downlink demand remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "contact_contention_resolution_pressure_planned_downlink_values_mb",
      {"contact_id", "dl_capacity_overflow"},
      "planned_downlink_mb",
      [0.0],
      [1.0]
    )
  end

  test "contention-resolution start bound remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "contact_contention_resolution_pressure_start_values_s",
      {"contact_id", "dl_capacity_overflow"},
      "starts_at_s",
      [1_560.0],
      [1_559.0]
    )
  end

  test "contention-resolution end bound remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "contact_contention_resolution_pressure_end_values_s",
      {"contact_id", "dl_capacity_overflow"},
      "ends_at_s",
      [1_620.0],
      [1_621.0]
    )
  end

  test "contention-resolution selected priority source remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "contact_contention_resolution_pressure_selected_priority_sources",
      {"contact_id", "dl_capacity_overflow"},
      "selected_priority_source",
      ["policy_contact_priority"],
      ["stale_contact_priority"]
    )
  end

  test "contention-resolution selection reason remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "contact_contention_resolution_pressure_selection_reasons",
      {"contact_id", "dl_capacity_overflow"},
      "selection_reason",
      ["highest_priority_highest_score"],
      ["stale_selection_reason"]
    )
  end

  test "contention-resolution selection rule remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "contact_contention_resolution_pressure_resolution_selection_rules",
      {"contact_id", "dl_capacity_overflow"},
      "resolution_selection_rule",
      ["highest_priority_highest_score"],
      ["stale_selection_rule"]
    )
  end

  test "contention-resolution priority override count remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "contact_contention_resolution_pressure_priority_override_count_values",
      {"contact_id", "dl_capacity_overflow"},
      "resolution_priority_override_count",
      [2],
      [3]
    )
  end

  test "contention-resolution priority override contacts remain source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "contact_contention_resolution_pressure_priority_override_contact_ids",
      {"contact_id", "dl_capacity_overflow"},
      "resolution_priority_override_contact_ids",
      ["dl_capacity_selected", "dl_capacity_overflow"],
      ["stale_dl_capacity_selected"]
    )
  end

  test "contention-resolution review status remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "contact_contention_resolution_pressure_review_statuses",
      {"contact_id", "dl_capacity_overflow"},
      "review_status",
      ["operator_review_required"],
      ["stale_review_status"]
    )
  end

  test "contention-resolution demand source remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "contact_contention_resolution_pressure_downlink_demand_sources",
      {"contact_id", "dl_capacity_overflow"},
      "downlink_demand_sources",
      ["contention_resolution.required_downlink:dl_capacity_overflow"],
      ["stale_contention_resolution_demand_source"]
    )
  end

  test "contention-resolution completion source remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "contact_contention_resolution_pressure_downlink_completion_sources",
      {"contact_id", "dl_capacity_overflow"},
      "downlink_completion_sources",
      ["contact_contention_resolution_report:recommendations"],
      ["stale_contention_resolution_completion_source"]
    )
  end

  test "contention-resolution feedback source remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "contact_contention_resolution_pressure_feedback_sources",
      {"contact_id", "dl_capacity_overflow"},
      "feedback_source",
      ["mission_state.source_contact_allocation_capacity_pack_summary"],
      ["stale_contention_resolution_feedback_source"]
    )
  end

  test "contention-resolution feedback scope remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "contact_contention_resolution_pressure_feedback_scopes",
      {"contact_id", "dl_capacity_overflow"},
      "feedback_scope",
      ["contact_contention_resolution"],
      ["stale_contact_contention_resolution"]
    )
  end

  test "contention-resolution trust boundary remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "contact_contention_resolution_pressure_trust_boundaries",
      {"contact_id", "dl_capacity_overflow"},
      "trust_boundary",
      ["mission_state_capacity_pack_summary"],
      ["stale_mission_state_capacity_pack_summary"]
    )
  end

  test "contention-resolution derivation reasons remain source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "contact_contention_resolution_pressure_derivation_reasons",
      {"contact_id", "dl_capacity_overflow"},
      "derivation_reasons",
      ["contact_contention_deferred", "deferred_by_reduced_station_capacity_pack"],
      ["stale_contention_resolution_derivation"]
    )
  end

  test "contact-contention risk type remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "contact_contention_pressure_risk_types",
      {"contact_id", "dl_contention_conflict"},
      ["type", "risk_type"],
      ["downlink_completion_gap"],
      ["stale_contact_contention_risk"]
    )
  end

  test "contact-contention contact identity remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "contact_contention_pressure_contact_ids",
      {"contact_id", "dl_contention_conflict"},
      "contact_id",
      ["dl_contention_conflict"],
      ["stale_dl_contention_conflict"]
    )
  end

  test "contact-contention scenario identity remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "contact_contention_pressure_scenario_ids",
      {"contact_id", "dl_contention_conflict"},
      "scenario_id",
      ["leo_1"],
      ["stale_leo_1"]
    )
  end

  test "contact-contention spacecraft identity remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "contact_contention_pressure_spacecraft_ids",
      {"contact_id", "dl_contention_conflict"},
      "spacecraft_id",
      ["leo_1"],
      ["stale_leo_1"]
    )
  end

  test "contact-contention ground-station identity remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "contact_contention_pressure_ground_station_ids",
      {"contact_id", "dl_contention_conflict"},
      "ground_station_id",
      ["equator_prime"],
      ["stale_equator_prime"]
    )
  end

  test "contact-contention source-activity identity remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "contact_contention_pressure_source_activity_ids",
      {"contact_id", "dl_contention_conflict"},
      ["source_activity_id", "source_activity_ids"],
      ["dl_contention_conflict"],
      ["stale_dl_contention_conflict"]
    )
  end

  test "contact-contention source-window identity remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "contact_contention_pressure_source_window_ids",
      {"contact_id", "dl_contention_conflict"},
      ["source_window_id", "source_window_ids"],
      ["window_contention_conflict", "window_contention_primary"],
      ["stale_window_contention"]
    )
  end

  test "contact-contention required-contact demand remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "contact_contention_pressure_required_contact_values",
      {"contact_id", "dl_contention_conflict"},
      "required_contacts",
      [1],
      [2]
    )
  end

  test "contact-contention planned-contact demand remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "contact_contention_pressure_planned_contact_values",
      {"contact_id", "dl_contention_conflict"},
      "planned_contacts",
      [0],
      [1]
    )
  end

  test "contact-contention required-downlink demand remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "contact_contention_pressure_required_downlink_values_mb",
      {"contact_id", "dl_contention_conflict"},
      "required_downlink_mb",
      [39.0],
      [40.0]
    )
  end

  test "contact-contention planned-downlink demand remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "contact_contention_pressure_planned_downlink_values_mb",
      {"contact_id", "dl_contention_conflict"},
      "planned_downlink_mb",
      [0.0],
      [1.0]
    )
  end

  test "contact-contention start bound remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "contact_contention_pressure_start_values_s",
      {"contact_id", "dl_contention_conflict"},
      "starts_at_s",
      [1_580.0],
      [1_579.0]
    )
  end

  test "contact-contention end bound remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "contact_contention_pressure_end_values_s",
      {"contact_id", "dl_contention_conflict"},
      "ends_at_s",
      [1_640.0],
      [1_641.0]
    )
  end

  test "contact-contention group identity remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "contact_contention_pressure_group_ids",
      {"contact_id", "dl_contention_conflict"},
      "contention_group_id",
      ["station:equator_prime:contention:selected"],
      ["station:equator_prime:contention:stale"]
    )
  end

  test "contact-contention resource scope remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "contact_contention_pressure_resource_scopes",
      {"contact_id", "dl_contention_conflict"},
      "contention_resource_scope",
      ["ground_station"],
      ["spacecraft"]
    )
  end

  test "contact-contention contact set remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "contact_contention_pressure_contention_contact_ids",
      {"contact_id", "dl_contention_conflict"},
      ["contention_contact_ids"],
      ["dl_contention_primary", "dl_contention_conflict"],
      ["stale_dl_contention"]
    )
  end

  test "contact-contention required operator action remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "contact_contention_pressure_required_operator_actions",
      {"contact_id", "dl_contention_conflict"},
      "required_operator_action",
      ["review_contact_contention"],
      ["accept_contact_contention"]
    )
  end

  test "contact-contention approval status remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "contact_contention_pressure_approval_statuses",
      {"contact_id", "dl_contention_conflict"},
      "approval_status",
      ["operator_review_required"],
      ["approved"]
    )
  end

  test "contact-contention operator-action reason remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "contact_contention_pressure_operator_action_reasons",
      {"contact_id", "dl_contention_conflict"},
      "operator_action_reason",
      ["same_station_overlapping_contact_windows"],
      ["stale_contention_reason"]
    )
  end

  test "contact-contention downlink-demand source remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "contact_contention_pressure_downlink_demand_sources",
      {"contact_id", "dl_contention_conflict"},
      ["downlink_demand_sources"],
      ["contact_contention.required_downlink:dl_contention_conflict"],
      ["stale_contact_contention_demand"]
    )
  end

  test "contact-contention completion source remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "contact_contention_pressure_downlink_completion_sources",
      {"contact_id", "dl_contention_conflict"},
      ["downlink_completion_sources"],
      ["contact_contention_report:conflict_groups"],
      ["stale_contact_contention_completion"]
    )
  end

  test "contact-contention feedback source remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "contact_contention_pressure_feedback_sources",
      {"contact_id", "dl_contention_conflict"},
      "feedback_source",
      ["mission_state.source_contact_contention_report.conflict_groups"],
      ["stale_contact_contention_feedback"]
    )
  end

  test "contact-contention feedback scope remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "contact_contention_pressure_feedback_scopes",
      {"contact_id", "dl_contention_conflict"},
      "feedback_scope",
      ["contact_contention"],
      ["stale_contact_contention"]
    )
  end

  test "contact-contention trust boundary remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "contact_contention_pressure_trust_boundaries",
      {"contact_id", "dl_contention_conflict"},
      "trust_boundary",
      ["mission_state_contact_contention_report"],
      ["stale_contact_contention_boundary"]
    )
  end

  test "contact-contention derivation reasons remain source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "contact_contention_pressure_derivation_reasons",
      {"contact_id", "dl_contention_conflict"},
      ["derivation_reasons"],
      [
        "contact_contention_conflict",
        "same_station_overlapping_contact_windows",
        "ground_station",
        "operator_review_required"
      ],
      ["stale_contact_contention_reason"]
    )
  end

  test "contact-filter risk type remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "contact_filter_pressure_risk_types",
      {"contact_id", "dl_contact_filter_suppressed"},
      ["type", "risk_type"],
      ["downlink_completion_gap"],
      ["stale_contact_filter_risk"]
    )
  end

  test "contact-filter contact identity remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "contact_filter_pressure_contact_ids",
      {"contact_id", "dl_contact_filter_suppressed"},
      "contact_id",
      ["dl_contact_filter_suppressed"],
      ["stale_dl_contact_filter_suppressed"]
    )
  end

  test "contact-filter scenario identity remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "contact_filter_pressure_scenario_ids",
      {"contact_id", "dl_contact_filter_suppressed"},
      "scenario_id",
      ["leo_1"],
      ["stale_leo_1"]
    )
  end

  test "contact-filter spacecraft identity remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "contact_filter_pressure_spacecraft_ids",
      {"contact_id", "dl_contact_filter_suppressed"},
      "spacecraft_id",
      ["leo_1"],
      ["stale_leo_1"]
    )
  end

  test "contact-filter ground-station identity remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "contact_filter_pressure_ground_station_ids",
      {"contact_id", "dl_contact_filter_suppressed"},
      "ground_station_id",
      ["goldstone"],
      ["stale_goldstone"]
    )
  end

  test "contact-filter source-activity identity remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "contact_filter_pressure_source_activity_ids",
      {"contact_id", "dl_contact_filter_suppressed"},
      ["source_activity_id", "source_activity_ids"],
      ["dl_contact_filter_suppressed"],
      ["stale_dl_contact_filter_suppressed"]
    )
  end

  test "contact-filter source-window identity remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "contact_filter_pressure_source_window_ids",
      {"contact_id", "dl_contact_filter_suppressed"},
      "source_window_id",
      ["window_contact_filter_suppressed"],
      ["stale_window_contact_filter_suppressed"]
    )
  end

  test "contact-filter required-contact demand remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "contact_filter_pressure_required_contact_values",
      {"contact_id", "dl_contact_filter_suppressed"},
      "required_contacts",
      [1],
      [2]
    )
  end

  test "contact-filter planned-contact demand remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "contact_filter_pressure_planned_contact_values",
      {"contact_id", "dl_contact_filter_suppressed"},
      "planned_contacts",
      [0],
      [1]
    )
  end

  test "contact-filter required-downlink demand remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "contact_filter_pressure_required_downlink_values_mb",
      {"contact_id", "dl_contact_filter_suppressed"},
      "required_downlink_mb",
      [38.0],
      [39.0]
    )
  end

  test "contact-filter planned-downlink demand remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "contact_filter_pressure_planned_downlink_values_mb",
      {"contact_id", "dl_contact_filter_suppressed"},
      "planned_downlink_mb",
      [0.0],
      [1.0]
    )
  end

  test "contact-filter start bound remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "contact_filter_pressure_start_values_s",
      {"contact_id", "dl_contact_filter_suppressed"},
      "starts_at_s",
      [1_165.0],
      [1_164.0]
    )
  end

  test "contact-filter end bound remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "contact_filter_pressure_end_values_s",
      {"contact_id", "dl_contact_filter_suppressed"},
      "ends_at_s",
      [1_225.0],
      [1_226.0]
    )
  end

  test "contact-filter suppression reason remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "contact_filter_pressure_suppressed_reasons",
      {"contact_id", "dl_contact_filter_suppressed"},
      "suppressed_reason",
      ["station_reserved"],
      ["stale_suppression_reason"]
    )
  end

  test "contact-filter review status remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "contact_filter_pressure_review_statuses",
      {"contact_id", "dl_contact_filter_suppressed"},
      "review_status",
      ["operator_review_required"],
      ["not_required"]
    )
  end

  test "contact-filter reservation identity remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "contact_filter_pressure_station_reservation_ids",
      {"contact_id", "dl_contact_filter_suppressed"},
      "station_reservation_id",
      ["reservation_contact_filter"],
      ["stale_reservation_contact_filter"]
    )
  end

  test "contact-filter reservation owner remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "contact_filter_pressure_station_reserved_by",
      {"contact_id", "dl_contact_filter_suppressed"},
      "station_reserved_by",
      ["partner_calendar"],
      ["stale_partner_calendar"]
    )
  end

  test "contact-filter reservation status remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "contact_filter_pressure_station_reservation_statuses",
      {"contact_id", "dl_contact_filter_suppressed"},
      "station_reservation_status",
      ["confirmed"],
      ["cancelled"]
    )
  end

  test "contact-filter reservation match remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "contact_filter_pressure_station_reservation_match_statuses",
      {"contact_id", "dl_contact_filter_suppressed"},
      "station_reservation_match_status",
      ["overlap"],
      ["matched"]
    )
  end

  test "contact-filter calendar-entry identity remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "contact_filter_pressure_station_calendar_entry_ids",
      {"contact_id", "dl_contact_filter_suppressed"},
      "station_calendar_entry_id",
      ["calendar_contact_filter_suppressed"],
      ["stale_calendar_contact_filter_suppressed"]
    )
  end

  test "contact-filter calendar-entry status remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "contact_filter_pressure_station_calendar_entry_statuses",
      {"contact_id", "dl_contact_filter_suppressed"},
      "station_calendar_entry_status",
      ["reserved"],
      ["available"]
    )
  end

  test "contact-filter downlink-demand source remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "contact_filter_pressure_downlink_demand_sources",
      {"contact_id", "dl_contact_filter_suppressed"},
      ["downlink_demand_sources"],
      ["contact_filter:dl_contact_filter_suppressed"],
      ["stale_contact_filter_demand"]
    )
  end

  test "contact-filter completion source remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "contact_filter_pressure_downlink_completion_sources",
      {"contact_id", "dl_contact_filter_suppressed"},
      ["downlink_completion_sources"],
      ["contact_filter_report:suppressed_candidates"],
      ["stale_contact_filter_completion"]
    )
  end

  test "contact-filter feedback source remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "contact_filter_pressure_feedback_sources",
      {"contact_id", "dl_contact_filter_suppressed"},
      "feedback_source",
      ["mission_state.source_contact_filter_report.suppressed_candidates"],
      ["stale_contact_filter_feedback"]
    )
  end

  test "contact-filter feedback scope remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "contact_filter_pressure_feedback_scopes",
      {"contact_id", "dl_contact_filter_suppressed"},
      "feedback_scope",
      ["contact_filter"],
      ["stale_contact_filter"]
    )
  end

  test "contact-filter trust boundary remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "contact_filter_pressure_trust_boundaries",
      {"contact_id", "dl_contact_filter_suppressed"},
      "trust_boundary",
      ["mission_state_contact_filter_report"],
      ["stale_contact_filter_boundary"]
    )
  end

  test "contact-filter derivation reasons remain source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "contact_filter_pressure_derivation_reasons",
      {"contact_id", "dl_contact_filter_suppressed"},
      ["derivation_reasons"],
      ["contact_filter_suppressed", "station_reserved"],
      ["stale_contact_filter_reason"]
    )
  end

  test "link-capacity risk type remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "link_capacity_pressure_risk_types",
      {"ground_station_id", "equator_prime"},
      ["type", "risk_type"],
      ["downlink_completion_gap"],
      ["stale_link_capacity_risk"]
    )
  end

  test "link-capacity ground-station identity remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "link_capacity_pressure_ground_station_ids",
      {"ground_station_id", "equator_prime"},
      "ground_station_id",
      ["equator_prime"],
      ["stale_equator_prime"]
    )
  end

  test "link-capacity required-contact demand remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "link_capacity_pressure_required_contact_values",
      {"ground_station_id", "equator_prime"},
      "required_contacts",
      [1],
      [2]
    )
  end

  test "link-capacity planned-contact demand remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "link_capacity_pressure_planned_contact_values",
      {"ground_station_id", "equator_prime"},
      "planned_contacts",
      [0],
      [1]
    )
  end

  test "link-capacity required-downlink demand remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "link_capacity_pressure_required_downlink_values_mb",
      {"ground_station_id", "equator_prime"},
      "required_downlink_mb",
      [45.0],
      [46.0]
    )
  end

  test "link-capacity planned-downlink demand remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "link_capacity_pressure_planned_downlink_values_mb",
      {"ground_station_id", "equator_prime"},
      "planned_downlink_mb",
      [10.0],
      [11.0]
    )
  end

  test "link-capacity start bound remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "link_capacity_pressure_start_values_s",
      {"ground_station_id", "equator_prime"},
      "starts_at_s",
      [1_020.0],
      [1_019.0]
    )
  end

  test "link-capacity end bound remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "link_capacity_pressure_end_values_s",
      {"ground_station_id", "equator_prime"},
      "ends_at_s",
      [1_080.0],
      [1_081.0]
    )
  end

  test "link-capacity source-activity identity remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "link_capacity_pressure_source_activity_ids",
      {"ground_station_id", "equator_prime"},
      ["source_activity_ids"],
      ["dl_link_capacity_source"],
      ["stale_dl_link_capacity_source"]
    )
  end

  test "link-capacity source-window identity remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "link_capacity_pressure_source_window_ids",
      {"ground_station_id", "equator_prime"},
      ["source_window_id", "source_window_ids"],
      ["window_link_capacity", "window_link_capacity_backup"],
      ["stale_window_link_capacity"]
    )
  end

  test "link-capacity selected adjusted throughput remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "link_capacity_pressure_selected_capacity_adjusted_throughput_values_mb",
      {"ground_station_id", "equator_prime"},
      "selected_capacity_adjusted_throughput_mb",
      [10.0],
      [11.0]
    )
  end

  test "link-capacity selected shortfall remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "link_capacity_pressure_selected_downlink_shortfall_values_mb",
      {"ground_station_id", "equator_prime"},
      "selected_downlink_shortfall_mb",
      [35.0],
      [34.0]
    )
  end

  test "link-capacity actual throughput remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "link_capacity_pressure_actual_throughput_values_mb",
      {"ground_station_id", "equator_prime"},
      "actual_throughput_mb",
      [8.0],
      [9.0]
    )
  end

  test "link-capacity actual completion ratio remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "link_capacity_pressure_actual_downlink_completion_ratio_values",
      {"ground_station_id", "equator_prime"},
      "actual_downlink_completion_ratio",
      [0.22],
      [0.5]
    )
  end

  test "link-capacity actual shortfall remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "link_capacity_pressure_actual_downlink_shortfall_values_mb",
      {"ground_station_id", "equator_prime"},
      "actual_downlink_shortfall_mb",
      [37.0],
      [36.0]
    )
  end

  test "link-capacity requirement status remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "link_capacity_pressure_downlink_requirement_statuses",
      {"ground_station_id", "equator_prime"},
      "downlink_requirement_status",
      ["shortfall"],
      ["satisfied"]
    )
  end

  test "link-capacity actual requirement status remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "link_capacity_pressure_actual_downlink_requirement_statuses",
      {"ground_station_id", "equator_prime"},
      "actual_downlink_requirement_status",
      ["shortfall"],
      ["satisfied"]
    )
  end

  test "link-capacity downlink-demand source remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "link_capacity_pressure_downlink_demand_sources",
      {"ground_station_id", "equator_prime"},
      ["downlink_demand_sources"],
      ["mission_objective:relay_collection"],
      ["stale_link_capacity_demand_source"]
    )
  end

  test "link-capacity completion source remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "link_capacity_pressure_downlink_completion_sources",
      {"ground_station_id", "equator_prime"},
      ["downlink_completion_sources"],
      ["link_capacity_report:selected_contacts"],
      ["stale_link_capacity_completion_source"]
    )
  end

  test "link-capacity feedback source remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "link_capacity_pressure_feedback_sources",
      {"ground_station_id", "equator_prime"},
      "feedback_source",
      ["mission_state.source_link_capacity_report.rows"],
      ["stale_link_capacity_feedback_source"]
    )
  end

  test "link-capacity feedback scope remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "link_capacity_pressure_feedback_scopes",
      {"ground_station_id", "equator_prime"},
      "feedback_scope",
      ["link_capacity"],
      ["stale_link_capacity"]
    )
  end

  test "link-capacity trust boundary remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "link_capacity_pressure_trust_boundaries",
      {"ground_station_id", "equator_prime"},
      "trust_boundary",
      ["mission_state_link_capacity_report"],
      ["stale_link_capacity_boundary"]
    )
  end

  test "link-capacity derivation reasons remain source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "link_capacity_pressure_derivation_reasons",
      {"ground_station_id", "equator_prime"},
      ["derivation_reasons"],
      ["link_capacity_selected_downlink_shortfall"],
      ["stale_link_capacity_derivation"]
    )
  end

  test "score-term risk type remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "score_term_pressure_risk_types",
      {"feedback_scope", "score_term"},
      ["type", "risk_type"],
      ["downlink_completion_gap"],
      ["stale_score_term_risk"]
    )
  end

  test "score-term objective identity remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "score_term_pressure_objective_ids",
      {"feedback_scope", "score_term"},
      "objective_id",
      ["score_term:downlink_shortfall"],
      ["score_term:stale"]
    )
  end

  test "score-term objective type remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "score_term_pressure_objective_types",
      {"feedback_scope", "score_term"},
      "objective_type",
      ["score_term_gap"],
      ["stale_score_term_gap"]
    )
  end

  test "score-term latency-objective flag remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "score_term_pressure_latency_objective_values",
      {"feedback_scope", "score_term"},
      "latency_objective",
      [true],
      [false]
    )
  end

  test "score-term target identity remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "score_term_pressure_target_ids",
      {"feedback_scope", "score_term"},
      "target_id",
      ["target_score_term"],
      ["stale_target_score_term"]
    )
  end

  test "score-term scenario identity remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "score_term_pressure_scenario_ids",
      {"feedback_scope", "score_term"},
      "scenario_id",
      ["leo_1"],
      ["stale_leo_1"]
    )
  end

  test "score-term branch identity remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "score_term_pressure_branch_ids",
      {"feedback_scope", "score_term"},
      "branch_id",
      ["urgent"],
      ["stale_urgent"]
    )
  end

  test "score-term station identity remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "score_term_pressure_ground_station_ids",
      {"feedback_scope", "score_term"},
      "ground_station_id",
      ["polar_prime"],
      ["stale_polar_prime"]
    )
  end

  test "score-term collection identity remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "score_term_pressure_collection_ids",
      {"feedback_scope", "score_term"},
      ["collection_id", "collection_ids"],
      ["collection_score_alpha", "collection_score_beta"],
      ["stale_collection_score"]
    )
  end

  test "score-term product identity remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "score_term_pressure_product_ids",
      {"feedback_scope", "score_term"},
      ["product_id", "product_ids"],
      ["product_score_alpha", "product_score_beta"],
      ["stale_product_score"]
    )
  end

  test "score-term payload identity remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "score_term_pressure_payload_ids",
      {"feedback_scope", "score_term"},
      ["payload_id", "payload_ids"],
      ["payload_score_alpha", "payload_score_beta"],
      ["stale_payload_score"]
    )
  end

  test "score-term instrument identity remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "score_term_pressure_instrument_ids",
      {"feedback_scope", "score_term"},
      ["instrument_id", "instrument_ids"],
      ["instrument_score_alpha", "instrument_score_beta"],
      ["stale_instrument_score"]
    )
  end

  test "score-term start bound remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "score_term_pressure_start_values_s",
      {"feedback_scope", "score_term"},
      "starts_at_s",
      [1_240.0],
      [1_239.0]
    )
  end

  test "score-term end bound remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "score_term_pressure_end_values_s",
      {"feedback_scope", "score_term"},
      "ends_at_s",
      [1_360.0],
      [1_361.0]
    )
  end

  test "score-term required contact demand remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "score_term_pressure_required_contact_values",
      {"feedback_scope", "score_term"},
      "required_contacts",
      [2],
      [3]
    )
  end

  test "score-term planned contact demand remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "score_term_pressure_planned_contact_values",
      {"feedback_scope", "score_term"},
      "planned_contacts",
      [1],
      [0]
    )
  end

  test "score-term required downlink demand remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "score_term_pressure_required_downlink_values_mb",
      {"feedback_scope", "score_term"},
      "required_downlink_mb",
      [80.0],
      [81.0]
    )
  end

  test "score-term planned downlink demand remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "score_term_pressure_planned_downlink_values_mb",
      {"feedback_scope", "score_term"},
      "planned_downlink_mb",
      [35.0],
      [34.0]
    )
  end

  test "score-term maximum latency remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "score_term_pressure_max_latency_values_s",
      {"feedback_scope", "score_term"},
      "max_latency_s",
      [300.0],
      [301.0]
    )
  end

  test "score-term planned latency remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "score_term_pressure_planned_latency_values_s",
      {"feedback_scope", "score_term"},
      "planned_latency_s",
      [420.0],
      [419.0]
    )
  end

  test "score-term required observation demand remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "score_term_pressure_required_observation_values",
      {"feedback_scope", "score_term"},
      "required_observations",
      [2],
      [3]
    )
  end

  test "score-term planned observation demand remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "score_term_pressure_planned_observation_values",
      {"feedback_scope", "score_term"},
      "planned_observations",
      [1],
      [0]
    )
  end

  test "score-term priority remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "score_term_pressure_priorities",
      {"feedback_scope", "score_term"},
      "priority",
      [24.0],
      [23.0]
    )
  end

  test "score-term latitude remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "score_term_pressure_latitude_values_deg",
      {"feedback_scope", "score_term"},
      "latitude_deg",
      [34.1],
      [34.2]
    )
  end

  test "score-term longitude remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "score_term_pressure_longitude_values_deg",
      {"feedback_scope", "score_term"},
      "longitude_deg",
      [-118.2],
      [-118.1]
    )
  end

  test "score-term minimum elevation remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "score_term_pressure_minimum_elevation_values_deg",
      {"feedback_scope", "score_term"},
      "minimum_elevation_deg",
      [15.0],
      [16.0]
    )
  end

  test "score-term source activity remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "score_term_pressure_source_activity_ids",
      {"feedback_scope", "score_term"},
      ["source_activity_id", "source_activity_ids"],
      ["obs_score_source", "dl_score_source"],
      ["stale_score_source"]
    )
  end

  test "score-term key remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "score_term_pressure_keys",
      {"feedback_scope", "score_term"},
      "score_term_key",
      ["collection_latency_gap_s"],
      ["stale_score_term_key"]
    )
  end

  test "score-term value remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "score_term_pressure_values",
      {"feedback_scope", "score_term"},
      "score_term_value",
      [120.0],
      [121.0]
    )
  end

  test "score-term timeline score remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "score_term_pressure_timeline_score_values",
      {"feedback_scope", "score_term"},
      "timeline_score",
      [9.5],
      [9.6]
    )
  end

  test "score-term map remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "score_term_pressure_score_term_maps",
      {"feedback_scope", "score_term"},
      "score_terms",
      [
        %{
          "collection_latency_gap_s" => 120.0,
          "downlink_shortfall_mb" => 45.0
        }
      ],
      [%{"collection_latency_gap_s" => 121.0}]
    )
  end

  test "score-term downlink-demand source remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "score_term_pressure_downlink_demand_sources",
      {"feedback_scope", "score_term"},
      ["downlink_demand_sources"],
      ["score_term:score_term:downlink_shortfall:collection_latency_gap_s"],
      ["stale_score_term_demand_source"]
    )
  end

  test "score-term completion source remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "score_term_pressure_downlink_completion_sources",
      {"feedback_scope", "score_term"},
      ["downlink_completion_sources"],
      ["score_term:score_term:downlink_shortfall:collection_latency_gap_s"],
      ["stale_score_term_completion_source"]
    )
  end

  test "score-term feedback source remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "score_term_pressure_feedback_sources",
      {"feedback_scope", "score_term"},
      "feedback_source",
      ["mission_state.source_score_term_report.rows"],
      ["stale_score_term_feedback_source"]
    )
  end

  test "score-term feedback scope remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "score_term_pressure_feedback_scopes",
      {"feedback_scope", "score_term"},
      "feedback_scope",
      ["score_term"],
      ["stale_score_term"]
    )
  end

  test "score-term trust boundary remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "score_term_pressure_trust_boundaries",
      {"feedback_scope", "score_term"},
      "trust_boundary",
      ["mission_state_score_term_report"],
      ["stale_score_term_boundary"]
    )
  end

  test "score-term derivation reasons remain source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "score_term_pressure_derivation_reasons",
      {"feedback_scope", "score_term"},
      ["derivation_reasons"],
      [
        "collection_latency_gap",
        "score_term_collection_latency_gap",
        "score_term_collection_latency_gap_s"
      ],
      ["stale_score_term_derivation"]
    )
  end

  test "station conflict expiration risk context remains source exact across handoffs" do
    assert_risk_expiration_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "station_reservation_conflict_expiration_statuses",
      {"contact_id", "dl_reservation_conflict"},
      "active"
    )
  end

  test "station conflict contact identity remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "station_reservation_conflict_contact_ids",
      {"contact_id", "dl_reservation_conflict"},
      "contact_id",
      ["dl_reservation_conflict"],
      ["stale_dl_reservation_conflict"]
    )
  end

  test "station conflict source activity identity remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "station_reservation_conflict_source_activity_ids",
      {"contact_id", "dl_reservation_conflict"},
      ["source_activity_id", "source_activity_ids"],
      ["dl_reservation_conflict"],
      ["stale_dl_reservation_conflict"]
    )
  end

  test "station conflict ground-station identity remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "station_reservation_conflict_ground_station_ids",
      {"contact_id", "dl_reservation_conflict"},
      "ground_station_id",
      ["equator_prime"],
      ["stale_equator_prime"]
    )
  end

  test "station conflict reservation identity remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "station_reservation_conflict_reservation_ids",
      {"contact_id", "dl_reservation_conflict"},
      "station_reservation_id",
      ["reservation_conflict_1"],
      ["stale_reservation_conflict_1"]
    )
  end

  test "station conflict reservation owner remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "station_reservation_conflict_reserved_by",
      {"contact_id", "dl_reservation_conflict"},
      "station_reserved_by",
      ["ops_team_b"],
      ["stale_ops_team_b"]
    )
  end

  test "station conflict reservation status remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "station_reservation_conflict_statuses",
      {"contact_id", "dl_reservation_conflict"},
      "station_reservation_status",
      ["confirmed"],
      ["cancelled"]
    )
  end

  test "station conflict match status remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "station_reservation_conflict_match_statuses",
      {"contact_id", "dl_reservation_conflict"},
      "station_reservation_match_status",
      ["overlap"],
      ["matched"]
    )
  end

  test "station conflict reservation deadline remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "station_reservation_conflict_expires_at_values_s",
      {"contact_id", "dl_reservation_conflict"},
      "station_reservation_expires_at_s",
      [360.0],
      [361.0]
    )
  end

  test "station conflict derivation reason remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "station_reservation_conflict_derivation_reasons",
      {"contact_id", "dl_reservation_conflict"},
      "derivation_reasons",
      ["contact_allocation_reservation_conflict"],
      ["stale_contact_allocation_reservation_conflict"]
    )
  end

  test "station conflict feedback source remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "station_reservation_conflict_feedback_sources",
      {"contact_id", "dl_reservation_conflict"},
      "feedback_source",
      ["mission_state.source_contact_allocation_reservation_conflict_summary"],
      ["stale.source_contact_allocation_reservation_conflict_summary"]
    )
  end

  test "station conflict feedback scope remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "station_reservation_conflict_feedback_scopes",
      {"contact_id", "dl_reservation_conflict"},
      "feedback_scope",
      ["contact_allocation"],
      ["stale_contact_allocation"]
    )
  end

  test "station conflict trust boundary remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "station_reservation_conflict_trust_boundaries",
      {"contact_id", "dl_reservation_conflict"},
      "trust_boundary",
      ["mission_state_reservation_conflict_summary"],
      ["stale_mission_state_reservation_conflict_summary"]
    )
  end

  test "station hold expiration risk context remains source exact across handoffs" do
    assert_risk_expiration_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "station_reservation_hold_expiration_statuses",
      {"contact_id", "dl_hold_import_review"},
      "active"
    )
  end

  test "station hold identity remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "station_reservation_hold_ids",
      {"contact_id", "dl_hold_import_review"},
      "station_reservation_hold_ids",
      ["reservation_hold_active", "reservation_hold_missing"],
      ["stale_reservation_hold_active"]
    )
  end

  test "station hold identity routing by import status remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "station_reservation_hold_ids_by_import_status",
      {"contact_id", "dl_hold_import_review"},
      "station_reservation_hold_ids_by_import_status",
      [
        %{
          "review_required_before_import" => [
            "reservation_hold_active",
            "reservation_hold_missing"
          ]
        }
      ],
      [%{"review_required_before_import" => ["stale_reservation_hold"]}]
    )
  end

  test "station hold identity routing by required action remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "station_reservation_hold_ids_by_required_import_action",
      {"contact_id", "dl_hold_import_review"},
      "station_reservation_hold_ids_by_required_import_action",
      [
        %{
          "review_station_provider_contention" => ["reservation_hold_missing"],
          "review_station_reservation_overlap" => ["reservation_hold_active"]
        }
      ],
      [%{"review_station_provider_contention" => ["stale_reservation_hold"]}]
    )
  end

  test "station hold identity routing by direction remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "station_reservation_hold_ids_by_direction",
      {"contact_id", "dl_hold_import_review"},
      "station_reservation_hold_ids_by_direction",
      [
        %{
          "downlink" => ["reservation_hold_active"],
          "uplink" => ["reservation_hold_missing"]
        }
      ],
      [%{"downlink" => ["stale_reservation_hold"]}]
    )
  end

  test "station hold identity routing by direction and station remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "station_reservation_hold_ids_by_direction_and_ground_station_id",
      {"contact_id", "dl_hold_import_review"},
      "station_reservation_hold_ids_by_direction_and_ground_station_id",
      [
        %{
          "downlink:equator_prime" => ["reservation_hold_active"],
          "uplink:equator_prime" => ["reservation_hold_missing"]
        }
      ],
      [%{"downlink:equator_prime" => ["stale_reservation_hold"]}]
    )
  end

  test "station hold contact identity remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "station_reservation_hold_contact_ids",
      {"contact_id", "dl_hold_import_review"},
      "contact_id",
      ["dl_hold_import_review"],
      ["stale_dl_hold_import_review"]
    )
  end

  test "station hold contact routing by import status remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "station_reservation_hold_contact_ids_by_import_status",
      {"contact_id", "dl_hold_import_review"},
      "station_reservation_hold_contact_ids_by_import_status",
      [%{"review_required_before_import" => ["dl_hold_import_review"]}],
      [%{"review_required_before_import" => ["stale_hold_contact"]}]
    )
  end

  test "station hold contact routing by expiration status remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "station_reservation_hold_contact_ids_by_expiration_status",
      {"contact_id", "dl_hold_import_review"},
      "station_reservation_hold_contact_ids_by_expiration_status",
      [%{"active" => ["dl_hold_import_review"]}],
      [%{"active" => ["stale_hold_contact"]}]
    )
  end

  test "station hold contact routing by direction remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "station_reservation_hold_contact_ids_by_direction",
      {"contact_id", "dl_hold_import_review"},
      "station_reservation_hold_contact_ids_by_direction",
      [%{"downlink" => ["dl_hold_import_review"]}],
      [%{"downlink" => ["stale_hold_contact"]}]
    )
  end

  test "station hold contact routing by direction and station remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "station_reservation_hold_contact_ids_by_direction_and_ground_station_id",
      {"contact_id", "dl_hold_import_review"},
      "station_reservation_hold_contact_ids_by_direction_and_ground_station_id",
      [%{"downlink:equator_prime" => ["dl_hold_import_review"]}],
      [%{"downlink:equator_prime" => ["stale_hold_contact"]}]
    )
  end

  test "station hold counts by import status remain source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "station_reservation_hold_import_status_count_maps",
      {"contact_id", "dl_hold_import_review"},
      "station_reservation_hold_import_status_counts",
      [%{"review_required_before_import" => 2}],
      [%{"review_required_before_import" => 3}]
    )
  end

  test "station hold counts by required action remain source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "station_reservation_hold_required_import_action_count_maps",
      {"contact_id", "dl_hold_import_review"},
      "station_reservation_hold_required_import_action_counts",
      [
        %{
          "review_station_provider_contention" => 1,
          "review_station_reservation_overlap" => 1
        }
      ],
      [%{"review_station_provider_contention" => 2}]
    )
  end

  test "station hold import execution boundary remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "station_reservation_hold_import_execution_boundaries",
      {"contact_id", "dl_hold_import_review"},
      "station_reservation_hold_import_execution_boundary",
      ["artifact_only_no_provider_or_cadence_writes"],
      ["provider_and_cadence_writes_allowed"]
    )
  end

  test "station hold provider-write boundary remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "station_reservation_hold_provider_write_values",
      {"contact_id", "dl_hold_import_review"},
      "station_reservation_hold_provider_write",
      ["not_performed_by_summary"],
      ["performed_by_summary"]
    )
  end

  test "station hold Cadence-write boundary remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "station_reservation_hold_cadence_write_values",
      {"contact_id", "dl_hold_import_review"},
      "station_reservation_hold_cadence_write",
      ["not_performed_by_summary"],
      ["performed_by_summary"]
    )
  end

  test "station hold reservation-acceptance boundary remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "station_reservation_hold_reservation_acceptance_values",
      {"contact_id", "dl_hold_import_review"},
      "station_reservation_hold_reservation_acceptance",
      ["not_performed_by_summary"],
      ["performed_by_summary"]
    )
  end

  test "station hold feedback source remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "station_reservation_hold_feedback_sources",
      {"contact_id", "dl_hold_import_review"},
      "feedback_source",
      ["mission_state.source_station_reservation_hold_import_readiness_summary"],
      ["mission_state.stale_station_reservation_hold_import_readiness_summary"]
    )
  end

  test "station hold feedback scope remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "station_reservation_hold_feedback_scopes",
      {"contact_id", "dl_hold_import_review"},
      "feedback_scope",
      ["station_reservation_hold_import_readiness"],
      ["stale_station_reservation_hold_import_readiness"]
    )
  end

  test "station hold trust boundary remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "station_reservation_hold_trust_boundaries",
      {"contact_id", "dl_hold_import_review"},
      "trust_boundary",
      ["mission_state_station_reservation_hold_import_readiness_summary"],
      ["mission_state_stale_station_reservation_hold_import_readiness_summary"]
    )
  end

  test "station hold source summary remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "source_station_reservation_hold_import_readiness_summaries",
      {"contact_id", "dl_hold_import_review"},
      "source_station_reservation_hold_import_readiness_summary",
      [
        %{
          "model" => "artifact_only_station_reservation_hold_import_readiness_summary",
          "source_artifact_type" => "station_reservation_report.v1",
          "source" => "station_calendar_report.reservation_evidence",
          "reservation_hold_count" => 2,
          "import_readiness_status" => "review_required",
          "import_classification" => "review_only"
        }
      ],
      [
        %{
          "model" => "artifact_only_station_reservation_hold_import_readiness_summary",
          "source_artifact_type" => "station_reservation_report.v1",
          "source" => "stale_station_calendar_report.reservation_evidence",
          "reservation_hold_count" => 2,
          "import_readiness_status" => "review_required",
          "import_classification" => "review_only"
        }
      ]
    )
  end

  test "station hold summary model remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "station_reservation_hold_import_readiness_summary_models",
      {"contact_id", "dl_hold_import_review"},
      "station_reservation_hold_import_readiness_summary_model",
      ["artifact_only_station_reservation_hold_import_readiness_summary"],
      ["stale_station_reservation_hold_import_readiness_summary"]
    )
  end

  test "station hold summary source remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "station_reservation_hold_import_readiness_sources",
      {"contact_id", "dl_hold_import_review"},
      "station_reservation_hold_import_readiness_source",
      ["station_calendar_report.reservation_evidence"],
      ["stale_station_calendar_report.reservation_evidence"]
    )
  end

  test "station hold summary source artifact type remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "station_reservation_hold_import_readiness_source_artifact_types",
      {"contact_id", "dl_hold_import_review"},
      "station_reservation_hold_import_readiness_source_artifact_type",
      ["station_reservation_report.v1"],
      ["stale_station_reservation_report.v1"]
    )
  end

  test "station hold import status remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "station_reservation_hold_import_statuses",
      {"contact_id", "dl_hold_import_review"},
      "station_reservation_hold_import_status",
      ["review_required_before_import"],
      ["ready_for_import"]
    )
  end

  test "station hold readiness status remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "station_reservation_hold_import_readiness_statuses",
      {"contact_id", "dl_hold_import_review"},
      "station_reservation_hold_import_readiness_status",
      ["review_required"],
      ["ready"]
    )
  end

  test "station hold import classification remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "station_reservation_hold_import_classifications",
      {"contact_id", "dl_hold_import_review"},
      "station_reservation_hold_import_classification",
      ["review_only"],
      ["auto_import"]
    )
  end

  test "station hold count remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "station_reservation_hold_count_values",
      {"contact_id", "dl_hold_import_review"},
      "station_reservation_hold_count",
      [2],
      [3]
    )
  end

  test "station calendar expiration risk context remains source exact across handoffs" do
    assert_risk_expiration_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "station_calendar_pressure_station_reservation_expiration_statuses",
      {"station_reservation_id", "reservation_calendar_selected"},
      "active"
    )
  end

  test "station calendar reservation deadlines remain source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "station_calendar_pressure_station_reservation_expires_at_values_s",
      {"station_reservation_id", "reservation_calendar_selected"},
      "station_reservation_expires_at_s",
      [1_260.0],
      [0.0]
    )
  end

  test "station calendar reservation identity remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "station_calendar_pressure_station_reservation_ids",
      {"station_reservation_id", "reservation_calendar_selected"},
      "station_reservation_id",
      ["reservation_calendar_selected"],
      ["reservation_calendar_stale"]
    )
  end

  test "station calendar reservation ownership remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "station_calendar_pressure_station_reserved_by",
      {"station_reservation_id", "reservation_calendar_selected"},
      "station_reserved_by",
      ["partner_team"],
      ["stale_partner_team"]
    )
  end

  test "station calendar reservation status remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "station_calendar_pressure_station_reservation_statuses",
      {"station_reservation_id", "reservation_calendar_selected"},
      "station_reservation_status",
      ["confirmed"],
      ["stale_status"]
    )
  end

  test "station calendar reservation match status remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "station_calendar_pressure_station_reservation_match_statuses",
      {"station_reservation_id", "reservation_calendar_selected"},
      "station_reservation_match_status",
      ["overlap"],
      ["stale_match_status"]
    )
  end

  test "station calendar entry identity remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "station_calendar_pressure_station_calendar_entry_ids",
      {"station_reservation_id", "reservation_calendar_selected"},
      "station_calendar_entry_id",
      ["calendar_selected_reserved"],
      ["stale_calendar_entry"]
    )
  end

  test "station calendar provider identity remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "station_calendar_pressure_station_calendar_provider_ids",
      {"station_reservation_id", "reservation_calendar_selected"},
      "station_calendar_provider_id",
      ["partner_calendar"],
      ["stale_provider"]
    )
  end

  test "station calendar provider entry identity remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "station_calendar_pressure_station_calendar_provider_entry_ids",
      {"station_reservation_id", "reservation_calendar_selected"},
      "station_calendar_provider_entry_id",
      ["partner_entry_calendar_selected"],
      ["stale_provider_entry"]
    )
  end

  test "station calendar direction remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "station_calendar_pressure_station_calendar_directions",
      {"station_reservation_id", "reservation_calendar_selected"},
      "station_calendar_directions",
      ["downlink"],
      ["uplink"]
    )
  end

  test "station calendar status remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "station_calendar_pressure_station_calendar_statuses",
      {"station_reservation_id", "reservation_calendar_selected"},
      "station_calendar_status",
      ["reserved"],
      ["maintenance"]
    )
  end

  test "station calendar availability remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "station_calendar_pressure_station_availabilities",
      {"station_reservation_id", "reservation_calendar_selected"},
      "station_availability",
      ["reserved"],
      ["unavailable"]
    )
  end

  test "station calendar contention status remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "station_calendar_pressure_station_contention_statuses",
      {"station_reservation_id", "reservation_calendar_selected"},
      "station_contention_status",
      ["reserved_overlap"],
      ["available"]
    )
  end

  test "station calendar overlap count remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "station_calendar_pressure_station_calendar_overlap_count_values",
      {"station_reservation_id", "reservation_calendar_selected"},
      "station_calendar_overlap_count",
      [2],
      [99]
    )
  end

  test "station calendar overlap entry identity remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "station_calendar_pressure_station_calendar_overlap_entry_ids",
      {"station_reservation_id", "reservation_calendar_selected"},
      "station_calendar_overlap_entry_ids",
      ["calendar_selected_reserved", "calendar_selected_maintenance"],
      ["calendar_selected_reserved", "calendar_stale_maintenance"]
    )
  end

  test "station calendar overlap availability remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "station_calendar_pressure_station_calendar_overlap_availabilities",
      {"station_reservation_id", "reservation_calendar_selected"},
      "station_calendar_overlap_availabilities",
      ["reserved", "maintenance"],
      ["reserved", "available"]
    )
  end

  test "station calendar entry ambiguity remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "station_calendar_pressure_station_calendar_entry_ambiguous_values",
      {"station_reservation_id", "reservation_calendar_selected"},
      "station_calendar_entry_ambiguous",
      [true],
      [false]
    )
  end

  test "station calendar ambiguous entry count remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "station_calendar_pressure_station_calendar_ambiguous_entry_count_values",
      {"station_reservation_id", "reservation_calendar_selected"},
      "station_calendar_ambiguous_entry_count",
      [2],
      [99]
    )
  end

  test "station calendar ambiguous entry identity remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "station_calendar_pressure_station_calendar_ambiguous_entry_ids",
      {"station_reservation_id", "reservation_calendar_selected"},
      "station_calendar_ambiguous_entry_ids",
      ["calendar_selected_reserved", "calendar_selected_backup"],
      ["calendar_selected_reserved", "calendar_stale_backup"]
    )
  end

  test "station calendar reservation overlap count remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "station_calendar_pressure_station_calendar_reservation_overlap_count_values",
      {"station_reservation_id", "reservation_calendar_selected"},
      "station_calendar_reservation_overlap_count",
      [1],
      [99]
    )
  end

  test "calendar-scoped reservation identity remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "station_calendar_pressure_station_calendar_reservation_ids",
      {"station_reservation_id", "reservation_calendar_selected"},
      "station_calendar_reservation_ids",
      ["reservation_calendar_selected"],
      ["reservation_calendar_stale"]
    )
  end

  test "calendar-scoped reservation ownership remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "station_calendar_pressure_station_calendar_reserved_by",
      {"station_reservation_id", "reservation_calendar_selected"},
      "station_calendar_reserved_by",
      ["partner_team"],
      ["stale_team"]
    )
  end

  test "calendar-scoped reservation status remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "station_calendar_pressure_station_calendar_reservation_statuses",
      {"station_reservation_id", "reservation_calendar_selected"},
      "station_calendar_reservation_statuses",
      ["confirmed"],
      ["cancelled"]
    )
  end

  test "station calendar trust-boundary status remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "station_calendar_pressure_station_calendar_trust_boundary_statuses",
      {"station_reservation_id", "reservation_calendar_selected"},
      "station_calendar_trust_boundary_status",
      ["declared"],
      ["undeclared"]
    )
  end

  test "provider calendar contention group remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "station_calendar_pressure_provider_calendar_contention_group_ids",
      {"station_reservation_id", "reservation_calendar_selected"},
      "provider_calendar_contention_group_id",
      ["provider_contention_selected"],
      ["provider_contention_stale"]
    )
  end

  test "provider calendar contention status remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "station_calendar_pressure_provider_calendar_contention_statuses",
      {"station_reservation_id", "reservation_calendar_selected"},
      "provider_calendar_contention_status",
      ["review_required"],
      ["resolved"]
    )
  end

  test "provider calendar contention entry identity remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "station_calendar_pressure_provider_calendar_contention_entry_ids",
      {"station_reservation_id", "reservation_calendar_selected"},
      "provider_calendar_contention_entry_ids",
      ["calendar_selected_reserved", "calendar_selected_maintenance"],
      ["calendar_selected_reserved", "calendar_stale_maintenance"]
    )
  end

  test "provider calendar contention provider identity remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "station_calendar_pressure_provider_calendar_contention_provider_ids",
      {"station_reservation_id", "reservation_calendar_selected"},
      "provider_calendar_contention_provider_ids",
      ["partner_calendar"],
      ["stale_partner_calendar"]
    )
  end

  test "provider calendar contention provider-entry identity remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "station_calendar_pressure_provider_calendar_contention_provider_entry_ids",
      {"station_reservation_id", "reservation_calendar_selected"},
      "provider_calendar_contention_provider_entry_ids",
      ["partner_entry_calendar_selected", "partner_entry_calendar_maintenance"],
      ["partner_entry_calendar_selected", "stale_partner_entry_calendar_maintenance"]
    )
  end

  test "provider calendar contention availability remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "station_calendar_pressure_provider_calendar_contention_availabilities",
      {"station_reservation_id", "reservation_calendar_selected"},
      "provider_calendar_contention_availabilities",
      ["reserved", "maintenance"],
      ["reserved", "unavailable"]
    )
  end

  test "provider calendar contention direction remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "station_calendar_pressure_provider_calendar_contention_directions",
      {"station_reservation_id", "reservation_calendar_selected"},
      "provider_calendar_contention_directions",
      ["downlink"],
      ["uplink"]
    )
  end

  test "provider calendar contention reservation identity remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "station_calendar_pressure_provider_calendar_contention_reservation_ids",
      {"station_reservation_id", "reservation_calendar_selected"},
      "provider_calendar_contention_reservation_ids",
      ["reservation_calendar_selected"],
      ["reservation_calendar_stale"]
    )
  end

  test "provider calendar contention reservation owner remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "station_calendar_pressure_provider_calendar_contention_reserved_by",
      {"station_reservation_id", "reservation_calendar_selected"},
      "provider_calendar_contention_reserved_by",
      ["partner_team"],
      ["stale_partner_team"]
    )
  end

  test "provider calendar contention reservation status remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "station_calendar_pressure_provider_calendar_contention_reservation_statuses",
      {"station_reservation_id", "reservation_calendar_selected"},
      "provider_calendar_contention_reservation_statuses",
      ["confirmed"],
      ["pending"]
    )
  end

  test "provider calendar contention trust-boundary status remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "station_calendar_pressure_provider_calendar_contention_trust_boundary_statuses",
      {"station_reservation_id", "reservation_calendar_selected"},
      "provider_calendar_contention_trust_boundary_statuses",
      ["declared"],
      ["inferred"]
    )
  end

  test "provider calendar contention overlap pair remains source exact across handoffs" do
    expected_pair = %{
      "left_entry_id" => "calendar_selected_reserved",
      "right_entry_id" => "calendar_selected_maintenance",
      "overlap_starts_at_s" => 1_170.0,
      "overlap_ends_at_s" => 1_230.0,
      "overlap_duration_s" => 60.0
    }

    stale_pair = Map.put(expected_pair, "right_entry_id", "calendar_stale_maintenance")

    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "station_calendar_pressure_provider_calendar_contention_overlap_pairs",
      {"station_reservation_id", "reservation_calendar_selected"},
      "provider_calendar_contention_overlap_pairs",
      [expected_pair],
      [stale_pair]
    )
  end

  test "station calendar ground-station identity remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "station_calendar_pressure_ground_station_ids",
      {"station_reservation_id", "reservation_calendar_selected"},
      "ground_station_id",
      ["canberra"],
      ["stale_canberra"]
    )
  end

  test "station calendar start timing remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "station_calendar_pressure_start_values_s",
      {"station_reservation_id", "reservation_calendar_selected"},
      "starts_at_s",
      [1_170.0],
      [1_171.0]
    )
  end

  test "station calendar end timing remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "station_calendar_pressure_end_values_s",
      {"station_reservation_id", "reservation_calendar_selected"},
      "ends_at_s",
      [1_230.0],
      [1_231.0]
    )
  end

  test "station calendar capacity fraction remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "station_calendar_pressure_capacity_fraction_values",
      {"station_reservation_id", "reservation_calendar_selected"},
      "capacity_fraction",
      [0.4],
      [0.6]
    )
  end

  test "station calendar risk type remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "station_calendar_pressure_risk_types",
      {"station_reservation_id", "reservation_calendar_selected"},
      "type",
      ["ground_station_reserved"],
      ["ground_station_outage"],
      :drop_risk
    )
  end

  test "station calendar required action remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "station_calendar_pressure_required_operator_actions",
      {"station_reservation_id", "reservation_calendar_selected"},
      "required_operator_action",
      ["review_station_calendar"],
      ["review_stale_station_calendar"]
    )
  end

  test "station calendar feedback source remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "station_calendar_pressure_feedback_sources",
      {"station_reservation_id", "reservation_calendar_selected"},
      "feedback_source",
      ["mission_state.source_station_calendar_report.affected_contacts"],
      ["mission_state.stale_station_calendar_report.affected_contacts"]
    )
  end

  test "station calendar feedback scope remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "station_calendar_pressure_feedback_scopes",
      {"station_reservation_id", "reservation_calendar_selected"},
      "feedback_scope",
      ["station_calendar"],
      ["contact_intent"]
    )
  end

  test "station calendar trust boundary remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "station_calendar_pressure_trust_boundaries",
      {"station_reservation_id", "reservation_calendar_selected"},
      "trust_boundary",
      ["mission_state_station_calendar_report"],
      ["mission_state_stale_station_calendar_report"]
    )
  end

  test "station calendar derivation reasons remain source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "station_calendar_pressure_derivation_reasons",
      {"station_reservation_id", "reservation_calendar_selected"},
      "derivation_reasons",
      ["station_calendar_reserved", "reserved_overlap", "overlap"],
      ["station_calendar_reserved", "reserved_overlap", "stale_overlap"]
    )
  end

  test "contact allocation risk type remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "contact_allocation_pressure_risk_types",
      {"contact_id", "dl_reservation_conflict"},
      ["type", "risk_type"],
      ["downlink_completion_gap"],
      ["stale_downlink_completion_gap"]
    )
  end

  test "contact allocation contact identity remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "contact_allocation_pressure_contact_ids",
      {"contact_id", "dl_reservation_conflict"},
      "contact_id",
      ["dl_reservation_conflict"],
      ["stale_dl_reservation_conflict"]
    )
  end

  test "contact allocation scenario identity remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "contact_allocation_pressure_scenario_ids",
      {"contact_id", "dl_reservation_conflict"},
      "scenario_id",
      ["leo_1"],
      ["stale_leo_1"]
    )
  end

  test "contact allocation spacecraft identity remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "contact_allocation_pressure_spacecraft_ids",
      {"contact_id", "dl_reservation_conflict"},
      "spacecraft_id",
      ["leo_1"],
      ["stale_leo_1"]
    )
  end

  test "contact allocation station identity remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "contact_allocation_pressure_ground_station_ids",
      {"contact_id", "dl_reservation_conflict"},
      "ground_station_id",
      ["equator_prime"],
      ["stale_equator_prime"]
    )
  end

  test "contact allocation source activity remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "contact_allocation_pressure_source_activity_ids",
      {"contact_id", "dl_reservation_conflict"},
      ["source_activity_id", "source_activity_ids"],
      ["dl_reservation_conflict"],
      ["stale_dl_reservation_conflict"]
    )
  end

  test "contact allocation source window remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "contact_allocation_pressure_source_window_ids",
      {"contact_id", "dl_reservation_conflict"},
      "source_window_id",
      ["window_allocation_deferred"],
      ["stale_window_allocation_deferred"]
    )
  end

  test "contact allocation required contact demand remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "contact_allocation_pressure_required_contact_values",
      {"contact_id", "dl_reservation_conflict"},
      "required_contacts",
      [1],
      [2]
    )
  end

  test "contact allocation planned contact demand remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "contact_allocation_pressure_planned_contact_values",
      {"contact_id", "dl_reservation_conflict"},
      "planned_contacts",
      [0],
      [1]
    )
  end

  test "contact allocation required downlink demand remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "contact_allocation_pressure_required_downlink_values_mb",
      {"contact_id", "dl_reservation_conflict"},
      "required_downlink_mb",
      [43.0],
      [44.0]
    )
  end

  test "contact allocation planned downlink demand remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "contact_allocation_pressure_planned_downlink_values_mb",
      {"contact_id", "dl_reservation_conflict"},
      "planned_downlink_mb",
      [0.0],
      [1.0]
    )
  end

  test "contact allocation start bound remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "contact_allocation_pressure_start_values_s",
      {"contact_id", "dl_reservation_conflict"},
      "starts_at_s",
      [1_620.0],
      [1_621.0]
    )
  end

  test "contact allocation end bound remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "contact_allocation_pressure_end_values_s",
      {"contact_id", "dl_reservation_conflict"},
      "ends_at_s",
      [1_680.0],
      [1_681.0]
    )
  end

  test "contact allocation realized status remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "contact_allocation_pressure_realized_statuses",
      {"contact_id", "dl_reservation_conflict"},
      "realized_status",
      ["deferred"],
      ["selected"]
    )
  end

  test "contact allocation result remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "contact_allocation_pressure_contact_results",
      {"contact_id", "dl_reservation_conflict"},
      "contact_result",
      ["same_station_contention"],
      ["completed"]
    )
  end

  test "contact allocation status remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "contact_allocation_pressure_allocation_statuses",
      {"contact_id", "dl_reservation_conflict"},
      "allocation_status",
      ["deferred"],
      ["selected"]
    )
  end

  test "contact allocation effective status remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "contact_allocation_pressure_effective_allocation_statuses",
      {"contact_id", "dl_reservation_conflict"},
      "effective_allocation_status",
      ["deferred"],
      ["selected"]
    )
  end

  test "contact allocation reason remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "contact_allocation_pressure_allocation_reasons",
      {"contact_id", "dl_reservation_conflict"},
      "allocation_reason",
      ["same_station_contention"],
      ["capacity_available"]
    )
  end

  test "contact allocation review status remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "contact_allocation_pressure_review_statuses",
      {"contact_id", "dl_reservation_conflict"},
      "review_status",
      ["operator_review_required"],
      ["not_required"]
    )
  end

  test "contact allocation approval status remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "contact_allocation_pressure_approval_statuses",
      {"contact_id", "dl_reservation_conflict"},
      "approval_status",
      ["operator_review_required"],
      ["approved"]
    )
  end

  test "contact allocation policy classification remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "contact_allocation_pressure_policy_classifications",
      {"contact_id", "dl_reservation_conflict"},
      "policy_classification",
      ["review_only"],
      ["approved"]
    )
  end

  test "contact allocation policy bundle remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "contact_allocation_pressure_policy_bundle_ids",
      {"contact_id", "dl_reservation_conflict"},
      "policy_bundle_id",
      ["contact_allocation_policy_v1"],
      ["stale_contact_allocation_policy_v1"]
    )
  end

  test "contact allocation reservation identity remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "contact_allocation_pressure_station_reservation_ids",
      {"contact_id", "dl_reservation_conflict"},
      "station_reservation_id",
      ["reservation_conflict_1"],
      ["stale_reservation_conflict_1"]
    )
  end

  test "contact allocation reservation owner remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "contact_allocation_pressure_station_reserved_by",
      {"contact_id", "dl_reservation_conflict"},
      "station_reserved_by",
      ["ops_team_b"],
      ["stale_ops_team_b"]
    )
  end

  test "contact allocation reservation status remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "contact_allocation_pressure_station_reservation_statuses",
      {"contact_id", "dl_reservation_conflict"},
      "station_reservation_status",
      ["confirmed"],
      ["cancelled"]
    )
  end

  test "contact allocation reservation match remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "contact_allocation_pressure_station_reservation_match_statuses",
      {"contact_id", "dl_reservation_conflict"},
      "station_reservation_match_status",
      ["overlap"],
      ["matched"]
    )
  end

  test "contact allocation calendar entry identity remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "contact_allocation_pressure_station_calendar_entry_ids",
      {"contact_id", "dl_reservation_conflict"},
      "station_calendar_entry_id",
      ["calendar_allocation_deferred"],
      ["stale_calendar_allocation_deferred"]
    )
  end

  test "contact allocation calendar entry status remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "contact_allocation_pressure_station_calendar_entry_statuses",
      {"contact_id", "dl_reservation_conflict"},
      "station_calendar_entry_status",
      ["reserved"],
      ["available"]
    )
  end

  test "contact allocation calendar direction remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "contact_allocation_pressure_station_calendar_directions",
      {"contact_id", "dl_reservation_conflict"},
      "station_calendar_directions",
      ["downlink"],
      ["uplink"]
    )
  end

  test "contact allocation downlink demand source remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "contact_allocation_pressure_downlink_demand_sources",
      {"contact_id", "dl_reservation_conflict"},
      "downlink_demand_sources",
      ["contact_allocation:dl_reservation_conflict"],
      ["stale_contact_allocation:dl_reservation_conflict"]
    )
  end

  test "contact allocation downlink completion source remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "contact_allocation_pressure_downlink_completion_sources",
      {"contact_id", "dl_reservation_conflict"},
      "downlink_completion_sources",
      ["contact_allocation_report:selected_contacts"],
      ["stale_contact_allocation_report:selected_contacts"]
    )
  end

  test "contact allocation feedback source remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "contact_allocation_pressure_feedback_sources",
      {"contact_id", "dl_reservation_conflict"},
      "feedback_source",
      ["mission_state.source_contact_allocation_reservation_conflict_summary"],
      ["stale.source_contact_allocation_reservation_conflict_summary"]
    )
  end

  test "contact allocation feedback scope remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "contact_allocation_pressure_feedback_scopes",
      {"contact_id", "dl_reservation_conflict"},
      "feedback_scope",
      ["contact_allocation"],
      ["stale_contact_allocation"]
    )
  end

  test "contact allocation trust boundary remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "contact_allocation_pressure_trust_boundaries",
      {"contact_id", "dl_reservation_conflict"},
      "trust_boundary",
      ["mission_state_reservation_conflict_summary"],
      ["stale_mission_state_reservation_conflict_summary"]
    )
  end

  test "contact allocation derivation reason remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "contact_allocation_pressure_derivation_reasons",
      {"contact_id", "dl_reservation_conflict"},
      "derivation_reasons",
      ["contact_allocation_reservation_conflict"],
      ["stale_contact_allocation_reservation_conflict"]
    )
  end

  test "contact intent risk type remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "contact_intent_pressure_risk_types",
      {"contact_id", "contact_intent:selected_blocked"},
      ["type", "risk_type"],
      ["downlink_completion_gap"],
      ["stale_downlink_completion_gap"]
    )
  end

  test "contact intent contact identity remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "contact_intent_pressure_contact_ids",
      {"contact_id", "contact_intent:selected_blocked"},
      "contact_id",
      ["contact_intent:selected_blocked"],
      ["contact_intent:stale_blocked"]
    )
  end

  test "contact intent source activity identity remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "contact_intent_pressure_source_activity_ids",
      {"contact_id", "contact_intent:selected_blocked"},
      ["source_activity_id", "source_activity_ids"],
      ["dl_contact_intent_selected"],
      ["dl_contact_intent_stale"]
    )
  end

  test "contact intent ground station identity remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "contact_intent_pressure_ground_station_ids",
      {"contact_id", "contact_intent:selected_blocked"},
      "ground_station_id",
      ["deep_space_net"],
      ["stale_ground_station"]
    )
  end

  test "contact intent required contact demand remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "contact_intent_pressure_required_contact_values",
      {"contact_id", "contact_intent:selected_blocked"},
      "required_contacts",
      [1],
      [2]
    )
  end

  test "contact intent planned contact demand remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "contact_intent_pressure_planned_contact_values",
      {"contact_id", "contact_intent:selected_blocked"},
      "planned_contacts",
      [0],
      [1]
    )
  end

  test "contact intent required downlink demand remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "contact_intent_pressure_required_downlink_values_mb",
      {"contact_id", "contact_intent:selected_blocked"},
      "required_downlink_mb",
      [42.0],
      [43.0]
    )
  end

  test "contact intent planned downlink demand remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "contact_intent_pressure_planned_downlink_values_mb",
      {"contact_id", "contact_intent:selected_blocked"},
      "planned_downlink_mb",
      [0.0],
      [1.0]
    )
  end

  test "contact intent start bound remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "contact_intent_pressure_start_values_s",
      {"contact_id", "contact_intent:selected_blocked"},
      "starts_at_s",
      [1_100.0],
      [1_101.0]
    )
  end

  test "contact intent end bound remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "contact_intent_pressure_end_values_s",
      {"contact_id", "contact_intent:selected_blocked"},
      "ends_at_s",
      [1_160.0],
      [1_161.0]
    )
  end

  test "contact intent source window identity remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "contact_intent_pressure_source_window_ids",
      {"contact_id", "contact_intent:selected_blocked"},
      "source_window_id",
      ["window_contact_intent_selected"],
      ["window_contact_intent_stale"]
    )
  end

  test "contact intent timeline identity remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "contact_intent_pressure_timeline_ids",
      {"contact_id", "contact_intent:selected_blocked"},
      "timeline_id",
      ["timeline:contact_intent:selected_blocked"],
      ["timeline:contact_intent:stale_blocked"]
    )
  end

  test "contact intent approval status remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "contact_intent_pressure_approval_statuses",
      {"contact_id", "contact_intent:selected_blocked"},
      "approval_status",
      ["blocked_by_policy"],
      ["approved"]
    )
  end

  test "contact intent required action remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "contact_intent_pressure_required_operator_actions",
      {"contact_id", "contact_intent:selected_blocked"},
      "required_operator_action",
      ["review_contact_intent"],
      ["review_stale_contact_intent"]
    )
  end

  test "contact intent import status remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "contact_intent_pressure_cadence_import_statuses",
      {"contact_id", "contact_intent:selected_blocked"},
      "cadence_import_status",
      ["missing"],
      ["ready"]
    )
  end

  test "contact intent gate status remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "contact_intent_pressure_gate_statuses",
      {"contact_id", "contact_intent:selected_blocked"},
      "contact_intent_gate_status",
      ["blocked_by_policy"],
      ["approved"]
    )
  end

  test "contact intent policy classification remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "contact_intent_pressure_policy_classifications",
      {"contact_id", "contact_intent:selected_blocked"},
      "policy_classification",
      ["blocked_by_policy"],
      ["approved"]
    )
  end

  test "contact intent policy bundle identity remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "contact_intent_pressure_policy_bundle_ids",
      {"contact_id", "contact_intent:selected_blocked"},
      "policy_bundle_id",
      ["contact_command_review_v1"],
      ["stale_contact_command_review_v1"]
    )
  end

  test "contact intent invalid import flag remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "contact_intent_pressure_invalid_cadence_import_values",
      {"contact_id", "contact_intent:selected_blocked"},
      "invalid_cadence_import",
      [true],
      [false]
    )
  end

  test "contact intent invalid import reason remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "contact_intent_pressure_invalid_cadence_import_reasons",
      {"contact_id", "contact_intent:selected_blocked"},
      "invalid_cadence_import_reason",
      ["missing_cadence_import_row"],
      ["stale_cadence_import_reason"]
    )
  end

  test "contact intent activity validity remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "contact_intent_pressure_invalid_activity_input_values",
      {"contact_id", "contact_intent:selected_blocked"},
      "invalid_activity_input",
      [false],
      [true]
    )
  end

  test "invalid contact intent activity reason remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.invalid_contact_intent_artifact(),
      "contact_intent_pressure_invalid_activity_input_reasons",
      {"contact_id", "contact_intent:selected_blocked"},
      "invalid_activity_input_reason",
      ["missing_activity_type"],
      ["stale_invalid_activity_input_reason"]
    )
  end

  test "contact intent station availability remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "contact_intent_pressure_station_availabilities",
      {"contact_id", "contact_intent:selected_blocked"},
      "station_availability",
      ["reserved"],
      ["available"]
    )
  end

  test "contact intent station contention remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "contact_intent_pressure_station_contention_statuses",
      {"contact_id", "contact_intent:selected_blocked"},
      "station_contention_status",
      ["operator_review_required"],
      ["clear"]
    )
  end

  test "contact intent station calendar entry identity remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "contact_intent_pressure_station_calendar_entry_ids",
      {"contact_id", "contact_intent:selected_blocked"},
      "station_calendar_entry_id",
      ["intent_selected_calendar_entry"],
      ["stale_intent_selected_calendar_entry"]
    )
  end

  test "contact intent station calendar provider identity remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "contact_intent_pressure_station_calendar_provider_ids",
      {"contact_id", "contact_intent:selected_blocked"},
      "station_calendar_provider_id",
      ["partner_calendar"],
      ["stale_partner_calendar"]
    )
  end

  test "contact intent station calendar provider entry remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "contact_intent_pressure_station_calendar_provider_entry_ids",
      {"contact_id", "contact_intent:selected_blocked"},
      "station_calendar_provider_entry_id",
      ["partner_entry_selected"],
      ["stale_partner_entry_selected"]
    )
  end

  test "contact intent station calendar direction remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "contact_intent_pressure_station_calendar_directions",
      {"contact_id", "contact_intent:selected_blocked"},
      "station_calendar_directions",
      ["downlink"],
      ["uplink"]
    )
  end

  test "contact intent station calendar status remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "contact_intent_pressure_station_calendar_statuses",
      {"contact_id", "contact_intent:selected_blocked"},
      "station_calendar_status",
      ["reserved"],
      ["available"]
    )
  end

  test "contact intent calendar trust boundary remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "contact_intent_pressure_station_calendar_trust_boundary_statuses",
      {"contact_id", "contact_intent:selected_blocked"},
      "station_calendar_trust_boundary_status",
      ["declared"],
      ["verified"]
    )
  end

  test "contact intent station reservation identity remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "contact_intent_pressure_station_reservation_ids",
      {"contact_id", "contact_intent:selected_blocked"},
      "station_reservation_id",
      ["reservation_intent_selected"],
      ["stale_reservation_intent_selected"]
    )
  end

  test "contact intent station reservation owner remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "contact_intent_pressure_station_reserved_by",
      {"contact_id", "contact_intent:selected_blocked"},
      "station_reserved_by",
      ["partner_team"],
      ["stale_partner_team"]
    )
  end

  test "contact intent station reservation status remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "contact_intent_pressure_station_reservation_statuses",
      {"contact_id", "contact_intent:selected_blocked"},
      "station_reservation_status",
      ["confirmed"],
      ["cancelled"]
    )
  end

  test "contact intent station reservation match remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "contact_intent_pressure_station_reservation_match_statuses",
      {"contact_id", "contact_intent:selected_blocked"},
      "station_reservation_match_status",
      ["unmatched_overlap"],
      ["matched"]
    )
  end

  test "contact intent feedback source remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "contact_intent_pressure_feedback_sources",
      {"contact_id", "contact_intent:selected_blocked"},
      "feedback_source",
      ["mission_state.source_contact_intent.rows"],
      ["mission_state.stale_contact_intent.rows"]
    )
  end

  test "contact intent feedback scope remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "contact_intent_pressure_feedback_scopes",
      {"contact_id", "contact_intent:selected_blocked"},
      "feedback_scope",
      ["contact_intent"],
      ["stale_contact_intent"]
    )
  end

  test "contact intent trust boundary remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "contact_intent_pressure_trust_boundaries",
      {"contact_id", "contact_intent:selected_blocked"},
      "trust_boundary",
      ["mission_state_contact_intent_review"],
      ["mission_state_stale_contact_intent_review"]
    )
  end

  test "contact intent derivation reasons remain source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "contact_intent_pressure_derivation_reasons",
      {"contact_id", "contact_intent:selected_blocked"},
      "derivation_reasons",
      [
        "contact_intent_blocked_by_policy",
        "review_contact_intent",
        "reserved",
        "unmatched_overlap"
      ],
      ["stale_contact_intent_derivation"]
    )
  end

  defp assert_risk_expiration_context_contract(
         artifact,
         field,
         {identity_field, identity_value},
         expected_status
       ) do
    stale_status = if expected_status == "active", do: "expired", else: "active"

    assert_risk_context_contract(
      artifact,
      field,
      {identity_field, identity_value},
      "station_reservation_expiration_status",
      [expected_status],
      [stale_status]
    )
  end

  defp assert_risk_context_contract(
         artifact,
         field,
         {identity_field, identity_value},
         source_field,
         expected_value,
         stale_value
       ) do
    assert_risk_context_contract(
      artifact,
      field,
      {identity_field, identity_value},
      source_field,
      expected_value,
      stale_value,
      :drop_field
    )
  end

  defp assert_risk_context_contract(
         artifact,
         field,
         {identity_field, identity_value},
         source_field,
         expected_value,
         stale_value,
         legacy_mode
       ) do
    recommendation_review_row =
      Enum.find(
        artifact["operator_review_package"]["rows"],
        &(&1["review_type"] == "strategy_recommendation")
      )

    selected_import_row =
      Enum.find(
        artifact["cadence_import_manifest"]["rows"],
        &(&1["import_action"] == "import_strategy_recommendation" and &1["selected"] == true)
      )

    review_import = OrbitalDynamics.cadence_import_manifest(artifact["operator_review_package"])

    review_import_row =
      Enum.find(
        review_import["rows"],
        &(&1["source_review_type"] == "strategy_recommendation")
      )

    assert recommendation_review_row[field] == expected_value
    assert selected_import_row[field] == expected_value
    assert review_import_row[field] == expected_value
    assert review_import_row["source_review_row"][field] == expected_value

    recommendation_review_index =
      Enum.find_index(
        artifact["operator_review_package"]["rows"],
        &(&1["id"] == recommendation_review_row["id"])
      )

    missing_review_context =
      update_in(
        artifact["operator_review_package"],
        ["rows", Access.at(recommendation_review_index)],
        &Map.delete(&1, field)
      )

    assert {:error, missing_review_context_report} =
             Schema.validate_artifact(missing_review_context)

    assert Enum.any?(
             missing_review_context_report["errors"],
             &(&1["path"] == "$.rows[#{recommendation_review_index}].#{field}")
           )

    legacy_review_context =
      update_in(
        artifact["operator_review_package"],
        ["rows", Access.at(recommendation_review_index)],
        &legacy_risk_context_row(
          &1,
          field,
          identity_field,
          identity_value,
          source_field,
          legacy_mode
        )
      )

    assert {:ok, _legacy_review_context} = Schema.validate_artifact(legacy_review_context)

    selected_import_index =
      Enum.find_index(
        artifact["cadence_import_manifest"]["rows"],
        &(&1["id"] == selected_import_row["id"])
      )

    stale_selected_context =
      update_in(
        artifact["cadence_import_manifest"],
        ["rows", Access.at(selected_import_index)],
        &Map.put(&1, field, stale_value)
      )

    assert {:error, stale_selected_context_report} =
             Schema.validate_artifact(stale_selected_context)

    assert Enum.any?(
             stale_selected_context_report["errors"],
             &(&1["path"] == "$.rows[#{selected_import_index}].#{field}")
           )

    review_import_index =
      Enum.find_index(review_import["rows"], &(&1["id"] == review_import_row["id"]))

    missing_review_import_context =
      update_in(
        review_import,
        ["rows", Access.at(review_import_index)],
        &Map.delete(&1, field)
      )

    assert {:error, missing_review_import_context_report} =
             Schema.validate_artifact(missing_review_import_context)

    assert Enum.any?(
             missing_review_import_context_report["errors"],
             &(&1["path"] == "$.rows[#{review_import_index}].#{field}")
           )
  end

  defp legacy_risk_context_row(
         row,
         field,
         identity_field,
         identity_value,
         source_fields,
         :drop_field
       ) do
    row
    |> Map.delete(field)
    |> update_in(["source_recommendation", "risks_remaining"], fn risks ->
      Enum.map(risks, fn risk ->
        if risk[identity_field] == identity_value do
          Enum.reduce(List.wrap(source_fields), risk, &Map.delete(&2, &1))
        else
          risk
        end
      end)
    end)
    |> update_in(["source_recommendation", "explanation"], fn explanation ->
      Enum.map(explanation, fn explanation_row ->
        if explanation_row[identity_field] == identity_value do
          Enum.reduce(List.wrap(source_fields), explanation_row, &Map.delete(&2, &1))
        else
          explanation_row
        end
      end)
    end)
  end

  defp legacy_risk_context_row(
         row,
         field,
         identity_field,
         identity_value,
         _source_field,
         :drop_risk
       ) do
    risks =
      row
      |> get_in(["source_recommendation", "risks_remaining"])
      |> Enum.reject(&(&1[identity_field] == identity_value))

    row
    |> Map.delete(field)
    |> put_in(["source_recommendation", "risks_remaining"], risks)
    |> Map.put("risk_count", length(risks))
  end
end
