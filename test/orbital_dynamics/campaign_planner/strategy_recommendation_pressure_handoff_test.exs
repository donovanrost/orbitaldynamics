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

  test "station conflict expiration risk context remains source exact across handoffs" do
    assert_risk_expiration_context_contract(
      StrategyRecommendationPressureEventsFixture.artifact(),
      "station_reservation_conflict_expiration_statuses",
      {"contact_id", "dl_reservation_conflict"},
      "active"
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
        fn row ->
          row
          |> Map.delete(field)
          |> update_in(["source_recommendation", "risks_remaining"], fn risks ->
            Enum.map(risks, fn risk ->
              if risk[identity_field] == identity_value do
                Map.delete(risk, source_field)
              else
                risk
              end
            end)
          end)
          |> update_in(["source_recommendation", "explanation"], fn explanation ->
            Enum.map(explanation, fn row ->
              if row[identity_field] == identity_value do
                Map.delete(row, source_field)
              else
                row
              end
            end)
          end)
        end
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
end
