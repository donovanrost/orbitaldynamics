Code.require_file("support.exs", __DIR__)

Code.require_file(
  "../../support/campaign_planner/contact_allocation_pressure_fixtures.ex",
  __DIR__
)

defmodule OrbitalDynamics.CampaignPlanner.StrategyContactAllocationPressureTest do
  use ExUnit.Case, async: true

  import OrbitalDynamics.CampaignPlanner.TestSupport
  import OrbitalDynamics.CampaignPlanner.ContactAllocationPressureFixtures

  alias OrbitalDynamics.{CadenceImport, Schema}
  alias OrbitalDynamics.Communications.ContactAllocation

  test "strategy replays allocation-embedded provider calendar contention from Cadence import rows" do
    {_allocated, allocation_report} =
      ContactAllocation.allocate_contacts(
        [
          downlink("dl_provider_contention", 100.0, 160.0)
        ],
        %{
          schema_contract: "station_calendar_provider.v1",
          provider_id: "ground_partner_a",
          trust_boundary: "ground_partner_api",
          entries: [
            %{
              id: "partner_outage",
              ground_station_id: :equator_prime,
              directions: [:downlink],
              status: :unavailable,
              starts_at_s: 90.0,
              ends_at_s: 170.0
            },
            %{
              id: "partner_reservation",
              ground_station_id: :equator_prime,
              directions: [:downlink],
              status: :reserved,
              reservation_id: :reservation_partner,
              reserved_by: :partner_team,
              starts_at_s: 120.0,
              ends_at_s: 180.0
            }
          ]
        },
        source: "strategy.provider_contention"
      )

    import_manifest = CadenceImport.from_contact_allocation_report(allocation_report)

    assert %{
             "source_review_type" => "station_calendar_review",
             "source_review_action" => "review_station_provider_contention",
             "source_station_calendar_provider_contention" => %{
               "id" => "station_calendar_provider_contention:equator_prime:1",
               "entry_ids" => ["partner_outage", "partner_reservation"]
             }
           } =
             Enum.find(
               import_manifest["rows"],
               &(&1["source_review_type"] == "station_calendar_review" and
                   &1["source_review_action"] == "review_station_provider_contention")
             )

    prior_plan =
      base_plan(%{
        "cadence_import_manifest" => import_manifest
      })

    artifact =
      strategy(prior_plan,
        mission_state: mission_state_with_refresh_inputs(),
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    provider_contention_branch =
      branch(
        artifact,
        "derived_station_calendar_provider_contention_station_calendar_provider_contention:equator_prime:1"
      )

    assert %{"type" => "candidate_refresh.v1", "scope" => "branch_generated"} =
             provider_contention_branch["assumptions"]["candidate_source"]

    assert [
             %{
               "type" => "ground_station_outage",
               "ground_station_id" => "equator_prime",
               "starts_at_s" => 120.0,
               "ends_at_s" => 170.0,
               "station_calendar_entry_id" => "partner_outage",
               "station_calendar_provider_id" => "ground_partner_a",
               "provider_calendar_contention_group_id" =>
                 "station_calendar_provider_contention:equator_prime:1",
               "provider_calendar_contention_entry_ids" => [
                 "partner_outage",
                 "partner_reservation"
               ],
               "feedback_source" =>
                 "prior_plan.cadence_import_manifest.rows.source_review_row.source_station_calendar_provider_contention",
               "feedback_scope" => "station_calendar",
               "trust_boundary" => "ground_partner_api"
             },
             %{
               "type" => "ground_station_reserved",
               "station_calendar_entry_id" => "partner_reservation",
               "station_reservation_id" => "reservation_partner",
               "station_reserved_by" => "partner_team"
             }
           ] = provider_contention_branch["events"]

    assert get_in(provider_contention_branch, ["provenance", "branch_metadata", "derived_source"]) ==
             "prior_plan.cadence_import_manifest.rows.source_review_row.source_station_calendar_provider_contention"

    assert {:ok, %{"schema_contract" => "contact_allocation_report.v1", "status" => "pass"}} =
             Schema.validate_artifact(allocation_report)

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1", "status" => "pass"}} =
             Schema.validate_artifact(import_manifest)

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy derives branch refresh from prior contact allocation pressure" do
    prior_plan =
      base_plan(%{
        "source_contact_allocation_report" => %{
          "schema_contract" => "contact_allocation_report.v1",
          "model" => "deterministic_station_contact_allocation",
          "source" => "campaign_repair.activities",
          "provenance" => %{"trust_boundary" => "ops_contact_allocation_report"},
          "input_contact_count" => 3,
          "allocated_contact_count" => 1,
          "deferred_contact_count" => 1,
          "blocked_contact_count" => 0,
          "policy_blocked_allocated_contact_count" => 1,
          "rows" => [
            %{
              "id" => "contact_allocation:dl_selected",
              "contact_id" => "dl_selected",
              "allocation_status" => "allocated",
              "effective_allocation_status" => "allocated",
              "allocation_reason" => "selected_by_contention_resolution",
              "type" => "downlink",
              "scenario_id" => "leo_1",
              "spacecraft_id" => "leo_1",
              "ground_station_id" => "equator_prime",
              "direction" => "downlink",
              "starts_at_s" => 500.0,
              "ends_at_s" => 560.0,
              "selected" => true
            },
            %{
              "id" => "contact_allocation:dl_deferred",
              "contact_id" => "dl_deferred",
              "allocation_status" => "Deferred",
              "effective_allocation_status" => "Deferred",
              "allocation_reason" => "same_station_contention",
              "type" => "downlink",
              "scenario_id" => "leo_1",
              "spacecraft_id" => "leo_1",
              "ground_station_id" => "equator_prime",
              "direction" => "downlink",
              "starts_at_s" => 520.0,
              "ends_at_s" => 580.0,
              "selected" => false,
              "contention_group_id" => "station:equator_prime:contention:1",
              "selected_contact_id" => "dl_selected",
              "capacity_pack_group_id" => "station:equator_prime:contention:1",
              "capacity_pack_status" => "deferred_by_reduced_station_capacity_pack",
              "capacity_pack_capacity_fraction" => 0.5,
              "capacity_pack_used_fraction" => 0.5,
              "downlink_completion_source" =>
                "contact_allocation.source_contact.required_downlink_mb:dl_deferred",
              "downlink_completion_sources" => [
                "contact_allocation.source_contact.required_downlink_mb:dl_deferred",
                "contact_allocation.throughput_model.required_downlink_mb"
              ],
              "downlink_demand_sources" => [
                "contact_allocation.required_downlink:dl_deferred"
              ],
              "trust_boundary" => "ops_contact_allocation",
              "source_contention_recommendation" => %{
                "group_id" => "station:equator_prime:contention:1",
                "selected_contact_id" => "dl_selected",
                "deferred_contact_ids" => ["dl_deferred"],
                "source_contact_candidates" => [
                  downlink("dl_selected", 500.0, 560.0)
                  |> Map.put("estimated_throughput_mb", 40.0),
                  downlink("dl_deferred", 520.0, 580.0)
                  |> Map.put("estimated_throughput_mb", 42.0)
                  |> Map.put(
                    "source_window_id",
                    "window:leo_1:ground_station_access:equator_prime:deferred"
                  )
                ]
              }
            },
            %{
              "id" => "contact_allocation:dl_policy_blocked",
              "contact_id" => "dl_policy_blocked",
              "allocation_status" => "allocated",
              "effective_allocation_status" => "Policy Blocked",
              "allocation_reason" => "selected_by_contention_resolution",
              "review_status" => "Operator Review Required",
              "approval_status" => "Blocked By Policy",
              "policy_decision" => %{
                "schema_contract" => "policy_decision.v1",
                "classification" => "Blocked By Policy",
                "policy_bundle_id" => "ground_network_allocation_v1"
              },
              "type" => "downlink",
              "scenario_id" => "leo_1",
              "spacecraft_id" => "leo_1",
              "ground_station_id" => "equator_prime",
              "direction" => "downlink",
              "starts_at_s" => 600.0,
              "ends_at_s" => 660.0,
              "selected" => true,
              "trust_boundary" => "ops_contact_allocation",
              "source_contact_candidate" =>
                downlink("dl_policy_blocked", 600.0, 660.0)
                |> Map.put("estimated_throughput_mb", 55.0)
                |> Map.put(
                  "source_window_id",
                  "window:leo_1:ground_station_access:equator_prime:policy_blocked"
                )
            },
            %{
              "id" => "contact_allocation:dl_nested_station_deferred",
              "contact_id" => "dl_nested_station_deferred",
              "allocation_status" => "Deferred",
              "allocation_reason" => "same_station_contention",
              "type" => "contact",
              "scenario_id" => "leo_1",
              "spacecraft_id" => "leo_1",
              "station" => %{"id" => "polar_nested"},
              "direction" => "downlink",
              "start_s" => "700.0",
              "end_s" => "760.0",
              "selected" => false,
              "trust_boundary" => "ops_contact_allocation",
              "throughput_model" => %{"required_downlink_mb" => "44.0"}
            },
            %{
              "id" => "contact_allocation:dl_source_contact_alias",
              "contact_id" => "dl_source_contact_alias",
              "allocation_status" => "Deferred",
              "allocation_reason" => "same_station_contention",
              "scenario_id" => "leo_1",
              "spacecraft_id" => "leo_1",
              "trust_boundary" => "ops_contact_allocation",
              "source_contact" => %{
                "id" => "dl_source_contact_alias",
                "type" => "downlink",
                "station" => %{"id" => "alias_station"},
                "start_s" => "820.0",
                "end_s" => "880.0",
                "throughput_model" => %{"required_downlink_mb" => "33.0"},
                "source_window" => %{
                  "id" => "window:leo_1:ground_station_access:alias_station:deferred"
                },
                "activity_context" => %{
                  "downlink_demand_source" =>
                    "contact_allocation.source_contact.required_downlink_mb:dl_source_contact_alias"
                }
              }
            },
            %{
              "id" => "contact_allocation:dl_report_reserved",
              "contact_id" => "dl_report_reserved",
              "allocation_status" => "Blocked",
              "allocation_reason" => "station_reserved",
              "type" => "downlink",
              "scenario_id" => "leo_1",
              "spacecraft_id" => "leo_1",
              "ground_station_id" => "equator_prime",
              "direction" => "downlink",
              "starts_at_s" => 900.0,
              "ends_at_s" => 960.0,
              "required_downlink_mb" => 28.0,
              "station_calendar_entry_id" => "partner_reservation",
              "station_calendar_entry_status" => "reserved",
              "station_reservation_id" => "reservation_partner",
              "station_reserved_by" => "partner_team",
              "station_reservation_status" => "confirmed",
              "station_reservation_match_status" => "unmatched_overlap"
            }
          ]
        }
      })

    artifact =
      strategy(prior_plan,
        mission_state: mission_state_with_refresh_inputs(),
        derive_branches?: true,
        approval_policy: %{
          "action_rules" => [
            %{
              "id" => "policy_blocked_contact_allocation_pressure",
              "event_types" => ["downlink_completion_gap"],
              "approval_statuses" => ["blocked_by_policy"],
              "classification" => "blocked_by_policy",
              "reason" => "policy-blocked contact allocation pressure cannot be promoted"
            }
          ]
        },
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    pressure_branch = branch(artifact, "derived_contact_allocation_pressure_deferred_dl_deferred")

    assert %{"type" => "candidate_refresh.v1", "scope" => "branch_generated"} =
             pressure_branch["assumptions"]["candidate_source"]

    assert %{
             "type" => "downlink_completion_gap",
             "ground_station_id" => "equator_prime",
             "source_activity_id" => "dl_deferred",
             "required_contacts" => 1,
             "planned_contacts" => 0,
             "required_downlink_mb" => 42.0,
             "allocation_status" => "deferred",
             "effective_allocation_status" => "deferred",
             "allocation_reason" => "same_station_contention",
             "capacity_pack_group_id" => "station:equator_prime:contention:1",
             "capacity_pack_status" => "deferred_by_reduced_station_capacity_pack",
             "capacity_pack_capacity_fraction" => 0.5,
             "capacity_pack_used_fraction" => 0.5,
             "derivation_reasons" => [
               "contact_allocation_deferred",
               "same_station_contention",
               "deferred_by_reduced_station_capacity_pack"
             ],
             "downlink_completion_source" =>
               "contact_allocation.source_contact.required_downlink_mb:dl_deferred",
             "downlink_completion_sources" => [
               "contact_allocation.source_contact.required_downlink_mb:dl_deferred",
               "contact_allocation.throughput_model.required_downlink_mb"
             ],
             "downlink_demand_sources" => [
               "contact_allocation.required_downlink:dl_deferred"
             ],
             "feedback_source" => "prior_plan.source_contact_allocation_report",
             "trust_boundary" => "ops_contact_allocation"
           } = List.first(pressure_branch["events"])

    assert get_in(pressure_branch, ["provenance", "branch_metadata", "capacity_pack_status"]) ==
             "deferred_by_reduced_station_capacity_pack"

    nested_station_branch =
      branch(
        artifact,
        "derived_contact_allocation_pressure_deferred_dl_nested_station_deferred"
      )

    assert %{
             "type" => "downlink_completion_gap",
             "ground_station_id" => "polar_nested",
             "starts_at_s" => 700.0,
             "ends_at_s" => 760.0,
             "required_downlink_mb" => 44.0,
             "source_activity_id" => "dl_nested_station_deferred",
             "feedback_source" => "prior_plan.source_contact_allocation_report",
             "trust_boundary" => "ops_contact_allocation"
           } = List.first(nested_station_branch["events"])

    source_contact_alias_branch =
      branch(artifact, "derived_contact_allocation_pressure_deferred_dl_source_contact_alias")

    assert %{
             "type" => "downlink_completion_gap",
             "ground_station_id" => "alias_station",
             "starts_at_s" => 820.0,
             "ends_at_s" => 880.0,
             "required_downlink_mb" => 33.0,
             "source_window_id" => "window:leo_1:ground_station_access:alias_station:deferred",
             "downlink_demand_sources" => [
               "contact_allocation.source_contact.required_downlink_mb:dl_source_contact_alias"
             ],
             "feedback_source" => "prior_plan.source_contact_allocation_report",
             "trust_boundary" => "ops_contact_allocation"
           } = List.first(source_contact_alias_branch["events"])

    reserved_branch =
      branch(artifact, "derived_contact_allocation_pressure_blocked_dl_report_reserved")

    assert %{
             "type" => "downlink_completion_gap",
             "ground_station_id" => "equator_prime",
             "required_downlink_mb" => 28.0,
             "station_calendar_entry_id" => "partner_reservation",
             "station_calendar_entry_status" => "reserved",
             "station_reservation_id" => "reservation_partner",
             "station_reserved_by" => "partner_team",
             "station_reservation_status" => "confirmed",
             "station_reservation_match_status" => "unmatched_overlap",
             "derivation_reasons" => [
               "contact_allocation_blocked",
               "station_reserved",
               "unmatched_overlap",
               "reserved"
             ],
             "feedback_source" => "prior_plan.source_contact_allocation_report",
             "trust_boundary" => "ops_contact_allocation_report"
           } = List.first(reserved_branch["events"])

    reserved_row =
      artifact["branch_comparison_report"]["rows"]
      |> Enum.find(
        &(&1["branch_id"] == "derived_contact_allocation_pressure_blocked_dl_report_reserved")
      )

    assert reserved_row["branch_station_reservation_ids"] == ["reservation_partner"]
    assert reserved_row["branch_station_reserved_by"] == ["partner_team"]
    assert reserved_row["branch_station_reservation_statuses"] == ["confirmed"]
    assert reserved_row["branch_station_reservation_match_statuses"] == ["unmatched_overlap"]
    assert reserved_row["branch_contact_allocation_statuses"] == ["blocked"]
    assert reserved_row["branch_contact_allocation_reasons"] == ["station_reserved"]

    policy_branch =
      branch(artifact, "derived_contact_allocation_pressure_policy_blocked_dl_policy_blocked")

    assert %{
             "type" => "downlink_completion_gap",
             "ground_station_id" => "equator_prime",
             "source_activity_id" => "dl_policy_blocked",
             "required_contacts" => 1,
             "planned_contacts" => 0,
             "required_downlink_mb" => 55.0,
             "allocation_status" => "allocated",
             "effective_allocation_status" => "policy_blocked",
             "allocation_reason" => "selected_by_contention_resolution",
             "review_status" => "operator_review_required",
             "approval_status" => "blocked_by_policy",
             "policy_classification" => "blocked_by_policy",
             "policy_decision" => %{
               "classification" => "blocked_by_policy",
               "policy_bundle_id" => "ground_network_allocation_v1"
             },
             "feedback_source" => "prior_plan.source_contact_allocation_report",
             "trust_boundary" => "ops_contact_allocation"
           } = List.first(policy_branch["events"])

    assert get_in(policy_branch, ["provenance", "branch_metadata", "contact_review_status"]) ==
             "operator_review_required"

    assert get_in(policy_branch, ["provenance", "branch_metadata", "contact_approval_status"]) ==
             "blocked_by_policy"

    assert get_in(policy_branch, [
             "provenance",
             "branch_metadata",
             "contact_policy_classification"
           ]) ==
             "blocked_by_policy"

    assert Enum.any?(
             policy_branch["repair_result"]["source_candidate_activities"],
             &(&1["type"] == "downlink" and &1["ground_station_id"] == "equator_prime" and
                 get_in(&1, ["throughput_model", "required_downlink_mb"]) == 55.0)
           )

    assert policy_branch["approval_status"] == "blocked_by_policy"

    assert %{
             "classification" => "blocked_by_policy",
             "rule_matches" => [
               %{
                 "rule_id" => "policy_blocked_contact_allocation_pressure",
                 "event_type" => "downlink_completion_gap",
                 "approval_status" => "blocked_by_policy",
                 "policy_classification" => "blocked_by_policy",
                 "allocation_status" => "allocated",
                 "effective_allocation_status" => "policy_blocked"
               }
             ]
           } = policy_branch["policy_decision"]

    refute "derived_contact_allocation_pressure_policy_blocked_dl_policy_blocked" in artifact[
             "recommendation"
           ]["ranked_branch_ids"]

    assert Enum.any?(
             pressure_branch["risk_indicators"],
             &(&1["type"] == "downlink_completion_gap" and
                 &1["ground_station_id"] == "equator_prime" and
                 &1["capacity_pack_group_id"] == "station:equator_prime:contention:1" and
                 &1["capacity_pack_status"] == "deferred_by_reduced_station_capacity_pack" and
                 &1["reason"] =~ "42.0 MB")
           )

    pressure_row =
      artifact["branch_comparison_report"]["rows"]
      |> Enum.find(
        &(&1["branch_id"] == "derived_contact_allocation_pressure_deferred_dl_deferred")
      )

    assert pressure_row["capacity_pack_group_ids"] == ["station:equator_prime:contention:1"]
    assert pressure_row["capacity_pack_statuses"] == ["deferred_by_reduced_station_capacity_pack"]
    assert pressure_row["capacity_pack_min_capacity_fraction"] == 0.5
    assert pressure_row["capacity_pack_max_used_fraction"] == 0.5
    assert pressure_row["branch_contact_allocation_statuses"] == ["deferred"]
    assert pressure_row["branch_contact_allocation_effective_statuses"] == ["deferred"]
    assert pressure_row["branch_contact_allocation_reasons"] == ["same_station_contention"]

    policy_row =
      artifact["branch_comparison_report"]["rows"]
      |> Enum.find(
        &(&1["branch_id"] ==
            "derived_contact_allocation_pressure_policy_blocked_dl_policy_blocked")
      )

    assert policy_row["branch_contact_allocation_statuses"] == ["allocated"]
    assert policy_row["branch_contact_allocation_effective_statuses"] == ["policy_blocked"]

    assert policy_row["branch_contact_allocation_reasons"] == [
             "selected_by_contention_resolution"
           ]

    assert policy_row["branch_contact_allocation_review_statuses"] == [
             "operator_review_required"
           ]

    assert policy_row["branch_contact_allocation_approval_statuses"] == ["blocked_by_policy"]

    assert policy_row["branch_contact_allocation_policy_classifications"] == [
             "blocked_by_policy"
           ]

    policy_review_row =
      artifact["operator_review_package"]["rows"]
      |> Enum.find(
        &(&1["review_type"] == "strategy_tradeoff" and
            &1["branch_id"] ==
              "derived_contact_allocation_pressure_policy_blocked_dl_policy_blocked" and
            &1["source"] == "campaign_strategy.branch_comparison_report.rows")
      )

    assert policy_review_row["branch_contact_allocation_statuses"] == ["allocated"]

    assert policy_review_row["branch_contact_allocation_effective_statuses"] == [
             "policy_blocked"
           ]

    assert policy_review_row["branch_contact_allocation_policy_classifications"] == [
             "blocked_by_policy"
           ]

    assert get_in(policy_review_row, [
             "source_branch_comparison",
             "branch_contact_allocation_effective_statuses"
           ]) == ["policy_blocked"]

    policy_import_row =
      artifact["cadence_import_manifest"]["rows"]
      |> Enum.find(
        &(&1["source_review_type"] == "strategy_branch_comparison" and
            &1["branch_id"] ==
              "derived_contact_allocation_pressure_policy_blocked_dl_policy_blocked")
      )

    assert policy_import_row["branch_contact_allocation_statuses"] == ["allocated"]

    assert policy_import_row["branch_contact_allocation_effective_statuses"] == [
             "policy_blocked"
           ]

    assert policy_import_row["branch_contact_allocation_policy_classifications"] == [
             "blocked_by_policy"
           ]

    refute Enum.any?(
             pressure_branch["repair_result"]["warnings"],
             &(&1 == "operational feedback was applied without a declared trust boundary")
           )

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy derives branch refresh from mission-state contact allocation pressure" do
    contact_allocation_report = %{
      "schema_contract" => "contact_allocation_report.v1",
      "model" => "deterministic_station_contact_allocation",
      "source" => "mission_state.contact_allocation",
      "provenance" => %{"trust_boundary" => "mission_contact_allocation"},
      "input_contact_count" => 1,
      "allocated_contact_count" => 0,
      "deferred_contact_count" => 1,
      "blocked_contact_count" => 0,
      "rows" => [
        %{
          "id" => "contact_allocation:dl_live_deferred",
          "contact_id" => "dl_live_deferred",
          "allocation_status" => "Deferred",
          "effective_allocation_status" => "Deferred",
          "allocation_reason" => "same_station_contention",
          "type" => "downlink",
          "scenario_id" => "leo_1",
          "spacecraft_id" => "leo_1",
          "ground_station_id" => "equator_prime",
          "direction" => "downlink",
          "starts_at_s" => 520.0,
          "ends_at_s" => 580.0,
          "selected" => false,
          "required_downlink_mb" => 42.0,
          "source_window_id" => "window:leo_1:ground_station_access:equator_prime:allocation",
          "contention_group_id" => "station:equator_prime:contention:live",
          "selected_contact_id" => "dl_live_selected",
          "downlink_demand_sources" => [
            "mission_state.contact_allocation.required_downlink:dl_live_deferred"
          ]
        }
      ]
    }

    artifact =
      strategy(base_plan(%{}),
        mission_state:
          mission_state_with_refresh_inputs()
          |> Map.put(:source_contact_allocation_report, contact_allocation_report),
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    pressure_branch =
      branch(artifact, "derived_contact_allocation_pressure_deferred_dl_live_deferred")

    assert %{
             "type" => "candidate_refresh.v1",
             "scope" => "branch_generated",
             "source_report_input_paths" => ["mission_state.source_contact_allocation_report"]
           } = pressure_branch["assumptions"]["candidate_source"]

    assert %{
             "type" => "downlink_completion_gap",
             "scenario_id" => "leo_1",
             "spacecraft_id" => "leo_1",
             "ground_station_id" => "equator_prime",
             "contact_id" => "dl_live_deferred",
             "source_activity_id" => "dl_live_deferred",
             "source_activity_ids" => ["dl_live_deferred"],
             "starts_at_s" => 520.0,
             "ends_at_s" => 580.0,
             "required_downlink_mb" => 42.0,
             "planned_downlink_mb" => planned_downlink_mb,
             "allocation_status" => "deferred",
             "effective_allocation_status" => "deferred",
             "allocation_reason" => "same_station_contention",
             "contact_result" => "same_station_contention",
             "source_window_id" => "window:leo_1:ground_station_access:equator_prime:allocation",
             "derivation_reasons" => [
               "contact_allocation_deferred",
               "same_station_contention"
             ],
             "downlink_demand_sources" => [
               "mission_state.contact_allocation.required_downlink:dl_live_deferred"
             ],
             "feedback_source" => "mission_state.source_contact_allocation_report",
             "feedback_scope" => "contact_allocation",
             "trust_boundary" => "mission_contact_allocation"
           } = List.first(pressure_branch["events"])

    assert planned_downlink_mb == 0.0

    assert Enum.any?(
             pressure_branch["risk_indicators"],
             &(&1["type"] == "downlink_completion_gap" and
                 &1["ground_station_id"] == "equator_prime" and
                 &1["reason"] =~ "42.0 MB")
           )

    assert_contact_allocation_pressure_score_terms(
      pressure_branch,
      artifact,
      "downlink_completion_gap",
      "contact_allocation"
    )

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy derives branch refresh from mission-state contact allocation summary pressure" do
    station_summary =
      "summary_station"
      |> contact_allocation_station_pressure_summary_fixture()
      |> put_in(["rows", Access.at(1), "starts_at_s"], 520.0)
      |> put_in(["rows", Access.at(1), "ends_at_s"], 580.0)
      |> put_in(["rows", Access.at(1), "required_downlink_mb"], 41.0)
      |> put_in(["review_rows", Access.at(0), "starts_at_s"], 520.0)
      |> put_in(["review_rows", Access.at(0), "ends_at_s"], 580.0)
      |> put_in(["review_rows", Access.at(0), "required_downlink_mb"], 41.0)

    reservation_summary =
      "summary_reservation"
      |> contact_allocation_reservation_conflict_summary_fixture()
      |> put_in(["rows", Access.at(1), "starts_at_s"], 620.0)
      |> put_in(["rows", Access.at(1), "ends_at_s"], 680.0)
      |> put_in(["rows", Access.at(1), "required_downlink_mb"], 43.0)
      |> put_in(["reservation_conflict_rows", Access.at(0), "starts_at_s"], 620.0)
      |> put_in(["reservation_conflict_rows", Access.at(0), "ends_at_s"], 680.0)
      |> put_in(["reservation_conflict_rows", Access.at(0), "required_downlink_mb"], 43.0)
      |> put_in(
        ["reservation_conflict_rows", Access.at(0), "reservation_match_status"],
        "matched"
      )
      |> put_in(["reservation_review_rows", Access.at(0), "starts_at_s"], 620.0)
      |> put_in(["reservation_review_rows", Access.at(0), "ends_at_s"], 680.0)
      |> put_in(["reservation_review_rows", Access.at(0), "required_downlink_mb"], 43.0)
      |> put_in(["reservation_review_rows", Access.at(0), "reservation_match_status"], "matched")

    capacity_summary =
      "summary_capacity"
      |> contact_allocation_capacity_pack_summary_fixture()
      |> put_in(["rows", Access.at(2), "starts_at_s"], 720.0)
      |> put_in(["rows", Access.at(2), "ends_at_s"], 780.0)
      |> put_in(["rows", Access.at(2), "required_downlink_mb"], 47.0)
      |> put_in(
        ["rows", Access.at(2), "capacity_pack_group_id"],
        "summary_capacity_pack_equator_prime"
      )
      |> put_in(["review_rows", Access.at(2), "starts_at_s"], 720.0)
      |> put_in(["review_rows", Access.at(2), "ends_at_s"], 780.0)
      |> put_in(["review_rows", Access.at(2), "required_downlink_mb"], 47.0)
      |> put_in(
        ["review_rows", Access.at(2), "capacity_pack_group_id"],
        "summary_capacity_pack_equator_prime"
      )

    provider_summary =
      "summary_provider"
      |> contact_allocation_provider_reservation_request_summary_fixture()
      |> put_in(
        ["provider_reservation_review_rows", Access.at(0), "station_calendar_reservation_ids"],
        [
          "summary_provider_reservation_review",
          "summary_provider_reservation_review_backup"
        ]
      )
      |> put_in(
        ["provider_reservation_review_ids_by_match_status", "overlap"],
        [
          "summary_provider_reservation_review",
          "summary_provider_reservation_review_backup"
        ]
      )
      |> update_in(
        ["provider_reservation_review_rows", Access.at(0)],
        &Map.merge(&1, %{
          "station_reserved_by" => "ops_primary",
          "station_calendar_reserved_by" => ["ops_backup", "ops_primary"],
          "station_calendar_reservation_statuses" => ["confirmed", "tentative"],
          "station_calendar_entry_id" => "summary_provider_calendar_entry",
          "station_calendar_provider_id" => "summary_provider_calendar",
          "station_calendar_provider_entry_id" => "summary_provider_calendar_source_entry",
          "source_window_id" => "summary_provider_source_window",
          "starts_at_s" => 820.0,
          "ends_at_s" => 880.0,
          "station_reservation_expires_at_s" => 360.0,
          "station_reservation_expiration_status" => "expired"
        })
      )

    mission_state =
      mission_state_with_refresh_inputs()
      |> Map.put(:source_contact_allocation_station_pressure_summary, station_summary)
      |> Map.put(:source_contact_allocation_reservation_conflict_summary, reservation_summary)
      |> Map.put(:source_contact_allocation_capacity_pack_summary, capacity_summary)
      |> Map.put(
        :source_contact_allocation_provider_reservation_request_summary,
        provider_summary
      )

    artifact =
      strategy(base_plan(%{}),
        mission_state: mission_state,
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    station_branch =
      branch(
        artifact,
        "derived_contact_allocation_pressure_deferred_summary_station_dl_station_pressure"
      )

    assert %{
             "type" => "downlink_completion_gap",
             "contact_id" => "summary_station_dl_station_pressure",
             "required_downlink_mb" => 41.0,
             "station_calendar_entry_id" => "summary_station_station_reserved_1",
             "feedback_source" =>
               "mission_state.source_contact_allocation_station_pressure_summary",
             "feedback_scope" => "contact_allocation",
             "trust_boundary" => "summary_station_station_pressure_fixture"
           } = List.first(station_branch["events"])

    reservation_branch =
      Enum.find(artifact["branches"], fn branch ->
        branch["branch_id"] =~
          "derived_contact_allocation_pressure_deferred_summary_reservation_dl_reserved_intruder" and
          Enum.any?(
            branch["events"] || [],
            &(&1["contact_id"] == "summary_reservation_dl_reserved_intruder")
          )
      end)

    assert %{
             "type" => "downlink_completion_gap",
             "contact_id" => "summary_reservation_dl_reserved_intruder",
             "required_downlink_mb" => 43.0,
             "station_reservation_id" => "summary_reservation_reservation_1",
             "station_reservation_match_status" => "overlap",
             "feedback_source" =>
               "mission_state.source_contact_allocation_reservation_conflict_summary",
             "trust_boundary" => "summary_reservation_reservation_conflict_fixture"
           } = List.first(reservation_branch["events"])

    assert_station_reservation_conflict_pressure_score_terms(reservation_branch, artifact)

    reservation_row =
      artifact["branch_comparison_report"]["rows"]
      |> Enum.find(&(&1["branch_id"] == reservation_branch["branch_id"]))

    assert "summary_reservation_dl_reserved_intruder" in reservation_row[
             "branch_station_reservation_conflict_contact_ids"
           ]

    assert "summary_reservation_reservation_1" in reservation_row[
             "branch_station_reservation_conflict_reservation_ids"
           ]

    assert reservation_row["branch_station_reservation_conflict_match_statuses"] == [
             "overlap"
           ]

    reservation_review_row =
      artifact["operator_review_package"]["rows"]
      |> Enum.find(
        &(&1["review_type"] == "strategy_tradeoff" and
            &1["branch_id"] == reservation_branch["branch_id"] and
            &1["source"] == "campaign_strategy.branch_comparison_report.rows")
      )

    assert "summary_reservation_dl_reserved_intruder" in reservation_review_row[
             "branch_station_reservation_conflict_contact_ids"
           ]

    assert "summary_reservation_reservation_1" in reservation_review_row[
             "branch_station_reservation_conflict_reservation_ids"
           ]

    assert reservation_review_row["branch_station_reservation_conflict_match_statuses"] == [
             "overlap"
           ]

    assert "summary_reservation_reservation_1" in get_in(reservation_review_row, [
             "source_branch_comparison",
             "branch_station_reservation_conflict_reservation_ids"
           ])

    reservation_import_row =
      artifact["cadence_import_manifest"]["rows"]
      |> Enum.find(
        &(&1["source_review_type"] == "strategy_branch_comparison" and
            &1["branch_id"] == reservation_branch["branch_id"])
      )

    assert "summary_reservation_dl_reserved_intruder" in reservation_import_row[
             "branch_station_reservation_conflict_contact_ids"
           ]

    assert "summary_reservation_reservation_1" in reservation_import_row[
             "branch_station_reservation_conflict_reservation_ids"
           ]

    assert reservation_import_row["branch_station_reservation_conflict_match_statuses"] == [
             "overlap"
           ]

    capacity_branch =
      branch(
        artifact,
        "derived_contact_allocation_pressure_deferred_summary_capacity_dl_capacity_overflow"
      )

    assert %{
             "type" => "downlink_completion_gap",
             "contact_id" => "summary_capacity_dl_capacity_overflow",
             "required_downlink_mb" => 47.0,
             "capacity_pack_group_id" => "summary_capacity_pack_equator_prime",
             "capacity_pack_status" => "deferred_by_reduced_station_capacity_pack",
             "capacity_pack_contact_ids_by_direction" => %{
               "downlink" => [
                 "summary_capacity_dl_capacity_overflow",
                 "summary_capacity_dl_capacity_primary",
                 "summary_capacity_dl_capacity_secondary"
               ]
             },
             "capacity_pack_selected_contact_ids_by_direction" => %{
               "downlink" => [
                 "summary_capacity_dl_capacity_primary",
                 "summary_capacity_dl_capacity_secondary"
               ]
             },
             "capacity_pack_deferred_contact_ids_by_direction" => %{
               "downlink" => ["summary_capacity_dl_capacity_overflow"]
             },
             "capacity_pack_required_capacity_fraction_by_direction" => %{"downlink" => 0.75},
             "capacity_pack_selected_required_capacity_fraction_by_direction" => %{
               "downlink" => 0.5
             },
             "capacity_pack_deferred_required_capacity_fraction_by_direction" => %{
               "downlink" => 0.25
             },
             "feedback_source" => "mission_state.source_contact_allocation_capacity_pack_summary",
             "trust_boundary" => "summary_capacity_capacity_pack_fixture"
           } = List.first(capacity_branch["events"])

    assert Enum.any?(
             capacity_branch["risk_indicators"],
             &(&1["type"] == "downlink_completion_gap" and &1["reason"] =~ "47.0 MB")
           )

    assert_contact_allocation_pressure_score_terms(
      capacity_branch,
      artifact,
      "downlink_completion_gap",
      "contact_allocation"
    )

    capacity_branch_id =
      "derived_contact_allocation_pressure_deferred_summary_capacity_dl_capacity_overflow"

    capacity_row =
      artifact["branch_comparison_report"]["rows"]
      |> Enum.find(&(&1["branch_id"] == capacity_branch_id))

    assert "downlink_completion_gap" in capacity_row["risk_types"]
    assert capacity_row["capacity_pack_group_ids"] == ["summary_capacity_pack_equator_prime"]

    assert capacity_row["capacity_pack_contact_ids_by_direction"] == %{
             "downlink" => [
               "summary_capacity_dl_capacity_overflow",
               "summary_capacity_dl_capacity_primary",
               "summary_capacity_dl_capacity_secondary"
             ]
           }

    assert capacity_row["capacity_pack_selected_contact_ids_by_direction"] == %{
             "downlink" => [
               "summary_capacity_dl_capacity_primary",
               "summary_capacity_dl_capacity_secondary"
             ]
           }

    assert capacity_row["capacity_pack_deferred_contact_ids_by_direction"] == %{
             "downlink" => ["summary_capacity_dl_capacity_overflow"]
           }

    assert capacity_row["capacity_pack_required_capacity_fraction_by_direction"] == %{
             "downlink" => 0.75
           }

    assert capacity_row["capacity_pack_selected_required_capacity_fraction_by_direction"] == %{
             "downlink" => 0.5
           }

    assert capacity_row["capacity_pack_deferred_required_capacity_fraction_by_direction"] == %{
             "downlink" => 0.25
           }

    assert capacity_row["capacity_pack_statuses"] == [
             "deferred_by_reduced_station_capacity_pack"
           ]

    capacity_review_row =
      artifact["operator_review_package"]["rows"]
      |> Enum.find(
        &(&1["review_type"] == "strategy_tradeoff" and
            &1["branch_id"] == capacity_branch_id and
            &1["source"] == "campaign_strategy.branch_comparison_report.rows")
      )

    assert capacity_review_row["capacity_pack_contact_ids_by_direction"] == %{
             "downlink" => [
               "summary_capacity_dl_capacity_overflow",
               "summary_capacity_dl_capacity_primary",
               "summary_capacity_dl_capacity_secondary"
             ]
           }

    assert capacity_review_row["capacity_pack_selected_contact_ids_by_direction"] == %{
             "downlink" => [
               "summary_capacity_dl_capacity_primary",
               "summary_capacity_dl_capacity_secondary"
             ]
           }

    assert capacity_review_row["capacity_pack_deferred_contact_ids_by_direction"] == %{
             "downlink" => ["summary_capacity_dl_capacity_overflow"]
           }

    assert capacity_review_row["capacity_pack_required_capacity_fraction_by_direction"] == %{
             "downlink" => 0.75
           }

    assert capacity_review_row[
             "capacity_pack_selected_required_capacity_fraction_by_direction"
           ] == %{
             "downlink" => 0.5
           }

    assert capacity_review_row[
             "capacity_pack_deferred_required_capacity_fraction_by_direction"
           ] == %{
             "downlink" => 0.25
           }

    assert get_in(capacity_review_row, [
             "source_branch_comparison",
             "capacity_pack_selected_contact_ids_by_direction"
           ]) == %{
             "downlink" => [
               "summary_capacity_dl_capacity_primary",
               "summary_capacity_dl_capacity_secondary"
             ]
           }

    capacity_import_row =
      artifact["cadence_import_manifest"]["rows"]
      |> Enum.find(
        &(&1["source_review_type"] == "strategy_branch_comparison" and
            &1["branch_id"] == capacity_branch_id)
      )

    assert capacity_import_row["capacity_pack_contact_ids_by_direction"] == %{
             "downlink" => [
               "summary_capacity_dl_capacity_overflow",
               "summary_capacity_dl_capacity_primary",
               "summary_capacity_dl_capacity_secondary"
             ]
           }

    assert capacity_import_row["capacity_pack_selected_contact_ids_by_direction"] == %{
             "downlink" => [
               "summary_capacity_dl_capacity_primary",
               "summary_capacity_dl_capacity_secondary"
             ]
           }

    assert capacity_import_row["capacity_pack_deferred_contact_ids_by_direction"] == %{
             "downlink" => ["summary_capacity_dl_capacity_overflow"]
           }

    assert capacity_import_row["capacity_pack_required_capacity_fraction_by_direction"] == %{
             "downlink" => 0.75
           }

    assert capacity_import_row[
             "capacity_pack_selected_required_capacity_fraction_by_direction"
           ] == %{
             "downlink" => 0.5
           }

    assert capacity_import_row[
             "capacity_pack_deferred_required_capacity_fraction_by_direction"
           ] == %{
             "downlink" => 0.25
           }

    assert get_in(capacity_import_row, [
             "source_branch_comparison",
             "capacity_pack_deferred_required_capacity_fraction_by_direction"
           ]) == %{
             "downlink" => 0.25
           }

    provider_branch =
      branch(
        artifact,
        "derived_contact_allocation_pressure_provider_reservation_review_required_summary_provider_dl_review_overlap"
      )

    assert %{
             "type" => "provider_reservation_request_pressure",
             "contact_id" => "summary_provider_dl_review_overlap",
             "source_window_id" => "summary_provider_source_window",
             "starts_at_s" => 820.0,
             "ends_at_s" => 880.0,
             "ground_station_id" => "equator_prime",
             "station_calendar_entry_id" => "summary_provider_calendar_entry",
             "station_calendar_provider_id" => "summary_provider_calendar",
             "station_calendar_provider_entry_id" => "summary_provider_calendar_source_entry",
             "station_reservation_id" => "summary_provider_reservation_review",
             "station_calendar_reservation_ids" => [
               "summary_provider_reservation_review",
               "summary_provider_reservation_review_backup"
             ],
             "station_reserved_by" => "ops_primary",
             "station_calendar_reserved_by" => ["ops_backup", "ops_primary"],
             "station_calendar_reservation_statuses" => ["confirmed", "tentative"],
             "station_reservation_expires_at_s" => 360.0,
             "station_reservation_expiration_status" => "expired",
             "station_reservation_match_status" => "overlap",
             "provider_reservation_request_status" => "review_required",
             "provider_reservation_row_scope" => "review",
             "feedback_source" =>
               "mission_state.source_contact_allocation_provider_reservation_request_summary",
             "feedback_scope" => "contact_allocation_provider_reservation_request",
             "trust_boundary" => "summary_provider_provider_reservation_request_fixture",
             "assumptions" => %{
               "provider_reservation_execution" => "not_performed_by_strategy_branch",
               "schedule_mutation" => "not_performed_by_strategy_branch",
               "operator_authority" => "not_granted_by_strategy_branch"
             }
           } = List.first(provider_branch["events"])

    assert provider_branch["approval_status"] == "blocked_by_policy"

    assert "provider_reservation_request_blocked" in artifact["approval_policy"][
             "blocked_risk_types"
           ]

    assert Enum.any?(
             provider_branch["risk_indicators"],
             &(&1["type"] == "provider_reservation_request_review" and
                 &1["station_reservation_match_status"] == "overlap" and
                 &1["source_window_id"] == "summary_provider_source_window" and
                 &1["starts_at_s"] == 820.0 and &1["ends_at_s"] == 880.0 and
                 &1["station_calendar_reservation_ids"] == [
                   "summary_provider_reservation_review",
                   "summary_provider_reservation_review_backup"
                 ] and
                 &1["station_calendar_reserved_by"] == ["ops_backup", "ops_primary"] and
                 &1["station_calendar_reservation_statuses"] == ["confirmed", "tentative"] and
                 &1["station_calendar_entry_id"] == "summary_provider_calendar_entry" and
                 &1["station_calendar_provider_id"] == "summary_provider_calendar" and
                 &1["station_calendar_provider_entry_id"] ==
                   "summary_provider_calendar_source_entry" and
                 &1["station_reservation_expires_at_s"] == 360.0 and
                 &1["station_reservation_expiration_status"] == "expired")
           )

    assert get_in(provider_branch, [
             "provenance",
             "branch_metadata",
             "source_window_id"
           ]) == "summary_provider_source_window"

    assert get_in(provider_branch, ["provenance", "branch_metadata", "starts_at_s"]) ==
             820.0

    assert get_in(provider_branch, ["provenance", "branch_metadata", "ends_at_s"]) ==
             880.0

    assert get_in(provider_branch, [
             "provenance",
             "branch_metadata",
             "station_calendar_entry_id"
           ]) == "summary_provider_calendar_entry"

    assert get_in(provider_branch, [
             "provenance",
             "branch_metadata",
             "station_calendar_provider_id"
           ]) == "summary_provider_calendar"

    assert get_in(provider_branch, [
             "provenance",
             "branch_metadata",
             "station_calendar_provider_entry_id"
           ]) == "summary_provider_calendar_source_entry"

    assert get_in(provider_branch, [
             "provenance",
             "branch_metadata",
             "station_calendar_reservation_ids"
           ]) == [
             "summary_provider_reservation_review",
             "summary_provider_reservation_review_backup"
           ]

    assert get_in(provider_branch, [
             "provenance",
             "branch_metadata",
             "station_calendar_reserved_by"
           ]) == ["ops_backup", "ops_primary"]

    assert get_in(provider_branch, [
             "provenance",
             "branch_metadata",
             "station_calendar_reservation_statuses"
           ]) == ["confirmed", "tentative"]

    assert get_in(provider_branch, [
             "provenance",
             "branch_metadata",
             "station_reservation_expires_at_s"
           ]) == 360.0

    assert get_in(provider_branch, [
             "provenance",
             "branch_metadata",
             "station_reservation_expiration_status"
           ]) == "expired"

    assert_provider_reservation_request_pressure_score_terms(provider_branch, artifact)

    provider_row =
      artifact["branch_comparison_report"]["rows"]
      |> Enum.find(
        &(&1["branch_id"] ==
            "derived_contact_allocation_pressure_provider_reservation_review_required_summary_provider_dl_review_overlap")
      )

    assert "provider_reservation_request_review" in provider_row["risk_types"]

    assert provider_row["branch_source_window_ids"] == ["summary_provider_source_window"]
    assert provider_row["branch_source_window_count"] == 1

    assert provider_row["branch_source_window_bounds"] == [
             %{
               "source_window_id" => "summary_provider_source_window",
               "earliest_starts_at_s" => 820.0,
               "latest_ends_at_s" => 880.0
             }
           ]

    assert provider_row["branch_source_window_bound_count"] == 1
    assert provider_row["branch_untimed_source_window_count"] == 0
    refute Map.has_key?(provider_row, "branch_untimed_source_window_ids")

    assert provider_row["branch_earliest_starts_at_s"] == 820.0
    assert provider_row["branch_latest_ends_at_s"] == 880.0

    assert provider_row["branch_station_calendar_entry_ids"] == [
             "summary_provider_calendar_entry"
           ]

    assert provider_row["branch_station_calendar_provider_ids"] == [
             "summary_provider_calendar"
           ]

    assert provider_row["branch_station_calendar_provider_entry_ids"] == [
             "summary_provider_calendar_source_entry"
           ]

    assert provider_row["branch_station_reservation_ids"] == [
             "summary_provider_reservation_review",
             "summary_provider_reservation_review_backup"
           ]

    assert provider_row["branch_station_reserved_by"] == ["ops_backup", "ops_primary"]

    assert provider_row["branch_station_reservation_statuses"] == [
             "confirmed",
             "tentative"
           ]

    assert provider_row["branch_station_reservation_expiration_statuses"] == ["expired"]

    provider_branch_id = provider_branch["branch_id"]

    provider_review_row =
      artifact["operator_review_package"]["rows"]
      |> Enum.find(
        &(&1["review_type"] == "strategy_tradeoff" and
            &1["branch_id"] == provider_branch_id and
            &1["source"] == "campaign_strategy.branch_comparison_report.rows")
      )

    assert provider_review_row["branch_source_window_ids"] == [
             "summary_provider_source_window"
           ]

    assert provider_review_row["branch_source_window_bounds"] ==
             provider_row["branch_source_window_bounds"]

    assert provider_review_row["branch_source_window_count"] == 1
    assert provider_review_row["branch_source_window_bound_count"] == 1
    assert provider_review_row["branch_untimed_source_window_count"] == 0

    assert provider_review_row["branch_earliest_starts_at_s"] == 820.0
    assert provider_review_row["branch_latest_ends_at_s"] == 880.0

    assert get_in(provider_review_row, [
             "source_branch_comparison",
             "branch_source_window_ids"
           ]) == ["summary_provider_source_window"]

    provider_import_row =
      artifact["cadence_import_manifest"]["rows"]
      |> Enum.find(
        &(&1["source_review_type"] == "strategy_branch_comparison" and
            &1["branch_id"] == provider_branch_id)
      )

    assert provider_import_row["branch_source_window_ids"] == [
             "summary_provider_source_window"
           ]

    assert provider_import_row["branch_source_window_bounds"] ==
             provider_row["branch_source_window_bounds"]

    assert provider_import_row["branch_source_window_count"] == 1
    assert provider_import_row["branch_source_window_bound_count"] == 1
    assert provider_import_row["branch_untimed_source_window_count"] == 0

    assert provider_import_row["branch_earliest_starts_at_s"] == 820.0
    assert provider_import_row["branch_latest_ends_at_s"] == 880.0

    assert get_in(provider_import_row, [
             "source_branch_comparison",
             "branch_latest_ends_at_s"
           ]) == 880.0

    branch_window_fields = [
      "branch_source_window_ids",
      "branch_source_window_count",
      "branch_source_window_bounds",
      "branch_source_window_bound_count",
      "branch_untimed_source_window_ids",
      "branch_untimed_source_window_count",
      "branch_earliest_starts_at_s",
      "branch_latest_ends_at_s"
    ]

    provider_review_index =
      Enum.find_index(
        artifact["operator_review_package"]["rows"],
        &(&1["id"] == provider_review_row["id"])
      )

    missing_review_window =
      update_in(
        artifact,
        ["operator_review_package", "rows", Access.at(provider_review_index)],
        &Map.delete(&1, "branch_source_window_bounds")
      )

    assert {:error, missing_review_window_report} =
             Schema.validate_artifact(missing_review_window["operator_review_package"])

    assert Enum.any?(
             missing_review_window_report["errors"],
             &(&1["path"] == "$.rows[#{provider_review_index}].branch_source_window_bounds")
           )

    legacy_review_package =
      update_in(
        artifact["operator_review_package"],
        ["rows", Access.at(provider_review_index)],
        fn row ->
          row
          |> Map.drop(branch_window_fields)
          |> Map.update!("source_branch_comparison", &Map.drop(&1, branch_window_fields))
        end
      )

    assert {:ok, _legacy_review_package} = Schema.validate_artifact(legacy_review_package)

    provider_import_index =
      Enum.find_index(
        artifact["cadence_import_manifest"]["rows"],
        &(&1["id"] == provider_import_row["id"])
      )

    missing_import_window =
      update_in(
        artifact["cadence_import_manifest"],
        ["rows", Access.at(provider_import_index)],
        &Map.delete(&1, "branch_earliest_starts_at_s")
      )

    assert {:error, missing_import_window_report} =
             Schema.validate_artifact(missing_import_window)

    assert Enum.any?(
             missing_import_window_report["errors"],
             &(&1["path"] == "$.rows[#{provider_import_index}].branch_earliest_starts_at_s")
           )

    stale_import_window =
      update_in(
        artifact["cadence_import_manifest"],
        ["rows", Access.at(provider_import_index)],
        &Map.put(&1, "branch_latest_ends_at_s", 881.0)
      )

    assert {:error, stale_import_window_report} = Schema.validate_artifact(stale_import_window)

    assert Enum.any?(
             stale_import_window_report["errors"],
             &(&1["path"] == "$.rows[#{provider_import_index}].branch_latest_ends_at_s")
           )

    legacy_import_manifest =
      update_in(
        artifact["cadence_import_manifest"],
        ["rows", Access.at(provider_import_index)],
        fn row ->
          row
          |> Map.drop(branch_window_fields)
          |> Map.update!("source_branch_comparison", &Map.drop(&1, branch_window_fields))
        end
      )

    assert {:ok, _legacy_import_manifest} = Schema.validate_artifact(legacy_import_manifest)

    risk_weight =
      get_in(artifact, ["score_term_report", "assumptions", "policy", "risk_weight"])

    assert Enum.count(
             provider_branch["risk_indicators"],
             &(&1["contact_id"] == "summary_provider_dl_review_overlap" and
                 &1["station_reservation_expiration_status"] == "expired")
           ) == 1

    expiration_pressure_count =
      Enum.count(
        provider_branch["risk_indicators"],
        &(&1["station_reservation_expiration_status"] in ["expired", "missing"])
      )

    provider_expiration_penalty =
      provider_branch["score_terms"]["station_reservation_expiration_pressure_penalty"]

    assert provider_expiration_penalty == -expiration_pressure_count * risk_weight

    assert Enum.any?(
             artifact["score_term_report"]["rows"],
             &(&1["branch_id"] == provider_branch["branch_id"] and
                 &1["term_key"] == "station_reservation_expiration_pressure_penalty" and
                 &1["value"] == provider_expiration_penalty)
           )

    refute Enum.any?(
             artifact["branch_comparison_report"]["rows"],
             &(&1["branch_id"] ==
                 "derived_contact_allocation_pressure_provider_reservation_review_required_summary_provider_dl_reserved_owner")
           )

    refute branch(
             artifact,
             "derived_contact_allocation_pressure_provider_reservation_request_ready_summary_provider_dl_reserved_owner"
           )

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy derives branch refresh from prior-plan contact allocation summary pressure" do
    station_summary =
      "prior_station"
      |> contact_allocation_station_pressure_summary_fixture()
      |> put_in(["rows", Access.at(1), "starts_at_s"], 520.0)
      |> put_in(["rows", Access.at(1), "ends_at_s"], 580.0)
      |> put_in(["rows", Access.at(1), "required_downlink_mb"], 41.0)
      |> put_in(["review_rows", Access.at(0), "starts_at_s"], 520.0)
      |> put_in(["review_rows", Access.at(0), "ends_at_s"], 580.0)
      |> put_in(["review_rows", Access.at(0), "required_downlink_mb"], 41.0)

    reservation_summary =
      "prior_reservation"
      |> contact_allocation_reservation_conflict_summary_fixture()
      |> put_in(["rows", Access.at(1), "starts_at_s"], 620.0)
      |> put_in(["rows", Access.at(1), "ends_at_s"], 680.0)
      |> put_in(["rows", Access.at(1), "required_downlink_mb"], 43.0)
      |> put_in(["reservation_conflict_rows", Access.at(0), "starts_at_s"], 620.0)
      |> put_in(["reservation_conflict_rows", Access.at(0), "ends_at_s"], 680.0)
      |> put_in(["reservation_conflict_rows", Access.at(0), "required_downlink_mb"], 43.0)
      |> put_in(["reservation_review_rows", Access.at(0), "starts_at_s"], 620.0)
      |> put_in(["reservation_review_rows", Access.at(0), "ends_at_s"], 680.0)
      |> put_in(["reservation_review_rows", Access.at(0), "required_downlink_mb"], 43.0)

    capacity_summary =
      "prior_capacity"
      |> contact_allocation_capacity_pack_summary_fixture()
      |> put_in(["rows", Access.at(2), "starts_at_s"], 720.0)
      |> put_in(["rows", Access.at(2), "ends_at_s"], 780.0)
      |> put_in(["rows", Access.at(2), "required_downlink_mb"], 47.0)
      |> put_in(
        ["rows", Access.at(2), "capacity_pack_group_id"],
        "prior_capacity_pack_equator_prime"
      )
      |> put_in(["review_rows", Access.at(2), "starts_at_s"], 720.0)
      |> put_in(["review_rows", Access.at(2), "ends_at_s"], 780.0)
      |> put_in(["review_rows", Access.at(2), "required_downlink_mb"], 47.0)
      |> put_in(
        ["review_rows", Access.at(2), "capacity_pack_group_id"],
        "prior_capacity_pack_equator_prime"
      )
      |> Map.delete("provenance")

    prior_plan =
      base_plan(%{
        "source_contact_allocation_station_pressure_summary" => station_summary,
        "source_result_artifact" => %{
          "schema_contract" => "result_artifact.v1",
          "study_id" => "prior_summary_pressure",
          "provenance" => %{"trust_boundary" => "prior_result_artifact_boundary"},
          "source_contact_allocation_reservation_conflict_summary" => reservation_summary,
          "source_contact_allocation_capacity_pack_summary" => capacity_summary
        }
      })

    artifact =
      strategy(prior_plan,
        mission_state: mission_state_with_refresh_inputs(),
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    station_branch =
      branch(
        artifact,
        "derived_contact_allocation_pressure_deferred_prior_station_dl_station_pressure"
      )

    assert %{
             "type" => "downlink_completion_gap",
             "contact_id" => "prior_station_dl_station_pressure",
             "required_downlink_mb" => 41.0,
             "feedback_source" => "prior_plan.source_contact_allocation_station_pressure_summary",
             "trust_boundary" => "prior_station_station_pressure_fixture"
           } = List.first(station_branch["events"])

    reservation_branch =
      branch(
        artifact,
        "derived_contact_allocation_pressure_deferred_prior_reservation_dl_reserved_intruder"
      )

    assert %{
             "type" => "downlink_completion_gap",
             "contact_id" => "prior_reservation_dl_reserved_intruder",
             "station_reservation_id" => "prior_reservation_reservation_1",
             "station_reservation_match_status" => "overlap",
             "feedback_source" =>
               "prior_plan.source_result_artifact.source_contact_allocation_reservation_conflict_summary",
             "trust_boundary" => "prior_reservation_reservation_conflict_fixture"
           } = List.first(reservation_branch["events"])

    assert_station_reservation_conflict_pressure_score_terms(reservation_branch, artifact)

    capacity_branch =
      branch(
        artifact,
        "derived_contact_allocation_pressure_deferred_prior_capacity_dl_capacity_overflow"
      )

    assert %{
             "type" => "downlink_completion_gap",
             "contact_id" => "prior_capacity_dl_capacity_overflow",
             "required_downlink_mb" => 47.0,
             "capacity_pack_group_id" => "prior_capacity_pack_equator_prime",
             "capacity_pack_status" => "deferred_by_reduced_station_capacity_pack",
             "capacity_pack_deferred_contact_ids_by_direction" => %{
               "downlink" => ["prior_capacity_dl_capacity_overflow"]
             },
             "capacity_pack_deferred_required_capacity_fraction_by_direction" => %{
               "downlink" => 0.25
             },
             "feedback_source" =>
               "prior_plan.source_result_artifact.source_contact_allocation_capacity_pack_summary",
             "trust_boundary" => "prior_result_artifact_boundary"
           } = List.first(capacity_branch["events"])

    assert Enum.any?(
             capacity_branch["risk_indicators"],
             &(&1["type"] == "downlink_completion_gap" and &1["reason"] =~ "47.0 MB")
           )

    assert_contact_allocation_pressure_score_terms(
      capacity_branch,
      artifact,
      "downlink_completion_gap",
      "contact_allocation"
    )

    capacity_row =
      artifact["branch_comparison_report"]["rows"]
      |> Enum.find(
        &(&1["branch_id"] ==
            "derived_contact_allocation_pressure_deferred_prior_capacity_dl_capacity_overflow")
      )

    assert "downlink_completion_gap" in capacity_row["risk_types"]
    assert capacity_row["capacity_pack_group_ids"] == ["prior_capacity_pack_equator_prime"]

    assert capacity_row["capacity_pack_deferred_contact_ids_by_direction"] == %{
             "downlink" => ["prior_capacity_dl_capacity_overflow"]
           }

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy derives contact allocation pressure from result artifact reports" do
    prior_plan =
      base_plan(%{
        "source_result_artifact" => %{
          "schema_contract" => "result_artifact.v1",
          "study_id" => "contact_allocation_result_artifact",
          "provenance" => %{"trust_boundary" => "ops_result_artifact"},
          "contact_allocation_report" => %{
            "schema_contract" => "contact_allocation_report.v1",
            "model" => "deterministic_station_contact_allocation",
            "source" => "campaign_repair.activities",
            "input_contact_count" => 1,
            "allocated_contact_count" => 0,
            "deferred_contact_count" => 1,
            "blocked_contact_count" => 0,
            "rows" => [
              %{
                "id" => "contact_allocation:dl_result_deferred",
                "contact_id" => "dl_result_deferred",
                "allocation_status" => "Deferred",
                "effective_allocation_status" => "Deferred",
                "allocation_reason" => "same_station_contention",
                "type" => "downlink",
                "scenario_id" => "leo_1",
                "spacecraft_id" => "leo_1",
                "ground_station_id" => "equator_prime",
                "direction" => "downlink",
                "starts_at_s" => 520.0,
                "ends_at_s" => 580.0,
                "selected" => false,
                "estimated_throughput_mb" => 42.0,
                "downlink_demand_sources" => [
                  "contact_allocation.required_downlink:dl_result_deferred"
                ]
              }
            ]
          }
        }
      })

    artifact =
      strategy(prior_plan,
        mission_state: mission_state_with_refresh_inputs(),
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    pressure_branch =
      branch(artifact, "derived_contact_allocation_pressure_deferred_dl_result_deferred")

    assert %{
             "type" => "downlink_completion_gap",
             "ground_station_id" => "equator_prime",
             "source_activity_id" => "dl_result_deferred",
             "required_contacts" => 1,
             "planned_contacts" => 0,
             "required_downlink_mb" => 42.0,
             "allocation_status" => "deferred",
             "effective_allocation_status" => "deferred",
             "allocation_reason" => "same_station_contention",
             "downlink_demand_sources" => [
               "contact_allocation.required_downlink:dl_result_deferred"
             ],
             "feedback_source" => "prior_plan.source_result_artifact.contact_allocation_report",
             "feedback_scope" => "contact_allocation",
             "trust_boundary" => "ops_result_artifact"
           } = List.first(pressure_branch["events"])

    assert %{"type" => "candidate_refresh.v1", "scope" => "branch_generated"} =
             pressure_branch["assumptions"]["candidate_source"]

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy keeps independent contact allocation pressures for the same contact" do
    prior_plan =
      base_plan(%{
        "source_contact_allocation_report" => %{
          "schema_contract" => "contact_allocation_report.v1",
          "model" => "deterministic_station_contact_allocation",
          "source" => "campaign_repair.activities",
          "input_contact_count" => 1,
          "allocated_contact_count" => 0,
          "deferred_contact_count" => 1,
          "blocked_contact_count" => 0,
          "rows" => [
            %{
              "id" => "contact_allocation:dl_shared:source",
              "contact_id" => "dl_shared",
              "allocation_status" => "deferred",
              "effective_allocation_status" => "deferred",
              "allocation_reason" => "same_station_contention",
              "type" => "downlink",
              "scenario_id" => "leo_1",
              "spacecraft_id" => "leo_1",
              "ground_station_id" => "equator_prime",
              "direction" => "downlink",
              "starts_at_s" => 520.0,
              "ends_at_s" => 580.0,
              "required_downlink_mb" => 42.0,
              "source_window_id" => "window:allocation:source",
              "trust_boundary" => "ops_source_allocation"
            }
          ]
        },
        "contact_allocation_report" => %{
          "schema_contract" => "contact_allocation_report.v1",
          "model" => "deterministic_station_contact_allocation",
          "source" => "campaign_strategy.branch_repair.activities",
          "input_contact_count" => 1,
          "allocated_contact_count" => 0,
          "deferred_contact_count" => 1,
          "blocked_contact_count" => 0,
          "rows" => [
            %{
              "id" => "contact_allocation:dl_shared:canonical",
              "contact_id" => "dl_shared",
              "allocation_status" => "deferred",
              "effective_allocation_status" => "deferred",
              "allocation_reason" => "reduced_capacity_contention",
              "type" => "downlink",
              "scenario_id" => "leo_1",
              "spacecraft_id" => "leo_1",
              "ground_station_id" => "polar_aux",
              "direction" => "downlink",
              "starts_at_s" => 620.0,
              "ends_at_s" => 680.0,
              "required_downlink_mb" => 31.0,
              "source_window_id" => "window:allocation:canonical",
              "trust_boundary" => "ops_canonical_allocation"
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

    branch_ids = Enum.map(artifact["branches"], & &1["branch_id"])

    refute "derived_contact_allocation_pressure_deferred_dl_shared" in branch_ids

    source_branch_id =
      Enum.find(
        branch_ids,
        &String.starts_with?(
          &1,
          "derived_contact_allocation_pressure_deferred_dl_shared_window:allocation:source"
        )
      )

    canonical_branch_id =
      Enum.find(
        branch_ids,
        &String.starts_with?(
          &1,
          "derived_contact_allocation_pressure_deferred_dl_shared_window:allocation:canonical"
        )
      )

    assert source_branch_id
    assert canonical_branch_id

    source_branch = branch(artifact, source_branch_id)
    canonical_branch = branch(artifact, canonical_branch_id)

    assert %{
             "type" => "downlink_completion_gap",
             "contact_id" => "dl_shared",
             "ground_station_id" => "equator_prime",
             "required_downlink_mb" => 42.0,
             "source_window_id" => "window:allocation:source",
             "feedback_source" => "prior_plan.source_contact_allocation_report",
             "trust_boundary" => "ops_source_allocation"
           } = List.first(source_branch["events"])

    assert %{
             "type" => "downlink_completion_gap",
             "contact_id" => "dl_shared",
             "ground_station_id" => "polar_aux",
             "required_downlink_mb" => 31.0,
             "source_window_id" => "window:allocation:canonical",
             "feedback_source" => "prior_plan.contact_allocation_report",
             "trust_boundary" => "ops_canonical_allocation"
           } = List.first(canonical_branch["events"])

    comparison_branch_ids =
      artifact["branch_comparison_report"]["rows"]
      |> Enum.map(& &1["branch_id"])

    assert source_branch_id in comparison_branch_ids
    assert canonical_branch_id in comparison_branch_ids

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy ignores reservation-conflict rows on station-pressure summaries" do
    summary = %{
      "schema_contract" => "contact_allocation_station_pressure_summary.v1",
      "model" => "artifact_only_contact_allocation_station_pressure_summary",
      "source_artifact_type" => "contact_allocation_report.v1",
      "rows" => [],
      "review_rows" => [],
      "reservation_conflict_rows" => [
        %{
          "contact_id" => "shadow_station_pressure_contact",
          "allocation_status" => "deferred",
          "effective_allocation_status" => "deferred",
          "allocation_reason" => "same_station_contention",
          "ground_station_id" => "shadow_station",
          "direction" => "downlink"
        }
      ]
    }

    artifact =
      strategy(base_plan(%{}),
        mission_state:
          mission_state_with_refresh_inputs()
          |> Map.put("source_contact_allocation_station_pressure_summary", summary),
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    refute branch(
             artifact,
             "derived_contact_allocation_pressure_deferred_shadow_station_pressure_contact"
           )
  end

  test "strategy treats present station-pressure rows as authoritative over review rows" do
    summary = %{
      "schema_contract" => "contact_allocation_station_pressure_summary.v1",
      "model" => "artifact_only_contact_allocation_station_pressure_summary",
      "source_artifact_type" => "contact_allocation_report.v1",
      "rows" => [],
      "review_rows" => [
        %{
          "contact_id" => "stale_station_review_contact",
          "allocation_status" => "deferred",
          "effective_allocation_status" => "deferred",
          "allocation_reason" => "same_station_contention",
          "ground_station_id" => "stale_station",
          "direction" => "downlink"
        }
      ]
    }

    artifact =
      strategy(base_plan(%{}),
        mission_state:
          mission_state_with_refresh_inputs()
          |> Map.put("source_contact_allocation_station_pressure_summary", summary),
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    refute branch(
             artifact,
             "derived_contact_allocation_pressure_deferred_stale_station_review_contact"
           )
  end

  defp assert_contact_allocation_pressure_score_terms(
         branch,
         artifact,
         risk_type,
         feedback_scope,
         expected_pressure_count \\ 1
       ) do
    risk_weight = get_in(artifact, ["score_term_report", "assumptions", "policy", "risk_weight"])

    contact_pressure_risk_count =
      Enum.count(
        branch["risk_indicators"],
        &(&1["type"] == risk_type and &1["feedback_scope"] == feedback_scope)
      )

    assert contact_pressure_risk_count == expected_pressure_count
    assert branch["score_terms"]["contact_allocation_pressure_penalty"] < 0.0

    assert branch["score_terms"]["contact_allocation_pressure_penalty"] ==
             -contact_pressure_risk_count * risk_weight

    assert branch["score_terms"]["risk_penalty"] ==
             -(length(branch["risk_indicators"]) - contact_pressure_risk_count) * risk_weight

    assert "contact_allocation_pressure_penalty" in artifact["score_term_report"][
             "score_term_keys"
           ]

    assert Enum.any?(
             artifact["score_term_report"]["rows"],
             &(&1["branch_id"] == branch["branch_id"] and
                 &1["term_key"] == "contact_allocation_pressure_penalty" and
                 &1["value"] < 0.0)
           )
  end

  defp assert_station_reservation_conflict_pressure_score_terms(branch, artifact) do
    risk_weight = get_in(artifact, ["score_term_report", "assumptions", "policy", "risk_weight"])

    contact_allocation_pressure_count =
      Enum.count(
        branch["risk_indicators"],
        &contact_allocation_non_conflict_pressure?/1
      )

    station_reservation_conflict_pressure_count =
      Enum.count(
        branch["risk_indicators"],
        &station_reservation_conflict_pressure?/1
      )

    assert station_reservation_conflict_pressure_count > 0

    assert branch["score_terms"]["contact_allocation_pressure_penalty"] ==
             -contact_allocation_pressure_count * risk_weight

    assert branch["score_terms"]["station_reservation_conflict_pressure_penalty"] ==
             -station_reservation_conflict_pressure_count * risk_weight

    assert "station_reservation_conflict_pressure_penalty" in artifact["score_term_report"][
             "score_term_keys"
           ]

    assert Enum.any?(
             artifact["score_term_report"]["rows"],
             &(&1["branch_id"] == branch["branch_id"] and
                 &1["term_key"] == "station_reservation_conflict_pressure_penalty" and
                 &1["value"] < 0.0)
           )
  end

  defp assert_provider_reservation_request_pressure_score_terms(branch, artifact) do
    risk_weight = get_in(artifact, ["score_term_report", "assumptions", "policy", "risk_weight"])

    provider_reservation_request_pressure_count =
      Enum.count(branch["risk_indicators"], &provider_reservation_request_pressure?/1)

    assert provider_reservation_request_pressure_count > 0

    assert branch["score_terms"]["provider_reservation_request_pressure_penalty"] ==
             -provider_reservation_request_pressure_count * risk_weight

    assert "provider_reservation_request_pressure_penalty" in artifact["score_term_report"][
             "score_term_keys"
           ]

    assert Enum.any?(
             artifact["score_term_report"]["rows"],
             &(&1["branch_id"] == branch["branch_id"] and
                 &1["term_key"] == "provider_reservation_request_pressure_penalty" and
                 &1["value"] < 0.0)
           )
  end

  defp station_reservation_conflict_pressure?(risk) do
    risk["type"] == "downlink_completion_gap" and
      risk["feedback_scope"] == "contact_allocation" and
      (risk["station_reservation_match_status"] in ["overlap"] or
         "contact_allocation_reservation_conflict" in List.wrap(risk["derivation_reasons"]))
  end

  defp provider_reservation_request_pressure?(risk) do
    risk["type"] == "provider_reservation_request_review"
  end

  defp contact_allocation_non_conflict_pressure?(risk) do
    not station_reservation_conflict_pressure?(risk) and
      risk["type"] == "downlink_completion_gap" and
      (risk["feedback_scope"] in [
         "contact_allocation",
         "contact_allocation_provider_reservation_request"
       ] or
         Enum.any?(List.wrap(risk["derivation_reasons"]), fn reason ->
           reason
           |> to_string()
           |> String.starts_with?("contact_allocation")
         end))
  end
end
