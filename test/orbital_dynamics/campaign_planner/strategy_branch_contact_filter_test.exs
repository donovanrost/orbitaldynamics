Code.require_file("support.exs", __DIR__)

defmodule OrbitalDynamics.CampaignPlanner.StrategyBranchContactFilterTest do
  use ExUnit.Case, async: true

  import OrbitalDynamics.CampaignPlanner.TestSupport

  alias OrbitalDynamics.Schema

  test "strategy-derived refresh applies branch ground-network outages through contact filters" do
    artifact =
      strategy(base_plan(%{}),
        mission_state: mission_state_with_refresh_inputs(),
        branches: [
          %{id: "baseline"},
          %{
            id: "outage",
            events: [
              %{
                type: "ground_station_outage",
                ground_station_id: "equator_prime",
                starts_at_s: 0.0,
                ends_at_s: 600.0
              }
            ]
          }
        ],
        current_epoch_s: 0.0
      )

    repair = branch(artifact, "outage")["repair_result"]

    assert %{
             "schema_contract" => "contact_filter_report.v1",
             "suppressed_candidate_count" => suppressed_count
           } = repair["source_contact_filter_report"]

    assert suppressed_count > 0

    refute Enum.any?(
             repair["source_candidate_activities"],
             &(&1["type"] == "downlink" and &1["ground_station_id"] == "equator_prime")
           )
  end

  test "strategy-derived refresh applies branch ground-station reservations through contact filters" do
    artifact =
      strategy(base_plan(%{}),
        mission_state: mission_state_with_refresh_inputs(),
        branches: [
          %{id: "baseline"},
          %{
            id: "reserved",
            events: [
              %{
                type: "ground_station_reserved",
                ground_station_id: "equator_prime",
                starts_at_s: 0.0,
                ends_at_s: 600.0,
                reservation_id: "reservation_equator_prime_1",
                reserved_by: "ops_team_b",
                reservation_status: "reserved"
              }
            ]
          }
        ],
        current_epoch_s: 0.0
      )

    repair = branch(artifact, "reserved")["repair_result"]

    assert %{
             "schema_contract" => "contact_filter_report.v1",
             "suppressed_candidate_count" => suppressed_count,
             "suppressed_candidates" => [
               %{
                 "suppressed_reason" => "ground_station_reserved",
                 "station_availability" => "reserved",
                 "station_contention_status" => "reserved_overlap",
                 "station_reservation_id" => "reservation_equator_prime_1",
                 "station_reserved_by" => "ops_team_b",
                 "station_reservation_status" => "reserved"
               }
               | _
             ]
           } = repair["source_contact_filter_report"]

    assert suppressed_count > 0

    refute Enum.any?(
             repair["source_candidate_activities"],
             &(&1["type"] == "downlink" and &1["ground_station_id"] == "equator_prime")
           )
  end

  test "strategy-derived refresh applies station-id branch reservations through contact filters" do
    artifact =
      strategy(base_plan(%{}),
        mission_state: mission_state_with_refresh_inputs(),
        approval_policy: %{
          "action_rules" => [
            %{
              "id" => "wrong_calendar_entry_must_not_match",
              "risk_types" => ["ground_station_reserved"],
              "station_id" => "equator_prime",
              "station_calendar_entry_id" => "other_reserved_window",
              "station_calendar_provider_id" => "partner_calendar",
              "station_calendar_status" => "reserved",
              "station_reservation_id" => "reservation_equator_prime_1",
              "station_reserved_by" => "ops_team_b",
              "classification" => "blocked_by_policy",
              "reason" => "wrong calendar entry must not match"
            },
            %{
              "id" => "wrong_calendar_entry_event_must_not_match",
              "event_types" => ["ground_station_reserved"],
              "station_id" => "equator_prime",
              "station_calendar_entry_id" => "other_reserved_window",
              "station_calendar_provider_id" => "partner_calendar",
              "station_calendar_status" => "reserved",
              "classification" => "operator_review_required",
              "reason" => "wrong event calendar entry must not match"
            },
            %{
              "id" => "wrong_calendar_reservation_must_not_match",
              "risk_types" => ["ground_station_reserved"],
              "station_id" => "equator_prime",
              "station_calendar_entry_id" => "partner_reserved_window_1",
              "station_calendar_provider_id" => "partner_calendar",
              "station_calendar_reservation_id" => "other_reservation",
              "classification" => "blocked_by_policy",
              "reason" => "wrong calendar reservation must not match"
            },
            %{
              "id" => "wrong_calendar_reservation_event_must_not_match",
              "event_types" => ["ground_station_reserved"],
              "station_id" => "equator_prime",
              "station_calendar_entry_id" => "partner_reserved_window_1",
              "station_calendar_provider_id" => "partner_calendar",
              "station_calendar_reservation_id" => "other_reservation",
              "classification" => "operator_review_required",
              "reason" => "wrong event calendar reservation must not match"
            },
            %{
              "id" => "wrong_calendar_owner_status_must_not_match",
              "risk_types" => ["ground_station_reserved"],
              "station_id" => "equator_prime",
              "station_calendar_reserved_by" => "other_ops_team",
              "station_calendar_reservation_status" => "reserved",
              "classification" => "blocked_by_policy",
              "reason" => "wrong calendar owner must not match"
            },
            %{
              "id" => "wrong_calendar_owner_status_event_must_not_match",
              "event_types" => ["ground_station_reserved"],
              "station_id" => "equator_prime",
              "station_calendar_reserved_by" => "ops_team_b",
              "station_calendar_reservation_status" => "planned",
              "classification" => "operator_review_required",
              "reason" => "wrong event calendar status must not match"
            },
            %{
              "id" => "equator_reservation_risk_block",
              "risk_types" => ["ground_station_reserved"],
              "station_id" => "equator_prime",
              "station_calendar_entry_id" => "partner_reserved_window_1",
              "station_calendar_provider_id" => "partner_calendar",
              "station_calendar_status" => "reserved",
              "station_calendar_reservation_id" => "reservation_equator_prime_1",
              "station_calendar_reserved_by" => "ops_team_b",
              "station_calendar_reservation_status" => "reserved",
              "classification" => "blocked_by_policy",
              "reason" => "equator reservation risk blocks branch promotion"
            },
            %{
              "id" => "equator_reservation_event_review",
              "event_types" => ["ground_station_reserved"],
              "station_id" => "equator_prime",
              "station_calendar_entry_id" => "partner_reserved_window_1",
              "station_calendar_provider_id" => "partner_calendar",
              "station_calendar_reservation_id" => "reservation_equator_prime_1",
              "station_calendar_reserved_by" => "ops_team_b",
              "station_calendar_reservation_status" => "reserved",
              "station_calendar_status" => "reserved",
              "classification" => "operator_review_required",
              "reason" => "equator reservation event routes to review"
            }
          ]
        },
        branches: [
          %{id: "baseline"},
          %{
            id: "reserved",
            events: [
              %{
                type: "ground_station_reserved",
                station_id: "equator_prime",
                starts_at_s: 0.0,
                ends_at_s: 600.0,
                station_calendar_entry_id: "partner_reserved_window_1",
                station_calendar_provider_id: "partner_calendar",
                station_calendar_provider_entry_id: "partner_entry_1",
                station_calendar_directions: ["downlink"],
                station_calendar_status: "reserved",
                station_calendar_trust_boundary_status: "declared",
                reservation_id: "reservation_equator_prime_1",
                reserved_by: "ops_team_b",
                reservation_status: "reserved",
                station_reservation_match_status: "unmatched_overlap"
              }
            ]
          }
        ],
        current_epoch_s: 0.0
      )

    reserved = branch(artifact, "reserved")
    repair = reserved["repair_result"]

    assert %{
             "schema_contract" => "contact_filter_report.v1",
             "suppressed_candidate_count" => suppressed_count,
             "suppressed_candidates" => [
               %{
                 "suppressed_reason" => "ground_station_reserved",
                 "ground_station_id" => "equator_prime",
                 "station_reservation_id" => "reservation_equator_prime_1"
               }
               | _
             ]
           } = repair["source_contact_filter_report"]

    assert suppressed_count > 0

    assert Enum.any?(
             reserved["risk_indicators"],
             &(&1["type"] == "ground_station_reserved" and
                 &1["reason"] == "station equator_prime reserved during branch window" and
                 &1["ground_station_id"] == "equator_prime" and
                 &1["station_availability"] == "reserved" and
                 &1["station_contention_status"] == "reserved_overlap" and
                 &1["station_calendar_entry_id"] == "partner_reserved_window_1" and
                 &1["station_calendar_provider_id"] == "partner_calendar" and
                 &1["station_calendar_provider_entry_id"] == "partner_entry_1" and
                 &1["station_calendar_directions"] == ["downlink"] and
                 &1["station_calendar_status"] == "reserved" and
                 &1["station_calendar_trust_boundary_status"] == "declared" and
                 &1["station_reservation_id"] == "reservation_equator_prime_1" and
                 &1["station_reserved_by"] == "ops_team_b" and
                 &1["station_reservation_status"] == "reserved" and
                 &1["station_reservation_match_status"] == "unmatched_overlap")
           )

    assert Enum.any?(
             reserved["approval_rule_matches"],
             &(&1["rule_id"] == "equator_reservation_risk_block" and
                 &1["risk_type"] == "ground_station_reserved" and
                 &1["ground_station_id"] == "equator_prime" and
                 &1["station_calendar_entry_id"] == "partner_reserved_window_1" and
                 &1["station_calendar_provider_id"] == "partner_calendar" and
                 &1["station_calendar_status"] == "reserved" and
                 &1["station_calendar_reservation_id"] == "reservation_equator_prime_1" and
                 &1["station_calendar_reserved_by"] == "ops_team_b" and
                 &1["station_calendar_reservation_status"] == "reserved" and
                 &1["station_reservation_id"] == "reservation_equator_prime_1" and
                 &1["station_reserved_by"] == "ops_team_b")
           )

    refute Enum.any?(
             reserved["approval_rule_matches"],
             &(&1["rule_id"] == "wrong_calendar_entry_must_not_match")
           )

    refute Enum.any?(
             reserved["approval_rule_matches"],
             &(&1["rule_id"] == "wrong_calendar_reservation_must_not_match")
           )

    refute Enum.any?(
             reserved["approval_rule_matches"],
             &(&1["rule_id"] == "wrong_calendar_owner_status_must_not_match")
           )

    assert Enum.any?(
             reserved["approval_rule_matches"],
             &(&1["rule_id"] == "equator_reservation_event_review" and
                 &1["event_type"] == "ground_station_reserved" and
                 &1["ground_station_id"] == "equator_prime" and
                 &1["station_calendar_entry_id"] == "partner_reserved_window_1" and
                 &1["station_calendar_provider_id"] == "partner_calendar" and
                 &1["station_calendar_reservation_id"] == "reservation_equator_prime_1" and
                 &1["station_calendar_reserved_by"] == "ops_team_b" and
                 &1["station_calendar_reservation_status"] == "reserved" and
                 &1["station_calendar_status"] == "reserved")
           )

    refute Enum.any?(
             reserved["approval_rule_matches"],
             &(&1["rule_id"] == "wrong_calendar_entry_event_must_not_match")
           )

    refute Enum.any?(
             reserved["approval_rule_matches"],
             &(&1["rule_id"] == "wrong_calendar_reservation_event_must_not_match")
           )

    refute Enum.any?(
             reserved["approval_rule_matches"],
             &(&1["rule_id"] == "wrong_calendar_owner_status_event_must_not_match")
           )

    assert %{
             "branch_station_availabilities" => ["reserved"],
             "branch_station_calendar_entry_ids" => ["partner_reserved_window_1"],
             "branch_station_calendar_provider_ids" => ["partner_calendar"],
             "branch_station_calendar_provider_entry_ids" => ["partner_entry_1"],
             "branch_station_calendar_directions" => ["downlink"],
             "branch_station_calendar_statuses" => ["reserved"],
             "branch_station_calendar_trust_boundary_statuses" => ["declared"],
             "branch_station_reservation_ids" => ["reservation_equator_prime_1"],
             "branch_station_reserved_by" => ["ops_team_b"],
             "branch_station_reservation_statuses" => ["reserved"],
             "branch_station_reservation_match_statuses" => ["unmatched_overlap"]
           } =
             artifact["branch_comparison_report"]["rows"]
             |> Enum.find(&(&1["branch_id"] == "reserved"))

    refute Enum.any?(
             repair["source_candidate_activities"],
             &(&1["type"] == "downlink" and &1["ground_station_id"] == "equator_prime")
           )

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end
end
