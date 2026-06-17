defmodule OrbitalDynamics.Schema.ContactAllocationContractsTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.Communications.ContactAllocation
  alias OrbitalDynamics.Schema

  test "validates checked-in contact allocation summary fixture" do
    summary = read_json!("study_results/contact_allocation_summary_v1.json")

    report = contact_allocation_summary_fixture_report("validation.contact_allocation_summary")

    generated_summary = OrbitalDynamics.contact_allocation_summary(report)

    assert generated_summary == summary

    assert {:ok, %{"schema_contract" => "contact_allocation_summary.v1"}} =
             Schema.validate_artifact(summary)

    expected_capability_assumptions =
      contact_allocation_summary_capability_assumptions()

    assert %{
             "source_artifact_type" => "contact_allocation_report.v1",
             "source" => "validation.contact_allocation_summary",
             "input_contact_count" => 3,
             "allocated_contact_count" => 1,
             "returned_allocated_contact_count" => 1,
             "deferred_contact_count" => 1,
             "blocked_contact_count" => 1,
             "allocation_status_counts" => %{
               "allocated" => 1,
               "blocked" => 1,
               "deferred" => 1
             },
             "allocation_reason_counts" => %{
               "ground_station_reserved" => 1,
               "same_station_contention" => 1,
               "selected_by_contention_resolution" => 1
             },
             "contact_ids_by_allocation_reason" => %{
               "ground_station_reserved" => ["dl_3"],
               "same_station_contention" => ["dl_2"],
               "selected_by_contention_resolution" => ["dl_1"]
             },
             "allocated_contact_ids" => ["dl_1"],
             "deferred_contact_ids" => ["dl_2"],
             "blocked_contact_ids" => ["dl_3"],
             "station_pressure_contact_ids_by_ground_station_id" => %{
               "equator_prime" => ["dl_3"]
             },
             "station_pressure_contact_ids_by_availability" => %{"reserved" => ["dl_3"]},
             "station_pressure_contact_ids_by_status" => %{"reserved" => ["dl_3"]},
             "station_pressure_contact_counts_by_status" => %{"reserved" => 1},
             "station_reservation_ids" => ["reservation_1"],
             "station_reservation_expires_at_s" => [420.0],
             "station_reservation_expiration_status_counts" => %{"declared" => 1},
             "station_reservation_contact_ids_by_match_status" => %{"overlap" => ["dl_3"]},
             "station_reservation_ids_by_match_status" => %{"overlap" => ["reservation_1"]},
             "review_contact_ids" => ["dl_1", "dl_2", "dl_3"],
             "review_row_count" => 3,
             "assumptions" => %{
               "execution_boundary" =>
                 "artifact_only_no_provider_reservation_or_schedule_mutation",
               "operator_authority" => "not_granted_by_summary",
               "source" => "contact_allocation_report.v1"
             }
           } = summary

    assert summary["model_limits"] ==
             ContactAllocation.capabilities().known_limits
             |> Enum.map(&Atom.to_string/1)

    assert Map.take(summary["assumptions"], Map.keys(expected_capability_assumptions)) ==
             expected_capability_assumptions

    assert {:ok, schema} = Schema.json_schema("contact_allocation_summary.v1")

    assumptions_schema = get_in(schema, ["properties", "assumptions", "properties"])

    for {field, expected_value} <- expected_capability_assumptions do
      assert get_in(assumptions_schema, [field, "const"]) == expected_value
    end
  end

  test "validates checked-in contact allocation station pressure summary fixture" do
    summary =
      read_json!("study_results/contact_allocation_station_pressure_summary_v1.json")

    report =
      contact_allocation_summary_fixture_report(
        "validation.contact_allocation_station_pressure_summary"
      )

    generated_summary = OrbitalDynamics.contact_allocation_station_pressure_summary(report)

    assert generated_summary == summary

    assert {:ok, %{"schema_contract" => "contact_allocation_station_pressure_summary.v1"}} =
             Schema.validate_artifact(summary)

    expected_capability_assumptions =
      contact_allocation_station_pressure_capability_assumptions()

    expected_station_unavailable_aliases =
      expected_capability_assumptions["station_unavailable_aliases"]

    expected_station_blocking_availability =
      expected_capability_assumptions["station_blocking_availability"]

    expected_station_availability_precedence =
      expected_capability_assumptions["station_availability_precedence"]

    expected_provider_direction_aliases =
      expected_capability_assumptions["provider_direction_aliases"]

    assert %{
             "source_artifact_type" => "contact_allocation_report.v1",
             "source" => "validation.contact_allocation_station_pressure_summary",
             "input_contact_count" => 3,
             "station_pressure_contact_count" => 1,
             "station_pressure_review_contact_count" => 1,
             "station_pressure_contact_ids" => ["dl_3"],
             "station_pressure_review_contact_ids" => ["dl_3"],
             "station_pressure_contact_ids_by_ground_station_id" => %{
               "equator_prime" => ["dl_3"]
             },
             "station_pressure_contact_counts_by_ground_station_id" => %{
               "equator_prime" => 1
             },
             "station_pressure_contact_ids_by_availability" => %{"reserved" => ["dl_3"]},
             "station_pressure_contact_counts_by_availability" => %{"reserved" => 1},
             "station_pressure_contact_ids_by_status" => %{"reserved" => ["dl_3"]},
             "station_pressure_contact_counts_by_status" => %{"reserved" => 1},
             "station_pressure_contact_ids_by_precedence_availability" => %{
               "reserved" => ["dl_3"]
             },
             "station_pressure_contact_counts_by_precedence_availability" => %{
               "reserved" => 1
             },
             "station_pressure_contact_ids_by_precedence_rank" => %{"1" => ["dl_3"]},
             "station_pressure_contact_counts_by_precedence_rank" => %{"1" => 1},
             "station_pressure_contact_ids_by_direction_and_ground_station_id" => %{
               "downlink" => %{"equator_prime" => ["dl_3"]}
             },
             "assumptions" => %{
               "execution_boundary" =>
                 "artifact_only_no_provider_reservation_or_schedule_mutation",
               "operator_authority" => "not_granted_by_station_pressure_summary",
               "source" => "contact_allocation_report.v1",
               "station_unavailable_aliases" => ^expected_station_unavailable_aliases,
               "station_blocking_availability" => ^expected_station_blocking_availability,
               "station_availability_precedence" => ^expected_station_availability_precedence,
               "provider_direction_aliases" => ^expected_provider_direction_aliases
             }
           } = summary

    assert Enum.map(summary["review_rows"], & &1["contact_id"]) == ["dl_3"]

    assert summary["model_limits"] ==
             ContactAllocation.capabilities().known_limits
             |> Enum.map(&Atom.to_string/1)

    assert {:ok, schema} = Schema.json_schema("contact_allocation_station_pressure_summary.v1")

    assert get_in(schema, [
             "properties",
             "assumptions",
             "properties",
             "station_unavailable_aliases",
             "const"
           ]) == expected_station_unavailable_aliases

    assert get_in(schema, [
             "properties",
             "assumptions",
             "properties",
             "station_blocking_availability",
             "const"
           ]) == expected_station_blocking_availability

    assert get_in(schema, [
             "properties",
             "assumptions",
             "properties",
             "station_availability_precedence",
             "const"
           ]) == expected_station_availability_precedence

    assert get_in(schema, [
             "properties",
             "assumptions",
             "properties",
             "provider_direction_aliases",
             "const"
           ]) == expected_provider_direction_aliases
  end

  test "validates checked-in contact allocation capacity pack summary fixture" do
    summary = read_json!("study_results/contact_allocation_capacity_pack_summary_v1.json")

    report = contact_allocation_capacity_pack_summary_fixture_report()

    generated_summary = OrbitalDynamics.contact_allocation_capacity_pack_summary(report)
    expected_capability_assumptions = contact_allocation_capacity_pack_capability_assumptions()
    expected_capacity_pack_statuses = expected_capability_assumptions["capacity_pack_statuses"]

    expected_reduced_capacity_pack_statuses =
      expected_capability_assumptions["reduced_capacity_pack_statuses"]

    expected_required_capacity_fraction_source_values =
      expected_capability_assumptions["required_capacity_fraction_source_values"]

    expected_required_capacity_value_paths =
      expected_capability_assumptions["required_capacity_value_paths"]

    expected_default_required_capacity_value_paths =
      expected_capability_assumptions["default_required_capacity_value_paths"]

    assert generated_summary == summary

    assert {:ok, %{"schema_contract" => "contact_allocation_capacity_pack_summary.v1"}} =
             Schema.validate_artifact(summary)

    pack_group_id = "capacity_pack:equator_prime:downlink:100_160"

    assert %{
             "source_artifact_type" => "contact_allocation_report.v1",
             "source" => "validation.contact_allocation_capacity_pack_summary",
             "input_contact_count" => 3,
             "capacity_pack_contact_count" => 3,
             "capacity_pack_review_status" => "review_required",
             "reduced_capacity_pack_group_count" => 1,
             "reduced_capacity_pack_status_counts" => %{"capacity_limited" => 1},
             "capacity_pack_status_counts" => %{
               "deferred_by_reduced_station_capacity_pack" => 1,
               "selected_by_contention_resolution" => 1,
               "selected_by_reduced_station_capacity_pack" => 1
             },
             "capacity_pack_contact_ids_by_status" => %{
               "deferred_by_reduced_station_capacity_pack" => ["dl_capacity_overflow"],
               "selected_by_contention_resolution" => ["dl_capacity_primary"],
               "selected_by_reduced_station_capacity_pack" => ["dl_capacity_secondary"]
             },
             "capacity_pack_contact_ids_by_ground_station_id" => %{
               "equator_prime" => [
                 "dl_capacity_overflow",
                 "dl_capacity_primary",
                 "dl_capacity_secondary"
               ]
             },
             "capacity_pack_selected_contact_ids_by_ground_station_id" => %{
               "equator_prime" => ["dl_capacity_primary", "dl_capacity_secondary"]
             },
             "capacity_pack_deferred_contact_ids_by_ground_station_id" => %{
               "equator_prime" => ["dl_capacity_overflow"]
             },
             "capacity_pack_required_capacity_fraction" => 0.75,
             "capacity_pack_selected_required_capacity_fraction" => 0.5,
             "capacity_pack_deferred_required_capacity_fraction" => 0.25,
             "capacity_pack_required_capacity_fraction_by_status" => %{
               "deferred_by_reduced_station_capacity_pack" => 0.25,
               "selected_by_contention_resolution" => 0.25,
               "selected_by_reduced_station_capacity_pack" => 0.25
             },
             "capacity_pack_required_capacity_fraction_by_ground_station_id" => %{
               "equator_prime" => 0.75
             },
             "capacity_pack_selected_required_capacity_fraction_by_ground_station_id" => %{
               "equator_prime" => 0.5
             },
             "capacity_pack_deferred_required_capacity_fraction_by_ground_station_id" => %{
               "equator_prime" => 0.25
             },
             "capacity_pack_required_capacity_fraction_by_direction" => %{
               "downlink" => 0.75
             },
             "capacity_pack_selected_required_capacity_fraction_by_direction" => %{
               "downlink" => 0.5
             },
             "capacity_pack_deferred_required_capacity_fraction_by_direction" => %{
               "downlink" => 0.25
             },
             "required_capacity_fraction_source_counts" => %{
               "contact_required_capacity_fraction" => 3
             },
             "required_capacity_fraction_contact_ids_by_source" => %{
               "contact_required_capacity_fraction" => [
                 "dl_capacity_overflow",
                 "dl_capacity_primary",
                 "dl_capacity_secondary"
               ]
             },
             "capacity_pack_contact_ids_by_direction" => %{
               "downlink" => [
                 "dl_capacity_overflow",
                 "dl_capacity_primary",
                 "dl_capacity_secondary"
               ]
             },
             "capacity_pack_selected_contact_ids_by_direction" => %{
               "downlink" => ["dl_capacity_primary", "dl_capacity_secondary"]
             },
             "capacity_pack_deferred_contact_ids_by_direction" => %{
               "downlink" => ["dl_capacity_overflow"]
             },
             "reduced_capacity_packed_contact_ids" => ["dl_capacity_secondary"],
             "reduced_capacity_deferred_contact_ids" => ["dl_capacity_overflow"],
             "capacity_pack_group_ids" => [^pack_group_id],
             "capacity_pack_group_ids_by_status" => %{"capacity_limited" => [^pack_group_id]},
             "assumptions" => %{
               "execution_boundary" =>
                 "artifact_only_no_provider_reservation_or_schedule_mutation",
               "operator_authority" => "not_granted_by_capacity_pack_summary",
               "source" => "contact_allocation_report.v1",
               "capacity_pack_statuses" => ^expected_capacity_pack_statuses,
               "reduced_capacity_pack_statuses" => ^expected_reduced_capacity_pack_statuses,
               "required_capacity_fraction_source_values" =>
                 ^expected_required_capacity_fraction_source_values,
               "required_capacity_value_paths" => ^expected_required_capacity_value_paths,
               "default_required_capacity_value_paths" =>
                 ^expected_default_required_capacity_value_paths
             }
           } = summary

    assert [%{"contention_group_id" => ^pack_group_id, "pack_status" => "capacity_limited"}] =
             summary["reduced_capacity_pack_groups"]

    assert Enum.map(summary["review_rows"], & &1["contact_id"]) == [
             "dl_capacity_primary",
             "dl_capacity_secondary",
             "dl_capacity_overflow"
           ]

    assert summary["model_limits"] ==
             ContactAllocation.capabilities().known_limits
             |> Enum.map(&Atom.to_string/1)

    assert {:ok, schema} = Schema.json_schema("contact_allocation_capacity_pack_summary.v1")

    assert get_in(schema, [
             "properties",
             "capacity_pack_required_capacity_fraction_by_direction",
             "additionalProperties",
             "minimum"
           ]) == 0.0

    assert get_in(schema, [
             "properties",
             "capacity_pack_contact_ids_by_direction",
             "additionalProperties",
             "items",
             "pattern"
           ]) == Schema.identity_policy()["stable_id_pattern"]

    assert get_in(schema, [
             "properties",
             "assumptions",
             "properties",
             "capacity_pack_statuses",
             "const"
           ]) == expected_capability_assumptions["capacity_pack_statuses"]

    assert get_in(schema, [
             "properties",
             "assumptions",
             "properties",
             "default_required_capacity_value_paths",
             "const"
           ]) == expected_capability_assumptions["default_required_capacity_value_paths"]
  end

  test "validates checked-in contact allocation reservation conflict summary fixture" do
    summary =
      read_json!("study_results/contact_allocation_reservation_conflict_summary_v1.json")

    report = contact_allocation_reservation_conflict_summary_fixture_report()

    generated_summary =
      OrbitalDynamics.contact_allocation_reservation_conflict_summary(report, now_s: 400.0)

    expected_capability_assumptions =
      contact_allocation_reservation_conflict_capability_assumptions()

    expected_station_reservation_match_statuses =
      expected_capability_assumptions["station_reservation_match_statuses"]

    expected_reservation_conflict_match_statuses =
      expected_capability_assumptions["reservation_conflict_match_statuses"]

    expected_station_reservation_expiration_statuses =
      expected_capability_assumptions["station_reservation_expiration_statuses"]

    expected_provider_direction_aliases =
      expected_capability_assumptions["provider_direction_aliases"]

    assert generated_summary == summary

    assert {:ok, %{"schema_contract" => "contact_allocation_reservation_conflict_summary.v1"}} =
             Schema.validate_artifact(summary)

    assert %{
             "source_artifact_type" => "contact_allocation_report.v1",
             "source" => "validation.contact_allocation_reservation_conflict_summary",
             "input_contact_count" => 2,
             "station_reservation_contact_count" => 2,
             "reservation_conflict_contact_count" => 1,
             "reservation_review_contact_count" => 1,
             "station_reservation_match_status_counts" => %{
               "matched" => 1,
               "overlap" => 1
             },
             "reservation_conflict_match_status_counts" => %{"overlap" => 1},
             "station_reservation_status_counts" => %{"confirmed" => 2},
             "station_reserved_by_counts" => %{"ops_team_b" => 2},
             "station_reservation_ids" => ["reservation_1"],
             "station_reservation_expires_at_s" => [360.0],
             "station_reservation_expiration_now_s" => 400.0,
             "station_reservation_expiration_status_counts" => %{"expired" => 2},
             "earliest_station_reservation_expires_at_s" => 360.0,
             "reservation_conflict_contact_ids" => ["dl_reserved_intruder"],
             "reservation_review_contact_ids" => ["dl_reserved_intruder"],
             "station_reservation_contact_ids_by_match_status" => %{
               "matched" => ["dl_reserved_owner"],
               "overlap" => ["dl_reserved_intruder"]
             },
             "reservation_conflict_contact_ids_by_match_status" => %{
               "overlap" => ["dl_reserved_intruder"]
             },
             "reservation_conflict_contact_ids_by_direction" => %{
               "downlink" => ["dl_reserved_intruder"]
             },
             "reservation_conflict_contact_ids_by_direction_and_ground_station_id" => %{
               "downlink" => %{"equator_prime" => ["dl_reserved_intruder"]}
             },
             "station_reservation_ids_by_expiration_status" => %{
               "expired" => ["reservation_1"]
             },
             "assumptions" => %{
               "execution_boundary" =>
                 "artifact_only_no_provider_reservation_or_schedule_mutation",
               "operator_authority" => "not_granted_by_reservation_conflict_summary",
               "source" => "contact_allocation_report.v1",
               "station_reservation_match_statuses" =>
                 ^expected_station_reservation_match_statuses,
               "reservation_conflict_match_statuses" =>
                 ^expected_reservation_conflict_match_statuses,
               "station_reservation_expiration_statuses" =>
                 ^expected_station_reservation_expiration_statuses,
               "provider_direction_aliases" => ^expected_provider_direction_aliases
             }
           } = summary

    assert Enum.map(summary["reservation_conflict_rows"], & &1["contact_id"]) == [
             "dl_reserved_intruder"
           ]

    assert Enum.map(summary["reservation_review_rows"], & &1["contact_id"]) == [
             "dl_reserved_intruder"
           ]

    assert summary["model_limits"] ==
             ContactAllocation.capabilities().known_limits
             |> Enum.map(&Atom.to_string/1)

    assert {:ok, schema} =
             Schema.json_schema("contact_allocation_reservation_conflict_summary.v1")

    assert get_in(schema, [
             "properties",
             "assumptions",
             "properties",
             "station_reservation_match_statuses",
             "const"
           ]) == expected_capability_assumptions["station_reservation_match_statuses"]

    assert get_in(schema, [
             "properties",
             "assumptions",
             "properties",
             "reservation_conflict_match_statuses",
             "const"
           ]) == expected_capability_assumptions["reservation_conflict_match_statuses"]

    assert get_in(schema, [
             "properties",
             "assumptions",
             "properties",
             "station_reservation_expiration_statuses",
             "const"
           ]) == expected_capability_assumptions["station_reservation_expiration_statuses"]

    assert get_in(schema, [
             "properties",
             "assumptions",
             "properties",
             "provider_direction_aliases",
             "const"
           ]) == expected_capability_assumptions["provider_direction_aliases"]
  end

  test "validates checked-in provider reservation request summary fixture" do
    summary =
      read_json!("study_results/contact_allocation_provider_reservation_request_summary_v1.json")

    contacts = [
      %{
        id: :dl_reserved_owner,
        type: :downlink,
        direction: :downlink,
        scenario_id: :leo_1,
        spacecraft_id: :sat_ready,
        ground_station_id: :equator_prime,
        source_window_id: :window_dl_reserved_owner,
        starts_at_s: 100.0,
        ends_at_s: 160.0,
        station_reservation_id: :reservation_1,
        score: 5
      },
      %{
        id: :dl_review_overlap,
        type: :command,
        direction: :command,
        scenario_id: :leo_1,
        spacecraft_id: :sat_ready,
        ground_station_id: :equator_prime,
        source_window_id: :window_dl_review_overlap,
        starts_at_s: 210.0,
        ends_at_s: 240.0,
        station_reservation_id: :reservation_review,
        station_reservation_match_status: :overlap,
        station_reservation_status: :confirmed,
        score: 4
      },
      %{
        id: :dl_reserved_intruder,
        type: :tracking,
        direction: :tracking,
        scenario_id: :leo_1,
        spacecraft_id: :sat_ready,
        ground_station_id: :equator_prime,
        source_window_id: :window_dl_reserved_intruder,
        starts_at_s: 100.0,
        ends_at_s: 160.0,
        score: 3
      },
      %{
        id: :dl_unreserved,
        type: :uplink,
        direction: :uplink,
        scenario_id: :leo_1,
        spacecraft_id: :sat_ready,
        ground_station_id: :equator_prime,
        source_window_id: :window_dl_unreserved,
        starts_at_s: 320.0,
        ends_at_s: 360.0,
        score: 2
      }
    ]

    ground_network = [
      %{
        ground_station_id: :equator_prime,
        status: :reserved,
        starts_at_s: 90.0,
        ends_at_s: 170.0,
        reservation_id: :reservation_1,
        reserved_by: "ops_team_b",
        reservation_status: :confirmed,
        reservation_expires_at_s: 360.0
      }
    ]

    generated_summary =
      OrbitalDynamics.contact_allocation_provider_reservation_request_summary(
        contacts,
        ground_network,
        source: "validation.provider_reservation_request_summary"
      )

    expected_capability_assumptions =
      contact_allocation_provider_reservation_request_capability_assumptions()

    expected_provider_reservation_request_statuses =
      expected_capability_assumptions["provider_reservation_request_statuses"]

    expected_station_reservation_match_statuses =
      expected_capability_assumptions["station_reservation_match_statuses"]

    expected_provider_direction_aliases =
      expected_capability_assumptions["provider_direction_aliases"]

    assert generated_summary == summary

    assert {:ok,
            %{"schema_contract" => "contact_allocation_provider_reservation_request_summary.v1"}} =
             Schema.validate_artifact(summary)

    assert %{
             "source_artifact_type" => "contact_allocation_report.v1",
             "source" => "validation.provider_reservation_request_summary",
             "input_contact_count" => 4,
             "provider_reservation_candidate_contact_count" => 2,
             "provider_reservation_request_contact_count" => 1,
             "provider_reservation_review_contact_count" => 1,
             "provider_reservation_no_request_contact_count" => 2,
             "provider_reservation_request_status" => "review_required",
             "provider_reservation_request_contact_ids" => ["dl_reserved_owner"],
             "provider_reservation_review_contact_ids" => ["dl_review_overlap"],
             "provider_reservation_no_request_contact_ids" => [
               "dl_reserved_intruder",
               "dl_unreserved"
             ],
             "provider_reservation_request_contact_ids_by_direction" => %{
               "downlink" => ["dl_reserved_owner"]
             },
             "provider_reservation_review_contact_ids_by_direction" => %{
               "command" => ["dl_review_overlap"]
             },
             "provider_reservation_no_request_contact_ids_by_direction" => %{
               "tracking" => ["dl_reserved_intruder"],
               "uplink" => ["dl_unreserved"]
             },
             "provider_reservation_no_request_contact_ids_by_direction_and_ground_station_id" =>
               %{
                 "tracking" => %{"equator_prime" => ["dl_reserved_intruder"]},
                 "uplink" => %{"equator_prime" => ["dl_unreserved"]}
               },
             "provider_reservation_request_contact_ids_by_direction_and_ground_station_id" => %{
               "downlink" => %{"equator_prime" => ["dl_reserved_owner"]}
             },
             "provider_reservation_review_contact_ids_by_direction_and_ground_station_id" => %{
               "command" => %{"equator_prime" => ["dl_review_overlap"]}
             },
             "provider_reservation_request_ids_by_match_status" => %{
               "matched" => ["reservation_1"]
             },
             "provider_reservation_review_ids_by_match_status" => %{
               "overlap" => ["reservation_review"]
             },
             "assumptions" => %{
               "execution_boundary" =>
                 "artifact_only_no_provider_reservation_or_schedule_mutation",
               "source" => "contact_allocation_report.v1",
               "provider_reservation_execution" => "not_performed_by_summary",
               "operator_authority" => "not_granted_by_provider_reservation_request_summary",
               "provider_reservation_request_statuses" =>
                 ^expected_provider_reservation_request_statuses,
               "station_reservation_match_statuses" =>
                 ^expected_station_reservation_match_statuses,
               "provider_direction_aliases" => ^expected_provider_direction_aliases
             }
           } = summary

    assert {:ok, schema} =
             Schema.json_schema("contact_allocation_provider_reservation_request_summary.v1")

    assert get_in(schema, [
             "properties",
             "assumptions",
             "properties",
             "provider_reservation_request_statuses",
             "const"
           ]) == expected_capability_assumptions["provider_reservation_request_statuses"]

    assert get_in(schema, [
             "properties",
             "assumptions",
             "properties",
             "station_reservation_match_statuses",
             "const"
           ]) == expected_capability_assumptions["station_reservation_match_statuses"]

    assert get_in(schema, [
             "properties",
             "assumptions",
             "properties",
             "provider_direction_aliases",
             "const"
           ]) == expected_capability_assumptions["provider_direction_aliases"]
  end

  test "validates checked-in contact allocation report fixture regenerates through public facade" do
    report = read_json!("study_results/contact_allocation_report_v1.json")

    contacts = [
      %{
        id: :dl_1,
        type: :downlink,
        scenario_id: :leo_1,
        ground_station_id: :equator_prime,
        spacecraft_id: :sat_ready,
        source_window_id: :window_dl_1,
        starts_at_s: 100.0,
        ends_at_s: 160.0,
        score: 5.0
      },
      %{
        id: :dl_2,
        type: :downlink,
        scenario_id: :leo_1,
        ground_station_id: :equator_prime,
        spacecraft_id: :sat_ready,
        source_window_id: :window_dl_2,
        starts_at_s: 120.0,
        ends_at_s: 180.0,
        score: 2.0
      },
      %{
        id: :dl_3,
        type: :downlink,
        scenario_id: :leo_1,
        ground_station_id: :equator_prime,
        spacecraft_id: :sat_ready,
        source_window_id: :window_dl_3,
        starts_at_s: 250.0,
        ends_at_s: 280.0,
        score: 4.0
      },
      %{
        id: :cmd_unavailable,
        type: :command,
        scenario_id: :leo_1,
        ground_station_id: :equator_prime,
        spacecraft_id: :sat_ready,
        source_window_id: :window_cmd_unavailable,
        starts_at_s: 400.0,
        ends_at_s: 430.0
      },
      %{
        id: :dl_resource_blocked,
        type: :downlink,
        scenario_id: :leo_1,
        ground_station_id: :equator_prime,
        spacecraft_id: :sat_low_resource,
        source_window_id: :window_dl_resource_blocked,
        starts_at_s: 500.0,
        ends_at_s: 560.0
      }
    ]

    ground_network = [
      %{
        ground_station_id: :equator_prime,
        status: :reserved,
        starts_at_s: 240.0,
        ends_at_s: 300.0,
        reservation_id: :reservation_1,
        reserved_by: "network_partner",
        reservation_status: :reserved,
        reservation_hold_expires_at_s: 420.0
      },
      %{
        ground_station_id: :equator_prime,
        status: :unavailable,
        starts_at_s: 390.0,
        ends_at_s: 440.0
      }
    ]

    resource_summaries = [
      %{
        spacecraft_id: :sat_low_resource,
        antenna_available: false,
        power_margin: 0.8,
        source_quality: :operator_supplied,
        provenance: %{trust_boundary: :operator_declared_resource_summary}
      }
    ]

    generated_report =
      OrbitalDynamics.contact_allocation_report(
        contacts,
        ground_network,
        source: "fixture.contact_allocation",
        approval_policy: %{policy_bundle_id: "ground_network_allocation_v1"},
        resource_summaries: resource_summaries
      )

    assert generated_report == report

    assert {:ok, %{"schema_contract" => "contact_allocation_report.v1"}} =
             Schema.validate_artifact(report)

    assert report["model"] == "deterministic_station_contact_allocation"
    assert report["source"] == "fixture.contact_allocation"

    assert report["model_limits"] == [
             "artifact_level_only",
             "declared_ground_network_only",
             "optional_externally_supplied_resource_summary",
             "no_full_realized_contact_reconciliation",
             "no_provider_reservation",
             "no_schedule_mutation",
             "no_approval_workflow",
             "no_link_budget_model"
           ]

    assert report["assumptions"] == %{
             "contact_status_model" =>
               "terminal_or_source_policy_blocked_contacts_are_audited_as_blocked_without_station_allocation",
             "contention_resolution" => "deterministic_recommendation_requires_operator_review",
             "default_reduced_capacity_requirement" =>
               "when configured, reduced-capacity packing may use a declared default contact capacity requirement for contacts without explicit per-contact capacity demand",
             "duplicate_contact_id" =>
               "duplicate contact IDs are blocked before contention allocation to preserve deterministic identity joins",
             "effective_allocation_status" =>
               "effective_allocation_status reflects whether allocated rows are usable after policy classification",
             "execution_boundary" => "artifact_only_no_provider_reservation_or_schedule_mutation",
             "ground_network_source" => "declared_ground_network_or_station_calendar_provider",
             "invalid_contact_input" =>
               "contact-like inputs missing required allocation identity, station, or timing fields are blocked for operator review instead of being silently dropped",
             "resource_filter" =>
               "optional resource summaries suppress unavailable resource contacts before station allocation",
             "returned_allocated_contacts" =>
               "returned contacts exclude allocated rows whose approval policy classification is blocked_by_policy"
           }

    assert %{
             "input_contact_count" => 5,
             "allocated_contact_count" => 1,
             "blocked_contact_count" => 3,
             "deferred_contact_count" => 1,
             "returned_allocated_contact_count" => 1,
             "policy_blocked_allocated_contact_count" => 0,
             "invalid_contact_input_count" => 0,
             "duplicate_contact_candidate_count" => 0,
             "duplicate_contact_id_count" => 0,
             "resource_blocked_contact_count" => 1,
             "status_blocked_contact_count" => 0,
             "reduced_capacity_pack_group_count" => 0
           } = report

    assert report["allocation_status_counts"] == %{
             "allocated" => 1,
             "blocked" => 3,
             "deferred" => 1
           }

    assert report["effective_allocation_status_counts"] == %{
             "allocated" => 1,
             "blocked" => 3,
             "deferred" => 1
           }

    assert report["allocation_reason_counts"] == %{
             "antenna_unavailable" => 1,
             "ground_station_reserved" => 1,
             "ground_station_unavailable" => 1,
             "same_station_contention" => 1,
             "selected_by_contention_resolution" => 1
           }

    assert report["resource_blocking_dimension_counts"] == %{"antenna" => 1}
    assert report["resource_blocked_contact_ids"] == ["dl_resource_blocked"]

    assert report["resource_blocked_contact_ids_by_blocking_dimension"] == %{
             "antenna" => ["dl_resource_blocked"]
           }

    assert report["resource_blocked_contact_ids_by_spacecraft_id"] == %{
             "sat_low_resource" => ["dl_resource_blocked"]
           }

    assert report["station_reservation_expiration_status_counts"] == %{"declared" => 1}
    assert report["station_reservation_declared_expiration_contact_count"] == 1
    assert report["station_reservation_missing_expiration_contact_count"] == 0
    assert report["earliest_station_reservation_expires_at_s"] == 420.0

    assert report["station_reservation_contact_ids_by_expiration_status"] == %{
             "declared" => ["dl_3"]
           }

    assert report["station_reservation_ids_by_expiration_status"] == %{
             "declared" => ["reservation_1"]
           }

    assert report["station_pressure_contact_counts_by_availability"] == %{
             "reserved" => 1,
             "unavailable" => 1
           }

    assert report["station_pressure_contact_counts_by_precedence_availability"] == %{
             "reserved" => 1,
             "unavailable" => 1
           }

    assert report["station_pressure_contact_ids_by_ground_station_id"] == %{
             "equator_prime" => ["cmd_unavailable", "dl_3"]
           }

    assert report["station_pressure_contact_ids_by_direction_and_ground_station_id"] == %{
             "command" => %{"equator_prime" => ["cmd_unavailable"]},
             "downlink" => %{"equator_prime" => ["dl_3"]}
           }

    assert report["capacity_pack_status_counts"] == %{}
    assert report["reduced_capacity_pack_groups"] == []
    assert report["reduced_capacity_packed_contact_ids"] == []
    assert report["reduced_capacity_deferred_contact_ids"] == []

    rows_by_contact_id = Map.new(report["rows"], &{&1["contact_id"], &1})

    assert rows_by_contact_id["dl_1"]["allocation_status"] == "allocated"
    assert rows_by_contact_id["dl_1"]["allocation_reason"] == "selected_by_contention_resolution"

    assert rows_by_contact_id["dl_2"]["allocation_status"] == "deferred"
    assert rows_by_contact_id["dl_2"]["allocation_reason"] == "same_station_contention"
    assert rows_by_contact_id["dl_2"]["selected_contact_id"] == "dl_1"

    assert rows_by_contact_id["dl_3"]["allocation_status"] == "blocked"
    assert rows_by_contact_id["dl_3"]["allocation_reason"] == "ground_station_reserved"
    assert rows_by_contact_id["dl_3"]["station_availability"] == "reserved"
    assert rows_by_contact_id["dl_3"]["station_reservation_id"] == "reservation_1"
    assert rows_by_contact_id["dl_3"]["station_reserved_by"] == "network_partner"
    assert rows_by_contact_id["dl_3"]["station_reservation_expires_at_s"] == 420.0

    assert rows_by_contact_id["cmd_unavailable"]["allocation_status"] == "blocked"

    assert rows_by_contact_id["cmd_unavailable"]["allocation_reason"] ==
             "ground_station_unavailable"

    assert rows_by_contact_id["cmd_unavailable"]["station_availability"] == "unavailable"

    assert rows_by_contact_id["dl_resource_blocked"]["allocation_status"] == "blocked"
    assert rows_by_contact_id["dl_resource_blocked"]["allocation_reason"] == "antenna_unavailable"
    assert rows_by_contact_id["dl_resource_blocked"]["resource_blocking_dimension"] == "antenna"
    assert rows_by_contact_id["dl_resource_blocked"]["antenna_available"] == false
  end

  test "validates checked-in contact allocation capacity-pack report fixture regenerates through public facade" do
    report = read_json!("study_results/contact_allocation_capacity_pack_report_v1.json")

    contacts = [
      %{
        id: :dl_capacity_primary,
        type: :downlink,
        scenario_id: :leo_1,
        ground_station_id: :equator_prime,
        spacecraft_id: :sat_ready,
        starts_at_s: 100.0,
        ends_at_s: 160.0,
        score: 10.0,
        required_capacity_fraction: 0.25
      },
      %{
        id: :dl_capacity_secondary,
        type: :downlink,
        scenario_id: :leo_1,
        ground_station_id: :equator_prime,
        spacecraft_id: :sat_ready,
        starts_at_s: 110.0,
        ends_at_s: 150.0,
        score: 8.0,
        required_capacity_fraction: 0.25
      },
      %{
        id: :dl_capacity_overflow,
        type: :downlink,
        scenario_id: :leo_1,
        ground_station_id: :equator_prime,
        spacecraft_id: :sat_ready,
        starts_at_s: 120.0,
        ends_at_s: 155.0,
        score: 6.0,
        required_capacity_fraction: 0.25
      }
    ]

    ground_network = [
      %{
        id: :equator_capacity,
        ground_station_id: :equator_prime,
        status: :available,
        availability: :reduced_capacity,
        starts_at_s: 90.0,
        ends_at_s: 170.0,
        capacity_fraction: 0.5,
        provenance: %{
          source: :station_calendar_provider,
          provider_id: :ops_calendar,
          trust_boundary: :operator_declared_station_calendar
        }
      }
    ]

    generated_report =
      OrbitalDynamics.contact_allocation_report(
        contacts,
        ground_network,
        source: "fixture.contact_allocation.capacity_pack",
        approval_policy: %{policy_bundle_id: "ground_network_allocation_v1"}
      )

    assert generated_report == report

    assert {:ok, %{"schema_contract" => "contact_allocation_report.v1"}} =
             Schema.validate_artifact(report)

    assert report["model"] == "deterministic_station_contact_allocation"
    assert report["source"] == "fixture.contact_allocation.capacity_pack"

    assert report["model_limits"] == [
             "artifact_level_only",
             "declared_ground_network_only",
             "optional_externally_supplied_resource_summary",
             "no_full_realized_contact_reconciliation",
             "no_provider_reservation",
             "no_schedule_mutation",
             "no_approval_workflow",
             "no_link_budget_model"
           ]

    assert report["assumptions"]["execution_boundary"] ==
             "artifact_only_no_provider_reservation_or_schedule_mutation"

    assert %{
             "input_contact_count" => 3,
             "allocated_contact_count" => 2,
             "blocked_contact_count" => 0,
             "deferred_contact_count" => 1,
             "returned_allocated_contact_count" => 2,
             "policy_blocked_allocated_contact_count" => 0,
             "invalid_contact_input_count" => 0,
             "duplicate_contact_candidate_count" => 0,
             "duplicate_contact_id_count" => 0,
             "resource_blocked_contact_count" => 0,
             "status_blocked_contact_count" => 0,
             "reduced_capacity_pack_group_count" => 1
           } = report

    assert report["allocation_status_counts"] == %{
             "allocated" => 2,
             "deferred" => 1
           }

    assert report["effective_allocation_status_counts"] == %{
             "allocated" => 2,
             "deferred" => 1
           }

    assert report["allocation_reason_counts"] == %{
             "same_station_contention" => 1,
             "selected_by_contention_resolution" => 1,
             "selected_by_reduced_station_capacity_pack" => 1
           }

    assert report["capacity_pack_status_counts"] == %{
             "deferred_by_reduced_station_capacity_pack" => 1,
             "selected_by_contention_resolution" => 1,
             "selected_by_reduced_station_capacity_pack" => 1
           }

    assert report["capacity_pack_contact_ids_by_status"] == %{
             "deferred_by_reduced_station_capacity_pack" => ["dl_capacity_overflow"],
             "selected_by_contention_resolution" => ["dl_capacity_primary"],
             "selected_by_reduced_station_capacity_pack" => ["dl_capacity_secondary"]
           }

    assert report["capacity_pack_required_capacity_fraction"] == 0.75
    assert report["capacity_pack_selected_required_capacity_fraction"] == 0.5
    assert report["capacity_pack_deferred_required_capacity_fraction"] == 0.25

    assert report["capacity_pack_required_capacity_fraction_by_status"] == %{
             "deferred_by_reduced_station_capacity_pack" => 0.25,
             "selected_by_contention_resolution" => 0.25,
             "selected_by_reduced_station_capacity_pack" => 0.25
           }

    assert report["capacity_pack_required_capacity_fraction_by_ground_station_id"] == %{
             "equator_prime" => 0.75
           }

    assert report["capacity_pack_selected_required_capacity_fraction_by_ground_station_id"] == %{
             "equator_prime" => 0.5
           }

    assert report["capacity_pack_deferred_required_capacity_fraction_by_ground_station_id"] == %{
             "equator_prime" => 0.25
           }

    assert report["required_capacity_fraction_source_counts"] == %{
             "contact_required_capacity_fraction" => 3
           }

    assert report["required_capacity_fraction_contact_ids_by_source"] == %{
             "contact_required_capacity_fraction" => [
               "dl_capacity_overflow",
               "dl_capacity_primary",
               "dl_capacity_secondary"
             ]
           }

    assert report["reduced_capacity_pack_status_counts"] == %{"capacity_limited" => 1}
    assert report["reduced_capacity_packed_contact_ids"] == ["dl_capacity_secondary"]
    assert report["reduced_capacity_deferred_contact_ids"] == ["dl_capacity_overflow"]
    assert report["station_calendar_trust_boundary_status_counts"] == %{"declared" => 3}

    assert [
             %{
               "contention_group_id" => pack_group_id,
               "ground_station_id" => "equator_prime",
               "capacity_fraction" => 0.5,
               "used_capacity_fraction" => 0.5,
               "unused_capacity_fraction" => unused_capacity_fraction,
               "pack_status" => "capacity_limited",
               "selected_contact_ids" => ["dl_capacity_primary"],
               "capacity_packed_contact_ids" => ["dl_capacity_secondary"],
               "deferred_contact_ids" => ["dl_capacity_overflow"],
               "capacity_requirement_rows" => capacity_requirement_rows
             }
           ] = report["reduced_capacity_pack_groups"]

    assert_in_delta unused_capacity_fraction, 0.0, 1.0e-12
    assert pack_group_id == "station:equator_prime:contention:1"

    assert capacity_requirement_rows == [
             %{
               "contact_id" => "dl_capacity_primary",
               "allocation_status" => "allocated",
               "allocation_reason" => "selected_by_contention_resolution",
               "capacity_pack_status" => "selected_by_contention_resolution",
               "required_capacity_fraction" => 0.25,
               "required_capacity_fraction_source" => "contact_required_capacity_fraction"
             },
             %{
               "contact_id" => "dl_capacity_secondary",
               "allocation_status" => "allocated",
               "allocation_reason" => "selected_by_reduced_station_capacity_pack",
               "capacity_pack_status" => "selected_by_reduced_station_capacity_pack",
               "required_capacity_fraction" => 0.25,
               "required_capacity_fraction_source" => "contact_required_capacity_fraction"
             },
             %{
               "contact_id" => "dl_capacity_overflow",
               "allocation_status" => "deferred",
               "allocation_reason" => "same_station_contention",
               "capacity_pack_status" => "deferred_by_reduced_station_capacity_pack",
               "required_capacity_fraction" => 0.25,
               "required_capacity_fraction_source" => "contact_required_capacity_fraction"
             }
           ]

    rows_by_contact_id = Map.new(report["rows"], &{&1["contact_id"], &1})

    assert rows_by_contact_id["dl_capacity_primary"]["allocation_status"] == "allocated"

    assert rows_by_contact_id["dl_capacity_primary"]["allocation_reason"] ==
             "selected_by_contention_resolution"

    assert rows_by_contact_id["dl_capacity_primary"]["capacity_pack_status"] ==
             "selected_by_contention_resolution"

    assert rows_by_contact_id["dl_capacity_primary"]["capacity_pack_group_id"] == pack_group_id

    assert rows_by_contact_id["dl_capacity_secondary"]["allocation_status"] == "allocated"

    assert rows_by_contact_id["dl_capacity_secondary"]["allocation_reason"] ==
             "selected_by_reduced_station_capacity_pack"

    assert rows_by_contact_id["dl_capacity_secondary"]["capacity_pack_status"] ==
             "selected_by_reduced_station_capacity_pack"

    assert rows_by_contact_id["dl_capacity_secondary"]["selected_contact_id"] ==
             "dl_capacity_secondary"

    assert rows_by_contact_id["dl_capacity_overflow"]["allocation_status"] == "deferred"

    assert rows_by_contact_id["dl_capacity_overflow"]["allocation_reason"] ==
             "same_station_contention"

    assert rows_by_contact_id["dl_capacity_overflow"]["capacity_pack_status"] ==
             "deferred_by_reduced_station_capacity_pack"

    assert rows_by_contact_id["dl_capacity_overflow"]["selected_contact_id"] ==
             "dl_capacity_primary"

    Enum.each(rows_by_contact_id, fn {_contact_id, row} ->
      assert row["station_availability"] == "reduced_capacity"
      assert row["station_calendar_entry_id"] == "equator_capacity"
      assert row["station_calendar_trust_boundary_status"] == "declared"
      assert row["required_capacity_fraction"] == 0.25
      assert row["required_capacity_fraction_source"] == "contact_required_capacity_fraction"
      assert row["capacity_pack_capacity_fraction"] == 0.5
      assert row["capacity_pack_used_fraction"] == 0.5
      assert row["capacity_pack_group_id"] == pack_group_id
    end)
  end

  test "validates contact allocation top-level count maps against rows" do
    report = read_json!("study_results/contact_allocation_report_v1.json")

    assert {:ok, %{"schema_contract" => "contact_allocation_report.v1"}} =
             Schema.validate_artifact(report)

    invalid_required_count =
      Map.put(report, "input_contact_count", -1)

    assert {:error, invalid_required_count_report} =
             Schema.validate_artifact(invalid_required_count)

    assert Enum.any?(
             invalid_required_count_report["errors"],
             &(&1["path"] == "$.input_contact_count")
           )

    invalid_optional_count =
      Map.put(report, "invalid_contact_input_count", -1)

    assert {:error, invalid_optional_count_report} =
             Schema.validate_artifact(invalid_optional_count)

    assert Enum.any?(
             invalid_optional_count_report["errors"],
             &(&1["path"] == "$.invalid_contact_input_count")
           )

    invalid_row_reservation_overlap_count =
      put_in(report, ["rows", Access.at(0), "station_calendar_reservation_overlap_count"], -1)

    assert {:error, invalid_row_reservation_overlap_count_report} =
             Schema.validate_artifact(invalid_row_reservation_overlap_count)

    assert Enum.any?(
             invalid_row_reservation_overlap_count_report["errors"],
             &(&1["path"] == "$.rows[0].station_calendar_reservation_overlap_count")
           )

    invalid_negative_count =
      put_in(report, ["allocation_status_counts", "allocated"], -1)

    assert {:error, invalid_negative_count_report} =
             Schema.validate_artifact(invalid_negative_count)

    assert Enum.any?(
             invalid_negative_count_report["errors"],
             &(&1["path"] == "$.allocation_status_counts.allocated")
           )

    invalid_resource_blocking_dimension_count =
      put_in(report, ["resource_blocking_dimension_counts", "antenna"], -1)

    assert {:error, invalid_resource_blocking_dimension_count_report} =
             Schema.validate_artifact(invalid_resource_blocking_dimension_count)

    assert Enum.any?(
             invalid_resource_blocking_dimension_count_report["errors"],
             &(&1["path"] == "$.resource_blocking_dimension_counts.antenna")
           )

    invalid_row_derived_count =
      put_in(report, ["effective_allocation_status_counts", "allocated"], 99)

    assert {:error, invalid_row_derived_count_report} =
             Schema.validate_artifact(invalid_row_derived_count)

    assert Enum.any?(
             invalid_row_derived_count_report["errors"],
             &(&1["path"] == "$.effective_allocation_status_counts")
           )

    capacity_pack_report =
      read_json!("study_results/contact_allocation_capacity_pack_report_v1.json")

    invalid_capacity_pack_count =
      Map.put(
        capacity_pack_report,
        "capacity_pack_status_counts",
        %{"selected_by_reduced_station_capacity_pack" => -1}
      )

    assert {:error, invalid_capacity_pack_count_report} =
             Schema.validate_artifact(invalid_capacity_pack_count)

    assert Enum.any?(
             invalid_capacity_pack_count_report["errors"],
             &(&1["path"] ==
                 "$.capacity_pack_status_counts.selected_by_reduced_station_capacity_pack")
           )

    invalid_capacity_pack_demand =
      Map.put(capacity_pack_report, "capacity_pack_required_capacity_fraction", -1.0)

    assert {:error, invalid_capacity_pack_demand_report} =
             Schema.validate_artifact(invalid_capacity_pack_demand)

    assert Enum.any?(
             invalid_capacity_pack_demand_report["errors"],
             &(&1["path"] == "$.capacity_pack_required_capacity_fraction")
           )

    invalid_capacity_pack_demand_map =
      Map.put(capacity_pack_report, "capacity_pack_required_capacity_fraction_by_status", %{
        "selected_by_reduced_station_capacity_pack" => -1.0
      })

    assert {:error, invalid_capacity_pack_demand_map_report} =
             Schema.validate_artifact(invalid_capacity_pack_demand_map)

    assert Enum.any?(
             invalid_capacity_pack_demand_map_report["errors"],
             &(&1["path"] ==
                 "$.capacity_pack_required_capacity_fraction_by_status.selected_by_reduced_station_capacity_pack")
           )

    invalid_capacity_pack_ids =
      Map.put(
        capacity_pack_report,
        "capacity_pack_contact_ids_by_status",
        %{"selected_by_reduced_station_capacity_pack" => ["bad id"]}
      )

    assert {:error, invalid_capacity_pack_ids_report} =
             Schema.validate_artifact(invalid_capacity_pack_ids)

    assert Enum.any?(
             invalid_capacity_pack_ids_report["errors"],
             &(&1["path"] ==
                 "$.capacity_pack_contact_ids_by_status.selected_by_reduced_station_capacity_pack[0]")
           )

    invalid_capacity_pack_id_group =
      Map.put(
        capacity_pack_report,
        "capacity_pack_contact_ids_by_status",
        %{"selected_by_reduced_station_capacity_pack" => ["dl_capacity_primary"]}
      )

    assert {:error, invalid_capacity_pack_id_group_report} =
             Schema.validate_artifact(invalid_capacity_pack_id_group)

    assert Enum.any?(
             invalid_capacity_pack_id_group_report["errors"],
             &(&1["path"] == "$.capacity_pack_contact_ids_by_status")
           )

    invalid_reduced_capacity_packed_ids =
      Map.put(capacity_pack_report, "reduced_capacity_packed_contact_ids", ["bad id"])

    assert {:error, invalid_reduced_capacity_packed_ids_report} =
             Schema.validate_artifact(invalid_reduced_capacity_packed_ids)

    assert Enum.any?(
             invalid_reduced_capacity_packed_ids_report["errors"],
             &(&1["path"] == "$.reduced_capacity_packed_contact_ids[0]")
           )

    invalid_station_pressure_id =
      Map.put(report, "station_pressure_contact_ids_by_availability", %{
        "reserved" => ["bad id"]
      })

    assert {:error, invalid_station_pressure_id_report} =
             Schema.validate_artifact(invalid_station_pressure_id)

    assert Enum.any?(
             invalid_station_pressure_id_report["errors"],
             &(&1["path"] == "$.station_pressure_contact_ids_by_availability.reserved[0]")
           )

    invalid_station_pressure_routing =
      Map.put(report, "station_pressure_contact_ids_by_availability", %{
        "reserved" => ["dl_1"]
      })

    assert {:error, invalid_station_pressure_routing_report} =
             Schema.validate_artifact(invalid_station_pressure_routing)

    assert Enum.any?(
             invalid_station_pressure_routing_report["errors"],
             &(&1["path"] == "$.station_pressure_contact_ids_by_availability" and
                 &1["message"] ==
                   "must equal row-derived station_pressure_contact_ids_by_availability")
           )

    invalid_station_pressure_status_routing =
      Map.put(report, "station_pressure_contact_ids_by_status", %{
        "reserved" => ["dl_1"]
      })

    assert {:error, invalid_station_pressure_status_routing_report} =
             Schema.validate_artifact(invalid_station_pressure_status_routing)

    assert Enum.any?(
             invalid_station_pressure_status_routing_report["errors"],
             &(&1["path"] == "$.station_pressure_contact_ids_by_status" and
                 &1["message"] == "must equal row-derived station_pressure_contact_ids_by_status")
           )

    invalid_station_pressure_status_count =
      Map.put(report, "station_pressure_contact_counts_by_status", %{
        "reserved" => 99,
        "unavailable" => 1
      })

    assert {:error, invalid_station_pressure_status_count_report} =
             Schema.validate_artifact(invalid_station_pressure_status_count)

    assert Enum.any?(
             invalid_station_pressure_status_count_report["errors"],
             &(&1["path"] == "$.station_pressure_contact_counts_by_status" and
                 &1["message"] ==
                   "must equal row-derived station_pressure_contact_counts_by_status")
           )

    invalid_resource_blocking_dimension_id =
      Map.put(report, "resource_blocked_contact_ids_by_blocking_dimension", %{
        "antenna" => ["bad id"]
      })

    assert {:error, invalid_resource_blocking_dimension_id_report} =
             Schema.validate_artifact(invalid_resource_blocking_dimension_id)

    assert Enum.any?(
             invalid_resource_blocking_dimension_id_report["errors"],
             &(&1["path"] ==
                 "$.resource_blocked_contact_ids_by_blocking_dimension.antenna[0]")
           )

    for {field, stale_values} <- [
          {"resource_blocking_dimension_counts", %{"antenna" => 99}},
          {"resource_blocked_contact_ids_by_blocking_dimension", %{"antenna" => ["stale"]}},
          {"resource_blocked_contact_ids_by_spacecraft_id", %{"sat_low_resource" => ["stale"]}},
          {"station_reservation_ids", ["reservation_stale"]},
          {"station_reserved_bys", ["stale_operator"]},
          {"station_reservation_statuses", ["stale_status"]},
          {"station_reservation_expiration_status_counts", %{"declared" => 99}},
          {"station_reservation_declared_expiration_contact_count", 99},
          {"station_reservation_missing_expiration_contact_count", 99},
          {"earliest_station_reservation_expires_at_s", 99_999.0},
          {"station_reservation_contact_ids_by_expiration_status", %{"declared" => ["stale"]}},
          {"station_reservation_ids_by_expiration_status", %{"declared" => ["reservation_stale"]}}
        ] do
      invalid_reservation_list =
        Map.put(report, field, stale_values)

      assert {:error, invalid_reservation_list_report} =
               Schema.validate_artifact(invalid_reservation_list)

      assert Enum.any?(
               invalid_reservation_list_report["errors"],
               &(&1["path"] == "$.#{field}")
             )
    end
  end

  defp read_json!(path) do
    path
    |> File.read!()
    |> :json.decode()
  end

  defp contact_allocation_summary_fixture_report(source) do
    %{
      "schema_contract" => "contact_allocation_report.v1",
      "model" => "deterministic_station_contact_allocation",
      "source" => source,
      "rows" => [
        %{
          "id" => "contact_allocation:dl_1",
          "contact_id" => "dl_1",
          "allocation_status" => "allocated",
          "effective_allocation_status" => "allocated",
          "allocation_reason" => "selected_by_contention_resolution",
          "ground_station_id" => "equator_prime",
          "direction" => "downlink",
          "review_status" => "operator_review_required"
        },
        %{
          "id" => "contact_allocation:dl_2",
          "contact_id" => "dl_2",
          "allocation_status" => "deferred",
          "effective_allocation_status" => "deferred",
          "allocation_reason" => "same_station_contention",
          "ground_station_id" => "equator_prime",
          "direction" => "downlink",
          "selected_contact_id" => "dl_1",
          "review_status" => "operator_review_required"
        },
        %{
          "id" => "contact_allocation:dl_3",
          "contact_id" => "dl_3",
          "allocation_status" => "blocked",
          "effective_allocation_status" => "blocked",
          "allocation_reason" => "ground_station_reserved",
          "ground_station_id" => "equator_prime",
          "direction" => "downlink",
          "station_availability" => "reserved",
          "station_calendar_status" => "reserved",
          "station_calendar_precedence_availability" => "reserved",
          "station_calendar_precedence_rank" => 1,
          "station_reservation_id" => "reservation_1",
          "station_reservation_status" => "reserved",
          "station_reserved_by" => "network_partner",
          "station_reservation_match_status" => "overlap",
          "station_reservation_expires_at_s" => 420.0,
          "review_status" => "operator_review_required"
        }
      ],
      "reduced_capacity_pack_groups" => [],
      "model_limits" => [
        "artifact_level_only",
        "no_provider_reservation",
        "no_schedule_mutation",
        "no_full_realized_contact_reconciliation"
      ]
    }
  end

  defp contact_allocation_capacity_pack_summary_fixture_report do
    pack_group_id = "capacity_pack:equator_prime:downlink:100_160"

    capacity_requirement_rows = [
      %{
        "contact_id" => "dl_capacity_primary",
        "allocation_status" => "allocated",
        "allocation_reason" => "selected_by_contention_resolution",
        "capacity_pack_status" => "selected_by_contention_resolution",
        "required_capacity_fraction" => 0.25,
        "required_capacity_fraction_source" => "contact_required_capacity_fraction"
      },
      %{
        "contact_id" => "dl_capacity_secondary",
        "allocation_status" => "allocated",
        "allocation_reason" => "selected_by_reduced_station_capacity_pack",
        "capacity_pack_status" => "selected_by_reduced_station_capacity_pack",
        "required_capacity_fraction" => 0.25,
        "required_capacity_fraction_source" => "contact_required_capacity_fraction"
      },
      %{
        "contact_id" => "dl_capacity_overflow",
        "allocation_status" => "deferred",
        "allocation_reason" => "same_station_contention",
        "capacity_pack_status" => "deferred_by_reduced_station_capacity_pack",
        "required_capacity_fraction" => 0.25,
        "required_capacity_fraction_source" => "contact_required_capacity_fraction"
      }
    ]

    %{
      "schema_contract" => "contact_allocation_report.v1",
      "model" => "deterministic_station_contact_allocation",
      "source" => "validation.contact_allocation_capacity_pack_summary",
      "rows" => [
        %{
          "id" => "contact_allocation:dl_capacity_primary",
          "contact_id" => "dl_capacity_primary",
          "allocation_status" => "allocated",
          "effective_allocation_status" => "allocated",
          "allocation_reason" => "selected_by_contention_resolution",
          "ground_station_id" => "equator_prime",
          "direction" => "downlink",
          "capacity_fraction" => 0.5,
          "required_capacity_fraction" => 0.25,
          "required_capacity_fraction_source" => "contact_required_capacity_fraction",
          "capacity_pack_group_id" => pack_group_id,
          "capacity_pack_status" => "selected_by_contention_resolution",
          "capacity_pack_capacity_fraction" => 0.5,
          "capacity_pack_used_fraction" => 0.5,
          "review_status" => "accepted_for_planning"
        },
        %{
          "id" => "contact_allocation:dl_capacity_secondary",
          "contact_id" => "dl_capacity_secondary",
          "allocation_status" => "allocated",
          "effective_allocation_status" => "allocated",
          "allocation_reason" => "selected_by_reduced_station_capacity_pack",
          "ground_station_id" => "equator_prime",
          "direction" => "downlink",
          "capacity_fraction" => 0.5,
          "required_capacity_fraction" => 0.25,
          "required_capacity_fraction_source" => "contact_required_capacity_fraction",
          "capacity_pack_group_id" => pack_group_id,
          "capacity_pack_status" => "selected_by_reduced_station_capacity_pack",
          "capacity_pack_capacity_fraction" => 0.5,
          "capacity_pack_used_fraction" => 0.5,
          "review_status" => "operator_review_required"
        },
        %{
          "id" => "contact_allocation:dl_capacity_overflow",
          "contact_id" => "dl_capacity_overflow",
          "allocation_status" => "deferred",
          "effective_allocation_status" => "deferred",
          "allocation_reason" => "same_station_contention",
          "ground_station_id" => "equator_prime",
          "direction" => "downlink",
          "selected_contact_id" => "dl_capacity_secondary",
          "capacity_fraction" => 0.5,
          "required_capacity_fraction" => 0.25,
          "required_capacity_fraction_source" => "contact_required_capacity_fraction",
          "capacity_pack_group_id" => pack_group_id,
          "capacity_pack_status" => "deferred_by_reduced_station_capacity_pack",
          "capacity_pack_capacity_fraction" => 0.5,
          "capacity_pack_used_fraction" => 0.5,
          "review_status" => "operator_review_required"
        }
      ],
      "reduced_capacity_pack_groups" => [
        %{
          "contention_group_id" => pack_group_id,
          "ground_station_id" => "equator_prime",
          "direction" => "downlink",
          "capacity_fraction" => 0.5,
          "used_capacity_fraction" => 0.5,
          "required_capacity_fraction" => 0.75,
          "pack_status" => "capacity_limited",
          "selected_contact_ids" => ["dl_capacity_primary"],
          "capacity_packed_contact_ids" => ["dl_capacity_secondary"],
          "deferred_contact_ids" => ["dl_capacity_overflow"],
          "capacity_requirement_rows" => capacity_requirement_rows
        }
      ],
      "model_limits" => [
        "artifact_level_only",
        "no_provider_reservation",
        "no_schedule_mutation",
        "no_full_realized_contact_reconciliation"
      ]
    }
  end

  defp contact_allocation_reservation_conflict_summary_fixture_report do
    %{
      "schema_contract" => "contact_allocation_report.v1",
      "model" => "deterministic_station_contact_allocation",
      "source" => "validation.contact_allocation_reservation_conflict_summary",
      "rows" => [
        %{
          "id" => "contact_allocation:dl_reserved_owner",
          "contact_id" => "dl_reserved_owner",
          "allocation_status" => "allocated",
          "effective_allocation_status" => "allocated",
          "allocation_reason" => "station_reservation_matched",
          "ground_station_id" => "equator_prime",
          "direction" => "downlink",
          "station_reservation_id" => "reservation_1",
          "station_reservation_status" => "confirmed",
          "station_reserved_by" => "ops_team_b",
          "station_reservation_match_status" => "matched",
          "station_reservation_expires_at_s" => 360.0,
          "review_status" => "accepted_for_planning"
        },
        %{
          "id" => "contact_allocation:dl_reserved_intruder",
          "contact_id" => "dl_reserved_intruder",
          "allocation_status" => "blocked",
          "effective_allocation_status" => "blocked",
          "allocation_reason" => "ground_station_reserved",
          "ground_station_id" => "equator_prime",
          "direction" => "downlink",
          "station_reservation_id" => "reservation_1",
          "station_reservation_status" => "confirmed",
          "station_reserved_by" => "ops_team_b",
          "station_reservation_match_status" => "overlap",
          "station_reservation_expires_at_s" => 360.0,
          "review_status" => "operator_review_required"
        }
      ],
      "reduced_capacity_pack_groups" => [],
      "model_limits" => [
        "artifact_level_only",
        "no_provider_reservation",
        "no_schedule_mutation",
        "no_full_realized_contact_reconciliation"
      ]
    }
  end

  defp contact_allocation_capacity_pack_capability_assumptions do
    capabilities = ContactAllocation.capabilities()

    %{
      "capacity_pack_statuses" => capabilities.capacity_pack_statuses,
      "reduced_capacity_pack_statuses" => capabilities.reduced_capacity_pack_statuses,
      "required_capacity_fraction_source_values" =>
        capabilities.required_capacity_fraction_source_values,
      "required_capacity_value_paths" =>
        json_capacity_value_paths(capabilities.required_capacity_value_paths),
      "default_required_capacity_value_paths" =>
        json_capacity_value_paths(capabilities.default_required_capacity_value_paths)
    }
  end

  defp contact_allocation_provider_reservation_request_capability_assumptions do
    capabilities = ContactAllocation.capabilities()

    %{
      "provider_reservation_request_statuses" =>
        capabilities.provider_reservation_request_statuses,
      "station_reservation_match_statuses" => capabilities.station_reservation_match_statuses,
      "provider_direction_aliases" => capabilities.provider_direction_aliases
    }
  end

  defp contact_allocation_summary_capability_assumptions do
    capabilities = ContactAllocation.capabilities()

    %{
      "row_statuses" => capabilities.row_statuses,
      "effective_row_statuses" => capabilities.effective_row_statuses,
      "station_unavailable_aliases" => capabilities.station_unavailable_aliases,
      "station_blocking_availability" => capabilities.station_blocking_availability,
      "station_availability_precedence" => capabilities.station_availability_precedence,
      "capacity_pack_statuses" => capabilities.capacity_pack_statuses,
      "reduced_capacity_pack_statuses" => capabilities.reduced_capacity_pack_statuses,
      "station_reservation_match_statuses" => capabilities.station_reservation_match_statuses,
      "station_reservation_expiration_statuses" =>
        capabilities.station_reservation_expiration_statuses,
      "required_capacity_fraction_source_values" =>
        capabilities.required_capacity_fraction_source_values,
      "required_capacity_value_paths" =>
        json_capacity_value_paths(capabilities.required_capacity_value_paths),
      "default_required_capacity_value_paths" =>
        json_capacity_value_paths(capabilities.default_required_capacity_value_paths),
      "provider_direction_aliases" => capabilities.provider_direction_aliases
    }
  end

  defp contact_allocation_station_pressure_capability_assumptions do
    capabilities = ContactAllocation.capabilities()

    %{
      "station_unavailable_aliases" => capabilities.station_unavailable_aliases,
      "station_blocking_availability" => capabilities.station_blocking_availability,
      "station_availability_precedence" => capabilities.station_availability_precedence,
      "provider_direction_aliases" => capabilities.provider_direction_aliases
    }
  end

  defp contact_allocation_reservation_conflict_capability_assumptions do
    capabilities = ContactAllocation.capabilities()

    %{
      "station_reservation_match_statuses" => capabilities.station_reservation_match_statuses,
      "reservation_conflict_match_statuses" => capabilities.reservation_conflict_match_statuses,
      "station_reservation_expiration_statuses" =>
        capabilities.station_reservation_expiration_statuses,
      "provider_direction_aliases" => capabilities.provider_direction_aliases
    }
  end

  defp json_capacity_value_paths(paths) do
    Enum.map(paths, fn %{unit: unit, path: path} ->
      %{"unit" => Atom.to_string(unit), "path" => path}
    end)
  end
end
