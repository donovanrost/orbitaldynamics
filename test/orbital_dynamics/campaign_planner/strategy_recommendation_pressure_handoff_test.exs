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

  @approval_boundary_context_contracts [
    {"identity", "approval_boundary_ids", "approval_boundary", ["command_execution"],
     ["stale_command_execution"]},
    {"status", "approval_boundary_statuses", "approval_boundary_status",
     ["operator_review_required"], ["stale_operator_review_required"]},
    {"reason", "approval_boundary_reasons", "approval_boundary_reason",
     ["command execution requires flight director approval"], ["stale_approval_reason"]},
    {"automation boundary", "automation_boundaries", "automation_boundary",
     ["no_command_execution"], ["stale_automation_boundary"]},
    {"execution boundary", "execution_boundaries", "execution_boundary",
     ["flight_director_approval"], ["stale_execution_boundary"]},
    {"import classification", "approval_boundary_import_classifications", "import_classification",
     ["review_only"], ["stale_import_classification"]},
    {"required operator action", "approval_boundary_required_operator_actions",
     "required_operator_action", ["review_approval_boundary"], ["stale_operator_action"]},
    {"required authority", "approval_boundary_required_authorities", "required_authority",
     ["flight_director"], ["stale_authority"]},
    {"policy bundle", "approval_boundary_policy_bundle_ids", "policy_bundle_id",
     ["flight_rules_v3"], ["stale_policy_bundle"]},
    {"rule identity", "approval_boundary_rule_ids", "rule_id",
     ["no_unapproved_command_execution"], ["stale_rule"]},
    {"feedback source", "approval_boundary_feedback_sources", "feedback_source",
     ["mission_state.source_approval_boundary_policy.rules"],
     ["mission_state.stale_approval_boundary_policy.rules"]},
    {"feedback scope", "approval_boundary_feedback_scopes", "feedback_scope",
     ["approval_boundary"], ["stale_approval_boundary"]},
    {"feedback key", "approval_boundary_feedback_keys", "feedback_key",
     ["no_unapproved_command_execution"], ["stale_feedback_key"]},
    {"trust boundary", "approval_boundary_trust_boundaries", "trust_boundary",
     ["mission_state_approval_boundary_policy"], ["stale_approval_boundary_policy"]}
  ]

  for {description, field, source_field, expected_value, stale_value} <-
        @approval_boundary_context_contracts do
    test "approval-boundary #{description} remains source exact across handoffs" do
      assert_risk_context_contract(
        StrategyRecommendationPressureEventsFixture.artifact(),
        unquote(field),
        {"feedback_scope", "approval_boundary"},
        unquote(source_field),
        unquote(expected_value),
        unquote(stale_value)
      )
    end
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

  @relay_data_path_context_contracts [
    {"risk type", "relay_data_path_risk_types", ["type", "risk_type"],
     ["relay_data_path_pressure"], ["stale_relay_data_path_pressure"]},
    {"ground-station identity", "relay_data_path_ground_station_ids", "ground_station_id",
     ["dss_14"], ["stale_dss_14"]},
    {"route identities", "relay_data_path_route_ids", ["route_id", "route_ids"],
     ["relay_route_review", "relay_route_backup"], ["stale_relay_route"]},
    {"source-spacecraft identity", "relay_data_path_source_spacecraft_ids",
     ["source_spacecraft_id", "source_spacecraft_ids"], ["leo_1"], ["stale_leo_1"]},
    {"relay-spacecraft identity", "relay_data_path_relay_spacecraft_ids",
     ["relay_spacecraft_ids"], ["relay_a"], ["stale_relay"]},
    {"relay-chain identity", "relay_data_path_relay_chain_spacecraft_ids",
     ["relay_chain_spacecraft_ids"], ["relay_a", "relay_b"], ["stale_relay_chain"]},
    {"relay-hop count", "relay_data_path_relay_hop_count_values", "relay_hop_count", [2], [3]},
    {"ground-downlink contact identities", "relay_data_path_ground_downlink_contact_ids",
     ["ground_downlink_contact_id", "ground_downlink_contact_ids"],
     ["downlink_relay_review", "downlink_relay_backup"], ["stale_downlink_relay"]},
    {"custody status", "relay_data_path_custody_statuses", "custody_status", ["missing_ack"],
     ["stale_custody"]},
    {"latency", "relay_data_path_latency_values_s", "latency_s", [500.0], [501.0]},
    {"latency limit", "relay_data_path_latency_limit_values_s", "latency_limit_s", [300.0],
     [301.0]},
    {"latency status", "relay_data_path_latency_statuses", "latency_status", ["exceeds_limit"],
     ["stale_latency"]},
    {"risk status", "relay_data_path_risk_statuses", "risk_status", ["high"], ["stale_risk"]},
    {"risk reasons", "relay_data_path_risk_reasons", ["risk_reasons"],
     ["custody_missing_ack", "latency_exceeds_limit"], ["stale_risk_reason"]},
    {"product identities", "relay_data_path_product_ids", ["product_ids"], ["product_relay"],
     ["stale_product"]},
    {"collection identities", "relay_data_path_collection_ids", ["collection_ids"],
     ["collection_relay"], ["stale_collection"]},
    {"route count", "relay_data_path_route_count_values", "route_count", [2], [3]},
    {"relay-route count", "relay_data_path_relay_route_count_values", "relay_route_count", [2],
     [3]},
    {"direct-downlink route count", "relay_data_path_direct_downlink_route_count_values",
     "direct_downlink_route_count", [0], [1]},
    {"custody-status counts", "relay_data_path_custody_status_count_maps",
     "custody_status_counts", [%{"missing_ack" => 2}], [%{"missing_ack" => 3}]},
    {"latency-status counts", "relay_data_path_latency_status_count_maps",
     "latency_status_counts", [%{"exceeds_limit" => 2}], [%{"exceeds_limit" => 3}]},
    {"risk-status counts", "relay_data_path_risk_status_count_maps", "risk_status_counts",
     [%{"high" => 2}], [%{"high" => 3}]},
    {"routes by custody status", "relay_data_path_route_ids_by_custody_status",
     "route_ids_by_custody_status",
     [%{"missing_ack" => ["relay_route_review", "relay_route_backup"]}],
     [%{"missing_ack" => ["stale_relay_route"]}]},
    {"routes by latency status", "relay_data_path_route_ids_by_latency_status",
     "route_ids_by_latency_status",
     [%{"exceeds_limit" => ["relay_route_review", "relay_route_backup"]}],
     [%{"exceeds_limit" => ["stale_relay_route"]}]},
    {"routes by risk status", "relay_data_path_route_ids_by_risk_status",
     "route_ids_by_risk_status", [%{"high" => ["relay_route_review", "relay_route_backup"]}],
     [%{"high" => ["stale_relay_route"]}]},
    {"routes by ground station", "relay_data_path_route_ids_by_ground_station_id",
     "route_ids_by_ground_station_id",
     [%{"dss_14" => ["relay_route_review", "relay_route_backup"]}],
     [%{"dss_14" => ["stale_relay_route"]}]},
    {"feedback source", "relay_data_path_feedback_sources", "feedback_source",
     ["mission_state.source_relay_data_path_summary.rows"],
     ["mission_state.stale_relay_data_path_summary.rows"]},
    {"feedback scope", "relay_data_path_feedback_scopes", "feedback_scope", ["link_capacity"],
     ["stale_link_capacity"]},
    {"feedback key", "relay_data_path_feedback_keys", "feedback_key", ["relay_route_review"],
     ["stale_relay_route"]},
    {"trust boundary", "relay_data_path_trust_boundaries", "trust_boundary",
     ["mission_state_relay_data_path_summary"], ["stale_relay_data_path_summary"]},
    {"derivation reasons", "relay_data_path_derivation_reasons", ["derivation_reasons"],
     [
       "relay_data_path_custody_missing_ack",
       "relay_data_path_latency_exceeds_limit",
       "relay_data_path_risk_high"
     ], ["stale_relay_derivation"]},
    {"safety assumptions", "relay_data_path_assumption_maps", "assumptions",
     [
       %{
         "execution_boundary" => "artifact_only_no_relay_scheduling_or_schedule_mutation",
         "operator_authority" => "not_granted_by_summary",
         "provider_reservation" => "not_performed"
       }
     ],
     [
       %{
         "execution_boundary" => "stale_execution_boundary",
         "operator_authority" => "not_granted_by_summary",
         "provider_reservation" => "not_performed"
       }
     ]}
  ]

  for {description, field, source_field, expected_value, stale_value} <-
        @relay_data_path_context_contracts do
    test "relay-data-path #{description} remains source exact across handoffs" do
      assert_risk_context_contract(
        StrategyRecommendationPressureEventsFixture.artifact(),
        unquote(field),
        {"type", "relay_data_path_pressure"},
        unquote(Macro.escape(source_field)),
        unquote(Macro.escape(expected_value)),
        unquote(Macro.escape(stale_value))
      )
    end
  end

  @maneuver_execution_uncertainty_context_contracts [
    {"risk type", "maneuver_execution_uncertainty_risk_types", ["type", "risk_type"],
     ["maneuver_execution_uncertainty_high"], ["maneuver_execution_uncertainty_missing"]},
    {"activity identity", "maneuver_execution_uncertainty_activity_ids", "activity_id",
     ["burn_uncertain_review"], ["stale_burn"]},
    {"timeline identity", "maneuver_execution_uncertainty_timeline_ids", "timeline_id",
     ["timeline:maneuver:burn_uncertain_review"], ["timeline:maneuver:stale_burn"]},
    {"maneuver identity", "maneuver_execution_uncertainty_maneuver_ids", "maneuver_id",
     ["burn_uncertain_review"], ["stale_burn"]},
    {"scenario identity", "maneuver_execution_uncertainty_scenario_ids", "scenario_id", ["leo_1"],
     ["stale_leo_1"]},
    {"source-activity identity", "maneuver_execution_uncertainty_source_activity_ids",
     ["source_activity_id", "source_activity_ids"],
     ["burn_uncertain_source", "burn_uncertain_review"], ["stale_burn_source"]},
    {"replacement-activity identity", "maneuver_execution_uncertainty_replacement_activity_ids",
     "replacement_activity_id", ["burn_uncertain_review"], ["stale_burn_replacement"]},
    {"status", "maneuver_execution_uncertainty_statuses", "execution_uncertainty_status",
     ["declared"], ["stale_status"]},
    {"source", "maneuver_execution_uncertainty_sources", "execution_uncertainty_source",
     ["ops_covariance_review"], ["stale_covariance_source"]},
    {"uncertainty map", "maneuver_execution_uncertainty_maps", "execution_uncertainty",
     [
       %{
         "delta_v_3sigma_km_s" => [0.0, 0.003, 0.004],
         "source" => "ops_covariance_review",
         "timing_3sigma_s" => 75.0
       }
     ],
     [
       %{
         "delta_v_3sigma_km_s" => [0.0, 0.003, 0.005],
         "source" => "ops_covariance_review",
         "timing_3sigma_s" => 75.0
       }
     ]},
    {"timing three-sigma", "maneuver_execution_uncertainty_timing_3sigma_values_s",
     "timing_3sigma_s", [75.0], [76.0]},
    {"timing three-sigma threshold",
     "maneuver_execution_uncertainty_timing_3sigma_threshold_values_s",
     "timing_3sigma_threshold_s", [60.0], [61.0]},
    {"delta-v three-sigma vector", "maneuver_execution_uncertainty_delta_v_3sigma_vectors_km_s",
     "delta_v_3sigma_km_s", [[0.0, 0.003, 0.004]], [[0.0, 0.003, 0.005]]},
    {"delta-v three-sigma magnitude",
     "maneuver_execution_uncertainty_delta_v_3sigma_magnitude_values_km_s",
     "delta_v_3sigma_magnitude_km_s", [0.005], [0.006]},
    {"delta-v three-sigma magnitude threshold",
     "maneuver_execution_uncertainty_delta_v_3sigma_magnitude_threshold_values_km_s",
     "delta_v_3sigma_magnitude_threshold_km_s", [0.002], [0.003]},
    {"start timing", "maneuver_execution_uncertainty_start_values_s", "starts_at_s", [620.0],
     [621.0]},
    {"end timing", "maneuver_execution_uncertainty_end_values_s", "ends_at_s", [620.0], [621.0]},
    {"changed fields", "maneuver_execution_uncertainty_changed_fields", ["changed_fields"],
     ["execution_uncertainty"], ["stale_uncertainty"]},
    {"required operator action", "maneuver_execution_uncertainty_required_operator_actions",
     "required_operator_action", ["review_maneuver_execution_uncertainty"],
     ["stale_operator_action"]},
    {"operator-review requirement",
     "maneuver_execution_uncertainty_requires_operator_review_values", "requires_operator_review",
     [true], [false]},
    {"feedback source", "maneuver_execution_uncertainty_feedback_sources", "feedback_source",
     ["mission_state.source_maneuver_review.rows"], ["mission_state.stale_maneuver_review.rows"]},
    {"feedback scope", "maneuver_execution_uncertainty_feedback_scopes", "feedback_scope",
     ["maneuver_execution_uncertainty"], ["stale_maneuver_execution_uncertainty"]},
    {"feedback key", "maneuver_execution_uncertainty_feedback_keys", "feedback_key",
     ["burn_uncertain_review"], ["stale_burn"]},
    {"trust boundary", "maneuver_execution_uncertainty_trust_boundaries", "trust_boundary",
     ["mission_state_maneuver_review"], ["stale_maneuver_review"]},
    {"derivation reasons", "maneuver_execution_uncertainty_derivation_reasons",
     ["derivation_reasons"], ["maneuver_review_execution_uncertainty_pressure"],
     ["stale_maneuver_uncertainty_derivation"]}
  ]

  for {description, field, source_field, expected_value, stale_value} <-
        @maneuver_execution_uncertainty_context_contracts do
    test "maneuver-execution uncertainty #{description} remains source exact across handoffs" do
      assert_risk_context_contract(
        StrategyRecommendationPressureEventsFixture.artifact(),
        unquote(field),
        {"feedback_scope", "maneuver_execution_uncertainty"},
        unquote(Macro.escape(source_field)),
        unquote(Macro.escape(expected_value)),
        unquote(Macro.escape(stale_value))
      )
    end
  end

  @execution_success_feedback_context_contracts [
    {"risk types", "execution_success_feedback_risk_types", ["type", "risk_type"],
     ["command_success_rate_low", "maneuver_success_rate_low"], ["stale_success_rate_low"]},
    {"activity identities", "execution_success_feedback_activity_ids", "activity_id",
     ["cmd_success_review", "burn_success_review"], ["stale_success_activity"]},
    {"scenario identity", "execution_success_feedback_scenario_ids", "scenario_id", ["leo_1"],
     ["stale_leo_1"]},
    {"timeline identities", "execution_success_feedback_timeline_ids", "timeline_id",
     ["timeline:cmd_success_review", "timeline:burn_success_review"], ["timeline:stale_success"]},
    {"source-activity identities", "execution_success_feedback_source_activity_ids",
     ["source_activity_id", "source_activity_ids"],
     ["cmd_success_source", "cmd_success_review", "burn_success_source", "burn_success_review"],
     ["stale_success_source"]},
    {"replacement-activity identities", "execution_success_feedback_replacement_activity_ids",
     "replacement_activity_id", ["cmd_success_review", "burn_success_review"],
     ["stale_success_replacement"]},
    {"command success factor", "execution_success_feedback_command_success_factor_values",
     "command_success_factor", [0.25], [0.5]},
    {"maneuver success factor", "execution_success_feedback_maneuver_success_factor_values",
     "maneuver_success_factor", [0.4], [0.5]},
    {"command result", "execution_success_feedback_command_results", "command_result",
     ["timeout"], ["stale_command_result"]},
    {"maneuver result", "execution_success_feedback_maneuver_results", "maneuver_result",
     ["accepted, failed"], ["stale_maneuver_result"]},
    {"realized status", "execution_success_feedback_realized_statuses", "realized_status",
     ["failed"], ["stale_realized_status"]},
    {"ground-station identity", "execution_success_feedback_ground_station_ids",
     "ground_station_id", ["equator_prime"], ["stale_equator_prime"]},
    {"planned ground-station identity", "execution_success_feedback_planned_ground_station_ids",
     "planned_ground_station_id", ["polar_prime"], ["stale_polar_prime"]},
    {"realized ground-station identity", "execution_success_feedback_realized_ground_station_ids",
     "realized_ground_station_id", ["equator_prime"], ["stale_equator_prime"]},
    {"ground-station match status", "execution_success_feedback_ground_station_match_statuses",
     "ground_station_match_status", ["mismatch"], ["stale_match"]},
    {"direction", "execution_success_feedback_directions", "direction", ["command"],
     ["stale_direction"]},
    {"planned direction", "execution_success_feedback_planned_directions", "planned_direction",
     ["uplink"], ["stale_planned_direction"]},
    {"realized direction", "execution_success_feedback_realized_directions", "realized_direction",
     ["command"], ["stale_realized_direction"]},
    {"direction match status", "execution_success_feedback_direction_match_statuses",
     "direction_match_status", ["mismatch"], ["stale_match"]},
    {"source-window identity", "execution_success_feedback_source_window_ids", "source_window_id",
     ["window_equator_command"], ["stale_source_window"]},
    {"planned source-window identity", "execution_success_feedback_planned_source_window_ids",
     "planned_source_window_id", ["window_polar_uplink"], ["stale_planned_window"]},
    {"realized source-window identity", "execution_success_feedback_realized_source_window_ids",
     "realized_source_window_id", ["window_equator_command"], ["stale_realized_window"]},
    {"source-window match status", "execution_success_feedback_source_window_match_statuses",
     "source_window_match_status", ["mismatch"], ["stale_match"]},
    {"command identity mismatch fields",
     "execution_success_feedback_command_identity_mismatch_fields",
     ["command_identity_mismatch_fields"], ["direction", "ground_station", "source_window"],
     ["stale_identity_field"]},
    {"start timing", "execution_success_feedback_start_values_s", "starts_at_s", [700.0, 760.0],
     [701.0]},
    {"end timing", "execution_success_feedback_end_values_s", "ends_at_s", [730.0, 760.0],
     [731.0]},
    {"changed fields", "execution_success_feedback_changed_fields", ["changed_fields"],
     ["command_result", "command_success_factor", "maneuver_result", "maneuver_success_factor"],
     ["stale_changed_field"]},
    {"status transitions", "execution_success_feedback_status_transition_maps",
     "status_transition",
     [
       %{
         "field" => "status",
         "from" => "planned",
         "requires_operator_review" => true,
         "to" => "failed",
         "transition_category" => "terminal_exception",
         "transition_reason" => "command execution timed out",
         "transition_type" => "status_changed"
       },
       %{
         "field" => "status",
         "from" => "planned",
         "requires_operator_review" => true,
         "to" => "failed",
         "transition_category" => "terminal_exception",
         "transition_reason" => "maneuver failed after acceptance",
         "transition_type" => "status_changed"
       }
     ],
     [
       %{
         "field" => "status",
         "from" => "planned",
         "requires_operator_review" => true,
         "to" => "stale",
         "transition_category" => "terminal_exception",
         "transition_reason" => "stale transition",
         "transition_type" => "status_changed"
       }
     ]},
    {"transition type", "execution_success_feedback_transition_types", "transition_type",
     ["status_changed"], ["stale_transition_type"]},
    {"transition category", "execution_success_feedback_transition_categories",
     "transition_category", ["terminal_exception"], ["stale_transition_category"]},
    {"transition reasons", "execution_success_feedback_transition_reasons", "transition_reason",
     ["command execution timed out", "maneuver failed after acceptance"],
     ["stale_transition_reason"]},
    {"required operator actions", "execution_success_feedback_required_operator_actions",
     "required_operator_action",
     ["review_command_execution_feedback", "review_maneuver_execution_feedback"],
     ["stale_operator_action"]},
    {"operator-review requirement", "execution_success_feedback_requires_operator_review_values",
     "requires_operator_review", [true], [false]},
    {"feedback sources", "execution_success_feedback_feedback_sources", "feedback_source",
     [
       "mission_state.source_command_window_report.rows",
       "mission_state.source_maneuver_review.rows"
     ], ["mission_state.stale_execution_feedback.rows"]},
    {"feedback scopes", "execution_success_feedback_feedback_scopes", "feedback_scope",
     ["command_execution_feedback", "maneuver_execution_feedback"], ["stale_execution_feedback"]},
    {"feedback keys", "execution_success_feedback_feedback_keys", "feedback_key",
     ["cmd_success_review", "burn_success_review"], ["stale_success_feedback"]},
    {"trust boundaries", "execution_success_feedback_trust_boundaries", "trust_boundary",
     ["mission_state_command_window_report", "mission_state_maneuver_review"],
     ["stale_execution_feedback_boundary"]},
    {"derivation reasons", "execution_success_feedback_derivation_reasons",
     ["derivation_reasons"],
     ["command_window_execution_feedback_pressure", "maneuver_review_success_feedback_pressure"],
     ["stale_execution_feedback_derivation"]}
  ]

  for {description, field, source_field, expected_value, stale_value} <-
        @execution_success_feedback_context_contracts do
    test "execution-success feedback #{description} remains source exact across handoffs" do
      assert_risk_context_contract(
        StrategyRecommendationPressureEventsFixture.artifact(),
        unquote(field),
        {"type", ["command_success_rate_low", "maneuver_success_rate_low"]},
        unquote(Macro.escape(source_field)),
        unquote(Macro.escape(expected_value)),
        unquote(Macro.escape(stale_value))
      )
    end
  end

  @timeline_dependency_impact_context_contracts [
    {"activity identity", "timeline_dependency_impact_activity_ids", "activity_id",
     ["cmd_dependency_review"], ["stale_dependency_activity"]},
    {"timeline identity", "timeline_dependency_impact_timeline_ids", "timeline_id",
     ["timeline:cmd_dependency_review"], ["timeline:stale_dependency"]},
    {"scope", "timeline_dependency_impact_scopes", "dependency_impact_scope", ["source"],
     ["stale_scope"]},
    {"status", "timeline_dependency_impact_statuses", "dependency_impact_status",
     ["review_required"], ["stale_status"]},
    {"required operator action", "timeline_dependency_impact_required_operator_actions",
     "required_operator_action", ["review_timeline_dependency_impact"],
     ["stale_operator_action"]},
    {"operator-action reason", "timeline_dependency_impact_operator_action_reasons",
     "operator_action_reason", ["dependency_link_impacted_by_timeline_change"],
     ["stale_action_reason"]},
    {"dependency activity identities", "timeline_dependency_impact_dependency_activity_ids",
     ["dependency_activity_ids"], ["health_check"], ["stale_dependency_activity"]},
    {"dependency timeline identities", "timeline_dependency_impact_dependency_timeline_ids",
     ["dependency_timeline_ids"], ["timeline:health_check"], ["timeline:stale_dependency"]},
    {"exclusive activity identities", "timeline_dependency_impact_exclusive_with_activity_ids",
     ["exclusive_with_activity_ids"], ["downlink_conflict"], ["stale_exclusive_activity"]},
    {"exclusive timeline identities", "timeline_dependency_impact_exclusive_with_timeline_ids",
     ["exclusive_with_timeline_ids"], ["timeline:downlink_conflict"],
     ["timeline:stale_exclusive"]},
    {"impacted dependency activity identities",
     "timeline_dependency_impact_impacted_dependency_activity_ids",
     ["impacted_dependency_activity_ids"], ["health_check"], ["stale_impacted_dependency"]},
    {"impacted dependency timeline identities",
     "timeline_dependency_impact_impacted_dependency_timeline_ids",
     ["impacted_dependency_timeline_ids"], ["timeline:health_check"],
     ["timeline:stale_impacted_dependency"]},
    {"impacted exclusive activity identities",
     "timeline_dependency_impact_impacted_exclusive_with_activity_ids",
     ["impacted_exclusive_with_activity_ids"], ["downlink_conflict"],
     ["stale_impacted_exclusive"]},
    {"impacted exclusive timeline identities",
     "timeline_dependency_impact_impacted_exclusive_with_timeline_ids",
     ["impacted_exclusive_with_timeline_ids"], ["timeline:downlink_conflict"],
     ["timeline:stale_impacted_exclusive"]},
    {"feedback source", "timeline_dependency_impact_feedback_sources", "feedback_source",
     ["mission_state.source_timeline_dependency_impact_summary.dependency_impact_rows"],
     ["mission_state.stale_timeline_dependency_impact_summary.rows"]},
    {"feedback scope", "timeline_dependency_impact_feedback_scopes", "feedback_scope",
     ["timeline_dependency_impact"], ["stale_timeline_dependency_impact"]},
    {"feedback key", "timeline_dependency_impact_feedback_keys", "feedback_key",
     ["cmd_dependency_review"], ["stale_dependency_key"]},
    {"trust boundary", "timeline_dependency_impact_trust_boundaries", "trust_boundary",
     ["mission_state_timeline_dependency_impact_summary"], ["stale_dependency_boundary"]},
    {"derivation reasons", "timeline_dependency_impact_derivation_reasons",
     ["derivation_reasons"], ["timeline_dependency_impact_summary_pressure"],
     ["stale_dependency_derivation"]}
  ]

  for {description, field, source_field, expected_value, stale_value} <-
        @timeline_dependency_impact_context_contracts do
    test "timeline-dependency impact #{description} remains source exact across handoffs" do
      assert_risk_context_contract(
        StrategyRecommendationPressureEventsFixture.artifact(),
        unquote(field),
        {"feedback_scope", "timeline_dependency_impact"},
        unquote(Macro.escape(source_field)),
        unquote(Macro.escape(expected_value)),
        unquote(Macro.escape(stale_value))
      )
    end
  end

  @timeline_publication_context_contracts [
    {"identity", "timeline_publication_ids", "publication_id",
     ["timeline_publication:9:timeline:selected_plan:v2:timeline:selected_plan:v1"],
     ["timeline_publication:stale"]},
    {"sequence", "timeline_publication_sequences", "publication_sequence", [9], [10]},
    {"status", "timeline_publication_statuses", "publication_status",
     ["published_with_downstream_invalidations"], ["stale_publication_status"]},
    {"downstream invalidation status", "timeline_publication_downstream_invalidation_statuses",
     "downstream_invalidation_status", ["invalidated"], ["stale_invalidation_status"]},
    {"dependency-impact status", "timeline_publication_dependency_impact_statuses",
     "dependency_impact_status", ["review_required"], ["stale_dependency_status"]},
    {"source-artifact identity", "timeline_publication_source_artifact_ids", "source_artifact_id",
     ["timeline:selected_plan:v2"], ["timeline:stale_plan"]},
    {"source-artifact type", "timeline_publication_source_artifact_types", "source_artifact_type",
     ["operational_timeline_report.v1"], ["stale_timeline_report.v1"]},
    {"authority", "timeline_publication_authorities", "publication_authority",
     ["mission_operations"], ["stale_authority"]},
    {"superseded artifact identities", "timeline_publication_supersedes_artifact_ids",
     ["supersedes_artifact_ids"], ["timeline:selected_plan:v1"], ["timeline:stale_plan"]},
    {"downstream product identities", "timeline_publication_downstream_product_ids",
     ["downstream_product_ids"], ["operator_review:selected:v1", "cadence_import:selected:v1"],
     ["stale_downstream_product"]},
    {"invalidated downstream product identities",
     "timeline_publication_invalidated_downstream_product_ids",
     ["invalidated_downstream_product_ids"],
     ["cadence_import:selected:v1", "operator_review:selected:v1"],
     ["stale_invalidated_product"]},
    {"downstream invalidation reason counts",
     "timeline_publication_downstream_invalidation_reason_count_maps",
     "downstream_invalidation_reason_counts", [%{"dependency_impact_review_required" => 2}],
     [%{"dependency_impact_review_required" => 3}]},
    {"downstream invalidation reasons", "timeline_publication_downstream_invalidation_reasons",
     ["downstream_invalidation_reasons"], ["dependency_impact_review_required"],
     ["stale_invalidation_reason"]},
    {"invalidated products by reason",
     "timeline_publication_invalidated_downstream_product_ids_by_reason",
     "invalidated_downstream_product_ids_by_reason",
     [
       %{
         "dependency_impact_review_required" => [
           "cadence_import:selected:v1",
           "operator_review:selected:v1"
         ]
       }
     ], [%{"dependency_impact_review_required" => ["stale_invalidated_product"]}]},
    {"dependency-impact row count", "timeline_publication_dependency_impact_row_count_values",
     "dependency_impact_row_count", [2], [3]},
    {"timeline-diff row count", "timeline_publication_timeline_diff_row_count_values",
     "timeline_diff_row_count", [3], [4]},
    {"timeline-diff changed count", "timeline_publication_timeline_diff_changed_count_values",
     "timeline_diff_changed_count", [2], [3]},
    {"timeline-diff review-required count",
     "timeline_publication_timeline_diff_review_required_count_values",
     "timeline_diff_review_required_count", [1], [2]},
    {"changed-field counts", "timeline_publication_changed_field_count_maps",
     "changed_field_counts", [%{"timeline_presence" => 2}], [%{"timeline_presence" => 3}]},
    {"changed fields", "timeline_publication_changed_fields", ["changed_fields"],
     ["timeline_presence"], ["stale_changed_field"]},
    {"changed timeline identities", "timeline_publication_changed_timeline_ids",
     ["changed_timeline_ids"], ["timeline:health_check:0.0"], ["timeline:stale_change"]},
    {"review timeline identities", "timeline_publication_review_timeline_ids",
     ["review_timeline_ids"], ["timeline:health_check:0.0", "timeline:health_check:5.0"],
     ["timeline:stale_review"]},
    {"timeline identities by changed field", "timeline_publication_timeline_ids_by_changed_field",
     "timeline_ids_by_changed_field",
     [
       %{
         "timeline_presence" => ["timeline:health_check:0.0", "timeline:health_check:5.0"]
       }
     ], [%{"timeline_presence" => ["timeline:stale_change"]}]},
    {"feedback source", "timeline_publication_feedback_sources", "feedback_source",
     ["mission_state.source_timeline_publication_summary"],
     ["mission_state.stale_timeline_publication_summary"]},
    {"feedback scope", "timeline_publication_feedback_scopes", "feedback_scope",
     ["timeline_publication"], ["stale_timeline_publication"]},
    {"feedback key", "timeline_publication_feedback_keys", "feedback_key",
     ["timeline_publication:9:timeline:selected_plan:v2:timeline:selected_plan:v1"],
     ["timeline_publication:stale"]},
    {"trust boundary", "timeline_publication_trust_boundaries", "trust_boundary",
     ["mission_state_timeline_publication_summary"], ["stale_publication_boundary"]},
    {"derivation reasons", "timeline_publication_derivation_reasons", ["derivation_reasons"],
     ["timeline_publication_summary_pressure"], ["stale_publication_derivation"]},
    {"safety assumptions", "timeline_publication_assumption_maps", "assumptions",
     [
       %{
         "import_approval" => "not_granted_by_strategy_branch",
         "notification_delivery" => "not_performed_by_strategy_branch",
         "operator_authority" => "not_granted_by_strategy_branch",
         "publication_execution" => "not_performed_by_strategy_branch"
       }
     ],
     [
       %{
         "import_approval" => "not_granted_by_strategy_branch",
         "notification_delivery" => "not_performed_by_strategy_branch",
         "operator_authority" => "not_granted_by_strategy_branch",
         "publication_execution" => "stale_publication_execution"
       }
     ]}
  ]

  for {description, field, source_field, expected_value, stale_value} <-
        @timeline_publication_context_contracts do
    test "timeline-publication #{description} remains source exact across handoffs" do
      assert_risk_context_contract(
        StrategyRecommendationPressureEventsFixture.artifact(),
        unquote(field),
        {"feedback_scope", "timeline_publication"},
        unquote(Macro.escape(source_field)),
        unquote(Macro.escape(expected_value)),
        unquote(Macro.escape(stale_value))
      )
    end
  end

  @timeline_lifecycle_state_context_contracts [
    {"status", "timeline_lifecycle_state_statuses", "timeline_lifecycle_state_status",
     ["review_required"], ["stale_lifecycle_status"]},
    {"planned-activity count", "timeline_lifecycle_state_planned_activity_count_values",
     "planned_activity_count", [4], [5]},
    {"realized-activity count", "timeline_lifecycle_state_realized_activity_count_values",
     "realized_activity_count", [1], [2]},
    {"row count", "timeline_lifecycle_state_row_count_values", "row_count", [4], [5]},
    {"recordable count", "timeline_lifecycle_state_recordable_count_values", "recordable_count",
     [3], [4]},
    {"preserved count", "timeline_lifecycle_state_preserved_count_values", "preserved_count", [1],
     [2]},
    {"review-required count", "timeline_lifecycle_state_review_required_count_values",
     "review_required_count", [3], [4]},
    {"duplicate-identity count", "timeline_lifecycle_state_duplicate_identity_count_values",
     "duplicate_timeline_identity_count", [1], [2]},
    {"invalid-activity-input count",
     "timeline_lifecycle_state_invalid_activity_input_count_values",
     "invalid_activity_input_count", [1], [2]},
    {"transition-decision counts", "timeline_lifecycle_state_transition_decision_count_maps",
     "transition_decision_counts", [%{"record" => 3, "none" => 1}],
     [%{"record" => 4, "none" => 1}]},
    {"required-operator-action counts",
     "timeline_lifecycle_state_required_operator_action_count_maps",
     "required_operator_action_counts",
     [
       %{
         "review_activity_approval" => 1,
         "review_duplicate_timeline_identity" => 1,
         "review_invalid_activity_input" => 1
       }
     ],
     [
       %{
         "review_activity_approval" => 2,
         "review_duplicate_timeline_identity" => 1,
         "review_invalid_activity_input" => 1
       }
     ]},
    {"operator-action-reason counts",
     "timeline_lifecycle_state_operator_action_reason_count_maps",
     "operator_action_reason_counts",
     [
       %{
         "activity_approval_pending" => 1,
         "duplicate_timeline_identity" => 1,
         "missing_activity_type" => 1
       }
     ],
     [
       %{
         "activity_approval_pending" => 2,
         "duplicate_timeline_identity" => 1,
         "missing_activity_type" => 1
       }
     ]},
    {"import-action counts", "timeline_lifecycle_state_import_action_count_maps",
     "import_action_counts", [%{"review_timeline_diff" => 3}], [%{"review_timeline_diff" => 4}]},
    {"planned-status-category counts",
     "timeline_lifecycle_state_planned_status_category_count_maps",
     "planned_status_category_counts", [%{"planned" => 4}], [%{"planned" => 5}]},
    {"realized-status-category counts",
     "timeline_lifecycle_state_realized_status_category_count_maps",
     "realized_status_category_counts", [%{"executed" => 1}], [%{"executed" => 2}]},
    {"status-transition-category counts",
     "timeline_lifecycle_state_status_transition_category_count_maps",
     "status_transition_category_counts", [%{"changed" => 1}], [%{"changed" => 2}]},
    {"approval-transition-category counts",
     "timeline_lifecycle_state_approval_transition_category_count_maps",
     "approval_transition_category_counts", [%{"changed" => 1}], [%{"changed" => 2}]},
    {"recordable timeline identities", "timeline_lifecycle_state_recordable_timeline_ids",
     ["recordable_timeline_ids"],
     [
       "timeline:lifecycle:cmd_pending",
       "timeline:lifecycle:dup",
       "timeline:invalid_activity_input:lifecycle_bad_missing_type"
     ], ["timeline:stale_recordable"]},
    {"preserved timeline identities", "timeline_lifecycle_state_preserved_timeline_ids",
     ["preserved_timeline_ids"], ["timeline:lifecycle:obs_preserved"],
     ["timeline:stale_preserved"]},
    {"review timeline identities", "timeline_lifecycle_state_review_timeline_ids",
     ["review_timeline_ids"],
     [
       "timeline:lifecycle:cmd_pending",
       "timeline:lifecycle:dup",
       "timeline:invalid_activity_input:lifecycle_bad_missing_type"
     ], ["timeline:stale_review"]},
    {"review activity identities", "timeline_lifecycle_state_review_activity_ids",
     ["review_activity_ids"],
     [
       "lifecycle_cmd_pending",
       "lifecycle_dup_a",
       "lifecycle_dup_b",
       "timeline_row:4:lifecycle_bad_missing_type"
     ], ["stale_review_activity"]},
    {"invalid-activity-input identities", "timeline_lifecycle_state_invalid_activity_input_ids",
     ["invalid_activity_input_ids"], ["timeline_row:4:lifecycle_bad_missing_type"],
     ["stale_invalid_activity_input"]},
    {"review timelines by required operator action",
     "timeline_lifecycle_state_review_timeline_ids_by_required_operator_action",
     "review_timeline_ids_by_required_operator_action",
     [
       %{
         "review_activity_approval" => ["timeline:lifecycle:cmd_pending"],
         "review_duplicate_timeline_identity" => ["timeline:lifecycle:dup"],
         "review_invalid_activity_input" => [
           "timeline:invalid_activity_input:lifecycle_bad_missing_type"
         ]
       }
     ], [%{"review_activity_approval" => ["timeline:stale_review"]}]},
    {"review timelines by operator-action reason",
     "timeline_lifecycle_state_review_timeline_ids_by_operator_action_reason",
     "review_timeline_ids_by_operator_action_reason",
     [
       %{
         "activity_approval_pending" => ["timeline:lifecycle:cmd_pending"],
         "duplicate_timeline_identity" => ["timeline:lifecycle:dup"],
         "missing_activity_type" => [
           "timeline:invalid_activity_input:lifecycle_bad_missing_type"
         ]
       }
     ], [%{"activity_approval_pending" => ["timeline:stale_review"]}]},
    {"review timelines by status-transition category",
     "timeline_lifecycle_state_review_timeline_ids_by_status_transition_category",
     "review_timeline_ids_by_status_transition_category",
     [%{"changed" => ["timeline:lifecycle:cmd_pending"]}],
     [%{"changed" => ["timeline:stale_review"]}]},
    {"review timelines by approval-transition category",
     "timeline_lifecycle_state_review_timeline_ids_by_approval_transition_category",
     "review_timeline_ids_by_approval_transition_category",
     [%{"changed" => ["timeline:lifecycle:cmd_pending"]}],
     [%{"changed" => ["timeline:stale_review"]}]},
    {"required operator actions", "timeline_lifecycle_state_required_operator_actions",
     "required_operator_action", ["review_timeline_lifecycle_state"], ["stale_operator_action"]},
    {"operator-review requirement", "timeline_lifecycle_state_requires_operator_review_values",
     "requires_operator_review", [true], [false]},
    {"feedback source", "timeline_lifecycle_state_feedback_sources", "feedback_source",
     ["mission_state.source_timeline_lifecycle_state_summary"],
     ["mission_state.stale_timeline_lifecycle_state_summary"]},
    {"feedback scope", "timeline_lifecycle_state_feedback_scopes", "feedback_scope",
     ["timeline_lifecycle_state"], ["stale_timeline_lifecycle_state"]},
    {"feedback key", "timeline_lifecycle_state_feedback_keys", "feedback_key",
     ["mission.lifecycle.summary"], ["stale.lifecycle.summary"]},
    {"trust boundary", "timeline_lifecycle_state_trust_boundaries", "trust_boundary",
     ["mission_state_timeline_lifecycle_state_summary"], ["stale_lifecycle_boundary"]},
    {"derivation reasons", "timeline_lifecycle_state_derivation_reasons", ["derivation_reasons"],
     ["timeline_lifecycle_state_summary_pressure"], ["stale_lifecycle_derivation"]},
    {"safety assumptions", "timeline_lifecycle_state_assumption_maps", "assumptions",
     [
       %{
         "cadence_import" => "not_performed_by_strategy_branch",
         "command_execution" => "not_performed_by_strategy_branch",
         "operator_authority" => "not_granted_by_strategy_branch",
         "timeline_lifecycle_application" => "not_performed_by_strategy_branch",
         "timeline_mutation" => "not_performed_by_strategy_branch"
       }
     ],
     [
       %{
         "cadence_import" => "not_performed_by_strategy_branch",
         "command_execution" => "not_performed_by_strategy_branch",
         "operator_authority" => "not_granted_by_strategy_branch",
         "timeline_lifecycle_application" => "stale_lifecycle_application",
         "timeline_mutation" => "not_performed_by_strategy_branch"
       }
     ]}
  ]

  for {description, field, source_field, expected_value, stale_value} <-
        @timeline_lifecycle_state_context_contracts do
    test "timeline-lifecycle-state #{description} remains source exact across handoffs" do
      assert_risk_context_contract(
        StrategyRecommendationPressureEventsFixture.artifact(),
        unquote(field),
        {"feedback_scope", "timeline_lifecycle_state"},
        unquote(Macro.escape(source_field)),
        unquote(Macro.escape(expected_value)),
        unquote(Macro.escape(stale_value))
      )
    end
  end

  @timeline_activity_lifecycle_state_unemitted_context_fields [
    "timeline_activity_lifecycle_state_invalid_activity_input_reasons"
  ]
  @timeline_activity_lifecycle_state_context_contracts OrbitalDynamics.RecommendationRiskContext.TimelineActivityLifecycleState.field_pairs()
                                                       |> Enum.reject(fn {field, _source_fields} ->
                                                         field in @timeline_activity_lifecycle_state_unemitted_context_fields
                                                       end)

  for {field, source_fields} <- @timeline_activity_lifecycle_state_context_contracts do
    test "activity-lifecycle-state #{field} remains source exact across handoffs" do
      artifact = StrategyRecommendationPressureEventsFixture.artifact()

      expected_value =
        artifact["operator_review_package"]["rows"]
        |> Enum.find(&(&1["review_type"] == "strategy_recommendation"))
        |> Map.fetch!(unquote(field))

      assert_risk_context_contract(
        artifact,
        unquote(field),
        {"feedback_scope", "timeline_activity_lifecycle_state"},
        unquote(Macro.escape(source_fields)),
        expected_value,
        stale_context_value(expected_value)
      )
    end
  end

  @timeline_preservation_unemitted_context_fields [
    "timeline_preservation_invalid_activity_input_reasons"
  ]
  @timeline_preservation_context_contracts OrbitalDynamics.RecommendationRiskContext.TimelinePreservation.field_pairs()
                                           |> Enum.reject(fn {field, _source_fields} ->
                                             field in @timeline_preservation_unemitted_context_fields
                                           end)

  for {field, source_fields} <- @timeline_preservation_context_contracts do
    test "timeline-preservation #{field} remains source exact across handoffs" do
      artifact = StrategyRecommendationPressureEventsFixture.artifact()

      expected_value =
        artifact["operator_review_package"]["rows"]
        |> Enum.find(&(&1["review_type"] == "strategy_recommendation"))
        |> Map.fetch!(unquote(field))

      assert_risk_context_contract(
        artifact,
        unquote(field),
        {"feedback_scope", "timeline_preservation"},
        unquote(Macro.escape(source_fields)),
        expected_value,
        stale_context_value(expected_value)
      )
    end
  end

  @timeline_activity_precondition_unemitted_context_fields [
    "timeline_activity_precondition_invalid_activity_input_reasons"
  ]
  @timeline_activity_precondition_context_contracts OrbitalDynamics.RecommendationRiskContext.TimelineActivityPrecondition.field_pairs()
                                                    |> Enum.reject(fn {field, _source_fields} ->
                                                      field in @timeline_activity_precondition_unemitted_context_fields
                                                    end)

  for {field, source_fields} <- @timeline_activity_precondition_context_contracts do
    test "activity-precondition #{field} remains source exact across handoffs" do
      artifact = StrategyRecommendationPressureEventsFixture.artifact()

      expected_value =
        artifact["operator_review_package"]["rows"]
        |> Enum.find(&(&1["review_type"] == "strategy_recommendation"))
        |> Map.fetch!(unquote(field))

      assert_risk_context_contract(
        artifact,
        unquote(field),
        {"feedback_scope", "timeline_activity_precondition"},
        unquote(Macro.escape(source_fields)),
        expected_value,
        stale_context_value(expected_value)
      )
    end
  end

  @timeline_integrity_unemitted_context_fields [
    "timeline_integrity_missing_dependency_timeline_ids",
    "timeline_integrity_dependency_cycle_activity_ids",
    "timeline_integrity_dependency_cycle_timeline_ids",
    "timeline_integrity_dependency_order_violation_activity_ids",
    "timeline_integrity_dependency_order_violation_timeline_ids"
  ]
  @timeline_integrity_context_contracts OrbitalDynamics.RecommendationRiskContext.TimelineIntegrity.field_pairs()
                                        |> Enum.reject(fn {field, _source_fields} ->
                                          field in @timeline_integrity_unemitted_context_fields
                                        end)

  for {field, source_fields} <- @timeline_integrity_context_contracts do
    test "timeline-integrity #{field} remains source exact across handoffs" do
      artifact = StrategyRecommendationPressureEventsFixture.artifact()

      expected_value =
        artifact["operator_review_package"]["rows"]
        |> Enum.find(&(&1["review_type"] == "strategy_recommendation"))
        |> Map.fetch!(unquote(field))

      assert_risk_context_contract(
        artifact,
        unquote(field),
        {"feedback_scope", "timeline_integrity"},
        unquote(Macro.escape(source_fields)),
        expected_value,
        stale_context_value(expected_value)
      )
    end
  end

  @operational_feedback_risk_types [
    "contact_success_rate_low",
    "observation_success_rate_low",
    "station_throughput_factor_low"
  ]
  @operational_feedback_context_contracts Enum.map(
                                            OrbitalDynamics.RecommendationRiskContext.OperationalFeedback.field_pairs(),
                                            fn {field, source_fields} ->
                                              legacy_mode =
                                                if field ==
                                                     "strategy_operational_feedback_risk_types",
                                                   do: :drop_risk,
                                                   else: :drop_field

                                              {field, source_fields, legacy_mode}
                                            end
                                          )

  for {field, source_fields, legacy_mode} <- @operational_feedback_context_contracts do
    test "operational-feedback #{field} remains source exact across handoffs" do
      artifact = StrategyRecommendationPressureEventsFixture.artifact()

      expected_value =
        artifact["operator_review_package"]["rows"]
        |> Enum.find(&(&1["review_type"] == "strategy_recommendation"))
        |> Map.fetch!(unquote(field))

      assert_risk_context_contract(
        artifact,
        unquote(field),
        {"type", unquote(@operational_feedback_risk_types)},
        unquote(Macro.escape(source_fields)),
        expected_value,
        stale_context_value(expected_value),
        unquote(legacy_mode)
      )
    end
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

  test "objective-satisfaction risk type remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "objective_satisfaction_pressure_risk_types",
      {"feedback_scope", "objective_satisfaction"},
      ["type", "risk_type"],
      ["downlink_completion_gap", "observation_success_rate_low"],
      ["stale_objective_satisfaction_risk"]
    )
  end

  test "objective-satisfaction objective identity remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "objective_satisfaction_pressure_objective_ids",
      {"feedback_scope", "objective_satisfaction"},
      "objective_id",
      ["objective:target_quality"],
      ["objective:stale_target_quality"]
    )
  end

  test "objective-satisfaction objective type remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "objective_satisfaction_pressure_objective_types",
      {"feedback_scope", "objective_satisfaction"},
      "objective_type",
      ["observation_quality"],
      ["stale_observation_quality"]
    )
  end

  test "objective-satisfaction objective status remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "objective_satisfaction_pressure_objective_statuses",
      {"feedback_scope", "objective_satisfaction"},
      "objective_status",
      ["at_risk"],
      ["stale_at_risk"]
    )
  end

  test "objective-satisfaction source objective status remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "objective_satisfaction_pressure_source_objective_statuses",
      {"feedback_scope", "objective_satisfaction"},
      "source_objective_status",
      ["missed_quality_threshold"],
      ["stale_quality_threshold"]
    )
  end

  test "objective-satisfaction target identity remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "objective_satisfaction_pressure_target_ids",
      {"feedback_scope", "objective_satisfaction"},
      "target_id",
      ["target_objective_quality"],
      ["stale_target_objective_quality"]
    )
  end

  test "objective-satisfaction scenario identity remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "objective_satisfaction_pressure_scenario_ids",
      {"feedback_scope", "objective_satisfaction"},
      "scenario_id",
      ["leo_1"],
      ["stale_leo_1"]
    )
  end

  test "objective-satisfaction spacecraft identity remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "objective_satisfaction_pressure_spacecraft_ids",
      {"feedback_scope", "objective_satisfaction"},
      "spacecraft_id",
      ["leo_1"],
      ["stale_leo_1"]
    )
  end

  test "objective-satisfaction branch identity remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "objective_satisfaction_pressure_branch_ids",
      {"feedback_scope", "objective_satisfaction"},
      "branch_id",
      ["urgent"],
      ["stale_urgent"]
    )
  end

  test "objective-satisfaction collection identities remain source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "objective_satisfaction_pressure_collection_ids",
      {"feedback_scope", "objective_satisfaction"},
      ["collection_id", "collection_ids"],
      ["collection_objective_quality", "collection_objective_quality_backup"],
      ["stale_collection_objective_quality"]
    )
  end

  test "objective-satisfaction product identities remain source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "objective_satisfaction_pressure_product_ids",
      {"feedback_scope", "objective_satisfaction"},
      ["product_id", "product_ids"],
      ["product_objective_quality", "product_objective_quality_backup"],
      ["stale_product_objective_quality"]
    )
  end

  test "objective-satisfaction payload identities remain source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "objective_satisfaction_pressure_payload_ids",
      {"feedback_scope", "objective_satisfaction"},
      ["payload_id", "payload_ids"],
      ["payload_objective_quality", "payload_objective_quality_backup"],
      ["stale_payload_objective_quality"]
    )
  end

  test "objective-satisfaction instrument identities remain source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "objective_satisfaction_pressure_instrument_ids",
      {"feedback_scope", "objective_satisfaction"},
      ["instrument_id", "instrument_ids"],
      ["instrument_objective_quality", "instrument_objective_quality_backup"],
      ["stale_instrument_objective_quality"]
    )
  end

  test "objective-satisfaction start timing remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "objective_satisfaction_pressure_start_values_s",
      {"feedback_scope", "objective_satisfaction"},
      "starts_at_s",
      [1_380.0],
      [1_381.0]
    )
  end

  test "objective-satisfaction end timing remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "objective_satisfaction_pressure_end_values_s",
      {"feedback_scope", "objective_satisfaction"},
      "ends_at_s",
      [1_440.0],
      [1_441.0]
    )
  end

  test "objective-satisfaction latency objective remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "objective_satisfaction_pressure_latency_objective_values",
      {"feedback_scope", "objective_satisfaction"},
      "latency_objective",
      [true],
      [false]
    )
  end

  test "objective-satisfaction ground station remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "objective_satisfaction_pressure_ground_station_ids",
      {"feedback_scope", "objective_satisfaction"},
      "ground_station_id",
      ["madrid_objective"],
      ["stale_objective_station"]
    )
  end

  test "objective-satisfaction required contacts remain source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "objective_satisfaction_pressure_required_contact_values",
      {"feedback_scope", "objective_satisfaction"},
      "required_contacts",
      [3],
      [4]
    )
  end

  test "objective-satisfaction planned contacts remain source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "objective_satisfaction_pressure_planned_contact_values",
      {"feedback_scope", "objective_satisfaction"},
      "planned_contacts",
      [1],
      [2]
    )
  end

  test "objective-satisfaction required downlink remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "objective_satisfaction_pressure_required_downlink_values_mb",
      {"feedback_scope", "objective_satisfaction"},
      "required_downlink_mb",
      [120.0],
      [121.0]
    )
  end

  test "objective-satisfaction planned downlink remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "objective_satisfaction_pressure_planned_downlink_values_mb",
      {"feedback_scope", "objective_satisfaction"},
      "planned_downlink_mb",
      [70.0],
      [71.0]
    )
  end

  test "objective-satisfaction maximum latency remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "objective_satisfaction_pressure_max_latency_values_s",
      {"feedback_scope", "objective_satisfaction"},
      "max_latency_s",
      [300.0],
      [301.0]
    )
  end

  test "objective-satisfaction planned latency remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "objective_satisfaction_pressure_planned_latency_values_s",
      {"feedback_scope", "objective_satisfaction"},
      "planned_latency_s",
      [480.0],
      [481.0]
    )
  end

  test "objective-satisfaction required observations remain source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "objective_satisfaction_pressure_required_observation_values",
      {"feedback_scope", "objective_satisfaction"},
      "required_observations",
      [2],
      [3]
    )
  end

  test "objective-satisfaction planned observations remain source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "objective_satisfaction_pressure_planned_observation_values",
      {"feedback_scope", "objective_satisfaction"},
      "planned_observations",
      [1],
      [2]
    )
  end

  test "objective-satisfaction priority remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "objective_satisfaction_pressure_priorities",
      {"feedback_scope", "objective_satisfaction"},
      "priority",
      [32.0],
      [33.0]
    )
  end

  test "objective-satisfaction latitude remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "objective_satisfaction_pressure_latitude_values_deg",
      {"feedback_scope", "objective_satisfaction"},
      "latitude_deg",
      [34.1],
      [34.2]
    )
  end

  test "objective-satisfaction longitude remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "objective_satisfaction_pressure_longitude_values_deg",
      {"feedback_scope", "objective_satisfaction"},
      "longitude_deg",
      [-118.2],
      [-118.1]
    )
  end

  test "objective-satisfaction minimum elevation remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "objective_satisfaction_pressure_minimum_elevation_values_deg",
      {"feedback_scope", "objective_satisfaction"},
      "minimum_elevation_deg",
      [15.0],
      [16.0]
    )
  end

  test "objective-satisfaction observation success remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "objective_satisfaction_pressure_observation_success_factor_values",
      {"feedback_scope", "objective_satisfaction"},
      "observation_success_factor",
      [0.35],
      [0.36]
    )
  end

  test "objective-satisfaction image quality score remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "objective_satisfaction_pressure_image_quality_score_values",
      {"feedback_scope", "objective_satisfaction"},
      "image_quality_score",
      [0.42],
      [0.43]
    )
  end

  test "objective-satisfaction image quality status remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "objective_satisfaction_pressure_image_quality_statuses",
      {"feedback_scope", "objective_satisfaction"},
      "image_quality_status",
      ["marginal"],
      ["stale_quality_status"]
    )
  end

  test "objective-satisfaction image quality source remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "objective_satisfaction_pressure_image_quality_sources",
      {"feedback_scope", "objective_satisfaction"},
      "image_quality_source",
      ["provider_imagery_quality"],
      ["stale_imagery_source"]
    )
  end

  test "objective-satisfaction cloud cover remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "objective_satisfaction_pressure_cloud_cover_fraction_values",
      {"feedback_scope", "objective_satisfaction"},
      "cloud_cover_fraction",
      [0.62],
      [0.63]
    )
  end

  test "objective-satisfaction blur score remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "objective_satisfaction_pressure_blur_score_values",
      {"feedback_scope", "objective_satisfaction"},
      "blur_score",
      [0.31],
      [0.32]
    )
  end

  test "objective-satisfaction quality feedback source remains exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "objective_satisfaction_pressure_quality_feedback_sources",
      {"feedback_scope", "objective_satisfaction"},
      "quality_feedback_source",
      ["mission_state.source_imagery_quality.rows"],
      ["stale_quality_feedback_source"]
    )
  end

  test "objective-satisfaction source activity remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "objective_satisfaction_pressure_source_activity_ids",
      {"feedback_scope", "objective_satisfaction"},
      ["source_activity_id", "source_activity_ids"],
      ["obs_objective_quality_source", "obs_objective_quality_selected"],
      ["stale_objective_satisfaction_activity"]
    )
  end

  test "objective-satisfaction feedback source remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "objective_satisfaction_pressure_feedback_sources",
      {"feedback_scope", "objective_satisfaction"},
      "feedback_source",
      ["mission_state.source_objective_satisfaction_report.rows"],
      ["stale_objective_satisfaction_source"]
    )
  end

  test "objective-satisfaction feedback scope remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "objective_satisfaction_pressure_feedback_scopes",
      {"feedback_scope", "objective_satisfaction"},
      "feedback_scope",
      ["objective_satisfaction"],
      ["stale_objective_satisfaction_scope"]
    )
  end

  test "objective-satisfaction trust boundary remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "objective_satisfaction_pressure_trust_boundaries",
      {"feedback_scope", "objective_satisfaction"},
      "trust_boundary",
      ["mission_state_objective_satisfaction_report"],
      ["stale_objective_satisfaction_boundary"]
    )
  end

  test "objective-satisfaction derivation reasons remain source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "objective_satisfaction_pressure_derivation_reasons",
      {"feedback_scope", "objective_satisfaction"},
      ["derivation_reasons"],
      [
        "objective_satisfaction_observation_quality_gap",
        "objective_satisfaction_image_quality_marginal"
      ],
      ["stale_objective_satisfaction_derivation"]
    )
  end

  test "objective-satisfaction missed downlink activity remains exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "objective_satisfaction_pressure_missed_downlink_activity_ids",
      {"feedback_scope", "objective_satisfaction"},
      ["missed_downlink_activity_id", "missed_downlink_activity_ids"],
      ["dl_objective_missed", "dl_objective_selected"],
      ["stale_objective_missed_downlink"]
    )
  end

  test "objective-satisfaction realized status remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "objective_satisfaction_pressure_realized_statuses",
      {"feedback_scope", "objective_satisfaction"},
      "realized_status",
      ["missed"],
      ["stale_realized_status"]
    )
  end

  test "objective-satisfaction contact result remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "objective_satisfaction_pressure_contact_results",
      {"feedback_scope", "objective_satisfaction"},
      "contact_result",
      ["missed"],
      ["stale_contact_result"]
    )
  end

  test "objective-satisfaction candidate windows remain source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "objective_satisfaction_pressure_candidate_window_maps",
      {"feedback_scope", "objective_satisfaction"},
      ["candidate_windows"],
      [
        %{
          "id" => "window_objective_quality_primary",
          "scenario_id" => "leo_1",
          "starts_at_s" => 1_380.0,
          "ends_at_s" => 1_440.0
        }
      ],
      [%{"id" => "window_objective_quality_stale"}]
    )
  end

  test "objective-satisfaction allowed scenarios remain source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "objective_satisfaction_pressure_allowed_scenario_ids",
      {"feedback_scope", "objective_satisfaction"},
      ["allowed_scenario_ids"],
      ["leo_1", "leo_2"],
      ["stale_objective_scenario"]
    )
  end

  test "objective-satisfaction spacecraft constraints remain exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "objective_satisfaction_pressure_spacecraft_constraint_maps",
      {"feedback_scope", "objective_satisfaction"},
      ["spacecraft_constraints"],
      ["leo_1", "leo_2"],
      ["stale_objective_spacecraft"]
    )
  end

  test "objective-satisfaction coverage objective remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "objective_satisfaction_pressure_coverage_objective_ids",
      {"feedback_scope", "objective_satisfaction"},
      "coverage_objective_id",
      ["coverage:target_quality"],
      ["coverage:stale_target_quality"]
    )
  end

  test "objective-satisfaction downlink demand source remains exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "objective_satisfaction_pressure_downlink_demand_sources",
      {"feedback_scope", "objective_satisfaction"},
      ["downlink_demand_sources"],
      ["objective_satisfaction.required_downlink"],
      ["stale_objective_downlink_demand"]
    )
  end

  test "objective-satisfaction downlink completion source remains exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "objective_satisfaction_pressure_downlink_completion_sources",
      {"feedback_scope", "objective_satisfaction"},
      ["downlink_completion_sources"],
      ["objective_satisfaction.realized_downlink"],
      ["stale_objective_downlink_completion"]
    )
  end

  test "objective-tradeoff risk type remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "objective_tradeoff_pressure_risk_types",
      {"feedback_scope", "objective_tradeoff"},
      ["type", "risk_type"],
      ["downlink_completion_gap"],
      ["stale_objective_tradeoff_risk"]
    )
  end

  test "objective-tradeoff objective identity remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "objective_tradeoff_pressure_objective_ids",
      {"feedback_scope", "objective_tradeoff"},
      "objective_id",
      ["objective_tradeoff:latency_gap"],
      ["objective_tradeoff:stale"]
    )
  end

  test "objective-tradeoff objective type remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "objective_tradeoff_pressure_objective_types",
      {"feedback_scope", "objective_tradeoff"},
      "objective_type",
      ["collection_latency"],
      ["stale_collection_latency"]
    )
  end

  test "objective-tradeoff latency-objective flag remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "objective_tradeoff_pressure_latency_objective_values",
      {"feedback_scope", "objective_tradeoff"},
      "latency_objective",
      [true],
      [false]
    )
  end

  test "objective-tradeoff target identity remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "objective_tradeoff_pressure_target_ids",
      {"feedback_scope", "objective_tradeoff"},
      "target_id",
      ["target_tradeoff"],
      ["stale_target_tradeoff"]
    )
  end

  test "objective-tradeoff scenario identity remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "objective_tradeoff_pressure_scenario_ids",
      {"feedback_scope", "objective_tradeoff"},
      "scenario_id",
      ["leo_1"],
      ["stale_leo_1"]
    )
  end

  test "objective-tradeoff branch identity remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "objective_tradeoff_pressure_branch_ids",
      {"feedback_scope", "objective_tradeoff"},
      "branch_id",
      ["urgent"],
      ["stale_urgent"]
    )
  end

  test "objective-tradeoff station identity remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "objective_tradeoff_pressure_ground_station_ids",
      {"feedback_scope", "objective_tradeoff"},
      "ground_station_id",
      ["madrid"],
      ["stale_madrid"]
    )
  end

  test "objective-tradeoff collection identities remain source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "objective_tradeoff_pressure_collection_ids",
      {"feedback_scope", "objective_tradeoff"},
      ["collection_id", "collection_ids"],
      ["collection_tradeoff_alpha", "collection_tradeoff_beta"],
      ["stale_collection_tradeoff"]
    )
  end

  test "objective-tradeoff product identities remain source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "objective_tradeoff_pressure_product_ids",
      {"feedback_scope", "objective_tradeoff"},
      ["product_id", "product_ids"],
      ["product_tradeoff_alpha", "product_tradeoff_beta"],
      ["stale_product_tradeoff"]
    )
  end

  test "objective-tradeoff payload identities remain source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "objective_tradeoff_pressure_payload_ids",
      {"feedback_scope", "objective_tradeoff"},
      ["payload_id", "payload_ids"],
      ["payload_tradeoff_alpha", "payload_tradeoff_beta"],
      ["stale_payload_tradeoff"]
    )
  end

  test "objective-tradeoff instrument identities remain source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "objective_tradeoff_pressure_instrument_ids",
      {"feedback_scope", "objective_tradeoff"},
      ["instrument_id", "instrument_ids"],
      ["instrument_tradeoff_alpha", "instrument_tradeoff_beta"],
      ["stale_instrument_tradeoff"]
    )
  end

  test "objective-tradeoff start timing remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "objective_tradeoff_pressure_start_values_s",
      {"feedback_scope", "objective_tradeoff"},
      "starts_at_s",
      [1_460.0],
      [1_461.0]
    )
  end

  test "objective-tradeoff end timing remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "objective_tradeoff_pressure_end_values_s",
      {"feedback_scope", "objective_tradeoff"},
      "ends_at_s",
      [1_580.0],
      [1_581.0]
    )
  end

  test "objective-tradeoff required contacts remain source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "objective_tradeoff_pressure_required_contact_values",
      {"feedback_scope", "objective_tradeoff"},
      "required_contacts",
      [2],
      [3]
    )
  end

  test "objective-tradeoff planned contacts remain source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "objective_tradeoff_pressure_planned_contact_values",
      {"feedback_scope", "objective_tradeoff"},
      "planned_contacts",
      [1],
      [2]
    )
  end

  test "objective-tradeoff required downlink remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "objective_tradeoff_pressure_required_downlink_values_mb",
      {"feedback_scope", "objective_tradeoff"},
      "required_downlink_mb",
      [90.0],
      [91.0]
    )
  end

  test "objective-tradeoff planned downlink remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "objective_tradeoff_pressure_planned_downlink_values_mb",
      {"feedback_scope", "objective_tradeoff"},
      "planned_downlink_mb",
      [45.0],
      [46.0]
    )
  end

  test "objective-tradeoff maximum latency remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "objective_tradeoff_pressure_max_latency_values_s",
      {"feedback_scope", "objective_tradeoff"},
      "max_latency_s",
      [240.0],
      [241.0]
    )
  end

  test "objective-tradeoff planned latency remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "objective_tradeoff_pressure_planned_latency_values_s",
      {"feedback_scope", "objective_tradeoff"},
      "planned_latency_s",
      [390.0],
      [391.0]
    )
  end

  test "objective-tradeoff source activity remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "objective_tradeoff_pressure_source_activity_ids",
      {"feedback_scope", "objective_tradeoff"},
      ["source_activity_id", "source_activity_ids"],
      ["obs_tradeoff_source", "dl_tradeoff_selected"],
      ["stale_tradeoff_source"]
    )
  end

  test "objective-tradeoff score remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "objective_tradeoff_pressure_score_values",
      {"feedback_scope", "objective_tradeoff"},
      "score",
      [7.25],
      [7.5]
    )
  end

  test "objective-tradeoff score delta remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "objective_tradeoff_pressure_score_delta_from_selected_values",
      {"feedback_scope", "objective_tradeoff"},
      "score_delta_from_selected",
      [-2.75],
      [-2.5]
    )
  end

  test "objective-tradeoff score terms remain source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "objective_tradeoff_pressure_score_term_maps",
      {"feedback_scope", "objective_tradeoff"},
      "score_terms",
      [%{"collection_latency_gap_s" => 150.0, "downlink_shortfall_mb" => 45.0}],
      [%{"collection_latency_gap_s" => 151.0, "downlink_shortfall_mb" => 45.0}]
    )
  end

  test "objective-tradeoff required observations remain source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "objective_tradeoff_pressure_required_observation_values",
      {"feedback_scope", "objective_tradeoff"},
      "required_observations",
      [2],
      [3]
    )
  end

  test "objective-tradeoff planned observations remain source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "objective_tradeoff_pressure_planned_observation_values",
      {"feedback_scope", "objective_tradeoff"},
      "planned_observations",
      [1],
      [2]
    )
  end

  test "objective-tradeoff priority remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "objective_tradeoff_pressure_priorities",
      {"feedback_scope", "objective_tradeoff"},
      "priority",
      [24.0],
      [25.0]
    )
  end

  test "objective-tradeoff latitude remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "objective_tradeoff_pressure_latitude_values_deg",
      {"feedback_scope", "objective_tradeoff"},
      "latitude_deg",
      [34.1],
      [34.2]
    )
  end

  test "objective-tradeoff longitude remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "objective_tradeoff_pressure_longitude_values_deg",
      {"feedback_scope", "objective_tradeoff"},
      "longitude_deg",
      [-118.2],
      [-118.1]
    )
  end

  test "objective-tradeoff minimum elevation remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "objective_tradeoff_pressure_minimum_elevation_values_deg",
      {"feedback_scope", "objective_tradeoff"},
      "minimum_elevation_deg",
      [15.0],
      [16.0]
    )
  end

  test "objective-tradeoff feedback source remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "objective_tradeoff_pressure_feedback_sources",
      {"feedback_scope", "objective_tradeoff"},
      "feedback_source",
      ["mission_state.source_objective_tradeoff_report.tradeoffs"],
      ["stale_objective_tradeoff_source"]
    )
  end

  test "objective-tradeoff feedback scope remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "objective_tradeoff_pressure_feedback_scopes",
      {"feedback_scope", "objective_tradeoff"},
      "feedback_scope",
      ["objective_tradeoff"],
      ["stale_objective_tradeoff_scope"]
    )
  end

  test "objective-tradeoff trust boundary remains source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "objective_tradeoff_pressure_trust_boundaries",
      {"feedback_scope", "objective_tradeoff"},
      "trust_boundary",
      ["mission_state_objective_tradeoff_report"],
      ["stale_objective_tradeoff_boundary"]
    )
  end

  test "objective-tradeoff derivation reasons remain source exact across handoffs" do
    assert_risk_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "objective_tradeoff_pressure_derivation_reasons",
      {"feedback_scope", "objective_tradeoff"},
      ["derivation_reasons"],
      [
        "objective_tradeoff_downlink_gap",
        "collection_latency_gap",
        "objective_tradeoff_latency_gap",
        "objective_tradeoff_unselected"
      ],
      ["stale_objective_tradeoff_derivation"]
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

  @resource_filter_availability_context_contracts [
    {"risk type", "resource_filter_pressure_risk_types", "type",
     [
       "downlink_margin_low",
       "fuel_margin_low",
       "payload_unavailable",
       "power_margin_low",
       "storage_margin_low",
       "thermal_margin_c_low"
     ], ["spacecraft_unavailable"]},
    {"scenario identity", "resource_filter_pressure_scenario_ids", "scenario_id", ["leo_1"],
     ["stale_scenario"]},
    {"spacecraft identity", "resource_filter_pressure_spacecraft_ids", "spacecraft_id", ["leo_1"],
     ["stale_spacecraft"]},
    {"resource field", "resource_filter_pressure_resource_fields", "resource_field",
     [
       "downlink_margin",
       "fuel_margin",
       "payload_available",
       "power_margin",
       "storage_margin",
       "thermal_margin_c"
     ], ["antenna_available"]},
    {"availability value", "resource_filter_pressure_available_values",
     ["available", "resource_availability_value"], [false], [true]},
    {"source activity identity", "resource_filter_pressure_source_activity_ids",
     ["source_activity_id", "source_activity_ids"],
     [
       "dl_resource_filter_downlink",
       "obs_resource_filter_fuel",
       "obs_resource_filter_suppressed",
       "obs_resource_filter_power",
       "obs_resource_filter_storage",
       "obs_resource_filter_thermal"
     ], ["stale_resource_filter_activity"]},
    {"start timing", "resource_filter_pressure_start_values_s", "starts_at_s",
     [1_510.0, 1_300.0, 1_230.0, 1_370.0, 1_440.0, 1_580.0], [1_231.0]},
    {"end timing", "resource_filter_pressure_end_values_s", "ends_at_s",
     [1_570.0, 1_360.0, 1_290.0, 1_430.0, 1_500.0, 1_640.0], [1_291.0]},
    {"suppression reason", "resource_filter_pressure_suppressed_reasons", "suppressed_reason",
     [
       "downlink_margin_below_policy",
       "fuel_margin_below_policy",
       "payload_unavailable",
       "power_margin_below_observe_policy",
       "storage_margin_below_observe_policy",
       "thermal_margin_below_policy"
     ], ["spacecraft_unavailable"]},
    {"source quality", "resource_filter_pressure_source_quality_values", "source_quality",
     ["operator_supplied"], ["stale_source_quality"]},
    {"resource trust status", "resource_filter_pressure_resource_trust_boundary_statuses",
     "resource_trust_boundary_status", ["declared"], ["unknown"]},
    {"feedback source", "resource_filter_pressure_feedback_sources", "feedback_source",
     ["mission_state.source_resource_filter_report.suppressed_candidates"],
     ["mission_state.stale_resource_filter_report.suppressed_candidates"]},
    {"feedback scope", "resource_filter_pressure_feedback_scopes", "feedback_scope",
     ["resource_filter"], ["stale_resource_filter"]},
    {"trust boundary", "resource_filter_pressure_trust_boundaries", "trust_boundary",
     ["mission_state_resource_filter_report"], ["stale_resource_filter_boundary"]},
    {"derivation reasons", "resource_filter_pressure_derivation_reasons", ["derivation_reasons"],
     [
       "resource_filter_suppressed",
       "downlink_margin_below_policy",
       "fuel_margin_below_policy",
       "payload_unavailable",
       "power_margin_below_observe_policy",
       "storage_margin_below_observe_policy",
       "thermal_margin_below_policy"
     ], ["stale_resource_filter_derivation"]}
  ]

  for {description, field, source_field, expected_value, stale_value} <-
        @resource_filter_availability_context_contracts do
    test "resource-filter #{description} remains source exact across handoffs" do
      assert_risk_context_contract(
        StrategyRecommendationPressureEventsFixture.artifact(),
        unquote(field),
        {"feedback_scope", "resource_filter"},
        unquote(Macro.escape(source_field)),
        unquote(Macro.escape(expected_value)),
        unquote(Macro.escape(stale_value))
      )
    end
  end

  @resource_filter_margin_context_contracts [
    {"fuel margin", "resource_filter_pressure_fuel_margin_values", "fuel_margin",
     ["fuel_margin", "resource_margin_value"], [0.05], [0.06]},
    {"fuel margin threshold", "resource_filter_pressure_fuel_margin_threshold_values",
     "fuel_margin", ["fuel_margin_threshold", "resource_margin_threshold"], [0.1], [0.11]},
    {"power margin", "resource_filter_pressure_power_margin_values", "power_margin",
     ["power_margin", "resource_margin_value"], [0.08], [0.09]},
    {"power margin threshold", "resource_filter_pressure_power_margin_threshold_values",
     "power_margin", ["power_margin_threshold", "resource_margin_threshold"], [0.2], [0.21]},
    {"storage margin", "resource_filter_pressure_storage_margin_values", "storage_margin",
     ["storage_margin", "resource_margin_value"], [12.0], [13.0]},
    {"storage margin threshold", "resource_filter_pressure_storage_margin_threshold_values",
     "storage_margin", ["storage_margin_threshold", "resource_margin_threshold"], [20.0], [21.0]},
    {"downlink margin", "resource_filter_pressure_downlink_margin_values", "downlink_margin",
     ["downlink_margin", "resource_margin_value"], [8.0], [9.0]},
    {"downlink margin threshold", "resource_filter_pressure_downlink_margin_threshold_values",
     "downlink_margin", ["downlink_margin_threshold", "resource_margin_threshold"], [15.0],
     [16.0]},
    {"thermal margin", "resource_filter_pressure_thermal_margin_values_c", "thermal_margin_c",
     ["thermal_margin_c", "resource_margin_value"], [2.0], [3.0]},
    {"thermal margin threshold", "resource_filter_pressure_thermal_margin_threshold_values_c",
     "thermal_margin_c", ["thermal_margin_c_threshold", "resource_margin_threshold"], [5.0],
     [6.0]},
    {"operator training count",
     "resource_filter_pressure_operator_training_requirement_count_values", "power_margin",
     "operator_training_requirement_count", [2], [3]},
    {"required operator roles", "resource_filter_pressure_required_operator_roles",
     "power_margin", ["required_operator_roles"], ["contact_operator", "resource_operator"],
     ["stale_operator_role"]}
  ]

  for {description, field, resource_field, source_field, expected_value, stale_value} <-
        @resource_filter_margin_context_contracts do
    test "resource-filter #{description} remains source exact across handoffs" do
      assert_risk_context_contract(
        StrategyRecommendationPressureEventsFixture.artifact(),
        unquote(field),
        {"resource_field", unquote(resource_field)},
        unquote(Macro.escape(source_field)),
        unquote(Macro.escape(expected_value)),
        unquote(Macro.escape(stale_value))
      )
    end
  end

  @resource_margin_context_contracts [
    {"risk type", "resource_margin_risk_types", "resource_margin_risk_type",
     [
       "downlink_margin_low",
       "fuel_margin_low",
       "power_margin_low",
       "storage_margin_low",
       "thermal_margin_c_low"
     ], ["stale_resource_margin_risk"]},
    {"spacecraft identity", "resource_margin_spacecraft_ids", "spacecraft_id",
     ["leo_1", "leo_projection_selected"], ["stale_spacecraft"]},
    {"scenario identity", "resource_margin_scenario_ids", "scenario_id",
     ["leo_1", "leo_projection_selected"], ["stale_scenario"]},
    {"timeline identity", "resource_margin_timeline_ids", "timeline_id",
     ["timeline:resource_margin:power"], ["timeline:stale_resource_margin"]},
    {"source activity identity", "resource_margin_source_activity_ids",
     ["source_activity_id", "source_activity_ids"],
     [
       "dl_resource_filter_downlink",
       "obs_projection_pressure",
       "obs_resource_filter_fuel",
       "obs_power_pressure",
       "obs_resource_filter_power",
       "obs_resource_filter_storage",
       "obs_resource_filter_thermal"
     ], ["stale_resource_margin_activity"]},
    {"replacement activity identity", "resource_margin_replacement_activity_ids",
     "replacement_activity_id", ["obs_power_pressure_replanned"],
     ["stale_resource_margin_replacement"]},
    {"resource field", "resource_margin_fields", "resource_field",
     [
       "downlink_margin",
       "fuel_margin",
       "power_margin",
       "storage_margin",
       "thermal_margin_c"
     ], ["stale_margin"]},
    {"margin value", "resource_margin_values", "resource_margin_value",
     [8.0, 0.0, 0.05, 0.08, 12.0, 2.0, -1.5], [999.0]},
    {"margin threshold", "resource_margin_threshold_values", "resource_margin_threshold",
     [15.0, 0.75, 0.1, 0.2, 20.0, 5.0, 0.0], [1_000.0]},
    {"field value map", "resource_margin_field_value_maps", "resource_margin_field_value",
     [
       %{"field" => "downlink_margin", "threshold" => 15.0, "value" => 8.0},
       %{"field" => "downlink_margin", "threshold" => 0.75, "value" => 0.0},
       %{"field" => "fuel_margin", "threshold" => 0.1, "value" => 0.05},
       %{"field" => "power_margin", "threshold" => 0.2, "value" => 0.08},
       %{"field" => "power_margin", "threshold" => 0.2, "value" => 0.0},
       %{"field" => "storage_margin", "threshold" => 20.0, "value" => 12.0},
       %{"field" => "storage_margin", "threshold" => 0.2, "value" => 0.0},
       %{"field" => "thermal_margin_c", "threshold" => 5.0, "value" => 2.0},
       %{"field" => "thermal_margin_c", "threshold" => 0.0, "value" => -1.5}
     ], [%{"field" => "stale_margin", "threshold" => 1_000.0, "value" => 999.0}]},
    {"source quality", "resource_margin_source_quality_values", "source_quality",
     ["operator_supplied", "declared"], ["stale_source_quality"]},
    {"start timing", "resource_margin_start_values_s", "starts_at_s",
     [1_510.0, 1_590.0, 1_300.0, 500.0, 1_370.0, 1_440.0, 1_580.0], [999.0]},
    {"end timing", "resource_margin_end_values_s", "ends_at_s",
     [1_570.0, 1_650.0, 1_360.0, 560.0, 1_430.0, 1_500.0, 1_640.0], [1_000.0]},
    {"diff status", "resource_margin_diff_statuses", "diff_status", ["changed"], ["unchanged"]},
    {"changed field", "resource_margin_changed_fields", ["changed_fields"], ["power_margin"],
     ["stale_margin"]},
    {"required operator action", "resource_margin_required_operator_actions",
     "required_operator_action", ["review_resource_margin"], ["stale_operator_action"]},
    {"operator review requirement", "resource_margin_requires_operator_review_values",
     "requires_operator_review", [true], [false]},
    {"feedback source", "resource_margin_feedback_sources", "feedback_source",
     [
       "mission_state.source_resource_filter_report.suppressed_candidates",
       "mission_state.source_resource_projection_report",
       "mission_state.source_resource_projection_report.rows"
     ], ["mission_state.stale_resource_margin_report.rows"]},
    {"feedback scope", "resource_margin_feedback_scopes", "feedback_scope",
     ["resource_filter", "resource_projection", "resource_margin"], ["stale_resource_margin"]},
    {"feedback key", "resource_margin_feedback_keys", "feedback_key", ["leo_1.power_margin"],
     ["stale_spacecraft.power_margin"]},
    {"trust boundary", "resource_margin_trust_boundaries", "trust_boundary",
     ["mission_state_resource_filter_report", "mission_state_resource_projection_report"],
     ["stale_resource_margin_boundary"]},
    {"derivation reason", "resource_margin_derivation_reasons", ["derivation_reasons"],
     [
       "resource_filter_suppressed",
       "downlink_margin_below_policy",
       "projected_downlink_shortfall",
       "fuel_margin_below_policy",
       "resource_projection_power_margin_low",
       "power_margin_below_observe_policy",
       "projected_battery_depletion",
       "storage_margin_below_observe_policy",
       "projected_storage_overflow",
       "thermal_margin_below_policy",
       "projected_thermal_margin_below_limit"
     ], ["stale_resource_margin_derivation"]}
  ]

  @resource_margin_risk_types [
    "downlink_margin_low",
    "fuel_margin_low",
    "power_margin_low",
    "storage_margin_low",
    "thermal_margin_c_low"
  ]

  for {description, field, source_field, expected_value, stale_value} <-
        @resource_margin_context_contracts do
    test "resource-margin #{description} remains source exact across handoffs" do
      assert_risk_context_contract(
        StrategyRecommendationPressureEventsFixture.artifact(),
        unquote(field),
        {"resource_margin_risk_type", @resource_margin_risk_types},
        unquote(Macro.escape(source_field)),
        unquote(Macro.escape(expected_value)),
        unquote(Macro.escape(stale_value))
      )
    end
  end

  @resource_projection_downlink_context_contracts [
    {"risk type", "resource_projection_pressure_risk_types", ["type", "risk_type"],
     [
       "activity_type_incompatible_with_resource_summary",
       "antenna_unavailable",
       "downlink_completion_gap",
       "downlink_margin_low",
       "power_margin_low",
       "spacecraft_degraded_payload_unavailable",
       "spacecraft_unavailable",
       "storage_margin_low",
       "thermal_margin_c_low"
     ], ["stale_resource_projection_risk"]},
    {"scenario identity", "resource_projection_pressure_scenario_ids", "scenario_id",
     ["leo_projection_selected"], ["stale_scenario"]},
    {"spacecraft identity", "resource_projection_pressure_spacecraft_ids", "spacecraft_id",
     ["leo_projection_selected"], ["stale_spacecraft"]},
    {"ground-station identity", "resource_projection_pressure_ground_station_ids",
     "ground_station_id", ["polar_prime"], ["stale_station"]},
    {"source activity identity", "resource_projection_pressure_source_activity_ids",
     ["source_activity_id", "source_activity_ids"], ["obs_projection_pressure"],
     ["stale_projection_activity"]},
    {"required contacts", "resource_projection_pressure_required_contact_values",
     "required_contacts", [1], [2]},
    {"planned contacts", "resource_projection_pressure_planned_contact_values",
     "planned_contacts", [0], [1]},
    {"required downlink", "resource_projection_pressure_required_downlink_values_mb",
     "required_downlink_mb", [52.0], [53.0]},
    {"planned downlink", "resource_projection_pressure_planned_downlink_values_mb",
     "planned_downlink_mb", [12.0], [13.0]},
    {"start timing", "resource_projection_pressure_start_values_s", "starts_at_s", [1_590.0],
     [1_591.0]},
    {"end timing", "resource_projection_pressure_end_values_s", "ends_at_s", [1_650.0],
     [1_651.0]},
    {"downlink demand source", "resource_projection_pressure_downlink_demand_sources",
     ["downlink_demand_sources"],
     ["resource_projection.projected_downlink_shortfall:obs_projection_pressure"],
     ["resource_projection.stale_downlink_demand:obs_projection_pressure"]},
    {"downlink completion source", "resource_projection_pressure_downlink_completion_sources",
     ["downlink_completion_sources"],
     ["resource_projection.projected_downlink_shortfall:obs_projection_pressure"],
     ["resource_projection.stale_downlink_completion:obs_projection_pressure"]},
    {"feedback source", "resource_projection_pressure_feedback_sources", "feedback_source",
     ["mission_state.source_resource_projection_report"],
     ["mission_state.stale_resource_projection_report"]},
    {"feedback scope", "resource_projection_pressure_feedback_scopes", "feedback_scope",
     ["resource_projection"], ["stale_resource_projection"]},
    {"trust boundary", "resource_projection_pressure_trust_boundaries", "trust_boundary",
     ["mission_state_resource_projection_report"], ["stale_resource_projection_boundary"]},
    {"derivation reason", "resource_projection_pressure_derivation_reasons",
     ["derivation_reasons"],
     [
       "projected_activity_type_incompatible_with_resource_summary",
       "projected_antenna_unavailable",
       "projected_downlink_shortfall",
       "projected_battery_depletion",
       "projected_spacecraft_degraded_payload_unavailable",
       "projected_spacecraft_unavailable",
       "projected_storage_overflow",
       "projected_thermal_margin_below_limit"
     ], ["stale_resource_projection_derivation"]}
  ]

  for {description, field, source_field, expected_value, stale_value} <-
        @resource_projection_downlink_context_contracts do
    test "resource-projection #{description} remains source exact across handoffs" do
      assert_risk_context_contract(
        StrategyRecommendationPressureEventsFixture.artifact(),
        unquote(field),
        {"feedback_scope", "resource_projection"},
        unquote(Macro.escape(source_field)),
        unquote(Macro.escape(expected_value)),
        unquote(Macro.escape(stale_value))
      )
    end
  end

  @resource_projection_resource_context_contracts [
    {"resource fields", "resource_projection_pressure_resource_fields", "resource_field",
     [
       "antenna_available",
       "downlink_margin",
       "power_margin",
       "payload_available",
       "spacecraft_available",
       "storage_margin",
       "thermal_margin_c"
     ], ["stale_resource_field"]},
    {"availability value", "resource_projection_pressure_available_values",
     ["available", "resource_availability_value"], [false], [true]},
    {"degraded value", "resource_projection_pressure_degraded_values", "degraded", [true],
     [false]},
    {"payload availability", "resource_projection_pressure_payload_available_values",
     "payload_available", [false], [true]},
    {"spacecraft availability", "resource_projection_pressure_spacecraft_available_values",
     "spacecraft_available", [false], [true]},
    {"antenna availability", "resource_projection_pressure_antenna_available_values",
     "antenna_available", [false], [true]},
    {"compatibility mode", "resource_projection_pressure_modes", "mode",
     ["resource_activity_type_constraint"], ["stale_resource_mode"]},
    {"incompatible activity types", "resource_projection_pressure_incompatible_activity_types",
     ["incompatible_activity_types"], ["downlink", "observe"], ["maneuver"]},
    {"storage margin", "resource_projection_pressure_storage_margin_values",
     ["storage_margin", "resource_margin_value"], [0.0], [1.0]},
    {"storage margin threshold", "resource_projection_pressure_storage_margin_threshold_values",
     ["storage_margin_threshold", "resource_margin_threshold"], [0.2], [0.3]},
    {"projected storage overflow",
     "resource_projection_pressure_projected_storage_overflow_values_mb",
     "projected_storage_overflow_mb", [25.0], [26.0]},
    {"downlink margin", "resource_projection_pressure_downlink_margin_values",
     ["downlink_margin", "resource_margin_value"], [0.0], [1.0]},
    {"downlink margin threshold", "resource_projection_pressure_downlink_margin_threshold_values",
     ["downlink_margin_threshold", "resource_margin_threshold"], [0.75], [0.8]},
    {"projected downlink shortfall",
     "resource_projection_pressure_projected_downlink_shortfall_values_mb",
     "projected_downlink_shortfall_mb", [10.0], [11.0]},
    {"power margin", "resource_projection_pressure_power_margin_values",
     ["power_margin", "resource_margin_value"], [0.0], [1.0]},
    {"power margin threshold", "resource_projection_pressure_power_margin_threshold_values",
     ["power_margin_threshold", "resource_margin_threshold"], [0.2], [0.3]},
    {"projected battery overuse",
     "resource_projection_pressure_projected_battery_overuse_values_wh",
     "projected_battery_overuse_wh", [5.0], [6.0]},
    {"thermal margin", "resource_projection_pressure_thermal_margin_values_c",
     ["thermal_margin_c", "resource_margin_value"], [-1.5], [-1.0]},
    {"thermal margin threshold", "resource_projection_pressure_thermal_margin_threshold_values_c",
     ["thermal_margin_c_threshold", "resource_margin_threshold"], [0.0], [1.0]},
    {"source quality", "resource_projection_pressure_source_quality_values", "source_quality",
     ["operator_supplied"], ["stale_source_quality"]}
  ]

  for {description, field, source_field, expected_value, stale_value} <-
        @resource_projection_resource_context_contracts do
    test "resource-projection #{description} remains source exact across handoffs" do
      assert_risk_context_contract(
        StrategyRecommendationPressureEventsFixture.artifact(),
        unquote(field),
        {"feedback_scope", "resource_projection"},
        unquote(Macro.escape(source_field)),
        unquote(Macro.escape(expected_value)),
        unquote(Macro.escape(stale_value))
      )
    end
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
        if risk_identity_matches?(risk, identity_field, identity_value) do
          Enum.reduce(List.wrap(source_fields), risk, &Map.delete(&2, &1))
        else
          risk
        end
      end)
    end)
    |> update_in(["source_recommendation", "explanation"], fn explanation ->
      Enum.map(explanation, fn explanation_row ->
        if risk_identity_matches?(explanation_row, identity_field, identity_value) do
          Enum.reduce(List.wrap(source_fields), explanation_row, &Map.delete(&2, &1))
        else
          explanation_row
        end
      end)
    end)
    |> sync_mutated_risk_contexts()
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
      |> Enum.reject(&risk_identity_matches?(&1, identity_field, identity_value))

    row
    |> Map.delete(field)
    |> put_in(["source_recommendation", "risks_remaining"], risks)
    |> Map.put("risk_count", length(risks))
    |> sync_mutated_risk_contexts()
  end

  defp stale_context_value([_, _ | _] = values), do: Enum.reverse(values)
  defp stale_context_value([value]) when is_boolean(value), do: [not value]
  defp stale_context_value([value]) when is_integer(value), do: [value + 1]
  defp stale_context_value([value]) when is_float(value), do: [value + 1.0]
  defp stale_context_value([value]) when is_binary(value), do: ["stale_" <> value]
  defp stale_context_value([values]) when is_list(values), do: [Enum.reverse(values)]

  defp stale_context_value([%{} = value]) do
    {key, current_value} = Enum.at(value, 0)
    [Map.put(value, key, stale_context_scalar(current_value))]
  end

  defp stale_context_scalar(value) when is_boolean(value), do: not value
  defp stale_context_scalar(value) when is_integer(value), do: value + 1
  defp stale_context_scalar(value) when is_float(value), do: value + 1.0
  defp stale_context_scalar(value) when is_binary(value), do: "stale_" <> value

  defp sync_mutated_risk_contexts(row) do
    risks = get_in(row, ["source_recommendation", "risks_remaining"])

    context_keys =
      OrbitalDynamics.RecommendationRiskContext.ResourceFilter.context_keys() ++
        OrbitalDynamics.RecommendationRiskContext.ResourceMargin.context_keys() ++
        OrbitalDynamics.RecommendationRiskContext.ResourceProjection.context_keys() ++
        OrbitalDynamics.RecommendationRiskContext.ExecutionSuccessFeedback.context_keys() ++
        OrbitalDynamics.RecommendationRiskContext.RelayDataPath.context_keys() ++
        OrbitalDynamics.RecommendationRiskContext.ObjectiveSatisfaction.context_keys() ++
        OrbitalDynamics.RecommendationRiskContext.OperationalFeedback.context_keys() ++
        OrbitalDynamics.RecommendationRiskContext.TimelineActivityLifecycleState.context_keys() ++
        OrbitalDynamics.RecommendationRiskContext.TimelinePreservation.context_keys() ++
        OrbitalDynamics.RecommendationRiskContext.TimelineActivityPrecondition.context_keys() ++
        OrbitalDynamics.RecommendationRiskContext.TimelineIntegrity.context_keys()

    context =
      risks
      |> OrbitalDynamics.RecommendationRiskContext.ResourceFilter.context()
      |> Map.merge(OrbitalDynamics.RecommendationRiskContext.ResourceMargin.context(risks))
      |> Map.merge(OrbitalDynamics.RecommendationRiskContext.ResourceProjection.context(risks))
      |> Map.merge(
        OrbitalDynamics.RecommendationRiskContext.ExecutionSuccessFeedback.context(risks)
      )
      |> Map.merge(OrbitalDynamics.RecommendationRiskContext.RelayDataPath.context(risks))
      |> Map.merge(OrbitalDynamics.RecommendationRiskContext.ObjectiveSatisfaction.context(risks))
      |> Map.merge(OrbitalDynamics.RecommendationRiskContext.OperationalFeedback.context(risks))
      |> Map.merge(
        OrbitalDynamics.RecommendationRiskContext.TimelineActivityLifecycleState.context(risks)
      )
      |> Map.merge(OrbitalDynamics.RecommendationRiskContext.TimelinePreservation.context(risks))
      |> Map.merge(
        OrbitalDynamics.RecommendationRiskContext.TimelineActivityPrecondition.context(risks)
      )
      |> Map.merge(OrbitalDynamics.RecommendationRiskContext.TimelineIntegrity.context(risks))

    row
    |> Map.drop(context_keys)
    |> Map.merge(context)
  end

  defp risk_identity_matches?(risk, identity_field, identity_values)
       when is_list(identity_values) do
    risk[identity_field] in identity_values
  end

  defp risk_identity_matches?(risk, identity_field, identity_value) do
    risk[identity_field] == identity_value
  end
end
