defmodule OrbitalDynamics.Schema.CommunicationsReportFixturesTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.{Communications.ContactFilter, Schema}

  test "validates checked-in contact filter report fixture regenerates through public facade" do
    report = read_json!("study_results/contact_filter_report_v1.json")

    candidates = [
      %{
        id: :leo_1_downlink_equator_prime_1,
        type: :downlink,
        scenario_id: :leo_1,
        ground_station_id: :equator_prime,
        source_window_id: :"window:leo_1:ground_station_access:equator_prime:1",
        starts_at_s: 100.0,
        ends_at_s: 160.0
      },
      %{
        id: :leo_1_tracking_equator_prime_1,
        type: :tracking,
        scenario_id: :leo_1,
        ground_station_id: :equator_prime,
        source_window_id: :"window:leo_1:ground_station_access:equator_prime:tracking:1",
        starts_at_s: 100.0,
        ends_at_s: 160.0
      },
      %{
        id: :leo_2_downlink_polar_north_1,
        type: :downlink,
        scenario_id: :leo_2,
        ground_station_id: :polar_north,
        source_window_id: :"window:leo_2:ground_station_access:polar_north:1",
        starts_at_s: 220.0,
        ends_at_s: 300.0
      }
    ]

    ground_network = [
      %{
        ground_station_id: :equator_prime,
        status: :unavailable,
        starts_at_s: 90.0,
        ends_at_s: 170.0
      },
      %{
        ground_station_id: :polar_north,
        status: :reserved,
        starts_at_s: 200.0,
        ends_at_s: 320.0,
        reservation_id: :"reservation:polar_north:1",
        reserved_by: :provider_calendar,
        reservation_status: :reserved
      }
    ]

    generated_report = OrbitalDynamics.contact_filter_report(candidates, ground_network)

    assert generated_report == report

    assert {:ok, %{"schema_contract" => "contact_filter_report.v1"}} =
             Schema.validate_artifact(report)

    expected_assumptions = contact_filter_report_capability_assumptions()

    assert Map.take(report["assumptions"], Map.keys(expected_assumptions)) == expected_assumptions

    assert report["model"] == "thin_ground_network_availability_filter"

    assert report["model_limits"] == [
             "artifact_level_only",
             "externally_supplied_ground_network",
             "no_provider_reservation",
             "no_schedule_mutation",
             "no_link_budget_model"
           ]

    assert %{
             "input_candidate_count" => 3,
             "kept_candidate_count" => 0,
             "suppressed_candidate_count" => 3,
             "invalid_contact_input_count" => 0,
             "duplicate_suppressed_candidate_id_count" => 0,
             "duplicate_suppressed_candidate_row_count" => 0,
             "suppression_reason_counts" => %{
               "ground_station_reserved" => 1,
               "ground_station_unavailable" => 2
             },
             "station_reservation_match_status_counts" => %{"overlap" => 1},
             "station_calendar_trust_boundary_status_counts" => %{"missing" => 3}
           } = report

    assert report["suppressed_candidate_ids_by_reason"] == %{
             "ground_station_reserved" => ["leo_2_downlink_polar_north_1"],
             "ground_station_unavailable" => [
               "leo_1_downlink_equator_prime_1",
               "leo_1_tracking_equator_prime_1"
             ]
           }

    assert report["suppressed_candidate_ids_by_reservation_match_status"] == %{
             "overlap" => ["leo_2_downlink_polar_north_1"]
           }

    assert report["suppressed_candidate_ids_by_station_calendar_trust_boundary_status"] == %{
             "missing" => [
               "leo_1_downlink_equator_prime_1",
               "leo_1_tracking_equator_prime_1",
               "leo_2_downlink_polar_north_1"
             ]
           }

    rows_by_id = Map.new(report["suppressed_candidates"], &{&1["id"], &1})

    assert %{
             "type" => "downlink",
             "direction" => "downlink",
             "spacecraft_id" => "leo_1",
             "ground_station_id" => "equator_prime",
             "suppressed_reason" => "ground_station_unavailable",
             "station_availability" => "unavailable",
             "station_calendar_trust_boundary_status" => "missing",
             "source_station_calendar_entry" => %{"status" => "unavailable"}
           } = rows_by_id["leo_1_downlink_equator_prime_1"]

    assert %{
             "type" => "tracking",
             "direction" => "tracking",
             "suppressed_reason" => "ground_station_unavailable",
             "station_availability" => "unavailable",
             "station_calendar_trust_boundary_status" => "missing"
           } = rows_by_id["leo_1_tracking_equator_prime_1"]

    assert %{
             "type" => "downlink",
             "direction" => "downlink",
             "spacecraft_id" => "leo_2",
             "ground_station_id" => "polar_north",
             "suppressed_reason" => "ground_station_reserved",
             "station_availability" => "reserved",
             "station_contention_status" => "reserved_overlap",
             "station_reservation_id" => "reservation:polar_north:1",
             "station_reservation_match_status" => "overlap",
             "station_reservation_status" => "reserved",
             "station_reserved_by" => "provider_calendar",
             "station_calendar_reservation_ids" => ["reservation:polar_north:1"],
             "station_calendar_reservation_overlap_count" => 1,
             "station_calendar_reservation_statuses" => ["reserved"],
             "station_calendar_reserved_by" => ["provider_calendar"]
           } = rows_by_id["leo_2_downlink_polar_north_1"]
  end

  test "validates checked-in station calendar report fixture regenerates through public facade" do
    report = read_json!("study_results/station_calendar_report_v1.json")

    contacts = [
      %{
        id: :dl_1,
        type: :downlink,
        scenario_id: :leo_1,
        ground_station_id: :equator_prime,
        starts_at_s: 100.0,
        ends_at_s: 160.0
      },
      %{
        id: :cmd_1,
        type: :planned_contact,
        direction: :command,
        scenario_id: :leo_1,
        ground_station_id: :equator_prime,
        starts_at_s: 170.0,
        ends_at_s: 190.0
      }
    ]

    provider = %{
      schema_contract: "station_calendar_provider.v1",
      id: :ops_calendar,
      provenance: %{trust_boundary: :operator_declared_station_calendar},
      entries: [
        %{
          id: :equator_capacity,
          station_id: :equator_prime,
          availability: :available,
          start_s: 90.0,
          end_s: 170.0,
          capacity_fraction: 0.5,
          provenance: %{
            source: :station_calendar_provider,
            provider_id: :ops_calendar,
            trust_boundary: :operator_declared_station_calendar
          }
        },
        %{
          id: :equator_reserved,
          station_id: :equator_prime,
          availability: :reserved,
          start_s: 165.0,
          end_s: 200.0,
          reservation_id: :provider_reservation_42,
          reserved_by: :cadence_ops,
          reservation_status: :confirmed,
          provenance: %{
            source: :station_calendar_provider,
            provider_id: :ops_calendar,
            trust_boundary: :operator_declared_station_calendar
          }
        }
      ]
    }

    generated_report =
      OrbitalDynamics.station_calendar_report(contacts, provider, source: "ops_calendar")

    assert generated_report == report

    assert {:ok, %{"schema_contract" => "station_calendar_report.v1"}} =
             Schema.validate_artifact(report)

    assert report["model"] == "campaign_ground_network_interval_overlay"

    assert report["model_limits"] == [
             "declared_data_only",
             "no_network_calls",
             "no_provider_reservation",
             "no_schedule_mutation",
             "no_conflict_resolution"
           ]

    assert %{
             "input_contact_count" => 2,
             "calendar_entry_count" => 2,
             "affected_contact_count" => 2,
             "affected_duration_s" => 80.0,
             "duplicate_affected_contact_id_count" => 0,
             "duplicate_affected_contact_row_count" => 0,
             "provider_calendar_contention_group_count" => 1,
             "provider_counteroffer_count" => 0,
             "affected_contact_ground_station_counts" => %{"equator_prime" => 2},
             "affected_contact_availability_counts" => %{
               "reduced_capacity" => 1,
               "reserved" => 1
             },
             "direction_counts" => %{"command" => 1, "downlink" => 1},
             "station_calendar_status_counts" => %{"available" => 1, "reserved" => 1},
             "calendar_entry_trust_boundary_status_counts" => %{"declared" => 2},
             "station_calendar_trust_boundary_status_counts" => %{"declared" => 2},
             "station_reservation_match_status_counts" => %{"overlap" => 1}
           } = report

    assert report["affected_contact_ids_by_reservation_match_status"] == %{
             "overlap" => ["cmd_1"]
           }

    assert report["affected_contact_ids_by_station_calendar_trust_boundary_status"] == %{
             "declared" => ["cmd_1", "dl_1"]
           }

    assert report["assumptions"] == %{
             "duplicate_affected_contact_identity" =>
               "duplicate affected-contact row IDs are suffixed deterministically while preserving contact_id",
             "execution_boundary" => "artifact_only_no_provider_reservation",
             "matching" => "ground_station_id_and_time_interval_overlap",
             "resolution" => "report_and_annotate_only_no_candidate_suppression",
             "source" => "ops_calendar"
           }

    rows_by_contact_id = Map.new(report["affected_contacts"], &{&1["contact_id"], &1})

    assert %{
             "contact_type" => "downlink",
             "ground_station_id" => "equator_prime",
             "station_availability" => "reduced_capacity",
             "station_calendar_entry_id" => "equator_capacity",
             "station_calendar_provider_id" => "ops_calendar",
             "station_calendar_provider_entry_id" => "equator_capacity",
             "station_calendar_precedence_availability" => "reduced_capacity",
             "station_calendar_precedence_rank" => 2,
             "station_calendar_trust_boundary_status" => "declared",
             "capacity_fraction" => 0.5,
             "provider_counteroffer_negotiation_state" => "unknown"
           } = rows_by_contact_id["dl_1"]

    assert %{
             "contact_type" => "planned_contact",
             "direction" => "command",
             "ground_station_id" => "equator_prime",
             "station_availability" => "reserved",
             "station_contention_status" => "reserved_overlap",
             "station_calendar_entry_id" => "equator_reserved",
             "station_calendar_provider_id" => "ops_calendar",
             "station_calendar_provider_entry_id" => "equator_reserved",
             "station_calendar_precedence_availability" => "reserved",
             "station_calendar_precedence_rank" => 1,
             "station_reservation_id" => "provider_reservation_42",
             "station_reservation_match_status" => "overlap",
             "station_reservation_status" => "confirmed",
             "station_reserved_by" => "cadence_ops",
             "provider_counteroffer_negotiation_state" => "unknown"
           } = rows_by_contact_id["cmd_1"]

    assert [
             %{
               "id" => "station_calendar_provider_contention:equator_prime:1",
               "ground_station_id" => "equator_prime",
               "entry_count" => 2,
               "entry_ids" => ["equator_capacity", "equator_reserved"],
               "provider_ids" => ["ops_calendar"],
               "provider_entry_ids" => ["equator_capacity", "equator_reserved"],
               "provider_calendar_contention_status" => "provider_calendar_overlap",
               "required_operator_action" => "review_station_provider_contention",
               "approval_status" => "operator_review_required",
               "overlap_duration_s" => 5.0,
               "trust_boundary_statuses" => ["declared"]
             }
           ] = report["provider_calendar_contention_groups"]
  end

  test "validates checked-in link capacity report fixture regenerates through public facade" do
    report = read_json!("study_results/link_capacity_report_v1.json")

    contacts = [
      %{
        id: :leo_1_downlink_equator_prime_1,
        type: :downlink,
        scenario_id: :leo_1,
        ground_station_id: :equator_prime,
        estimated_throughput_mb: 345.42424173964787,
        capacity_fraction: 0.5
      }
    ]

    generated_report =
      OrbitalDynamics.link_capacity_report(
        contacts,
        [],
        source: "campaign_plan.candidate_activities"
      )

    assert generated_report == report

    assert {:ok, %{"schema_contract" => "link_capacity_report.v1"}} =
             Schema.validate_artifact(report)

    refute Enum.any?(report, fn {_key, value} -> is_nil(value) end)

    assert %{
             "model" => "fixed_rate_downlink_capacity_summary",
             "source" => "campaign_plan.candidate_activities",
             "contact_count" => 1,
             "effective_contact_count" => 1,
             "ignored_contact_count" => 0,
             "selected_contact_count" => 0,
             "required_downlink_contact_count" => 0,
             "actual_throughput_contact_count" => 0,
             "actual_completion_contact_count" => 0,
             "capacity_adjusted_throughput_mb" => capacity_adjusted_throughput_mb,
             "selected_capacity_adjusted_throughput_mb" => 0,
             "unused_capacity_adjusted_throughput_mb" => unused_capacity_adjusted_throughput_mb,
             "selection_utilization_status" => "unselected_capacity",
             "rows" => [
               %{
                 "ground_station_id" => "equator_prime",
                 "contact_ids" => ["leo_1_downlink_equator_prime_1"],
                 "contact_count" => 1,
                 "effective_contact_count" => 1,
                 "selected_contact_count" => 0,
                 "selected_contact_ids" => [],
                 "required_downlink_contact_count" => 0,
                 "actual_throughput_contact_count" => 0,
                 "actual_completion_contact_count" => 0,
                 "estimated_throughput_mb" => 345.42424173964787,
                 "capacity_adjusted_throughput_mb" => row_capacity_adjusted_throughput_mb,
                 "selected_capacity_adjusted_throughput_mb" => 0,
                 "unused_capacity_adjusted_throughput_mb" =>
                   row_unused_capacity_adjusted_throughput_mb,
                 "capacity_fraction_min" => 0.5,
                 "capacity_fraction_max" => 0.5,
                 "station_availability" => "reduced_capacity",
                 "selection_utilization_status" => "unselected_capacity"
               }
             ]
           } = report

    assert_in_delta capacity_adjusted_throughput_mb, 172.71212086982393, 1.0e-12
    assert_in_delta unused_capacity_adjusted_throughput_mb, 172.71212086982393, 1.0e-12
    assert_in_delta row_capacity_adjusted_throughput_mb, 172.71212086982393, 1.0e-12
    assert_in_delta row_unused_capacity_adjusted_throughput_mb, 172.71212086982393, 1.0e-12

    assert report["model_limits"] == [
             "artifact_level_only",
             "fixed_rate_summary",
             "no_link_budget_model",
             "limited_realized_selected_throughput_reconciliation",
             "limited_realized_selected_completion_fraction_reconciliation",
             "no_full_realized_contact_reconciliation",
             "no_modulation_or_coding_model",
             "no_provider_reservation",
             "no_schedule_mutation"
           ]
  end

  test "validates checked-in resource and communications report examples" do
    link_capacity_report = read_json!("study_results/link_capacity_report_v1.json")
    resource_filter_report = read_json!("study_results/resource_filter_report_v1.json")
    resource_projection_report = read_json!("study_results/resource_projection_report_v1.json")
    station_calendar_report = read_json!("study_results/station_calendar_report_v1.json")

    assert {:ok, %{"schema_contract" => "link_capacity_report.v1"}} =
             Schema.validate_artifact(link_capacity_report)

    invalid_link_capacity_model =
      Map.put(link_capacity_report, "model", "stale_link_capacity_model")

    assert {:error, link_capacity_model_report} =
             Schema.validate_artifact(invalid_link_capacity_model)

    assert Enum.any?(link_capacity_model_report["errors"], &(&1["path"] == "$.model"))

    assert %{
             "model" => "fixed_rate_downlink_capacity_summary",
             "contact_count" => 1,
             "capacity_adjusted_throughput_mb" => 172.71212086982393,
             "rows" => [
               %{
                 "ground_station_id" => "equator_prime",
                 "capacity_adjusted_throughput_mb" => 172.71212086982393,
                 "contact_ids" => ["leo_1_downlink_equator_prime_1"]
               }
             ]
           } = link_capacity_report

    invalid_link_capacity =
      Map.put(link_capacity_report, "ignored_selected_contact_ids", ["bad contact"])

    assert {:error, link_capacity_validation_report} =
             Schema.validate_artifact(invalid_link_capacity)

    assert Enum.any?(
             link_capacity_validation_report["errors"],
             &(&1["path"] == "$.ignored_selected_contact_ids[0]")
           )

    invalid_link_capacity_derivation =
      Map.put(link_capacity_report, "actual_data_rate_throughput_derivations", [
        %{"duration_s" => "sixty"}
      ])

    assert {:error, link_capacity_derivation_report} =
             Schema.validate_artifact(invalid_link_capacity_derivation)

    assert Enum.any?(
             link_capacity_derivation_report["errors"],
             &(&1["path"] == "$.actual_data_rate_throughput_derivations[0].duration_s")
           )

    invalid_link_capacity_contact_count =
      Map.put(link_capacity_report, "contact_count", 1.0)

    assert {:error, link_capacity_contact_count_report} =
             Schema.validate_artifact(invalid_link_capacity_contact_count)

    assert Enum.any?(
             link_capacity_contact_count_report["errors"],
             &(&1["path"] == "$.contact_count")
           )

    invalid_link_capacity_ignored_count =
      Map.put(link_capacity_report, "ignored_contact_count", -1)

    assert {:error, link_capacity_ignored_count_report} =
             Schema.validate_artifact(invalid_link_capacity_ignored_count)

    assert Enum.any?(
             link_capacity_ignored_count_report["errors"],
             &(&1["path"] == "$.ignored_contact_count")
           )

    invalid_link_capacity_utilization =
      Map.put(link_capacity_report, "selected_capacity_utilization_fraction", 1.2)

    assert {:error, link_capacity_utilization_report} =
             Schema.validate_artifact(invalid_link_capacity_utilization)

    assert Enum.any?(
             link_capacity_utilization_report["errors"],
             &(&1["path"] == "$.selected_capacity_utilization_fraction")
           )

    invalid_link_capacity_row_contact_count =
      put_in(link_capacity_report, ["rows", Access.at(0), "contact_count"], 1.0)

    assert {:error, link_capacity_row_contact_count_report} =
             Schema.validate_artifact(invalid_link_capacity_row_contact_count)

    assert Enum.any?(
             link_capacity_row_contact_count_report["errors"],
             &(&1["path"] == "$.rows[0].contact_count")
           )

    invalid_link_capacity_row_utilization =
      put_in(
        link_capacity_report,
        ["rows", Access.at(0), "selected_capacity_utilization_fraction"],
        1.2
      )

    assert {:error, link_capacity_row_utilization_report} =
             Schema.validate_artifact(invalid_link_capacity_row_utilization)

    assert Enum.any?(
             link_capacity_row_utilization_report["errors"],
             &(&1["path"] == "$.rows[0].selected_capacity_utilization_fraction")
           )

    invalid_link_capacity_row_capacity_range =
      link_capacity_report
      |> put_in(["rows", Access.at(0), "capacity_fraction_min"], -0.1)
      |> put_in(["rows", Access.at(0), "capacity_fraction_max"], 1.2)

    assert {:error, link_capacity_row_capacity_range_report} =
             Schema.validate_artifact(invalid_link_capacity_row_capacity_range)

    assert Enum.any?(
             link_capacity_row_capacity_range_report["errors"],
             &(&1["path"] == "$.rows[0].capacity_fraction_min")
           )

    assert Enum.any?(
             link_capacity_row_capacity_range_report["errors"],
             &(&1["path"] == "$.rows[0].capacity_fraction_max")
           )

    invalid_link_capacity_row_actual_count =
      put_in(link_capacity_report, ["rows", Access.at(0), "actual_throughput_contact_count"], -1)

    assert {:error, link_capacity_row_actual_count_report} =
             Schema.validate_artifact(invalid_link_capacity_row_actual_count)

    assert Enum.any?(
             link_capacity_row_actual_count_report["errors"],
             &(&1["path"] == "$.rows[0].actual_throughput_contact_count")
           )

    invalid_link_capacity_row_actual_ids =
      link_capacity_report
      |> put_in(["rows", Access.at(0), "actual_throughput_contact_count"], 1)
      |> put_in(["rows", Access.at(0), "actual_throughput_contact_ids"], ["bad contact"])

    assert {:error, link_capacity_row_actual_ids_report} =
             Schema.validate_artifact(invalid_link_capacity_row_actual_ids)

    assert Enum.any?(
             link_capacity_row_actual_ids_report["errors"],
             &(&1["path"] == "$.rows[0].actual_throughput_contact_ids[0]")
           )

    invalid_link_capacity_actual_completion_ids =
      link_capacity_report
      |> Map.put("actual_completion_contact_count", 1)
      |> Map.put("actual_completion_contact_ids", ["bad contact"])

    assert {:error, link_capacity_actual_completion_ids_report} =
             Schema.validate_artifact(invalid_link_capacity_actual_completion_ids)

    assert Enum.any?(
             link_capacity_actual_completion_ids_report["errors"],
             &(&1["path"] == "$.actual_completion_contact_ids[0]")
           )

    invalid_link_capacity_row_unmatched_actual_ids =
      link_capacity_report
      |> put_in(["rows", Access.at(0), "unmatched_actual_throughput_contact_count"], 1)
      |> put_in(["rows", Access.at(0), "unmatched_actual_throughput_contact_ids"], [
        "bad contact"
      ])

    assert {:error, link_capacity_row_unmatched_actual_ids_report} =
             Schema.validate_artifact(invalid_link_capacity_row_unmatched_actual_ids)

    assert Enum.any?(
             link_capacity_row_unmatched_actual_ids_report["errors"],
             &(&1["path"] == "$.rows[0].unmatched_actual_throughput_contact_ids[0]")
           )

    assert {:ok, %{"schema_contract" => "resource_projection_report.v1"}} =
             Schema.validate_artifact(resource_projection_report)

    invalid_resource_projection_model =
      Map.put(resource_projection_report, "model", "stale_resource_projection_model")

    assert {:error, resource_projection_model_report} =
             Schema.validate_artifact(invalid_resource_projection_model)

    assert Enum.any?(
             resource_projection_model_report["errors"],
             &(&1["path"] == "$.model")
           )

    invalid_resource_projection =
      put_in(resource_projection_report, ["resource_trust_boundary_status_counts", "missing"], 99)

    assert {:error, resource_projection_validation_report} =
             Schema.validate_artifact(invalid_resource_projection)

    assert Enum.any?(
             resource_projection_validation_report["errors"],
             &(&1["path"] == "$.resource_trust_boundary_status_counts")
           )

    battery_handoff_resource_projection_report =
      read_json!("study_results/resource_projection_battery_handoff_v1.json")

    assert {:ok, %{"schema_contract" => "resource_projection_report.v1"}} =
             Schema.validate_artifact(battery_handoff_resource_projection_report)

    invalid_resource_projection_source =
      Map.put(battery_handoff_resource_projection_report, "source", %{"fixture" => true})

    assert {:error, resource_projection_source_report} =
             Schema.validate_artifact(invalid_resource_projection_source)

    assert Enum.any?(
             resource_projection_source_report["errors"],
             &(&1["path"] == "$.source" and &1["message"] =~ "must be a binary")
           )

    assert {:ok, %{"schema_contract" => "resource_filter_report.v1"}} =
             Schema.validate_artifact(resource_filter_report)

    invalid_resource_filter_model =
      Map.put(resource_filter_report, "model", "stale_resource_filter_model")

    assert {:error, resource_filter_model_report} =
             Schema.validate_artifact(invalid_resource_filter_model)

    assert Enum.any?(
             resource_filter_model_report["errors"],
             &(&1["path"] == "$.model")
           )

    invalid_resource_filter_input_count =
      Map.put(resource_filter_report, "input_candidate_count", 1.0)

    assert {:error, resource_filter_input_count_report} =
             Schema.validate_artifact(invalid_resource_filter_input_count)

    assert Enum.any?(
             resource_filter_input_count_report["errors"],
             &(&1["path"] == "$.input_candidate_count")
           )

    invalid_resource_filter_duplicate_count =
      Map.put(resource_filter_report, "duplicate_suppressed_candidate_row_count", -1)

    assert {:error, resource_filter_duplicate_count_report} =
             Schema.validate_artifact(invalid_resource_filter_duplicate_count)

    assert Enum.any?(
             resource_filter_duplicate_count_report["errors"],
             &(&1["path"] == "$.duplicate_suppressed_candidate_row_count")
           )

    invalid_resource_filter =
      put_in(
        resource_filter_report,
        ["suppressed_resource_trust_boundary_status_counts", "missing"],
        99
      )

    assert {:error, resource_filter_validation_report} =
             Schema.validate_artifact(invalid_resource_filter)

    assert Enum.any?(
             resource_filter_validation_report["errors"],
             &(&1["path"] == "$.suppressed_resource_trust_boundary_status_counts")
           )

    invalid_resource_filter_source_count =
      put_in(resource_filter_report, ["resource_source_quality_counts", "operator_supplied"], -1)

    assert {:error, resource_filter_source_count_report} =
             Schema.validate_artifact(invalid_resource_filter_source_count)

    assert Enum.any?(
             resource_filter_source_count_report["errors"],
             &(&1["path"] == "$.resource_source_quality_counts.operator_supplied")
           )

    assert %{
             "model" => "resource_summary_availability_and_margin_filter",
             "suppressed_candidate_count" => 2,
             "resource_source_quality_counts" => %{"operator_supplied" => 1},
             "suppressed_candidates" => [
               %{"suppressed_reason" => "storage_margin_below_observe_policy"},
               %{"suppressed_reason" => "downlink_margin_below_policy"}
             ]
           } = resource_filter_report

    assert %{
             "model" => "thin_campaign_selected_activity_resource_projection",
             "projected_resources" => [
               %{
                 "spacecraft_id" => "leo_1",
                 "projected_storage_margin" => 0.75,
                 "projected_downlink_margin" => projected_downlink_margin,
                 "resource_source_quality" => "operator_supplied"
               }
             ]
           } = resource_projection_report

    assert projected_downlink_margin == 1.0

    invalid_resource_projection_input_count =
      Map.put(resource_projection_report, "input_resource_summary_count", 1.0)

    assert {:error, resource_projection_input_count_report} =
             Schema.validate_artifact(invalid_resource_projection_input_count)

    assert Enum.any?(
             resource_projection_input_count_report["errors"],
             &(&1["path"] == "$.input_resource_summary_count")
           )

    invalid_resource_projection_activity_count =
      Map.put(resource_projection_report, "invalid_activity_input_count", -1)

    assert {:error, resource_projection_activity_count_report} =
             Schema.validate_artifact(invalid_resource_projection_activity_count)

    assert Enum.any?(
             resource_projection_activity_count_report["errors"],
             &(&1["path"] == "$.invalid_activity_input_count")
           )

    invalid_projected_activity_count =
      put_in(
        resource_projection_report,
        ["projected_resources", Access.at(0), "activity_count"],
        1.0
      )

    assert {:error, projected_activity_count_report} =
             Schema.validate_artifact(invalid_projected_activity_count)

    assert Enum.any?(
             projected_activity_count_report["errors"],
             &(&1["path"] == "$.projected_resources[0].activity_count")
           )

    invalid_projected_downlink_count =
      put_in(
        resource_projection_report,
        ["projected_resources", Access.at(0), "downlink_count"],
        -1
      )

    assert {:error, projected_downlink_count_report} =
             Schema.validate_artifact(invalid_projected_downlink_count)

    assert Enum.any?(
             projected_downlink_count_report["errors"],
             &(&1["path"] == "$.projected_resources[0].downlink_count")
           )

    assert {:ok, %{"schema_contract" => "station_calendar_report.v1"}} =
             Schema.validate_artifact(station_calendar_report)

    invalid_station_calendar_model =
      Map.put(station_calendar_report, "model", "stale_station_calendar_model")

    assert {:error, station_calendar_model_report} =
             Schema.validate_artifact(invalid_station_calendar_model)

    assert Enum.any?(
             station_calendar_model_report["errors"],
             &(&1["path"] == "$.model")
           )

    invalid_station_calendar_input_count =
      Map.put(station_calendar_report, "input_contact_count", 1.0)

    assert {:error, station_calendar_input_count_report} =
             Schema.validate_artifact(invalid_station_calendar_input_count)

    assert Enum.any?(
             station_calendar_input_count_report["errors"],
             &(&1["path"] == "$.input_contact_count")
           )

    invalid_station_calendar_provider_count =
      Map.put(station_calendar_report, "provider_calendar_contention_group_count", -1)

    assert {:error, station_calendar_provider_count_report} =
             Schema.validate_artifact(invalid_station_calendar_provider_count)

    assert Enum.any?(
             station_calendar_provider_count_report["errors"],
             &(&1["path"] == "$.provider_calendar_contention_group_count")
           )

    station_calendar_provider_contention =
      station_calendar_report
      |> Map.put("provider_calendar_contention_group_count", 1)
      |> Map.put("provider_calendar_contention_groups", [
        %{
          "id" => "station_calendar_provider_contention:equator_prime:1",
          "provider_calendar_contention_status" => "provider_calendar_overlap",
          "required_operator_action" => "review_station_provider_contention",
          "approval_status" => "operator_review_required",
          "ground_station_id" => "equator_prime",
          "entry_count" => 1,
          "entry_ids" => ["equator_reserved_a"],
          "overlap_pairs" => []
        }
      ])

    assert {:ok, %{"schema_contract" => "station_calendar_report.v1"}} =
             Schema.validate_artifact(station_calendar_provider_contention)

    invalid_provider_entry_count =
      put_in(
        station_calendar_provider_contention,
        ["provider_calendar_contention_groups", Access.at(0), "entry_count"],
        -1
      )

    assert {:error, provider_entry_count_report} =
             Schema.validate_artifact(invalid_provider_entry_count)

    assert Enum.any?(
             provider_entry_count_report["errors"],
             &(&1["path"] == "$.provider_calendar_contention_groups[0].entry_count")
           )

    invalid_provider_entry_count_shape =
      put_in(
        station_calendar_provider_contention,
        ["provider_calendar_contention_groups", Access.at(0), "entry_count"],
        1.0
      )

    assert {:error, provider_entry_count_shape_report} =
             Schema.validate_artifact(invalid_provider_entry_count_shape)

    assert Enum.any?(
             provider_entry_count_shape_report["errors"],
             &(&1["path"] == "$.provider_calendar_contention_groups[0].entry_count")
           )

    invalid_station_calendar_limits =
      Map.put(station_calendar_report, "model_limits", ["declared_data_only"])

    assert {:error, station_calendar_limits_validation_report} =
             Schema.validate_artifact(invalid_station_calendar_limits)

    assert Enum.any?(
             station_calendar_limits_validation_report["errors"],
             &(&1["path"] == "$.model_limits")
           )

    invalid_station_calendar_trust_count =
      put_in(
        station_calendar_report,
        ["station_calendar_trust_boundary_status_counts", "declared"],
        99
      )

    assert {:error, station_calendar_trust_validation_report} =
             Schema.validate_artifact(invalid_station_calendar_trust_count)

    assert Enum.any?(
             station_calendar_trust_validation_report["errors"],
             &(&1["path"] == "$.station_calendar_trust_boundary_status_counts")
           )

    invalid_station_calendar_duplicate_count =
      Map.put(station_calendar_report, "duplicate_affected_contact_row_count", 99)

    assert {:error, station_calendar_duplicate_validation_report} =
             Schema.validate_artifact(invalid_station_calendar_duplicate_count)

    assert Enum.any?(
             station_calendar_duplicate_validation_report["errors"],
             &(&1["path"] == "$.duplicate_affected_contact_row_count")
           )

    invalid_station_calendar_affected_fields =
      update_in(
        station_calendar_report,
        ["affected_contacts", Access.at(0)],
        fn row ->
          Map.merge(row, %{
            "station_calendar_directions" => ["downlink", 42],
            "station_calendar_ambiguous_entry_count" => -1,
            "contact_success_factor" => 1.5,
            "source_station_calendar_entry" => %{
              "id" => "bad id",
              "status" => "ambiguous",
              "station_calendar_ambiguous_entry_count" => 2,
              "station_calendar_ambiguous_entry_ids" => ["equator_capacity"]
            }
          })
        end
      )

    assert {:error, station_calendar_affected_validation_report} =
             Schema.validate_artifact(invalid_station_calendar_affected_fields)

    affected_errors = station_calendar_affected_validation_report["errors"]

    assert Enum.any?(
             affected_errors,
             &(&1["path"] == "$.affected_contacts[0].station_calendar_directions[1]")
           )

    assert Enum.any?(
             affected_errors,
             &(&1["path"] == "$.affected_contacts[0].station_calendar_ambiguous_entry_count")
           )

    assert Enum.any?(
             affected_errors,
             &(&1["path"] == "$.affected_contacts[0].contact_success_factor")
           )

    assert Enum.any?(
             affected_errors,
             &(&1["path"] == "$.affected_contacts[0].source_station_calendar_entry.id")
           )
  end

  defp contact_filter_report_capability_assumptions do
    capabilities = ContactFilter.capabilities()

    %{
      "suppressed_directions" => capabilities.suppressed_directions,
      "suppression_reasons" => capabilities.suppression_reasons,
      "station_unavailable_aliases" => capabilities.station_unavailable_aliases,
      "station_availability_precedence" => capabilities.station_availability_precedence,
      "station_capacity_value_paths" =>
        json_capacity_value_paths(capabilities.station_capacity_value_paths),
      "contact_capacity_value_paths" =>
        json_capacity_value_paths(capabilities.contact_capacity_value_paths),
      "provider_direction_aliases" => capabilities.provider_direction_aliases
    }
  end

  defp json_capacity_value_paths(paths) do
    Enum.map(paths, fn %{unit: unit, path: path} ->
      %{"unit" => Atom.to_string(unit), "path" => path}
    end)
  end

  defp read_json!(path) do
    path
    |> File.read!()
    |> :json.decode()
  end
end
