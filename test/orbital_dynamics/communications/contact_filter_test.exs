defmodule OrbitalDynamics.Communications.ContactFilterTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.Communications.ContactFilter
  alias OrbitalDynamics.{CadenceImport, OperatorReview, Schema}

  test "declares contact filter capabilities" do
    assert %{
             artifact_contract: "contact_filter_report.v1",
             validation_level: :artifact_contract,
             model: :thin_ground_network_availability_filter,
             suppressed_directions: suppressed_directions,
             station_unavailable_aliases: station_unavailable_aliases,
             station_availability_precedence: station_availability_precedence,
             station_capacity_fraction_paths: station_capacity_fraction_paths,
             station_capacity_percent_paths: station_capacity_percent_paths,
             station_capacity_value_paths: station_capacity_value_paths,
             contact_capacity_fraction_paths: contact_capacity_fraction_paths,
             contact_capacity_percent_paths: contact_capacity_percent_paths,
             contact_capacity_value_paths: contact_capacity_value_paths,
             provider_direction_aliases: provider_direction_aliases,
             provider_result_map_value_keys: provider_result_map_value_keys,
             provider_counteroffer_fields: provider_counteroffer_fields,
             contact_stable_identity_fields: contact_stable_identity_fields,
             suppression_reasons: suppression_reasons,
             row_semantics: row_semantics,
             known_limits: known_limits
           } = ContactFilter.capabilities()

    assert suppressed_directions == ["downlink", "tracking", "health_check"]
    assert station_unavailable_aliases == ["outage", "down", "offline"]

    assert station_availability_precedence == %{
             "unavailable" => 5,
             "maintenance" => 5,
             "reserved" => 4,
             "reduced_capacity" => 3,
             "available" => 1
           }

    assert station_capacity_fraction_paths == [
             ["capacity_pack_capacity_fraction"],
             ["station_capacity_fraction"],
             ["capacity_fraction"]
           ]

    assert station_capacity_percent_paths == [["capacity_percent"], ["station_capacity_percent"]]
    assert contact_capacity_fraction_paths == station_capacity_fraction_paths
    assert contact_capacity_percent_paths == station_capacity_percent_paths
    assert contact_capacity_value_paths == station_capacity_value_paths

    assert %{unit: :fraction, path: ["capacity_pack_capacity_fraction"]} in station_capacity_value_paths

    assert %{unit: :fraction, path: ["station_capacity_fraction"]} in station_capacity_value_paths
    assert %{unit: :fraction, path: ["capacity_fraction"]} in station_capacity_value_paths
    assert %{unit: :percent, path: ["capacity_percent"]} in contact_capacity_value_paths
    assert %{unit: :percent, path: ["station_capacity_percent"]} in contact_capacity_value_paths
    assert "scenario_id" in contact_stable_identity_fields
    assert "spacecraft_id" in contact_stable_identity_fields
    assert "ground_station_id" in contact_stable_identity_fields
    assert "source_window_id" in contact_stable_identity_fields
    assert "station_calendar_entry_id" in contact_stable_identity_fields
    assert "station_reservation_id" in contact_stable_identity_fields

    assert Map.take(provider_direction_aliases, [
             "cmd",
             "commanding",
             "commands",
             "sband_command",
             "s_band_command",
             "up",
             "up_link",
             "dl",
             "down",
             "downlinking",
             "down_link",
             "track",
             "track_ing",
             "tracking_pass",
             "health",
             "healthcheck",
             "health_check_window"
           ]) == %{
             "cmd" => "command",
             "commanding" => "command",
             "commands" => "command",
             "sband_command" => "command",
             "s_band_command" => "command",
             "up" => "uplink",
             "up_link" => "uplink",
             "dl" => "downlink",
             "down" => "downlink",
             "downlinking" => "downlink",
             "down_link" => "downlink",
             "track" => "tracking",
             "track_ing" => "tracking",
             "tracking_pass" => "tracking",
             "health" => "health_check",
             "healthcheck" => "health_check",
             "health_check_window" => "health_check"
           }

    assert "result" in provider_result_map_value_keys
    assert "provider_status" in provider_result_map_value_keys
    assert "provider_outcome" in provider_result_map_value_keys
    assert "diagnostics" in provider_result_map_value_keys

    assert provider_counteroffer_fields == [
             "provider_counteroffer_id",
             "provider_counteroffer_status",
             "provider_counteroffer_negotiation_state",
             "provider_counteroffer_reason_code",
             "provider_counteroffer_cost_delta",
             "provider_counteroffer_lock_deadline_s",
             "provider_counteroffer_starts_at_s",
             "provider_counteroffer_ends_at_s",
             "provider_counteroffer_start_delta_s",
             "provider_counteroffer_end_delta_s",
             "provider_counteroffer_duration_delta_s"
           ]

    assert :invalid_contact_input_review in row_semantics
    assert :feedback_unit_interval_input_validation in row_semantics
    assert :station_calendar_provider_input in row_semantics
    assert :station_calendar_provider_list_input in row_semantics
    assert :direction_scoped_station_calendar in row_semantics
    assert :station_capacity_value_paths in row_semantics
    assert :contact_capacity_value_paths in row_semantics
    assert :contact_stable_identity_fields in row_semantics
    assert :provider_direction_aliases in row_semantics
    assert :provider_result_map_value_keys in row_semantics
    assert :provider_counteroffer_review_handoff in row_semantics
    assert :provider_counteroffer_fields in row_semantics
    assert :station_calendar_entry_identity_preservation in row_semantics
    assert :station_calendar_reservation_expiration_context in row_semantics
    assert :station_reservation_owner_match in row_semantics
    assert :station_reservation_match_status_counts in row_semantics
    assert :station_reservation_match_status_id_routing in row_semantics
    assert :station_calendar_trust_boundary_status_id_routing in row_semantics
    assert :contact_filter_suppression_reason_counts in row_semantics
    assert :contact_filter_suppression_reason_id_routing in row_semantics
    assert "invalid_contact_input" in suppression_reasons
    assert "provider_counteroffer_review" in suppression_reasons
    assert "ground_station_reserved" in suppression_reasons
    assert "ground_station_unavailable" in suppression_reasons
    assert "ground_station_capacity_zero" in suppression_reasons
    assert :artifact_level_only in known_limits
    assert :externally_supplied_ground_network in known_limits
    assert :no_provider_reservation in known_limits
    assert :no_schedule_mutation in known_limits
  end

  test "suppresses provider counteroffer contacts for review while preserving offer evidence" do
    provider = %{
      schema_contract: "station_calendar_provider.v1",
      id: :ops_calendar,
      trust_boundary: :declared_station_calendar,
      entries: [
        %{
          id: :provider_counteroffer_window,
          station_id: :equator_prime,
          availability: :available,
          directions: [:downlink],
          start_s: 130.0,
          end_s: 170.0,
          counteroffer_id: :provider_offer_1,
          counteroffer_status: :proposed,
          counteroffer_reason_code: :provider_shifted_window,
          price_delta: "125.5",
          schedule_lock_deadline_s: "150.0",
          offered_start_s: "130.0",
          offered_end_s: "170.0"
        }
      ]
    }

    {kept, report} =
      ContactFilter.filter_candidates(
        [contact(:dl_counteroffer, direction: :downlink)],
        provider
      )

    assert kept == []

    assert %{
             "kept_candidate_count" => 0,
             "suppressed_candidate_count" => 1,
             "suppression_reason_counts" => %{"provider_counteroffer_review" => 1},
             "suppressed_candidate_ids_by_reason" => %{
               "provider_counteroffer_review" => ["dl_counteroffer"]
             },
             "suppressed_candidates" => [
               %{
                 "id" => "dl_counteroffer",
                 "suppressed_reason" => "provider_counteroffer_review",
                 "required_operator_action" => "review_provider_counteroffer",
                 "operator_action_reason" => "provider_counteroffer_requires_review",
                 "station_availability" => "available",
                 "station_calendar_entry_id" => "provider_counteroffer_window",
                 "station_calendar_status" => "available",
                 "station_calendar_provider_id" => "ops_calendar",
                 "station_calendar_provider_entry_id" => "provider_counteroffer_window",
                 "provider_counteroffer_id" => "provider_offer_1",
                 "provider_counteroffer_status" => "proposed",
                 "provider_counteroffer_negotiation_state" => "proposed",
                 "provider_counteroffer_reason_code" => "provider_shifted_window",
                 "provider_counteroffer_cost_delta" => 125.5,
                 "provider_counteroffer_lock_deadline_s" => 150.0,
                 "provider_counteroffer_starts_at_s" => 130.0,
                 "provider_counteroffer_ends_at_s" => 170.0,
                 "provider_counteroffer_start_delta_s" => 30.0,
                 "provider_counteroffer_end_delta_s" => 10.0,
                 "provider_counteroffer_duration_delta_s" => -20.0,
                 "source_station_calendar_entry" => %{
                   "provider_counteroffer_id" => "provider_offer_1",
                   "provider_counteroffer_status" => "proposed",
                   "provider_counteroffer_negotiation_state" => "proposed"
                 }
               }
             ]
           } = report

    review = OperatorReview.from_contact_filter_report(report)
    [review_row] = review["rows"]

    assert %{
             "review_type" => "contact_suppression",
             "required_operator_action" => "review_provider_counteroffer",
             "provider_counteroffer_id" => "provider_offer_1",
             "provider_counteroffer_status" => "proposed",
             "provider_counteroffer_negotiation_state" => "proposed",
             "provider_counteroffer_reason_code" => "provider_shifted_window",
             "provider_counteroffer_cost_delta" => 125.5,
             "provider_counteroffer_lock_deadline_s" => 150.0,
             "provider_counteroffer_starts_at_s" => 130.0,
             "provider_counteroffer_ends_at_s" => 170.0,
             "provider_counteroffer_start_delta_s" => 30.0,
             "provider_counteroffer_end_delta_s" => 10.0,
             "provider_counteroffer_duration_delta_s" => -20.0,
             "source_contact_suppression" => %{
               "suppressed_reason" => "provider_counteroffer_review",
               "provider_counteroffer_id" => "provider_offer_1",
               "provider_counteroffer_duration_delta_s" => -20.0
             }
           } = review_row

    import = CadenceImport.from_contact_filter_report(report)
    [import_row] = import["rows"]

    assert %{
             "import_action" => "review_contact_suppression",
             "source_review_action" => "review_provider_counteroffer",
             "provider_counteroffer_id" => "provider_offer_1",
             "provider_counteroffer_status" => "proposed",
             "provider_counteroffer_negotiation_state" => "proposed",
             "provider_counteroffer_reason_code" => "provider_shifted_window",
             "provider_counteroffer_cost_delta" => 125.5,
             "provider_counteroffer_lock_deadline_s" => 150.0,
             "provider_counteroffer_starts_at_s" => 130.0,
             "provider_counteroffer_ends_at_s" => 170.0,
             "provider_counteroffer_start_delta_s" => 30.0,
             "provider_counteroffer_end_delta_s" => 10.0,
             "provider_counteroffer_duration_delta_s" => -20.0,
             "source_review_row" => %{
               "required_operator_action" => "review_provider_counteroffer",
               "provider_counteroffer_id" => "provider_offer_1",
               "provider_counteroffer_duration_delta_s" => -20.0
             }
           } = import_row

    assert {:ok, %{"schema_contract" => "contact_filter_report.v1"}} =
             Schema.validate_artifact(report)

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(review)

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(import)
  end

  test "suppresses invalid contact-like inputs for review instead of keeping them" do
    candidates = [
      contact(:valid_suppressed, starts_at_s: 100.0, ends_at_s: 160.0),
      contact(:missing_station, starts_at_s: 170.0, ends_at_s: 220.0)
      |> Map.delete(:ground_station_id)
      |> Map.put(:source_station_calendar_entry, %{id: :provider_entry_only})
      |> Map.put(:source_station_calendar_overlaps, [%{id: :provider_entry_only}]),
      %{
        type: :downlink,
        scenario_id: :leo_1,
        ground_station_id: :equator_prime,
        starts_at_s: 230.0,
        ends_at_s: 280.0
      },
      {:bad_contact_shape, :not_a_map},
      %{id: :obs_1, type: :observe, scenario_id: :leo_1, starts_at_s: 100.0, ends_at_s: 160.0}
    ]

    ground_network = [
      %{ground_station_id: :equator_prime, status: :offline, starts_at_s: 90.0, ends_at_s: 300.0}
    ]

    {kept, report} = ContactFilter.filter_candidates(candidates, ground_network)

    assert Enum.map(kept, & &1["id"]) == ["obs_1"]

    assert %{
             "input_candidate_count" => 5,
             "kept_candidate_count" => 1,
             "suppressed_candidate_count" => 4,
             "invalid_contact_input_count" => 3,
             "invalid_contact_input_ids" => [
               "missing_station",
               "missing_contact_id:3",
               "missing_contact_id:4"
             ],
             "suppression_reason_counts" => %{
               "ground_station_unavailable" => 1,
               "invalid_contact_input" => 3
             },
             "suppressed_candidate_ids_by_reason" => %{
               "ground_station_unavailable" => ["valid_suppressed"],
               "invalid_contact_input" => [
                 "missing_contact_id:3",
                 "missing_contact_id:4",
                 "missing_station"
               ]
             },
             "suppressed_candidates" => suppressed
           } = report

    assert %{
             "id" => "missing_station",
             "suppressed_reason" => "invalid_contact_input",
             "invalid_contact_input" => true,
             "invalid_contact_input_reason" => "missing_ground_station_id",
             "station_calendar_entry_id" => "provider_entry_only",
             "source_station_calendar_entry" => %{"id" => "provider_entry_only"},
             "required_operator_action" => "review_invalid_contact_filter_input",
             "source_contact_candidate" => %{"id" => "missing_station"}
           } = Enum.find(suppressed, &(&1["id"] == "missing_station"))

    assert %{
             "id" => "missing_contact_id:3",
             "suppressed_reason" => "invalid_contact_input",
             "invalid_contact_input_reason" => "missing_contact_id"
           } = Enum.find(suppressed, &(&1["id"] == "missing_contact_id:3"))

    assert %{
             "id" => "missing_contact_id:4",
             "suppressed_reason" => "invalid_contact_input",
             "invalid_contact_input_reason" => "invalid_contact_shape",
             "source_contact_candidate" => %{
               "invalid_contact_shape" => true,
               "raw_input" => "{:bad_contact_shape, :not_a_map}"
             }
           } = Enum.find(suppressed, &(&1["id"] == "missing_contact_id:4"))

    assert %{
             "id" => "valid_suppressed",
             "suppressed_reason" => "ground_station_unavailable"
           } = Enum.find(suppressed, &(&1["id"] == "valid_suppressed"))

    assert {:ok, %{"schema_contract" => "contact_filter_report.v1"}} =
             Schema.validate_artifact(report)

    invalid_kept_count = Map.put(report, "kept_candidate_count", 99)

    assert {:error, kept_count_report} = Schema.validate_artifact(invalid_kept_count)

    assert Enum.any?(
             kept_count_report["errors"],
             &(&1["path"] == "$.kept_candidate_count" and &1["message"] == "must equal 1")
           )

    invalid_input_ids = Map.put(report, "invalid_contact_input_ids", ["other_contact"])

    assert {:error, invalid_input_ids_report} = Schema.validate_artifact(invalid_input_ids)

    assert Enum.any?(
             invalid_input_ids_report["errors"],
             &(&1["path"] == "$.invalid_contact_input_ids" and
                 &1["message"] == "must equal row-derived invalid_contact_input_ids")
           )

    invalid_reason_counts =
      Map.put(report, "suppression_reason_counts", %{"ground_station_unavailable" => 9})

    assert {:error, reason_counts_report} = Schema.validate_artifact(invalid_reason_counts)

    assert Enum.any?(
             reason_counts_report["errors"],
             &(&1["path"] == "$.suppression_reason_counts" and
                 &1["message"] == "must equal row-derived suppression_reason_counts")
           )

    invalid_reason_ids =
      Map.put(report, "suppressed_candidate_ids_by_reason", %{
        "ground_station_unavailable" => ["stale_contact"]
      })

    assert {:error, reason_ids_report} = Schema.validate_artifact(invalid_reason_ids)

    assert Enum.any?(
             reason_ids_report["errors"],
             &(&1["path"] == "$.suppressed_candidate_ids_by_reason" and
                 &1["message"] == "must equal row-derived suppressed_candidate_ids_by_reason")
           )

    invalid_trust_counts =
      Map.put(report, "station_calendar_trust_boundary_status_counts", %{"declared" => 1})

    assert {:error, trust_counts_report} = Schema.validate_artifact(invalid_trust_counts)

    assert Enum.any?(
             trust_counts_report["errors"],
             &(&1["path"] == "$.station_calendar_trust_boundary_status_counts" and
                 &1["message"] ==
                   "must equal row-derived station_calendar_trust_boundary_status_counts")
           )

    invalid_reservation_match_counts =
      Map.put(report, "station_reservation_match_status_counts", %{"overlap" => 99})

    assert {:error, reservation_match_counts_report} =
             Schema.validate_artifact(invalid_reservation_match_counts)

    assert Enum.any?(
             reservation_match_counts_report["errors"],
             &(&1["path"] == "$.station_reservation_match_status_counts" and
                 &1["message"] ==
                   "must equal row-derived station_reservation_match_status_counts")
           )

    review = OperatorReview.from_contact_filter_report(report)
    review_row = Enum.find(review["rows"], &(&1["subject_id"] == "missing_station"))

    assert %{
             "review_type" => "contact_suppression",
             "required_operator_action" => "review_invalid_contact_filter_input",
             "invalid_contact_input" => true,
             "invalid_contact_input_reason" => "missing_ground_station_id",
             "station_calendar_entry_id" => "provider_entry_only",
             "source_station_calendar_entry" => %{"id" => "provider_entry_only"},
             "source_contact_candidate" => %{"id" => "missing_station"}
           } = review_row

    manifest = CadenceImport.from_contact_filter_report(report)
    import_row = Enum.find(manifest["rows"], &(&1["subject_id"] == "missing_station"))

    assert %{
             "import_action" => "review_contact_suppression",
             "invalid_contact_input" => true,
             "invalid_contact_input_reason" => "missing_ground_station_id",
             "station_calendar_entry_id" => "provider_entry_only",
             "source_station_calendar_entry" => %{"id" => "provider_entry_only"},
             "source_contact_candidate" => %{"id" => "missing_station"}
           } = import_row
  end

  test "preserves malformed contact filter identity fields for review" do
    candidates = [
      %{
        id: "bad contact id",
        type: :downlink,
        scenario_id: :leo_1,
        ground_station_id: :equator_prime,
        starts_at_s: 100.0,
        ends_at_s: 160.0
      },
      %{
        id: :bad_station,
        type: :downlink,
        scenario_id: :leo_1,
        ground_station_id: "bad station id",
        starts_at_s: 170.0,
        ends_at_s: 220.0
      },
      %{
        id: :bad_source_window,
        type: :tracking,
        scenario_id: :leo_1,
        ground_station_id: :equator_prime,
        source_window_id: "bad source window",
        starts_at_s: 230.0,
        ends_at_s: 280.0
      }
    ]

    {_kept, report} = ContactFilter.filter_candidates(candidates, [])
    suppressed_by_id = Map.new(report["suppressed_candidates"], &{&1["id"], &1})

    assert %{
             "invalid_contact_input_count" => 3,
             "invalid_contact_input_ids" => [
               "invalid_contact_id:1",
               "bad_station",
               "bad_source_window"
             ]
           } = report

    assert %{
             "id" => "invalid_contact_id:1",
             "invalid_contact_input_reason" => "invalid_contact_id",
             "source_contact_candidate" => %{"id" => "bad contact id"}
           } = suppressed_by_id["invalid_contact_id:1"]

    assert %{
             "id" => "bad_station",
             "invalid_contact_input_reason" => "invalid_ground_station_id",
             "source_contact_candidate" => %{"ground_station_id" => "bad station id"}
           } = bad_station = suppressed_by_id["bad_station"]

    refute Map.has_key?(bad_station, "ground_station_id")

    assert %{
             "id" => "bad_source_window",
             "invalid_contact_input_reason" => "invalid_source_window_id",
             "source_contact_candidate" => %{"source_window_id" => "bad source window"}
           } = bad_source_window = suppressed_by_id["bad_source_window"]

    refute Map.has_key?(bad_source_window, "source_window_id")

    assert {:ok, %{"schema_contract" => "contact_filter_report.v1"}} =
             Schema.validate_artifact(report)

    review = OperatorReview.from_contact_filter_report(report)
    manifest = CadenceImport.from_contact_filter_report(report)

    assert %{
             "required_operator_action" => "review_invalid_contact_filter_input",
             "invalid_contact_input_reason" => "invalid_contact_id",
             "source_contact_candidate" => %{"id" => "bad contact id"}
           } = Enum.find(review["rows"], &(&1["subject_id"] == "invalid_contact_id:1"))

    assert %{
             "import_action" => "review_contact_suppression",
             "invalid_contact_input_reason" => "invalid_source_window_id",
             "source_contact_candidate" => %{"source_window_id" => "bad source window"}
           } = Enum.find(manifest["rows"], &(&1["subject_id"] == "bad_source_window"))
  end

  test "suppresses downlinks when an overlapping station window is unavailable" do
    candidates = [
      contact(:dl_1, starts_at_s: 100.0, ends_at_s: 160.0),
      %{id: :obs_1, type: :observe, scenario_id: :leo_1, starts_at_s: 100.0, ends_at_s: 160.0}
    ]

    ground_network = [
      %{
        ground_station_id: :equator_prime,
        status: :maintenance,
        starts_at_s: 90.0,
        ends_at_s: 120.0
      }
    ]

    {kept, report} = ContactFilter.filter_candidates(candidates, ground_network)

    assert Enum.map(kept, & &1["id"]) == ["obs_1"]

    assert %{
             "schema_contract" => "contact_filter_report.v1",
             "model" => "thin_ground_network_availability_filter",
             "model_limits" => model_limits,
             "input_candidate_count" => 2,
             "kept_candidate_count" => 1,
             "suppressed_candidate_count" => 1,
             "station_calendar_trust_boundary_status_counts" => %{"missing" => 1},
             "suppressed_candidates" => [
               %{
                 "id" => "dl_1",
                 "type" => "downlink",
                 "scenario_id" => "leo_1",
                 "ground_station_id" => "equator_prime",
                 "starts_at_s" => 100.0,
                 "ends_at_s" => 160.0,
                 "suppressed_reason" => "ground_station_unavailable",
                 "station_calendar_trust_boundary_status" => "missing",
                 "source_station_calendar_entry" => %{
                   "ground_station_id" => "equator_prime",
                   "status" => "maintenance"
                 },
                 "station_availability" => "unavailable"
               }
             ]
           } = report

    assert "no_provider_reservation" in model_limits
    assert "no_schedule_mutation" in model_limits
    assert "no_link_budget_model" in model_limits

    expected_model_limits =
      ContactFilter.capabilities()
      |> Map.fetch!(:known_limits)
      |> Enum.map(&to_string/1)

    assert model_limits == expected_model_limits

    assert {:ok, %{"schema_contract" => "contact_filter_report.v1"}} =
             Schema.validate_artifact(report)
  end

  test "suppresses only matching direction contacts for direction-scoped station windows" do
    candidates = [
      contact(:dl_1,
        starts_at_s: 100.0,
        ends_at_s: 160.0,
        direction: "down"
      ),
      contact(:track_1,
        type: :tracking,
        starts_at_s: 105.0,
        ends_at_s: 140.0,
        direction: "tracking-pass"
      )
    ]

    ground_network = [
      %{
        id: :tracking_outage,
        ground_station_id: :equator_prime,
        status: :maintenance,
        directions: ["tracking pass"],
        starts_at_s: 90.0,
        ends_at_s: 170.0
      }
    ]

    {kept, report} = ContactFilter.filter_candidates(candidates, ground_network)

    assert Enum.map(kept, & &1["id"]) == ["dl_1"]

    assert [
             %{
               "id" => "track_1",
               "type" => "tracking",
               "direction" => "tracking",
               "suppressed_reason" => "ground_station_unavailable",
               "station_calendar_entry_id" => "tracking_outage",
               "station_calendar_directions" => ["tracking"],
               "source_station_calendar_entry" => %{
                 "id" => "tracking_outage",
                 "directions" => ["tracking pass"]
               }
             }
           ] = report["suppressed_candidates"]

    assert {:ok, %{"schema_contract" => "contact_filter_report.v1"}} =
             Schema.validate_artifact(report)
  end

  test "suppresses matching contacts for station-calendar direction aliases" do
    candidates = [
      contact(:dl_1,
        starts_at_s: 100.0,
        ends_at_s: 160.0,
        direction: :downlink
      ),
      contact(:track_1,
        type: :tracking,
        starts_at_s: 105.0,
        ends_at_s: 140.0,
        direction: :tracking
      )
    ]

    ground_network = [
      %{
        id: :tracking_outage,
        ground_station_id: :equator_prime,
        status: :maintenance,
        station_calendar_directions: [:tracking],
        starts_at_s: 90.0,
        ends_at_s: 170.0
      }
    ]

    {kept, report} = ContactFilter.filter_candidates(candidates, ground_network)

    assert Enum.map(kept, & &1["id"]) == ["dl_1"]

    assert [
             %{
               "id" => "track_1",
               "type" => "tracking",
               "direction" => "tracking",
               "suppressed_reason" => "ground_station_unavailable",
               "station_calendar_entry_id" => "tracking_outage",
               "station_calendar_directions" => ["tracking"],
               "source_station_calendar_entry" => %{
                 "id" => "tracking_outage",
                 "station_calendar_directions" => ["tracking"]
               }
             }
           ] = report["suppressed_candidates"]

    assert {:ok, %{"schema_contract" => "contact_filter_report.v1"}} =
             Schema.validate_artifact(report)
  end

  test "preserves declared ground-network trust boundary on suppressed contacts" do
    candidates = [
      contact(:dl_1, starts_at_s: 100.0, ends_at_s: 160.0)
    ]

    ground_network = [
      %{
        id: :provider_outage,
        provider_id: :ops_calendar,
        provider_entry_id: :ops_calendar_window_1,
        ground_station_id: :equator_prime,
        status: :maintenance,
        directions: [:downlink],
        starts_at_s: 90.0,
        ends_at_s: 170.0,
        provenance: %{
          source: :station_calendar_provider,
          trust_boundary: :declared_station_calendar
        }
      }
    ]

    {_kept, report} = ContactFilter.filter_candidates(candidates, ground_network)

    assert report["station_calendar_trust_boundary_status_counts"] == %{"declared" => 1}

    assert report["suppressed_candidate_ids_by_station_calendar_trust_boundary_status"] == %{
             "declared" => ["dl_1"]
           }

    assert [
             %{
               "id" => "dl_1",
               "station_calendar_entry_id" => "provider_outage",
               "station_calendar_provider_id" => "ops_calendar",
               "station_calendar_provider_entry_id" => "ops_calendar_window_1",
               "station_calendar_directions" => ["downlink"],
               "station_calendar_status" => "maintenance",
               "station_calendar_trust_boundary_status" => "declared",
               "trust_boundary" => "declared_station_calendar",
               "provenance" => %{
                 "source" => "station_calendar_provider",
                 "trust_boundary" => "declared_station_calendar"
               },
               "source_station_calendar_entry" => %{
                 "id" => "provider_outage",
                 "provider_id" => "ops_calendar",
                 "provider_entry_id" => "ops_calendar_window_1",
                 "directions" => ["downlink"],
                 "provenance" => %{
                   "source" => "station_calendar_provider",
                   "trust_boundary" => "declared_station_calendar"
                 }
               },
               "source_station_calendar_overlaps" => [
                 %{"id" => "provider_outage"}
               ]
             }
           ] = report["suppressed_candidates"]

    assert {:ok, %{"schema_contract" => "contact_filter_report.v1"}} =
             Schema.validate_artifact(report)

    invalid_trust_ids =
      Map.put(
        report,
        "suppressed_candidate_ids_by_station_calendar_trust_boundary_status",
        %{"declared" => ["stale_contact"]}
      )

    assert {:error, invalid_trust_ids_report} = Schema.validate_artifact(invalid_trust_ids)

    assert Enum.any?(
             invalid_trust_ids_report["errors"],
             &(&1["path"] ==
                 "$.suppressed_candidate_ids_by_station_calendar_trust_boundary_status" and
                 &1["message"] ==
                   "must equal row-derived suppressed_candidate_ids_by_station_calendar_trust_boundary_status")
           )

    invalid_provider_id =
      put_in(
        report,
        ["suppressed_candidates", Access.at(0), "station_calendar_provider_id"],
        "bad provider id"
      )

    assert {:error, invalid_provider_id_report} = Schema.validate_artifact(invalid_provider_id)

    assert Enum.any?(
             invalid_provider_id_report["errors"],
             &(&1["path"] == "$.suppressed_candidates[0].station_calendar_provider_id" and
                 &1["message"] =~ "must match stable ID pattern")
           )
  end

  test "accepts station calendar provider artifacts directly" do
    candidates = [
      contact(:dl_1, starts_at_s: 100.0, ends_at_s: 160.0),
      contact(:track_1, type: :tracking, starts_at_s: 100.0, ends_at_s: 160.0)
    ]

    station_calendar_provider = %{
      schema_contract: "station_calendar_provider.v1",
      id: :ops_calendar,
      trust_boundary: :declared_station_calendar,
      entries: [
        %{
          id: :provider_downlink_outage,
          station_id: :equator_prime,
          availability: :maintenance,
          directions: [:downlink],
          start_s: 90.0,
          end_s: 170.0
        }
      ]
    }

    {kept, report} = ContactFilter.filter_candidates(candidates, station_calendar_provider)

    assert Enum.map(kept, & &1["id"]) == ["track_1"]

    assert [
             %{
               "id" => "dl_1",
               "suppressed_reason" => "ground_station_unavailable",
               "station_calendar_entry_id" => "provider_downlink_outage",
               "station_calendar_provider_id" => "ops_calendar",
               "station_calendar_provider_entry_id" => "provider_downlink_outage",
               "station_calendar_directions" => ["downlink"],
               "station_calendar_trust_boundary_status" => "declared",
               "source_station_calendar_entry" => %{
                 "id" => "provider_downlink_outage",
                 "provider_id" => "ops_calendar",
                 "provider_entry_id" => "provider_downlink_outage",
                 "directions" => ["downlink"],
                 "provenance" => %{
                   "source" => "station_calendar_provider",
                   "provider_id" => "ops_calendar",
                   "trust_boundary" => "declared_station_calendar"
                 }
               }
             }
           ] = report["suppressed_candidates"]

    assert {:ok, %{"schema_contract" => "contact_filter_report.v1"}} =
             Schema.validate_artifact(report)

    facade_report = OrbitalDynamics.contact_filter_report(candidates, station_calendar_provider)

    assert facade_report["suppressed_candidate_count"] == 1
    assert get_in(facade_report, ["suppressed_candidates", Access.at(0), "id"]) == "dl_1"
  end

  test "accepts station calendar provider artifact lists directly" do
    candidates = [
      contact(:dl_1, starts_at_s: 100.0, ends_at_s: 160.0),
      contact(:track_1, type: :tracking, starts_at_s: 100.0, ends_at_s: 160.0)
    ]

    station_calendar_providers = [
      %{
        schema_contract: "station_calendar_provider.v1",
        id: :aux_calendar,
        trust_boundary: :declared_station_calendar,
        entries: [
          %{
            id: :aux_available,
            station_id: :polar_aux,
            availability: :available,
            start_s: 90.0,
            end_s: 170.0
          }
        ]
      },
      %{
        schema_contract: "station_calendar_provider.v1",
        id: :ops_calendar,
        trust_boundary: :declared_station_calendar,
        entries: [
          %{
            id: :provider_downlink_reservation,
            station_id: :equator_prime,
            availability: :reserved,
            directions: [:downlink],
            start_s: 90.0,
            end_s: 170.0,
            reservation_id: :provider_reservation_1,
            reserved_by: :ops_calendar,
            reservation_status: :confirmed
          }
        ]
      }
    ]

    {kept, report} = ContactFilter.filter_candidates(candidates, station_calendar_providers)

    assert Enum.map(kept, & &1["id"]) == ["track_1"]

    assert [
             %{
               "id" => "dl_1",
               "suppressed_reason" => "ground_station_reserved",
               "station_calendar_entry_id" => "provider_downlink_reservation",
               "station_calendar_provider_id" => "ops_calendar",
               "station_calendar_provider_entry_id" => "provider_downlink_reservation",
               "station_calendar_reservation_ids" => ["provider_reservation_1"],
               "station_calendar_reserved_by" => ["ops_calendar"],
               "station_calendar_reservation_statuses" => ["confirmed"],
               "station_calendar_directions" => ["downlink"],
               "source_station_calendar_entry" => %{
                 "id" => "provider_downlink_reservation",
                 "provider_id" => "ops_calendar",
                 "provider_entry_id" => "provider_downlink_reservation",
                 "provenance" => %{
                   "source" => "station_calendar_provider",
                   "provider_id" => "ops_calendar",
                   "trust_boundary" => "declared_station_calendar"
                 }
               }
             }
           ] = report["suppressed_candidates"]

    assert {:ok, %{"schema_contract" => "contact_filter_report.v1"}} =
             Schema.validate_artifact(report)
  end

  test "rejects invalid station calendar provider artifacts at the contact-filter boundary" do
    assert_raise ArgumentError, ~r/station calendar provider entries must be a list/, fn ->
      ContactFilter.filter_candidates(
        [contact(:dl_1, starts_at_s: 100.0, ends_at_s: 160.0)],
        %{
          schema_contract: "station_calendar_provider.v1",
          id: :ops_calendar,
          entries: %{}
        }
      )
    end
  end

  test "treats availability-only maintenance station rows as unavailable" do
    {_kept, report} =
      ContactFilter.filter_candidates(
        [contact(:dl_1, starts_at_s: 100.0, ends_at_s: 160.0)],
        [
          %{
            ground_station_id: :equator_prime,
            availability: :maintenance,
            starts_at_s: 90.0,
            ends_at_s: 170.0
          }
        ]
      )

    assert %{
             "suppressed_candidate_count" => 1,
             "suppressed_candidates" => [
               %{
                 "id" => "dl_1",
                 "suppressed_reason" => "ground_station_unavailable",
                 "station_availability" => "unavailable"
               }
             ]
           } = report

    assert {:ok, %{"schema_contract" => "contact_filter_report.v1"}} =
             Schema.validate_artifact(report)
  end

  test "treats numeric station availability as capacity fraction" do
    {_kept, report} =
      ContactFilter.filter_candidates(
        [contact(:dl_1, starts_at_s: 100.0, ends_at_s: 160.0)],
        [
          %{
            ground_station_id: :equator_prime,
            availability: 0.0,
            starts_at_s: 90.0,
            ends_at_s: 170.0
          }
        ]
      )

    assert %{
             "suppressed_candidate_count" => 1,
             "suppressed_candidates" => [
               %{
                 "id" => "dl_1",
                 "suppressed_reason" => "ground_station_capacity_zero",
                 "station_availability" => "reduced_capacity"
               } = suppressed
             ]
           } = report

    assert suppressed["capacity_fraction"] == 0.0

    assert {:ok, %{"schema_contract" => "contact_filter_report.v1"}} =
             Schema.validate_artifact(report)
  end

  test "preserves reservation context for reserved station suppressions" do
    {_kept, report} =
      ContactFilter.filter_candidates(
        [contact(:dl_1, starts_at_s: 100.0, ends_at_s: 160.0)],
        [
          %{
            "ground_station_id" => "equator_prime",
            "status" => "Reserved",
            "starts_at_s" => 90.0,
            "ends_at_s" => 120.0,
            "reservation_id" => "reservation_1",
            "reserved_by" => "ops_team_b",
            "reservation_status" => "Reserved",
            "provider_counteroffer_negotiation_state" => "unknown"
          }
        ]
      )

    assert %{
             "suppressed_candidate_count" => 1,
             "suppressed_candidates" => [
               %{
                 "id" => "dl_1",
                 "suppressed_reason" => "ground_station_reserved",
                 "station_availability" => "reserved",
                 "station_contention_status" => "reserved_overlap",
                 "station_reservation_id" => "reservation_1",
                 "station_reserved_by" => "ops_team_b",
                 "station_reservation_status" => "reserved"
               }
             ]
           } = report

    suppressed = hd(report["suppressed_candidates"])
    refute Map.has_key?(suppressed, "provider_counteroffer_negotiation_state")
    refute Map.has_key?(suppressed, "provider_counteroffer_id")

    assert {:ok, %{"schema_contract" => "contact_filter_report.v1"}} =
             Schema.validate_artifact(report)
  end

  test "keeps downlink candidates that match declared station reservations" do
    {kept, report} =
      ContactFilter.filter_candidates(
        [
          contact(:dl_reserved_owner,
            starts_at_s: 100.0,
            ends_at_s: 160.0,
            station_reservation_id: :reservation_1
          ),
          contact(:dl_reserved_intruder, starts_at_s: 100.0, ends_at_s: 160.0)
        ],
        [
          %{
            "ground_station_id" => "equator_prime",
            "status" => "reserved",
            "starts_at_s" => 90.0,
            "ends_at_s" => 170.0,
            "reservation_id" => "reservation_1",
            "reserved_by" => "ops_team_b",
            "reservation_status" => "reserved"
          }
        ]
      )

    assert Enum.map(kept, & &1["id"]) == ["dl_reserved_owner"]

    assert %{
             "kept_candidate_count" => 1,
             "suppressed_candidate_count" => 1,
             "station_reservation_match_status_counts" => %{"overlap" => 1},
             "suppressed_candidate_ids_by_reservation_match_status" => %{
               "overlap" => ["dl_reserved_intruder"]
             },
             "suppressed_candidates" => [
               %{
                 "id" => "dl_reserved_intruder",
                 "suppressed_reason" => "ground_station_reserved",
                 "station_reservation_match_status" => "overlap"
               }
             ]
           } = report

    assert {:ok, %{"schema_contract" => "contact_filter_report.v1"}} =
             Schema.validate_artifact(report)

    invalid_match_ids =
      Map.put(report, "suppressed_candidate_ids_by_reservation_match_status", %{
        "overlap" => ["stale_contact"]
      })

    assert {:error, invalid_match_ids_report} = Schema.validate_artifact(invalid_match_ids)

    assert Enum.any?(
             invalid_match_ids_report["errors"],
             &(&1["path"] == "$.suppressed_candidate_ids_by_reservation_match_status" and
                 &1["message"] ==
                   "must equal row-derived suppressed_candidate_ids_by_reservation_match_status")
           )
  end

  test "keeps downlink candidates owned by declared station reservations" do
    {kept, report} =
      ContactFilter.filter_candidates(
        [
          contact(:dl_reserved_owner,
            starts_at_s: 100.0,
            ends_at_s: 160.0,
            reserved_by: :ops_team_b
          ),
          contact(:dl_reserved_intruder, starts_at_s: 100.0, ends_at_s: 160.0)
        ],
        [
          %{
            "ground_station_id" => "equator_prime",
            "status" => "reserved",
            "starts_at_s" => 90.0,
            "ends_at_s" => 170.0,
            "reservation_id" => "reservation_1",
            "reserved_by" => "ops_team_b",
            "reservation_status" => "reserved"
          }
        ]
      )

    assert Enum.map(kept, & &1["id"]) == ["dl_reserved_owner"]

    assert %{
             "kept_candidate_count" => 1,
             "suppressed_candidate_count" => 1,
             "station_reservation_match_status_counts" => %{"overlap" => 1},
             "suppressed_candidates" => [
               %{
                 "id" => "dl_reserved_intruder",
                 "suppressed_reason" => "ground_station_reserved",
                 "station_reserved_by" => "ops_team_b",
                 "station_reservation_match_status" => "overlap"
               }
             ]
           } = report

    assert {:ok, %{"schema_contract" => "contact_filter_report.v1"}} =
             Schema.validate_artifact(report)
  end

  test "unavailable station state outranks reserved overlap while preserving reservation evidence" do
    {_kept, report} =
      ContactFilter.filter_candidates(
        [contact(:dl_1, starts_at_s: 100.0, ends_at_s: 160.0)],
        [
          %{
            ground_station_id: :equator_prime,
            id: :equator_outage,
            status: "Unavailable",
            starts_at_s: 90.0,
            ends_at_s: 170.0
          },
          %{
            ground_station_id: :equator_prime,
            id: :equator_reserved,
            status: "Reserved",
            starts_at_s: 95.0,
            ends_at_s: 165.0,
            reservation_id: :reservation_1,
            reserved_by: :ops_team_b,
            reservation_status: :confirmed,
            reservation_hold_expires_at_s: "420.0"
          }
        ],
        approval_policy: %{policy_bundle_id: "ground_network_allocation_v1"}
      )

    assert %{
             "suppressed_candidate_count" => 1,
             "suppressed_candidates" => [
               %{
                 "id" => "dl_1",
                 "suppressed_reason" => "ground_station_unavailable",
                 "station_availability" => "unavailable",
                 "station_contention_status" => "reserved_overlap",
                 "station_reservation_id" => "reservation_1",
                 "station_reserved_by" => "ops_team_b",
                 "station_reservation_status" => "confirmed",
                 "station_calendar_reservation_overlap_count" => 1,
                 "station_calendar_reservation_ids" => ["reservation_1"],
                 "station_calendar_reserved_by" => ["ops_team_b"],
                 "station_calendar_reservation_statuses" => ["confirmed"],
                 "station_reservation_expires_at_s" => 420.0,
                 "station_calendar_reservation_expires_at_s" => [420.0],
                 "approval_status" => "blocked_by_policy",
                 "approval_requirements" => [
                   %{
                     "policy_classification" => "blocked_by_policy",
                     "activity_context" => %{
                       "station_availability" => "unavailable",
                       "station_contention_status" => "reserved_overlap",
                       "station_reservation_id" => "reservation_1",
                       "station_reserved_by" => "ops_team_b",
                       "station_reservation_status" => "confirmed",
                       "station_reservation_match_status" => "overlap",
                       "station_reservation_expires_at_s" => 420.0,
                       "station_calendar_reservation_ids" => ["reservation_1"],
                       "station_calendar_reservation_expires_at_s" => [420.0]
                     }
                   }
                 ],
                 "approval_rule_matches" => rule_matches
               }
             ]
           } = report

    assert Enum.any?(
             rule_matches,
             &(&1["rule_id"] == "unavailable_station_contact_block" and
                 &1["classification"] == "blocked_by_policy")
           )

    assert {:ok, %{"schema_contract" => "contact_filter_report.v1"}} =
             Schema.validate_artifact(report)
  end

  test "suppresses same-priority ambiguous unavailable ground-network rows" do
    {_kept, report} =
      ContactFilter.filter_candidates(
        [contact(:dl_ambiguous_outage, starts_at_s: 100.0, ends_at_s: 160.0)],
        [
          %{
            id: :equator_outage_a,
            ground_station_id: :equator_prime,
            status: :maintenance,
            starts_at_s: 90.0,
            ends_at_s: 170.0
          },
          %{
            id: :equator_outage_b,
            ground_station_id: :equator_prime,
            status: :offline,
            starts_at_s: 95.0,
            ends_at_s: 165.0
          }
        ]
      )

    assert %{
             "suppressed_candidate_count" => 1,
             "suppressed_candidates" => [
               %{
                 "id" => "dl_ambiguous_outage",
                 "suppressed_reason" => "ground_station_unavailable",
                 "station_availability" => "unavailable",
                 "station_calendar_entry_id" =>
                   "ambiguous_station_calendar:equator_outage_a:equator_outage_b",
                 "station_calendar_status" => "ambiguous",
                 "station_calendar_entry_ambiguous" => true,
                 "station_calendar_ambiguous_entry_count" => 2,
                 "station_calendar_ambiguous_entry_ids" => [
                   "equator_outage_a",
                   "equator_outage_b"
                 ],
                 "station_calendar_overlap_count" => 2,
                 "station_calendar_overlap_entry_ids" => [
                   "equator_outage_a",
                   "equator_outage_b"
                 ],
                 "station_calendar_overlap_availabilities" => ["unavailable"]
               }
             ]
           } = report

    assert {:ok, %{"schema_contract" => "contact_filter_report.v1"}} =
             Schema.validate_artifact(report)

    mismatched_overlap_count =
      put_in(report, ["suppressed_candidates", Access.at(0), "station_calendar_overlap_count"], 1)

    assert {:error, mismatched_overlap_count_report} =
             Schema.validate_artifact(mismatched_overlap_count)

    assert Enum.any?(
             mismatched_overlap_count_report["errors"],
             &(&1["path"] ==
                 "$.suppressed_candidates[0].station_calendar_overlap_count" and
                 &1["message"] == "must be at least 2")
           )

    mismatched_ambiguous_count =
      put_in(
        report,
        ["suppressed_candidates", Access.at(0), "station_calendar_ambiguous_entry_count"],
        1
      )

    assert {:error, mismatched_ambiguous_count_report} =
             Schema.validate_artifact(mismatched_ambiguous_count)

    assert Enum.any?(
             mismatched_ambiguous_count_report["errors"],
             &(&1["path"] ==
                 "$.suppressed_candidates[0].station_calendar_ambiguous_entry_count" and
                 &1["message"] == "must equal 2")
           )
  end

  test "suppresses same-priority ambiguous reserved ground-network rows without choosing one reservation" do
    {_kept, report} =
      ContactFilter.filter_candidates(
        [contact(:dl_ambiguous_reserved, starts_at_s: 100.0, ends_at_s: 160.0)],
        [
          %{
            id: :equator_reserved_a,
            ground_station_id: :equator_prime,
            status: "Reserved",
            starts_at_s: 90.0,
            ends_at_s: 170.0,
            reservation_id: :reservation_a,
            reserved_by: :ops_team_a,
            reservation_status: "Tentative",
            hold_expires_at_s: "360.0"
          },
          %{
            id: :equator_reserved_b,
            ground_station_id: :equator_prime,
            availability: "Reserved",
            starts_at_s: 95.0,
            ends_at_s: 165.0,
            reservation_id: :reservation_b,
            reserved_by: :ops_team_b,
            reservation_status: "Confirmed",
            reservation_expires_at_s: 480.0
          }
        ],
        approval_policy: %{policy_bundle_id: "ground_network_allocation_v1"}
      )

    assert %{
             "suppressed_candidate_count" => 1,
             "suppressed_candidates" => [
               %{
                 "id" => "dl_ambiguous_reserved",
                 "suppressed_reason" => "ground_station_reserved",
                 "station_availability" => "reserved",
                 "station_contention_status" => "reserved_overlap",
                 "station_calendar_entry_id" =>
                   "ambiguous_station_calendar:equator_reserved_a:equator_reserved_b",
                 "station_calendar_status" => "ambiguous",
                 "station_calendar_entry_ambiguous" => true,
                 "station_calendar_ambiguous_entry_count" => 2,
                 "station_calendar_ambiguous_entry_ids" => [
                   "equator_reserved_a",
                   "equator_reserved_b"
                 ],
                 "station_calendar_reservation_overlap_count" => 2,
                 "station_calendar_reservation_ids" => ["reservation_a", "reservation_b"],
                 "station_calendar_reserved_by" => ["ops_team_a", "ops_team_b"],
                 "station_calendar_reservation_statuses" => ["tentative", "confirmed"],
                 "station_calendar_reservation_expires_at_s" => [360.0, 480.0],
                 "approval_requirements" => [
                   %{
                     "activity_context" => %{
                       "station_calendar_entry_ambiguous" => true,
                       "station_calendar_ambiguous_entry_ids" => [
                         "equator_reserved_a",
                         "equator_reserved_b"
                       ],
                       "station_calendar_reservation_ids" => [
                         "reservation_a",
                         "reservation_b"
                       ],
                       "station_calendar_reservation_expires_at_s" => [360.0, 480.0]
                     }
                   }
                 ]
               } = suppressed
             ]
           } = report

    refute Map.has_key?(suppressed, "station_reservation_id")
    refute Map.has_key?(suppressed, "station_reserved_by")
    refute Map.has_key?(suppressed, "station_reservation_status")

    assert {:ok, %{"schema_contract" => "contact_filter_report.v1"}} =
             Schema.validate_artifact(report)
  end

  test "reserved station state outranks reduced capacity while preserving overlap evidence" do
    {_kept, report} =
      ContactFilter.filter_candidates(
        [contact(:dl_reserved_capacity, starts_at_s: 100.0, ends_at_s: 160.0)],
        [
          %{
            id: :equator_reduced,
            ground_station_id: :equator_prime,
            capacity_fraction: 0.4,
            starts_at_s: 90.0,
            ends_at_s: 170.0
          },
          %{
            id: :equator_reserved,
            ground_station_id: :equator_prime,
            status: "Reserved",
            starts_at_s: 95.0,
            ends_at_s: 165.0,
            reservation_id: :reservation_1,
            reserved_by: :ops_team_b,
            reservation_status: "Confirmed"
          }
        ],
        approval_policy: %{policy_bundle_id: "ground_network_allocation_v1"}
      )

    assert %{
             "suppressed_candidate_count" => 1,
             "suppressed_candidates" => [
               %{
                 "id" => "dl_reserved_capacity",
                 "suppressed_reason" => "ground_station_reserved",
                 "station_availability" => "reserved",
                 "station_contention_status" => "reserved_overlap",
                 "station_calendar_overlap_count" => 2,
                 "station_calendar_overlap_entry_ids" => [
                   "equator_reduced",
                   "equator_reserved"
                 ],
                 "station_calendar_overlap_availabilities" => [
                   "reserved",
                   "reduced_capacity"
                 ],
                 "station_calendar_reservation_ids" => ["reservation_1"],
                 "station_calendar_reserved_by" => ["ops_team_b"],
                 "station_calendar_reservation_statuses" => ["confirmed"],
                 "station_reservation_match_status" => "overlap"
               }
             ]
           } = report

    assert {:ok, %{"schema_contract" => "contact_filter_report.v1"}} =
             Schema.validate_artifact(report)
  end

  test "suppresses downlinks when station capacity is zero" do
    {_kept, report} =
      ContactFilter.filter_candidates(
        [contact(:dl_1, starts_at_s: 100.0, ends_at_s: 160.0)],
        [
          %{
            ground_station_id: :equator_prime,
            capacity_pack_capacity_fraction: 0.0,
            starts_at_s: 90.0,
            ends_at_s: 120.0
          }
        ]
      )

    assert %{
             "suppressed_candidate_count" => 1,
             "suppressed_candidates" => [
               %{
                 "id" => "dl_1",
                 "suppressed_reason" => "ground_station_capacity_zero",
                 "station_availability" => "reduced_capacity",
                 "capacity_fraction" => capacity_fraction,
                 "source_station_calendar_entry" => %{
                   "capacity_pack_capacity_fraction" => source_capacity_pack_fraction
                 }
               }
             ]
           } = report

    assert capacity_fraction == 0.0
    assert source_capacity_pack_fraction == 0.0
  end

  test "normalizes numeric string timing capacity and factor fields before filtering" do
    {_kept, report} =
      ContactFilter.filter_candidates(
        [
          %{
            id: :dl_1,
            type: :downlink,
            scenario_id: :leo_1,
            station_id: :equator_prime,
            start_s: "100.0",
            end_s: "160.0",
            contact_success_factor: "0.75"
          }
        ],
        [
          %{
            ground_station_id: :equator_prime,
            capacity_fraction: "0.0",
            starts_at_s: 90.0,
            ends_at_s: 120.0
          }
        ]
      )

    assert %{
             "suppressed_candidate_count" => 1,
             "suppressed_candidates" => [
               %{
                 "id" => "dl_1",
                 "starts_at_s" => 100.0,
                 "ends_at_s" => 160.0,
                 "suppressed_reason" => "ground_station_capacity_zero",
                 "station_availability" => "reduced_capacity",
                 "capacity_fraction" => capacity_fraction,
                 "contact_success_factor" => 0.75
               }
             ]
           } = report

    assert capacity_fraction == 0.0

    assert {:ok, %{"schema_contract" => "contact_filter_report.v1"}} =
             Schema.validate_artifact(report)
  end

  test "keeps downlinks when duplicate overlapping station states are ambiguous" do
    candidates = [contact(:dl_1, starts_at_s: 100.0, ends_at_s: 160.0)]

    ground_network = [
      %{
        ground_station_id: :equator_prime,
        capacity_fraction: 0.0,
        starts_at_s: 90.0,
        ends_at_s: 170.0
      },
      %{
        ground_station_id: :equator_prime,
        capacity_fraction: 0.5,
        starts_at_s: 90.0,
        ends_at_s: 170.0
      }
    ]

    {kept, report} = ContactFilter.filter_candidates(candidates, ground_network)

    assert Enum.map(kept, & &1["id"]) == ["dl_1"]
    assert report["kept_candidate_count"] == 1
    assert report["suppressed_candidate_count"] == 0
    assert report["suppressed_candidates"] == []

    assert {:ok, %{"schema_contract" => "contact_filter_report.v1"}} =
             Schema.validate_artifact(report)
  end

  test "preserves station calendar ambiguity on suppressed contact review and import rows" do
    candidate =
      contact(:dl_ambiguous, starts_at_s: 100.0, ends_at_s: 160.0)
      |> Map.put(:station_calendar_entry_id, "ambiguous_station_calendar:outage_a:outage_b")
      |> Map.put(:station_calendar_status, "ambiguous")
      |> Map.put(:station_calendar_overlap_count, 2)
      |> Map.put(:station_calendar_overlap_entry_ids, ["outage_a", "outage_b"])
      |> Map.put(:station_calendar_overlap_availabilities, ["unavailable"])
      |> Map.put(:station_calendar_entry_ambiguous, true)
      |> Map.put(:station_calendar_ambiguous_entry_count, 2)
      |> Map.put(:station_calendar_ambiguous_entry_ids, ["outage_a", "outage_b"])

    ground_network = [
      %{
        ground_station_id: :equator_prime,
        status: :unavailable,
        starts_at_s: 90.0,
        ends_at_s: 170.0
      }
    ]

    {_kept, report} =
      ContactFilter.filter_candidates([candidate], ground_network,
        approval_policy: %{policy_bundle_id: "ground_network_allocation_v1"}
      )

    assert [
             %{
               "id" => "dl_ambiguous",
               "suppressed_reason" => "ground_station_unavailable",
               "station_calendar_entry_ambiguous" => true,
               "station_calendar_ambiguous_entry_count" => 2,
               "station_calendar_ambiguous_entry_ids" => ambiguous_entry_ids
             }
           ] = report["suppressed_candidates"]

    assert ambiguous_entry_ids == ["outage_a", "outage_b"]

    assert [
             %{
               "activity_context" => %{
                 "station_availability" => "unavailable",
                 "station_calendar_entry_ambiguous" => true,
                 "station_calendar_ambiguous_entry_count" => 2,
                 "station_calendar_ambiguous_entry_ids" => ^ambiguous_entry_ids
               }
             }
           ] = get_in(report, ["suppressed_candidates", Access.at(0), "approval_requirements"])

    assert {:ok, %{"schema_contract" => "contact_filter_report.v1"}} =
             Schema.validate_artifact(report)

    review = OperatorReview.from_contact_filter_report(report)

    assert [
             %{
               "review_type" => "contact_suppression",
               "station_calendar_entry_ambiguous" => true,
               "station_calendar_ambiguous_entry_ids" => ^ambiguous_entry_ids
             }
           ] = review["rows"]

    manifest = CadenceImport.from_contact_filter_report(report)

    assert [
             %{
               "import_action" => "review_contact_suppression",
               "station_calendar_entry_ambiguous" => true,
               "station_calendar_ambiguous_entry_ids" => ^ambiguous_entry_ids
             }
           ] = manifest["rows"]
  end

  test "carries contact feedback evidence into suppression policy, review, and import rows" do
    candidate =
      contact(:dl_failed_feedback,
        starts_at_s: 100.0,
        ends_at_s: 160.0,
        metadata: %{
          contact_success: " FALSE ",
          contact_result: %{
            outcome: :accepted,
            provider_status: :dropped
          },
          contact_success_factor: "0.25",
          contact_success_factor_source: :operational_feedback_contact_success,
          command_success: " False ",
          command_result: %{
            outcome: :accepted,
            status: :rejected
          },
          command_success_factor: "0.5",
          command_success_factor_source: :operational_feedback_command_success
        }
      )

    ground_network = [
      %{
        ground_station_id: :equator_prime,
        status: :maintenance,
        starts_at_s: 90.0,
        ends_at_s: 170.0
      }
    ]

    {_kept, report} =
      ContactFilter.filter_candidates([candidate], ground_network,
        approval_policy: %{policy_bundle_id: "command_contact_authority_v1"}
      )

    assert [
             %{
               "id" => "dl_failed_feedback",
               "suppressed_reason" => "ground_station_unavailable",
               "contact_success" => false,
               "contact_result" => "accepted,dropped",
               "contact_success_factor" => 0.25,
               "contact_success_factor_source" => "operational_feedback_contact_success",
               "command_success" => false,
               "command_result" => "accepted,rejected",
               "command_success_factor" => 0.5,
               "command_success_factor_source" => "operational_feedback_command_success",
               "approval_requirements" => [
                 %{
                   "activity_context" => %{
                     "contact_success" => false,
                     "contact_result" => "accepted,dropped",
                     "contact_success_factor" => 0.25,
                     "contact_success_factor_source" => "operational_feedback_contact_success",
                     "command_success" => false,
                     "command_result" => "accepted,rejected",
                     "command_success_factor" => 0.5,
                     "command_success_factor_source" => "operational_feedback_command_success"
                   }
                 }
               ]
             } = row
           ] = report["suppressed_candidates"]

    assert Enum.any?(
             row["approval_rule_matches"],
             &(&1["rule_id"] == "failed_contact_success_review" and
                 &1["contact_success"] == false)
           )

    assert Enum.any?(
             row["approval_rule_matches"],
             &(&1["rule_id"] == "low_contact_success_confidence_review" and
                 &1["contact_success_factor"] == 0.25 and
                 &1["contact_success_factor_source"] ==
                   "operational_feedback_contact_success")
           )

    assert {:ok, %{"schema_contract" => "contact_filter_report.v1"}} =
             Schema.validate_artifact(report)

    review = OperatorReview.from_contact_filter_report(report)

    assert [
             %{
               "review_type" => "contact_suppression",
               "contact_success" => false,
               "contact_result" => "accepted,dropped",
               "contact_success_factor" => 0.25,
               "contact_success_factor_source" => "operational_feedback_contact_success",
               "command_success" => false,
               "command_result" => "accepted,rejected",
               "command_success_factor" => 0.5,
               "command_success_factor_source" => "operational_feedback_command_success",
               "source_contact_suppression" => %{
                 "contact_success" => false,
                 "contact_result" => "accepted,dropped",
                 "command_success" => false
               }
             }
           ] = review["rows"]

    manifest = CadenceImport.from_contact_filter_report(report)

    assert [
             %{
               "import_action" => "review_contact_suppression",
               "contact_success" => false,
               "contact_result" => "accepted,dropped",
               "contact_success_factor" => 0.25,
               "contact_success_factor_source" => "operational_feedback_contact_success",
               "command_success" => false,
               "command_result" => "accepted,rejected",
               "command_success_factor" => 0.5,
               "command_success_factor_source" => "operational_feedback_command_success",
               "source_contact_suppression" => %{
                 "contact_success" => false,
                 "contact_result" => "accepted,dropped",
                 "command_success" => false
               },
               "source_review_row" => %{
                 "contact_success" => false,
                 "contact_result" => "accepted,dropped",
                 "command_success" => false
               }
             }
           ] = manifest["rows"]
  end

  test "review-gates out-of-range feedback confidence factors before suppression policy handoff" do
    candidate =
      contact(:dl_invalid_feedback,
        starts_at_s: 100.0,
        ends_at_s: 160.0,
        metadata: %{
          contact_success_factor: 1.4,
          contact_success_factor_source: :operator_feedback,
          command_success_factor: -0.25,
          command_success_factor_source: :command_adapter
        }
      )

    ground_network = [
      %{
        ground_station_id: :equator_prime,
        status: :maintenance,
        starts_at_s: 90.0,
        ends_at_s: 170.0
      }
    ]

    {_kept, report} =
      ContactFilter.filter_candidates([candidate], ground_network,
        approval_policy: %{policy_bundle_id: "command_contact_authority_v1"}
      )

    assert [
             %{
               "id" => "dl_invalid_feedback",
               "suppressed_reason" => "invalid_contact_input",
               "invalid_contact_input" => true,
               "invalid_contact_input_reason" => "invalid_contact_success_factor",
               "source_contact_candidate" => %{
                 "metadata" => %{
                   "contact_success_factor" => 1.4,
                   "command_success_factor" => -0.25
                 }
               }
             }
           ] = report["suppressed_candidates"]

    suppressed = List.first(report["suppressed_candidates"])

    refute Map.has_key?(suppressed, "contact_success_factor")
    refute Map.has_key?(suppressed, "command_success_factor")
    assert report["invalid_contact_input_count"] == 1
    assert report["invalid_contact_input_ids"] == ["dl_invalid_feedback"]

    review = OperatorReview.from_contact_filter_report(report)
    manifest = CadenceImport.from_contact_filter_report(report)

    assert Enum.any?(
             review["rows"],
             &(&1["subject_id"] == "dl_invalid_feedback" and
                 &1["invalid_contact_input_reason"] == "invalid_contact_success_factor")
           )

    assert Enum.any?(
             manifest["rows"],
             &(&1["subject_id"] == "dl_invalid_feedback" and
                 &1["invalid_contact_input_reason"] == "invalid_contact_success_factor")
           )

    assert {:ok, %{"schema_contract" => "contact_filter_report.v1"}} =
             Schema.validate_artifact(report)
  end

  test "disambiguates duplicate suppressed candidate ids without dropping rows" do
    candidates = [
      contact(:dup_contact, scenario_id: :leo_1, starts_at_s: 100.0, ends_at_s: 160.0),
      contact(:dup_contact, scenario_id: :leo_2, starts_at_s: 120.0, ends_at_s: 180.0)
    ]

    ground_network = [
      %{
        ground_station_id: :equator_prime,
        status: :maintenance,
        starts_at_s: 90.0,
        ends_at_s: 190.0
      }
    ]

    {_kept, report} = ContactFilter.filter_candidates(candidates, ground_network)

    assert %{
             "suppressed_candidate_count" => 2,
             "duplicate_suppressed_candidate_id_count" => 1,
             "duplicate_suppressed_candidate_row_count" => 2,
             "suppressed_candidates" => suppressed_candidates
           } = report

    assert Enum.map(suppressed_candidates, & &1["id"]) == ["dup_contact:1", "dup_contact:2"]
    assert Enum.map(suppressed_candidates, & &1["scenario_id"]) == ["leo_1", "leo_2"]

    assert Enum.all?(
             suppressed_candidates,
             &(&1["base_candidate_id"] == "dup_contact" and
                 &1["duplicate_suppressed_candidate_id_collision"])
           )

    assert Enum.map(suppressed_candidates, & &1["duplicate_suppressed_candidate_index"]) == [1, 2]
    assert Enum.all?(suppressed_candidates, &(&1["duplicate_suppressed_candidate_count"] == 2))

    assert {:ok, %{"schema_contract" => "contact_filter_report.v1"}} =
             Schema.validate_artifact(report)

    missing_duplicate_evidence =
      update_in(
        report,
        ["suppressed_candidates", Access.at(0)],
        &Map.delete(&1, "base_candidate_id")
      )

    assert {:error, missing_duplicate_evidence_report} =
             Schema.validate_artifact(missing_duplicate_evidence)

    assert Enum.any?(
             missing_duplicate_evidence_report["errors"],
             &(&1["path"] == "$.suppressed_candidates[0].base_candidate_id" and
                 &1["message"] == "is required")
           )

    invalid_row_duplicate_count =
      update_in(
        report,
        ["suppressed_candidates", Access.at(0)],
        &Map.put(&1, "duplicate_suppressed_candidate_count", 1)
      )

    assert {:error, row_duplicate_count_report} =
             Schema.validate_artifact(invalid_row_duplicate_count)

    assert Enum.any?(
             row_duplicate_count_report["errors"],
             &(&1["path"] == "$.suppressed_candidates[0].duplicate_suppressed_candidate_count" and
                 &1["message"] == "must equal 2")
           )

    duplicate_index_collision =
      update_in(
        report,
        ["suppressed_candidates", Access.at(1)],
        &Map.put(&1, "duplicate_suppressed_candidate_index", 1)
      )

    assert {:error, duplicate_index_report} =
             Schema.validate_artifact(duplicate_index_collision)

    assert Enum.any?(
             duplicate_index_report["errors"],
             &(&1["path"] == "$.suppressed_candidates" and
                 String.starts_with?(
                   &1["message"],
                   "duplicate_suppressed_candidate_index values must cover 1..2"
                 ))
           )

    invalid_duplicate_count = Map.put(report, "duplicate_suppressed_candidate_row_count", 1)

    assert {:error, duplicate_count_report} = Schema.validate_artifact(invalid_duplicate_count)

    assert Enum.any?(
             duplicate_count_report["errors"],
             &(&1["path"] == "$.duplicate_suppressed_candidate_row_count" and
                 &1["message"] == "must equal 2")
           )

    review = OperatorReview.from_contact_filter_report(report)

    assert Enum.count(
             review["rows"],
             &(&1["base_candidate_id"] == "dup_contact" and
                 &1["duplicate_suppressed_candidate_id_collision"])
           ) == 2

    manifest = CadenceImport.from_contact_filter_report(report)

    assert Enum.count(
             manifest["rows"],
             &(&1["base_candidate_id"] == "dup_contact" and
                 &1["duplicate_suppressed_candidate_id_collision"])
           ) == 2
  end

  test "classifies suppressed contacts with approval policy" do
    candidates = [
      contact(:dl_blocked, starts_at_s: 100.0, ends_at_s: 160.0),
      contact(:dl_reserved, starts_at_s: 200.0, ends_at_s: 260.0),
      contact(:dl_zero, starts_at_s: 300.0, ends_at_s: 360.0)
    ]

    ground_network = [
      %{
        ground_station_id: :equator_prime,
        status: :maintenance,
        starts_at_s: 90.0,
        ends_at_s: 170.0
      },
      %{
        ground_station_id: :equator_prime,
        status: :reserved,
        starts_at_s: 190.0,
        ends_at_s: 270.0,
        reservation_id: :reservation_1,
        reserved_by: "ops_team_b",
        reservation_status: :reserved
      },
      %{
        ground_station_id: :equator_prime,
        capacity_fraction: 0.0,
        starts_at_s: 290.0,
        ends_at_s: 370.0
      }
    ]

    report =
      ContactFilter.report(candidates, ground_network,
        approval_policy: %{policy_bundle_id: "ground_network_allocation_v1"}
      )

    rows = Map.new(report["suppressed_candidates"], &{&1["id"], &1})

    assert %{
             "approval_status" => "blocked_by_policy",
             "approval_rule_matches" => [
               %{"rule_id" => "unavailable_station_contact_block"}
             ],
             "policy_decision" => %{"policy_bundle_id" => "ground_network_allocation_v1"}
           } = rows["dl_blocked"]

    assert %{
             "approval_status" => "operator_review_required",
             "station_contention_status" => "reserved_overlap",
             "approval_rule_matches" => [
               %{"rule_id" => "reserved_station_contact_review"}
             ]
           } = rows["dl_reserved"]

    assert %{
             "approval_status" => "operator_review_required",
             "approval_rule_matches" => [
               %{"rule_id" => "severe_capacity_reduction_review"}
             ]
           } = rows["dl_zero"]

    assert rows["dl_zero"]["capacity_fraction"] == 0.0

    assert {:ok, %{"schema_contract" => "contact_filter_report.v1"}} =
             Schema.validate_artifact(report)
  end

  test "keeps downlinks when station windows do not overlap" do
    {kept, report} =
      ContactFilter.filter_candidates(
        [contact(:dl_1, starts_at_s: 100.0, ends_at_s: 160.0)],
        [
          %{
            ground_station_id: :equator_prime,
            status: :unavailable,
            starts_at_s: 10.0,
            ends_at_s: 20.0
          }
        ]
      )

    assert Enum.map(kept, & &1["id"]) == ["dl_1"]
    assert report["kept_candidate_count"] == 1
    assert report["suppressed_candidate_count"] == 0
    assert report["suppressed_candidates"] == []
  end

  test "public facades filter contact candidates and build reports" do
    candidates = [contact(:dl_1, starts_at_s: 100.0, ends_at_s: 160.0)]
    ground_network = [%{ground_station_id: :equator_prime, available: false}]

    {kept, report} = OrbitalDynamics.filter_contact_candidates(candidates, ground_network)

    assert kept == []
    assert report["suppressed_candidate_count"] == 1

    assert OrbitalDynamics.contact_filter_report(candidates, ground_network) == report
    assert ContactFilter.report(report) == report
    assert OrbitalDynamics.contact_filter_report(report) == report

    atom_keyed_report =
      Map.new(report, fn {key, value} -> {String.to_atom(key), value} end)

    assert ContactFilter.report(atom_keyed_report) == report
    assert OrbitalDynamics.contact_filter_report(atom_keyed_report) == report
  end

  test "filters downlink planned-contact rows" do
    {_kept, report} =
      ContactFilter.filter_candidates(
        [
          %{
            id: :planned_1,
            type: :planned_contact,
            direction: :downlink,
            scenario_id: :leo_1,
            ground_station_id: :equator_prime,
            starts_at_s: 100.0,
            ends_at_s: 160.0
          }
        ],
        [%{ground_station_id: :equator_prime, status: :offline}],
        approval_policy: %{policy_bundle_id: "ground_network_allocation_v1"}
      )

    assert %{
             "suppressed_candidate_count" => 1,
             "suppressed_candidates" => [
               %{
                 "id" => "planned_1",
                 "suppressed_reason" => "ground_station_unavailable",
                 "approval_status" => "blocked_by_policy",
                 "approval_requirements" => [
                   %{
                     "action" => "review_suppressed_contact",
                     "requirement_type" => "contact_schedule_change"
                   }
                 ],
                 "approval_rule_matches" => [
                   %{"rule_id" => "unavailable_station_contact_block"}
                 ]
               }
             ]
           } = report
  end

  test "filters tracking station contacts without suppressing command or uplink contacts" do
    {kept, report} =
      ContactFilter.filter_candidates(
        [
          %{
            id: :planned_tracking,
            type: :planned_contact,
            direction: :tracking,
            scenario_id: :leo_1,
            ground_station_id: :equator_prime,
            starts_at_s: 100.0,
            ends_at_s: 160.0
          },
          %{
            id: :typed_tracking,
            type: :tracking,
            scenario_id: :leo_1,
            ground_station_id: :equator_prime,
            starts_at_s: 100.0,
            ends_at_s: 160.0
          },
          %{
            id: :provider_tracking,
            type: :contact,
            direction: :tracking,
            scenario_id: :leo_1,
            station_id: :equator_prime,
            starts_at_s: 100.0,
            ends_at_s: 160.0
          },
          %{
            id: :planned_command,
            type: :planned_contact,
            direction: :command,
            scenario_id: :leo_1,
            ground_station_id: :equator_prime,
            starts_at_s: 100.0,
            ends_at_s: 160.0
          },
          %{
            id: :uplink_contact,
            type: :contact,
            direction: :uplink,
            scenario_id: :leo_1,
            ground_station_id: :equator_prime,
            starts_at_s: 100.0,
            ends_at_s: 160.0
          }
        ],
        [%{ground_station_id: :equator_prime, status: :offline}],
        approval_policy: %{policy_bundle_id: "ground_network_allocation_v1"}
      )

    assert Enum.map(kept, & &1["id"]) == ["planned_command", "uplink_contact"]

    rows = Map.new(report["suppressed_candidates"], &{&1["id"], &1})

    assert %{
             "id" => "planned_tracking",
             "type" => "planned_contact",
             "direction" => "tracking",
             "suppressed_reason" => "ground_station_unavailable",
             "approval_status" => "blocked_by_policy",
             "approval_requirements" => [
               %{
                 "action" => "review_suppressed_contact",
                 "requirement_type" => "contact_schedule_change",
                 "activity_context" => %{"direction" => "tracking"}
               }
             ],
             "approval_rule_matches" => [
               %{"rule_id" => "unavailable_station_contact_block"}
             ]
           } = rows["planned_tracking"]

    assert %{
             "id" => "typed_tracking",
             "type" => "tracking",
             "direction" => "tracking",
             "suppressed_reason" => "ground_station_unavailable"
           } = rows["typed_tracking"]

    assert %{
             "id" => "provider_tracking",
             "type" => "contact",
             "direction" => "tracking",
             "ground_station_id" => "equator_prime",
             "suppressed_reason" => "ground_station_unavailable"
           } = rows["provider_tracking"]

    review_rows =
      report
      |> OperatorReview.from_contact_filter_report()
      |> Map.fetch!("rows")
      |> Map.new(&{&1["subject_id"], &1})

    assert %{
             "direction" => "tracking",
             "required_operator_action" => "review_suppressed_contact"
           } = review_rows["provider_tracking"]

    import_rows =
      report
      |> CadenceImport.from_contact_filter_report()
      |> Map.fetch!("rows")
      |> Map.new(&{&1["subject_id"], &1})

    assert %{
             "direction" => "tracking",
             "import_action" => "review_contact_suppression",
             "source_review_action" => "review_suppressed_contact"
           } = import_rows["provider_tracking"]

    assert {:ok, %{"schema_contract" => "contact_filter_report.v1"}} =
             Schema.validate_artifact(report)
  end

  test "filters direction-only downlink station rows" do
    {_kept, report} =
      ContactFilter.filter_candidates(
        [
          %{
            id: :dl_direction_only,
            direction: :downlink,
            scenario_id: :leo_1,
            ground_station_id: :equator_prime,
            starts_at_s: 100.0,
            ends_at_s: 160.0
          }
        ],
        [%{ground_station_id: :equator_prime, status: :offline}]
      )

    assert %{
             "suppressed_candidate_count" => 1,
             "suppressed_candidates" => [
               %{
                 "id" => "dl_direction_only",
                 "direction" => "downlink",
                 "suppressed_reason" => "ground_station_unavailable",
                 "station_availability" => "unavailable"
               }
             ]
           } = report

    assert {:ok, %{"schema_contract" => "contact_filter_report.v1"}} =
             Schema.validate_artifact(report)
  end

  test "filters station-id-only provider contacts" do
    {_kept, report} =
      ContactFilter.filter_candidates(
        [
          %{
            id: :provider_contact,
            type: :contact,
            direction: :downlink,
            scenario_id: :leo_1,
            station_id: :equator_prime,
            starts_at_s: 100.0,
            ends_at_s: 160.0
          }
        ],
        [%{ground_station_id: :equator_prime, status: :offline}]
      )

    assert %{
             "suppressed_candidate_count" => 1,
             "suppressed_candidates" => [
               %{
                 "id" => "provider_contact",
                 "type" => "contact",
                 "direction" => "downlink",
                 "ground_station_id" => "equator_prime",
                 "suppressed_reason" => "ground_station_unavailable",
                 "station_availability" => "unavailable"
               }
             ]
           } = report

    assert {:ok, %{"schema_contract" => "contact_filter_report.v1"}} =
             Schema.validate_artifact(report)
  end

  test "filters provider contacts with nested station identity objects" do
    {_kept, report} =
      ContactFilter.filter_candidates(
        [
          %{
            id: :provider_nested_station,
            direction: :downlink,
            scenario_id: :leo_1,
            station: %{id: :equator_prime},
            starts_at_s: 100.0,
            ends_at_s: 160.0
          },
          %{
            id: :provider_nested_ground_station,
            direction: :downlink,
            scenario_id: :leo_2,
            ground_station: %{ground_station_id: :equator_prime},
            starts_at_s: 180.0,
            ends_at_s: 220.0
          }
        ],
        [%{ground_station_id: :equator_prime, status: :offline}]
      )

    assert %{
             "suppressed_candidate_count" => 2,
             "suppressed_candidates" => suppressed
           } = report

    assert Enum.all?(suppressed, &(&1["ground_station_id"] == "equator_prime"))
    assert Enum.all?(suppressed, &(&1["suppressed_reason"] == "ground_station_unavailable"))

    assert Enum.any?(
             suppressed,
             &(&1["id"] == "provider_nested_station" and
                 &1["ground_station_id"] == "equator_prime")
           )

    assert Enum.any?(
             suppressed,
             &(&1["id"] == "provider_nested_ground_station" and
                 &1["ground_station_id"] ==
                   "equator_prime")
           )

    assert {:ok, %{"schema_contract" => "contact_filter_report.v1"}} =
             Schema.validate_artifact(report)
  end

  test "filters provider contacts without explicit type or direction" do
    {_kept, report} =
      ContactFilter.filter_candidates(
        [
          %{
            id: :provider_contact,
            scenario_id: :leo_1,
            station_id: :equator_prime,
            starts_at_s: 100.0,
            ends_at_s: 160.0,
            estimated_throughput_mb: 120.0,
            station_calendar_overlap_availabilities: [nil, :offline]
          },
          %{
            scenario_id: :leo_1,
            station_id: :equator_prime,
            starts_at_s: 180.0,
            ends_at_s: 220.0,
            actual_throughput_mb: 12.0
          }
        ],
        [%{ground_station_id: :equator_prime, status: :offline}]
      )

    assert %{
             "suppressed_candidate_count" => 2,
             "invalid_contact_input_count" => 1,
             "invalid_contact_input_ids" => ["missing_contact_id:2"],
             "suppressed_candidates" => suppressed
           } = report

    assert %{
             "id" => "provider_contact",
             "type" => "downlink",
             "direction" => "downlink",
             "station_calendar_overlap_availabilities" => ["unavailable"],
             "ground_station_id" => "equator_prime",
             "suppressed_reason" => "ground_station_unavailable",
             "station_availability" => "unavailable",
             "source_station_calendar_entry" => %{
               "status" => "unavailable"
             }
           } = Enum.find(suppressed, &(&1["id"] == "provider_contact"))

    assert %{
             "id" => "missing_contact_id:2",
             "type" => "downlink",
             "direction" => "downlink",
             "suppressed_reason" => "invalid_contact_input",
             "invalid_contact_input_reason" => "missing_contact_id",
             "source_contact_candidate" => %{
               "ground_station_id" => "equator_prime",
               "actual_throughput_mb" => 12.0
             }
           } = Enum.find(suppressed, &(&1["id"] == "missing_contact_id:2"))

    assert {:ok, %{"schema_contract" => "contact_filter_report.v1"}} =
             Schema.validate_artifact(report)
  end

  test "filters contacts using station-id-only ground network entries" do
    {_kept, report} =
      ContactFilter.filter_candidates(
        [contact(:dl_1, starts_at_s: 100.0, ends_at_s: 160.0)],
        [
          %{
            station_id: :equator_prime,
            status: :offline,
            starts_at_s: 90.0,
            ends_at_s: 170.0
          }
        ]
      )

    assert %{
             "suppressed_candidate_count" => 1,
             "suppressed_candidates" => [
               %{
                 "id" => "dl_1",
                 "ground_station_id" => "equator_prime",
                 "suppressed_reason" => "ground_station_unavailable",
                 "station_availability" => "unavailable",
                 "source_station_calendar_entry" => %{
                   "status" => "unavailable"
                 }
               }
             ]
           } = report

    assert {:ok, %{"schema_contract" => "contact_filter_report.v1"}} =
             Schema.validate_artifact(report)
  end

  test "suppresses direct station-calendar outage evidence on contact candidates" do
    candidates = [
      contact(:dl_status_only,
        station_calendar_status: "Offline"
      ),
      contact(:dl_nested_outage_overrides_flat_available,
        starts_at_s: 180.0,
        ends_at_s: 220.0,
        station_availability: "Available",
        source_station_calendar_entry: %{
          id: :nested_provider_outage,
          availability: "Offline",
          provenance: %{trust_boundary: :ground_partner_api}
        }
      ),
      contact(:dl_direct_reserved_reviewable,
        starts_at_s: 240.0,
        ends_at_s: 300.0,
        station_availability: "Reserved",
        station_contention_status: "Reserved Overlap"
      )
    ]

    {kept, report} =
      ContactFilter.filter_candidates(candidates, [],
        approval_policy: %{policy_bundle_id: "ground_network_allocation_v1"}
      )

    assert Enum.map(kept, & &1["id"]) == ["dl_direct_reserved_reviewable"]
    assert report["suppressed_candidate_count"] == 2

    status_only = Enum.find(report["suppressed_candidates"], &(&1["id"] == "dl_status_only"))

    assert %{
             "suppressed_reason" => "ground_station_unavailable",
             "station_availability" => "unavailable",
             "station_calendar_status" => "unavailable",
             "approval_status" => "blocked_by_policy"
           } = status_only

    assert Enum.any?(
             status_only["approval_rule_matches"],
             &(&1["rule_id"] == "unavailable_station_contact_block" and
                 &1["station_availability"] == "unavailable")
           )

    nested_outage =
      Enum.find(
        report["suppressed_candidates"],
        &(&1["id"] == "dl_nested_outage_overrides_flat_available")
      )

    assert %{
             "suppressed_reason" => "ground_station_unavailable",
             "station_availability" => "unavailable",
             "station_calendar_entry_id" => "nested_provider_outage",
             "source_station_calendar_entry" => %{
               "availability" => "unavailable"
             },
             "approval_status" => "blocked_by_policy"
           } = nested_outage

    assert Enum.any?(
             nested_outage["approval_rule_matches"],
             &(&1["rule_id"] == "unavailable_station_contact_block" and
                 &1["station_availability"] == "unavailable")
           )

    assert {:ok, %{"schema_contract" => "contact_filter_report.v1"}} =
             Schema.validate_artifact(report)
  end

  test "accepts activity-type-only tracking and health-check rows without downlink inference" do
    candidates = [
      %{
        id: :provider_tracking,
        activity_type: :tracking,
        scenario_id: :leo_1,
        station_id: :equator_prime,
        start_s: 100.0,
        end_s: 160.0
      },
      %{
        id: :provider_health_check,
        activity_type: :health_check,
        scenario_id: :leo_1,
        station_id: :equator_prime,
        start_s: 170.0,
        end_s: 220.0
      },
      %{
        id: :provider_command,
        activity_type: :command,
        scenario_id: :leo_1,
        station_id: :equator_prime,
        start_s: 100.0,
        end_s: 160.0
      }
    ]

    {kept, report} =
      ContactFilter.filter_candidates(candidates, [
        %{station_id: :equator_prime, status: :offline, starts_at_s: 90.0, ends_at_s: 230.0}
      ])

    assert Enum.map(kept, & &1["id"]) == ["provider_command"]

    assert Enum.map(report["suppressed_candidates"], &{&1["id"], &1["type"], &1["direction"]}) ==
             [
               {"provider_tracking", "tracking", "tracking"},
               {"provider_health_check", "health_check", "health_check"}
             ]

    assert %{
             "id" => "provider_tracking",
             "ground_station_id" => "equator_prime",
             "starts_at_s" => 100.0,
             "ends_at_s" => 160.0,
             "suppressed_reason" => "ground_station_unavailable"
           } = Enum.find(report["suppressed_candidates"], &(&1["id"] == "provider_tracking"))

    assert %{
             "id" => "provider_health_check",
             "ground_station_id" => "equator_prime",
             "starts_at_s" => 170.0,
             "ends_at_s" => 220.0,
             "suppressed_reason" => "ground_station_unavailable"
           } = Enum.find(report["suppressed_candidates"], &(&1["id"] == "provider_health_check"))

    assert {:ok, %{"schema_contract" => "contact_filter_report.v1"}} =
             Schema.validate_artifact(report)
  end

  test "uses health-check review requirements for suppressed health-check contacts" do
    candidates = [
      contact(:health_reserved,
        type: :health_check,
        starts_at_s: 100.0,
        ends_at_s: 160.0
      )
    ]

    ground_network = [
      %{
        ground_station_id: :equator_prime,
        status: :reserved,
        reservation_id: :reservation_health,
        starts_at_s: 90.0,
        ends_at_s: 170.0
      }
    ]

    {_kept, report} =
      ContactFilter.filter_candidates(candidates, ground_network,
        approval_policy: %{policy_bundle_id: "ground_network_allocation_v1"}
      )

    assert [
             %{
               "id" => "health_reserved",
               "type" => "health_check",
               "direction" => "health_check",
               "suppressed_reason" => "ground_station_reserved",
               "approval_requirements" => [
                 %{
                   "activity_type" => "health_check",
                   "requirement_type" => "health_check_review",
                   "activity_context" => %{
                     "direction" => "health_check",
                     "station_reservation_id" => "reservation_health"
                   }
                 }
               ]
             }
           ] = report["suppressed_candidates"]

    assert {:ok, %{"schema_contract" => "contact_filter_report.v1"}} =
             Schema.validate_artifact(report)

    review = OperatorReview.from_contact_filter_report(report)

    assert [
             %{
               "review_type" => "contact_suppression",
               "activity_type" => "health_check",
               "direction" => "health_check",
               "requirement_type" => "health_check_review",
               "source_contact_suppression" => %{
                 "id" => "health_reserved",
                 "approval_requirements" => [
                   %{"requirement_type" => "health_check_review"}
                 ]
               }
             }
           ] = review["rows"]

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(review)

    manifest = CadenceImport.from_contact_filter_report(report)

    assert [
             %{
               "import_action" => "review_contact_suppression",
               "activity_type" => "health_check",
               "direction" => "health_check",
               "requirement_type" => "health_check_review",
               "source_review_row" => %{
                 "review_type" => "contact_suppression",
                 "requirement_type" => "health_check_review"
               }
             }
           ] = manifest["rows"]

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(manifest)
  end

  test "flattens nested station-calendar entry id through contact suppression handoffs" do
    candidates = [
      contact(:downlink_nested_calendar,
        starts_at_s: 100.0,
        ends_at_s: 160.0
      )
    ]

    ground_network = [
      %{
        ground_station_id: :equator_prime,
        availability: :unavailable,
        starts_at_s: 90.0,
        ends_at_s: 170.0,
        source_station_calendar_entry: %{
          id: :provider_entry_only,
          provenance: %{trust_boundary: :ground_partner_api}
        },
        source_station_calendar_overlaps: [
          %{id: :provider_entry_only}
        ]
      }
    ]

    {_kept, report} =
      ContactFilter.filter_candidates(candidates, ground_network,
        approval_policy: %{policy_bundle_id: "ground_network_allocation_v1"}
      )

    assert [
             %{
               "id" => "downlink_nested_calendar",
               "station_calendar_entry_id" => "provider_entry_only",
               "source_station_calendar_entry" => %{
                 "source_station_calendar_entry" => %{"id" => "provider_entry_only"}
               },
               "approval_requirements" => [
                 %{
                   "activity_context" => %{
                     "station_calendar_entry_id" => "provider_entry_only",
                     "source_station_calendar_entry" => %{
                       "source_station_calendar_entry" => %{"id" => "provider_entry_only"}
                     }
                   }
                 }
               ]
             }
           ] = report["suppressed_candidates"]

    review = OperatorReview.from_contact_filter_report(report)
    [review_row] = review["rows"]

    assert %{
             "station_calendar_entry_id" => "provider_entry_only",
             "source_station_calendar_entry" => %{
               "source_station_calendar_entry" => %{"id" => "provider_entry_only"}
             }
           } = review_row

    manifest = CadenceImport.from_contact_filter_report(report)
    [import_row] = manifest["rows"]

    assert %{
             "station_calendar_entry_id" => "provider_entry_only",
             "source_station_calendar_entry" => %{
               "source_station_calendar_entry" => %{"id" => "provider_entry_only"}
             }
           } = import_row

    assert {:ok, %{"schema_contract" => "contact_filter_report.v1"}} =
             Schema.validate_artifact(report)

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(review)

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(manifest)
  end

  defp contact(id, attrs) do
    defaults = %{
      id: id,
      type: :downlink,
      scenario_id: :leo_1,
      ground_station_id: :equator_prime,
      starts_at_s: 100.0,
      ends_at_s: 160.0
    }

    Map.merge(defaults, Map.new(attrs))
  end
end
