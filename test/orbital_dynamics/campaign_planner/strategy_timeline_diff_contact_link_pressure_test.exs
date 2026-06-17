Code.require_file("support.exs", __DIR__)

defmodule OrbitalDynamics.CampaignPlanner.StrategyTimelineDiffContactLinkPressureTest do
  use ExUnit.Case, async: true

  import OrbitalDynamics.CampaignPlanner.TestSupport

  alias OrbitalDynamics.Schema

  test "strategy derives changed timeline diff contact feedback from failed contact rows" do
    prior_plan =
      base_plan(%{
        "source_timeline_diff_report" => %{
          "schema_contract" => "timeline_diff_report.v1",
          "model" => "timeline_identity_activity_diff",
          "source" => "repair.activities",
          "row_count" => 1,
          "changed_count" => 1,
          "provenance" => %{"trust_boundary" => "ops_timeline_review"},
          "rows" => [
            %{
              "id" => "timeline_diff:timeline:contact_changed",
              "rank" => 1,
              "timeline_id" => "timeline:contact_changed",
              "diff_status" => "changed",
              "changed_fields" => ["contact_result", "contact_success_factor"],
              "source_activity_id" => "contact_source",
              "replacement_activity_id" => "contact_changed",
              "source_activity_type" => "contact",
              "replacement_activity_type" => "contact",
              "source_direction" => "downlink",
              "replacement_direction" => "downlink",
              "source_ground_station_id" => "equator_prime",
              "replacement_ground_station_id" => "equator_prime",
              "scenario_id" => "leo_1",
              "source_status" => "planned",
              "contact_result" => "no-contact",
              "replacement_activity_context" => %{
                "starts_at_s" => 300.0,
                "ends_at_s" => 360.0,
                "realized_status" => "missed"
              },
              "required_operator_action" => "review_timeline_change"
            }
          ]
        }
      })

    artifact =
      strategy(prior_plan,
        mission_state: mission_state_with_refresh_inputs(),
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    branch = branch(artifact, "derived_timeline_diff_changed_contact_source")

    assert %{
             "type" => "contact_success_feedback",
             "scenario_id" => "leo_1",
             "ground_station_id" => "equator_prime",
             "starts_at_s" => 300.0,
             "ends_at_s" => 360.0,
             "contact_result" => "no-contact",
             "realized_status" => "missed",
             "source_activity_id" => "contact_source",
             "replacement_activity_id" => "contact_changed",
             "source_activity_ids" => ["contact_changed", "contact_source"],
             "timeline_id" => "timeline:contact_changed",
             "feedback_source" => "prior_plan.source_timeline_diff_report",
             "feedback_scope" => "timeline_diff",
             "feedback_key" => "equator_prime",
             "trust_boundary" => "ops_timeline_review",
             "derivation_reasons" => [
               "timeline_diff_changed_activity",
               "timeline_diff_changed_contact"
             ]
           } = List.first(branch["events"])

    assert List.first(branch["events"])["contact_success_factor"] == 0.0
    assert branch["feedback_adjustments"]["contact_success_factor"] == 0.0

    downlink =
      branch
      |> get_in(["repair_result", "source_candidate_activities"])
      |> Enum.find(&(&1["type"] == "downlink" and &1["ground_station_id"] == "equator_prime"))

    assert get_in(downlink, ["throughput_model", "contact_success_factor"]) == 0.0

    assert Enum.any?(
             branch["risk_indicators"],
             &(&1["type"] == "contact_success_rate_low" and &1["value"] == 0.0 and
                 &1["contact_result"] == "no-contact" and &1["realized_status"] == "missed" and
                 &1["source_activity_ids"] == ["contact_changed", "contact_source"])
           )

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy derives changed timeline diff contact feedback from failed tracking rows" do
    prior_plan =
      base_plan(%{
        "source_timeline_diff_report" => %{
          "schema_contract" => "timeline_diff_report.v1",
          "model" => "timeline_identity_activity_diff",
          "source" => "repair.activities",
          "row_count" => 1,
          "changed_count" => 1,
          "provenance" => %{"trust_boundary" => "ops_tracking_review"},
          "rows" => [
            %{
              "id" => "timeline_diff:timeline:tracking_changed",
              "rank" => 1,
              "timeline_id" => "timeline:tracking_changed",
              "diff_status" => "changed",
              "changed_fields" => ["contact_result", "contact_success_factor"],
              "source_activity_id" => "tracking_source",
              "replacement_activity_id" => "tracking_changed",
              "source_activity_type" => "tracking",
              "replacement_activity_type" => "tracking",
              "source_ground_station_id" => "equator_prime",
              "replacement_ground_station_id" => "equator_prime",
              "scenario_id" => "leo_1",
              "source_status" => "planned",
              "contact_result" => "no-contact",
              "replacement_activity_context" => %{
                "starts_at_s" => 300.0,
                "ends_at_s" => 360.0,
                "realized_status" => "missed"
              },
              "required_operator_action" => "review_timeline_change"
            }
          ]
        }
      })

    artifact =
      strategy(prior_plan,
        mission_state: mission_state_with_refresh_inputs(),
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    branch = branch(artifact, "derived_timeline_diff_changed_tracking_source")

    assert %{
             "type" => "contact_success_feedback",
             "scenario_id" => "leo_1",
             "ground_station_id" => "equator_prime",
             "starts_at_s" => 300.0,
             "ends_at_s" => 360.0,
             "contact_result" => "no-contact",
             "realized_status" => "missed",
             "source_activity_id" => "tracking_source",
             "replacement_activity_id" => "tracking_changed",
             "feedback_source" => "prior_plan.source_timeline_diff_report",
             "feedback_scope" => "timeline_diff",
             "feedback_key" => "equator_prime",
             "trust_boundary" => "ops_tracking_review",
             "derivation_reasons" => [
               "timeline_diff_changed_activity",
               "timeline_diff_changed_contact"
             ]
           } = List.first(branch["events"])

    assert List.first(branch["events"])["contact_success_factor"] == 0.0
    assert branch["feedback_adjustments"]["contact_success_factor"] == 0.0

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy ignores successful changed timeline diff contact rows" do
    prior_plan =
      base_plan(%{
        "source_timeline_diff_report" => %{
          "schema_contract" => "timeline_diff_report.v1",
          "model" => "timeline_identity_activity_diff",
          "source" => "repair.activities",
          "row_count" => 1,
          "changed_count" => 1,
          "provenance" => %{"trust_boundary" => "ops_timeline_review"},
          "rows" => [
            %{
              "id" => "timeline_diff:timeline:contact_success",
              "rank" => 1,
              "timeline_id" => "timeline:contact_success",
              "diff_status" => "changed",
              "changed_fields" => ["contact_result"],
              "source_activity_id" => "contact_success_source",
              "replacement_activity_id" => "contact_success",
              "source_activity_type" => "contact",
              "replacement_activity_type" => "contact",
              "source_direction" => "downlink",
              "replacement_direction" => "downlink",
              "source_ground_station_id" => "equator_prime",
              "replacement_ground_station_id" => "equator_prime",
              "scenario_id" => "leo_1",
              "source_status" => "planned",
              "replacement_activity_context" => %{"contact_result" => "accepted, delivered"},
              "required_operator_action" => "review_timeline_change"
            }
          ]
        }
      })

    artifact =
      strategy(prior_plan,
        mission_state: mission_state_with_refresh_inputs(),
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    refute branch(artifact, "derived_timeline_diff_changed_contact_success_source")

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy derives changed timeline diff contact identity mismatch feedback" do
    prior_plan =
      base_plan(%{
        "source_timeline_diff_report" => %{
          "schema_contract" => "timeline_diff_report.v1",
          "model" => "timeline_identity_activity_diff",
          "source" => "repair.activities",
          "row_count" => 1,
          "changed_count" => 1,
          "provenance" => %{"trust_boundary" => "ops_contact_identity_review"},
          "rows" => [
            %{
              "id" => "timeline_diff:timeline:contact_route_changed",
              "rank" => 1,
              "timeline_id" => "timeline:contact_route_changed",
              "diff_status" => "changed",
              "changed_fields" => [
                "direction",
                "ground_station_id",
                "source_window_id"
              ],
              "source_activity_id" => "contact_route_source",
              "replacement_activity_id" => "contact_route_replacement",
              "source_activity_type" => "contact",
              "replacement_activity_type" => "contact",
              "source_direction" => "downlink",
              "replacement_direction" => "tracking",
              "source_ground_station_id" => "polar_prime",
              "replacement_ground_station_id" => "equator_prime",
              "source_source_window_id" => "window_polar_prime",
              "replacement_source_window_id" => "window_equator_prime",
              "scenario_id" => "leo_1",
              "source_status" => "planned",
              "replacement_activity_context" => %{
                "starts_at_s" => 300.0,
                "ends_at_s" => 360.0,
                "contact_result" => "accepted, delivered",
                "realized_status" => "completed"
              },
              "required_operator_action" => "review_timeline_change"
            }
          ]
        }
      })

    artifact =
      strategy(prior_plan,
        mission_state: mission_state_with_refresh_inputs(),
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    branch = branch(artifact, "derived_timeline_diff_changed_contact_route_source")
    event = List.first(branch["events"])

    assert %{
             "type" => "contact_success_feedback",
             "scenario_id" => "leo_1",
             "ground_station_id" => "equator_prime",
             "planned_ground_station_id" => "polar_prime",
             "realized_ground_station_id" => "equator_prime",
             "ground_station_match_status" => "mismatch",
             "direction" => "tracking",
             "planned_direction" => "downlink",
             "realized_direction" => "tracking",
             "direction_match_status" => "mismatch",
             "source_window_id" => "window_equator_prime",
             "planned_source_window_id" => "window_polar_prime",
             "realized_source_window_id" => "window_equator_prime",
             "source_window_match_status" => "mismatch",
             "contact_identity_mismatch_fields" => [
               "direction",
               "ground_station",
               "source_window"
             ],
             "starts_at_s" => 300.0,
             "ends_at_s" => 360.0,
             "contact_result" => "accepted, delivered",
             "realized_status" => "completed",
             "source_activity_id" => "contact_route_source",
             "replacement_activity_id" => "contact_route_replacement",
             "source_activity_ids" => ["contact_route_replacement", "contact_route_source"],
             "timeline_id" => "timeline:contact_route_changed",
             "feedback_source" => "prior_plan.source_timeline_diff_report",
             "feedback_scope" => "timeline_diff",
             "feedback_key" => "equator_prime",
             "trust_boundary" => "ops_contact_identity_review",
             "derivation_reasons" => [
               "timeline_diff_changed_activity",
               "timeline_diff_changed_contact_identity",
               "direction_mismatch",
               "ground_station_mismatch",
               "source_window_mismatch"
             ]
           } = event

    assert event["contact_success_factor"] == 0.0
    assert branch["feedback_adjustments"]["contact_success_factor"] == 0.0

    assert Enum.any?(
             branch["risk_indicators"],
             &(&1["type"] == "contact_success_rate_low" and &1["value"] == 0.0)
           )

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy derives changed timeline diff link quality feedback from degraded contact rows" do
    prior_plan =
      base_plan(%{
        "source_timeline_diff_report" => %{
          "schema_contract" => "timeline_diff_report.v1",
          "model" => "timeline_identity_activity_diff",
          "source" => "repair.activities",
          "row_count" => 1,
          "changed_count" => 1,
          "provenance" => %{"trust_boundary" => "ops_link_quality_review"},
          "rows" => [
            %{
              "id" => "timeline_diff:timeline:contact_link_quality",
              "rank" => 1,
              "timeline_id" => "timeline:contact_link_quality",
              "diff_status" => "changed",
              "changed_fields" => [
                "realized_carrier_lock",
                "realized_link_margin_db",
                "realized_link_quality_status"
              ],
              "source_activity_id" => "contact_link_quality_source",
              "replacement_activity_id" => "contact_link_quality_replacement",
              "source_activity_type" => "contact",
              "replacement_activity_type" => "contact",
              "source_direction" => "downlink",
              "replacement_direction" => "downlink",
              "source_ground_station_id" => "equator_prime",
              "replacement_ground_station_id" => "equator_prime",
              "scenario_id" => "leo_1",
              "source_status" => "planned",
              "replacement_activity_context" => %{
                "starts_at_s" => 520.0,
                "ends_at_s" => 580.0,
                "contact_result" => "accepted, delivered",
                "realized_status" => "completed",
                "realized_carrier_lock" => false,
                "realized_symbol_lock" => false,
                "realized_link_margin_db" => -1.5,
                "snr_db" => 2.1,
                "eb_no_db" => 1.3,
                "packet_loss_rate" => 0.12,
                "frame_loss_rate" => 0.08,
                "realized_link_quality_status" => "lost lock"
              },
              "required_operator_action" => "review_timeline_change"
            }
          ]
        }
      })

    artifact =
      strategy(prior_plan,
        mission_state: mission_state_with_refresh_inputs(),
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    branch = branch(artifact, "derived_timeline_diff_changed_contact_link_quality_source")

    assert %{
             "type" => "contact_success_feedback",
             "scenario_id" => "leo_1",
             "ground_station_id" => "equator_prime",
             "starts_at_s" => 520.0,
             "ends_at_s" => 580.0,
             "contact_result" => "accepted, delivered",
             "realized_status" => "completed",
             "link_margin_db" => -1.5,
             "snr_db" => 2.1,
             "eb_no_db" => 1.3,
             "packet_loss_rate" => 0.12,
             "frame_loss_rate" => 0.08,
             "carrier_lock" => false,
             "symbol_lock" => false,
             "link_quality_status" => "lost_lock",
             "source_activity_id" => "contact_link_quality_source",
             "replacement_activity_id" => "contact_link_quality_replacement",
             "source_activity_ids" => [
               "contact_link_quality_replacement",
               "contact_link_quality_source"
             ],
             "timeline_id" => "timeline:contact_link_quality",
             "feedback_source" => "prior_plan.source_timeline_diff_report",
             "feedback_scope" => "timeline_diff",
             "feedback_key" => "equator_prime",
             "trust_boundary" => "ops_link_quality_review",
             "derivation_reasons" => [
               "timeline_diff_changed_activity",
               "timeline_diff_changed_link_quality",
               "carrier_lock_lost",
               "symbol_lock_lost",
               "negative_link_margin",
               "link_quality_status_lost_lock"
             ]
           } = List.first(branch["events"])

    assert List.first(branch["events"])["contact_success_factor"] == 0.0
    assert branch["feedback_adjustments"]["contact_success_factor"] == 0.0

    assert Enum.any?(
             branch["risk_indicators"],
             &(&1["type"] == "contact_success_rate_low" and &1["value"] == 0.0 and
                 &1["link_margin_db"] == -1.5 and &1["carrier_lock"] == false and
                 &1["symbol_lock"] == false and &1["link_quality_status"] == "lost_lock")
           )

    downlink =
      branch
      |> get_in(["repair_result", "source_candidate_activities"])
      |> Enum.find(&(&1["type"] == "downlink" and &1["ground_station_id"] == "equator_prime"))

    assert get_in(downlink, ["throughput_model", "contact_success_factor"]) == 0.0

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy derives changed timeline diff link profile mismatch feedback" do
    prior_plan =
      base_plan(%{
        "source_timeline_diff_report" => %{
          "schema_contract" => "timeline_diff_report.v1",
          "model" => "timeline_identity_activity_diff",
          "source" => "repair.activities",
          "row_count" => 1,
          "changed_count" => 1,
          "provenance" => %{"trust_boundary" => "ops_link_profile_review"},
          "rows" => [
            %{
              "id" => "timeline_diff:timeline:contact_link_profile",
              "rank" => 1,
              "timeline_id" => "timeline:contact_link_profile",
              "diff_status" => "changed",
              "changed_fields" => [
                "frequency_band",
                "coding_scheme",
                "polarization",
                "actual_data_rate_mb_s"
              ],
              "source_activity_id" => "contact_link_profile_source",
              "replacement_activity_id" => "contact_link_profile_replacement",
              "source_activity_type" => "contact",
              "replacement_activity_type" => "contact",
              "source_direction" => "downlink",
              "replacement_direction" => "downlink",
              "source_ground_station_id" => "equator_prime",
              "replacement_ground_station_id" => "equator_prime",
              "scenario_id" => "leo_1",
              "source_status" => "planned",
              "source_activity_context" => %{
                "starts_at_s" => 520.0,
                "ends_at_s" => 580.0,
                "link_protocol" => "space_packet",
                "frequency_band" => "x_band",
                "modulation" => "qpsk",
                "coding_scheme" => "ldpc",
                "polarization" => "rhcp",
                "data_rate_mbps" => 8.0
              },
              "replacement_activity_context" => %{
                "starts_at_s" => 520.0,
                "ends_at_s" => 580.0,
                "contact_result" => "accepted, delivered",
                "realized_status" => "completed",
                "carrier_lock" => true,
                "symbol_lock" => true,
                "link_margin_db" => 4.0,
                "link_quality_status" => "nominal",
                "link_protocol" => "space_packet",
                "frequency_band" => "s_band",
                "modulation" => "qpsk",
                "coding_scheme" => "convolutional",
                "polarization" => "lhcp",
                "actual_data_rate_mb_s" => 0.5
              },
              "required_operator_action" => "review_timeline_change"
            }
          ]
        }
      })

    artifact =
      strategy(prior_plan,
        mission_state: mission_state_with_refresh_inputs(),
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    branch = branch(artifact, "derived_timeline_diff_changed_contact_link_profile_source")
    event = List.first(branch["events"])

    assert %{
             "type" => "contact_success_feedback",
             "scenario_id" => "leo_1",
             "ground_station_id" => "equator_prime",
             "starts_at_s" => 520.0,
             "ends_at_s" => 580.0,
             "contact_result" => "accepted, delivered",
             "realized_status" => "completed",
             "carrier_lock" => true,
             "symbol_lock" => true,
             "link_quality_status" => "nominal",
             "planned_link_protocol" => "space_packet",
             "realized_link_protocol" => "space_packet",
             "link_protocol_match_status" => "matched",
             "planned_frequency_band" => "x_band",
             "realized_frequency_band" => "s_band",
             "frequency_band_match_status" => "mismatch",
             "planned_coding_scheme" => "ldpc",
             "realized_coding_scheme" => "convolutional",
             "coding_scheme_match_status" => "mismatch",
             "planned_polarization" => "rhcp",
             "realized_polarization" => "lhcp",
             "polarization_match_status" => "mismatch",
             "planned_data_rate_mbps" => 8.0,
             "realized_data_rate_mbps" => 4.0,
             "data_rate_delta_mbps" => -4.0,
             "data_rate_match_status" => "mismatch",
             "source_activity_id" => "contact_link_profile_source",
             "replacement_activity_id" => "contact_link_profile_replacement",
             "timeline_id" => "timeline:contact_link_profile",
             "feedback_source" => "prior_plan.source_timeline_diff_report",
             "feedback_scope" => "timeline_diff",
             "feedback_key" => "equator_prime",
             "trust_boundary" => "ops_link_profile_review"
           } = event

    assert event["contact_success_factor"] == 0.0

    assert event["link_profile_mismatch_fields"] == [
             "frequency_band",
             "coding_scheme",
             "polarization",
             "data_rate"
           ]

    assert "link_profile_mismatch" in event["derivation_reasons"]
    assert "frequency_band_mismatch" in event["derivation_reasons"]
    assert "coding_scheme_mismatch" in event["derivation_reasons"]
    assert "polarization_mismatch" in event["derivation_reasons"]
    assert "data_rate_mismatch" in event["derivation_reasons"]

    assert branch["feedback_adjustments"]["contact_success_factor"] == 0.0

    assert Enum.any?(
             branch["risk_indicators"],
             &(&1["type"] == "contact_success_rate_low" and &1["value"] == 0.0)
           )

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy ignores healthy changed timeline diff link quality rows" do
    prior_plan =
      base_plan(%{
        "source_timeline_diff_report" => %{
          "schema_contract" => "timeline_diff_report.v1",
          "model" => "timeline_identity_activity_diff",
          "source" => "repair.activities",
          "row_count" => 1,
          "changed_count" => 1,
          "provenance" => %{"trust_boundary" => "ops_link_quality_review"},
          "rows" => [
            %{
              "id" => "timeline_diff:timeline:healthy_link_quality",
              "rank" => 1,
              "timeline_id" => "timeline:healthy_link_quality",
              "diff_status" => "changed",
              "changed_fields" => ["realized_link_quality_status"],
              "source_activity_id" => "healthy_link_quality_source",
              "replacement_activity_id" => "healthy_link_quality_replacement",
              "source_activity_type" => "contact",
              "replacement_activity_type" => "contact",
              "source_direction" => "downlink",
              "replacement_direction" => "downlink",
              "source_ground_station_id" => "equator_prime",
              "replacement_ground_station_id" => "equator_prime",
              "scenario_id" => "leo_1",
              "source_activity_context" => %{
                "link_protocol" => "space_packet",
                "frequency_band" => "x_band",
                "modulation" => "qpsk",
                "coding_scheme" => "ldpc",
                "polarization" => "rhcp",
                "data_rate_mbps" => 8.0
              },
              "replacement_activity_context" => %{
                "carrier_lock" => true,
                "symbol_lock" => true,
                "link_margin_db" => 3.4,
                "link_quality_status" => "nominal",
                "link_protocol" => "space_packet",
                "frequency_band" => "x_band",
                "modulation" => "qpsk",
                "coding_scheme" => "ldpc",
                "polarization" => "rhcp",
                "actual_data_rate_mbps" => 8.0
              },
              "required_operator_action" => "review_timeline_change"
            }
          ]
        }
      })

    artifact =
      strategy(prior_plan,
        mission_state: mission_state_with_refresh_inputs(),
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    refute branch(artifact, "derived_timeline_diff_changed_healthy_link_quality_source")

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy derives changed timeline diff downlink station throughput feedback from degraded throughput rows" do
    prior_plan =
      base_plan(%{
        "source_timeline_diff_report" => %{
          "schema_contract" => "timeline_diff_report.v1",
          "model" => "timeline_identity_activity_diff",
          "source" => "repair.activities",
          "row_count" => 1,
          "changed_count" => 1,
          "provenance" => %{"trust_boundary" => "ops_timeline_review"},
          "rows" => [
            %{
              "id" => "timeline_diff:timeline:dl_throughput",
              "rank" => 1,
              "timeline_id" => "timeline:dl_throughput",
              "diff_status" => "changed",
              "changed_fields" => ["actual_throughput_mb", "estimated_throughput_mb"],
              "source_activity_id" => "dl_throughput_source",
              "replacement_activity_id" => "dl_throughput_replacement",
              "source_activity_type" => "downlink",
              "replacement_activity_type" => "downlink",
              "source_ground_station_id" => "equator_prime",
              "replacement_ground_station_id" => "equator_prime",
              "scenario_id" => "leo_1",
              "source_status" => "planned",
              "replacement_activity_context" => %{
                "starts_at_s" => 300.0,
                "ends_at_s" => 360.0,
                "actual_throughput_mb" => 45.0,
                "estimated_throughput_mb" => 100.0
              },
              "required_operator_action" => "review_timeline_change"
            }
          ]
        }
      })

    artifact =
      strategy(prior_plan,
        mission_state: mission_state_with_refresh_inputs(),
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    branch = branch(artifact, "derived_timeline_diff_changed_dl_throughput_source")

    assert %{
             "type" => "station_throughput_feedback",
             "scenario_id" => "leo_1",
             "ground_station_id" => "equator_prime",
             "starts_at_s" => 300.0,
             "ends_at_s" => 360.0,
             "station_throughput_factor" => 0.45,
             "actual_throughput_mb" => 45.0,
             "estimated_throughput_mb" => 100.0,
             "source_activity_id" => "dl_throughput_source",
             "replacement_activity_id" => "dl_throughput_replacement",
             "source_activity_ids" => ["dl_throughput_replacement", "dl_throughput_source"],
             "timeline_id" => "timeline:dl_throughput",
             "feedback_source" => "prior_plan.source_timeline_diff_report",
             "feedback_scope" => "timeline_diff",
             "feedback_key" => "equator_prime",
             "trust_boundary" => "ops_timeline_review",
             "derivation_reasons" => [
               "timeline_diff_changed_activity",
               "timeline_diff_changed_station_throughput"
             ]
           } = List.first(branch["events"])

    assert branch["feedback_adjustments"]["station_throughput_factor"] == 0.45

    assert Enum.any?(
             branch["risk_indicators"],
             &(&1["type"] == "station_throughput_factor_low" and &1["value"] == 0.45 and
                 &1["ground_station_id"] == "equator_prime")
           )

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy derives changed timeline diff contact station throughput feedback from explicit degraded factors" do
    prior_plan =
      base_plan(%{
        "source_timeline_diff_report" => %{
          "schema_contract" => "timeline_diff_report.v1",
          "model" => "timeline_identity_activity_diff",
          "source" => "repair.activities",
          "row_count" => 1,
          "changed_count" => 1,
          "provenance" => %{"trust_boundary" => "ops_contact_review"},
          "rows" => [
            %{
              "id" => "timeline_diff:timeline:contact_throughput",
              "rank" => 1,
              "timeline_id" => "timeline:contact_throughput",
              "diff_status" => "changed",
              "changed_fields" => ["station_throughput_factor"],
              "source_activity_id" => "contact_throughput_source",
              "replacement_activity_id" => "contact_throughput_replacement",
              "source_activity_type" => "contact",
              "replacement_activity_type" => "contact",
              "source_direction" => "downlink",
              "replacement_direction" => "downlink",
              "source_ground_station_id" => "equator_prime",
              "replacement_ground_station_id" => "equator_prime",
              "scenario_id" => "leo_1",
              "source_status" => "planned",
              "replacement_activity_context" => %{
                "starts_at_s" => 420.0,
                "ends_at_s" => 480.0,
                "contact_result" => "accepted, delivered",
                "station_throughput_factor" => 0.5
              },
              "required_operator_action" => "review_timeline_change"
            }
          ]
        }
      })

    artifact =
      strategy(prior_plan,
        mission_state: mission_state_with_refresh_inputs(),
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    branch = branch(artifact, "derived_timeline_diff_changed_contact_throughput_source")

    assert %{
             "type" => "station_throughput_feedback",
             "ground_station_id" => "equator_prime",
             "station_throughput_factor" => 0.5,
             "source_activity_id" => "contact_throughput_source",
             "replacement_activity_id" => "contact_throughput_replacement",
             "feedback_source" => "prior_plan.source_timeline_diff_report",
             "feedback_scope" => "timeline_diff",
             "feedback_key" => "equator_prime",
             "trust_boundary" => "ops_contact_review",
             "derivation_reasons" => [
               "timeline_diff_changed_activity",
               "timeline_diff_changed_station_throughput"
             ]
           } = List.first(branch["events"])

    assert branch["feedback_adjustments"]["station_throughput_factor"] == 0.5

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy ignores healthy changed timeline diff station throughput rows" do
    prior_plan =
      base_plan(%{
        "source_timeline_diff_report" => %{
          "schema_contract" => "timeline_diff_report.v1",
          "model" => "timeline_identity_activity_diff",
          "source" => "repair.activities",
          "row_count" => 1,
          "changed_count" => 1,
          "provenance" => %{"trust_boundary" => "ops_timeline_review"},
          "rows" => [
            %{
              "id" => "timeline_diff:timeline:healthy_throughput",
              "rank" => 1,
              "timeline_id" => "timeline:healthy_throughput",
              "diff_status" => "changed",
              "changed_fields" => ["station_throughput_factor"],
              "source_activity_id" => "healthy_throughput_source",
              "replacement_activity_id" => "healthy_throughput_replacement",
              "source_activity_type" => "contact",
              "replacement_activity_type" => "contact",
              "source_direction" => "downlink",
              "replacement_direction" => "downlink",
              "source_ground_station_id" => "equator_prime",
              "replacement_ground_station_id" => "equator_prime",
              "scenario_id" => "leo_1",
              "replacement_activity_context" => %{"station_throughput_factor" => 0.95},
              "required_operator_action" => "review_timeline_change"
            }
          ]
        }
      })

    artifact =
      strategy(prior_plan,
        mission_state: mission_state_with_refresh_inputs(),
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    refute branch(artifact, "derived_timeline_diff_changed_healthy_throughput_source")

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end
end
