defmodule OrbitalDynamics.CandidateRefresh.ContactAllocationHandoffTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.{CadenceImport, OperatorReview, Schema}

  test "operator review and import lift contact allocation summaries from candidate refresh artifacts" do
    summary_with_contact = fn source, contact_id ->
      contact_allocation_summary_fixture()
      |> Map.put("source", source)
      |> Map.update!("review_rows", fn rows ->
        Enum.map(rows, &Map.merge(&1, %{"contact_id" => contact_id, "source" => source}))
      end)
      |> Map.update!("rows", fn rows ->
        Enum.map(rows, fn row ->
          if row["contact_id"] == "dl_deferred" do
            Map.merge(row, %{"contact_id" => contact_id, "source" => source})
          else
            row
          end
        end)
      end)
    end

    direct_summary =
      summary_with_contact.(
        "unit_test.contact_allocation_summary.direct",
        "dl_summary_direct_review"
      )

    canonical_summary =
      summary_with_contact.(
        "unit_test.contact_allocation_summary.canonical",
        "dl_summary_canonical_review"
      )

    wrapped_summary =
      summary_with_contact.(
        "unit_test.contact_allocation_summary.wrapped",
        "dl_summary_wrapped_review"
      )

    nested_summary =
      summary_with_contact.(
        "unit_test.contact_allocation_summary.nested",
        "dl_summary_nested_review"
      )

    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "refresh_id" => "candidate_refresh:contact_allocation_summary_handoff",
      "source_contact_allocation_summary" => [direct_summary],
      "contact_allocation_summary" => canonical_summary,
      "source_result_artifact" => [
        wrapped_summary,
        %{
          "schema_contract" => "result_artifact.v1",
          "contact_allocation_summary" => nested_summary
        }
      ]
    }

    review = OperatorReview.from_candidate_refresh_artifact(artifact)
    import = CadenceImport.from_candidate_refresh_artifact(artifact)

    allocation_rows =
      Enum.filter(review["rows"], &(&1["review_type"] == "contact_allocation_review"))

    assert length(allocation_rows) == 4

    assert %{
             "source_artifact_type" => "candidate_refresh.v1",
             "source_artifact_id" => "candidate_refresh:contact_allocation_summary_handoff",
             "contact_allocation_review_count" => 4,
             "review_type_counts" => %{"contact_allocation_review" => 4}
           } = review

    assert Enum.sort(Enum.map(allocation_rows, & &1["source"])) == [
             "candidate_refresh.contact_allocation_summary.review_rows",
             "candidate_refresh.source_contact_allocation_summary[0].review_rows",
             "candidate_refresh.source_result_artifact[0].review_rows",
             "candidate_refresh.source_result_artifact[1].contact_allocation_summary.review_rows"
           ]

    assert Enum.all?(
             allocation_rows,
             &(&1["allocation_status"] == "deferred" and
                 &1["effective_allocation_status"] == "deferred" and
                 &1["allocation_reason"] == "same_station_contention" and
                 &1["ground_station_id"] == "equator_prime" and
                 &1["direction"] == "downlink" and
                 &1["required_operator_action"] == "review_contact_allocation" and
                 &1["source_contact_allocation"]["schema_contract"] ==
                   "contact_allocation_summary.v1")
           )

    assert Enum.any?(
             allocation_rows,
             &match?(
               %{
                 "source" => "candidate_refresh.contact_allocation_summary.review_rows",
                 "contact_id" => "dl_summary_canonical_review",
                 "source_contact_allocation" => %{
                   "source" => "unit_test.contact_allocation_summary.canonical"
                 }
               },
               &1
             )
           )

    import_rows =
      Enum.filter(import["rows"], &(&1["source_review_type"] == "contact_allocation_review"))

    assert length(import_rows) == 4

    assert %{
             "source_artifact_type" => "candidate_refresh.v1",
             "source_artifact_id" => "candidate_refresh:contact_allocation_summary_handoff",
             "import_action_counts" => %{"review_contact_allocation" => 4},
             "source_review_type_counts" => %{"contact_allocation_review" => 4}
           } = import

    assert Enum.all?(
             import_rows,
             &(&1["import_action"] == "review_contact_allocation" and
                 &1["source_review_row"]["source_contact_allocation"]["schema_contract"] ==
                   "contact_allocation_summary.v1")
           )

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(review)

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(import)
  end

  test "operator review and import lift specialized contact allocation summaries from candidate refresh artifacts" do
    summary_with_source = fn summary, source, prefix ->
      rename_contact_row = fn row ->
        Map.update(row, "contact_id", "#{prefix}_contact", &"#{prefix}_#{&1}")
      end

      summary
      |> Map.put("source", source)
      |> then(fn summary ->
        ["rows", "review_rows", "reservation_conflict_rows", "reservation_review_rows"]
        |> Enum.reduce(summary, fn field, acc ->
          Map.update(acc, field, [], &Enum.map(&1, rename_contact_row))
        end)
      end)
      |> Map.update("reduced_capacity_pack_groups", [], fn groups ->
        Enum.map(groups, fn group ->
          group
          |> Map.put("contention_group_id", "#{prefix}_pack_group")
          |> Map.put("source", source)
        end)
      end)
    end

    station_summary = fn source, prefix ->
      contact_allocation_station_pressure_summary_fixture()
      |> summary_with_source.(source, prefix)
    end

    reservation_summary = fn source, prefix ->
      contact_allocation_reservation_conflict_summary_fixture()
      |> summary_with_source.(source, prefix)
    end

    capacity_summary = fn source, prefix ->
      contact_allocation_capacity_pack_summary_fixture()
      |> summary_with_source.(source, prefix)
    end

    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "refresh_id" => "candidate_refresh:specialized_contact_allocation_summary_handoff",
      "source_contact_allocation_station_pressure_summary" => [
        station_summary.("unit_test.station_pressure.direct", "station_direct")
      ],
      "contact_allocation_station_pressure_summary" =>
        station_summary.("unit_test.station_pressure.canonical", "station_canonical"),
      "source_contact_allocation_reservation_conflict_summary" => [
        reservation_summary.("unit_test.reservation_conflict.direct", "reservation_direct")
      ],
      "contact_allocation_reservation_conflict_summary" =>
        reservation_summary.("unit_test.reservation_conflict.canonical", "reservation_canonical"),
      "source_contact_allocation_capacity_pack_summary" => [
        capacity_summary.("unit_test.capacity_pack.direct", "capacity_direct")
      ],
      "contact_allocation_capacity_pack_summary" =>
        capacity_summary.("unit_test.capacity_pack.canonical", "capacity_canonical"),
      "source_result_artifact" => [
        station_summary.("unit_test.station_pressure.wrapped", "station_wrapped"),
        reservation_summary.("unit_test.reservation_conflict.wrapped", "reservation_wrapped"),
        capacity_summary.("unit_test.capacity_pack.wrapped", "capacity_wrapped"),
        %{
          "schema_contract" => "result_artifact.v1",
          "contact_allocation_station_pressure_summary" =>
            station_summary.("unit_test.station_pressure.nested", "station_nested"),
          "contact_allocation_reservation_conflict_summary" =>
            reservation_summary.("unit_test.reservation_conflict.nested", "reservation_nested"),
          "contact_allocation_capacity_pack_summary" =>
            capacity_summary.("unit_test.capacity_pack.nested", "capacity_nested")
        }
      ]
    }

    review = OperatorReview.from_candidate_refresh_artifact(artifact)
    import = CadenceImport.from_candidate_refresh_artifact(artifact)

    allocation_rows =
      Enum.filter(review["rows"], &(&1["review_type"] == "contact_allocation_review"))

    capacity_pack_rows =
      Enum.filter(
        review["rows"],
        &(&1["review_type"] == "contact_allocation_capacity_pack_review")
      )

    assert length(allocation_rows) == 20
    assert length(capacity_pack_rows) == 4

    assert %{
             "source_artifact_type" => "candidate_refresh.v1",
             "source_artifact_id" =>
               "candidate_refresh:specialized_contact_allocation_summary_handoff",
             "contact_allocation_review_count" => 20,
             "contact_allocation_capacity_pack_review_count" => 4
           } = review

    assert allocation_rows
           |> Enum.map(&get_in(&1, ["source_contact_allocation", "schema_contract"]))
           |> Enum.frequencies() == %{
             "contact_allocation_capacity_pack_summary.v1" => 12,
             "contact_allocation_reservation_conflict_summary.v1" => 4,
             "contact_allocation_station_pressure_summary.v1" => 4
           }

    assert Enum.sort(Enum.map(capacity_pack_rows, & &1["source"])) == [
             "candidate_refresh.contact_allocation_capacity_pack_summary.reduced_capacity_pack_groups",
             "candidate_refresh.source_contact_allocation_capacity_pack_summary[0].reduced_capacity_pack_groups",
             "candidate_refresh.source_result_artifact[2].reduced_capacity_pack_groups",
             "candidate_refresh.source_result_artifact[3].contact_allocation_capacity_pack_summary.reduced_capacity_pack_groups"
           ]

    assert Enum.any?(
             allocation_rows,
             &match?(
               %{
                 "source" =>
                   "candidate_refresh.contact_allocation_station_pressure_summary.review_rows",
                 "source_contact_allocation" => %{
                   "schema_contract" => "contact_allocation_station_pressure_summary.v1",
                   "station_calendar_precedence_availability" => "reserved",
                   "source_contact_allocation_summary" => %{
                     "schema_contract" => "contact_allocation_station_pressure_summary.v1"
                   }
                 }
               },
               &1
             )
           )

    assert Enum.any?(
             allocation_rows,
             &match?(
               %{
                 "source" =>
                   "candidate_refresh.contact_allocation_reservation_conflict_summary.reservation_review_rows",
                 "station_reservation_match_status" => "overlap",
                 "source_contact_allocation" => %{
                   "schema_contract" => "contact_allocation_reservation_conflict_summary.v1",
                   "source_contact_allocation_summary" => %{
                     "schema_contract" => "contact_allocation_reservation_conflict_summary.v1"
                   }
                 }
               },
               &1
             )
           )

    assert Enum.any?(
             allocation_rows,
             &match?(
               %{
                 "source" =>
                   "candidate_refresh.contact_allocation_capacity_pack_summary.review_rows",
                 "required_capacity_fraction_source" => "contact_required_capacity_fraction",
                 "source_contact_allocation" => %{
                   "schema_contract" => "contact_allocation_capacity_pack_summary.v1",
                   "source_contact_allocation_summary" => %{
                     "schema_contract" => "contact_allocation_capacity_pack_summary.v1"
                   }
                 }
               },
               &1
             )
           )

    assert Enum.all?(
             capacity_pack_rows,
             &(get_in(&1, [
                 "source_contact_allocation_capacity_pack",
                 "source_contact_allocation_summary",
                 "schema_contract"
               ]) == "contact_allocation_capacity_pack_summary.v1")
           )

    allocation_import_rows =
      Enum.filter(import["rows"], &(&1["source_review_type"] == "contact_allocation_review"))

    capacity_pack_import_rows =
      Enum.filter(
        import["rows"],
        &(&1["source_review_type"] == "contact_allocation_capacity_pack_review")
      )

    assert length(allocation_import_rows) == 20
    assert length(capacity_pack_import_rows) == 4

    assert %{
             "import_action_counts" => %{
               "review_contact_allocation" => 20,
               "review_contact_allocation_capacity_pack" => 4
             },
             "source_review_type_counts" => %{
               "contact_allocation_review" => 20,
               "contact_allocation_capacity_pack_review" => 4
             }
           } = import

    assert Enum.all?(
             allocation_import_rows,
             &(&1["import_action"] == "review_contact_allocation" and
                 &1["source_review_row"]["source_contact_allocation"][
                   "source_contact_allocation_summary"
                 ])
           )

    assert Enum.all?(
             capacity_pack_import_rows,
             &(&1["import_action"] == "review_contact_allocation_capacity_pack" and
                 get_in(&1, [
                   "source_review_row",
                   "source_contact_allocation_capacity_pack",
                   "source_contact_allocation_summary",
                   "schema_contract"
                 ]) == "contact_allocation_capacity_pack_summary.v1")
           )

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(review)

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(import)
  end

  defp contact_allocation_summary_fixture do
    allocated_row = %{
      "contact_id" => "dl_allocated",
      "allocation_status" => "allocated",
      "effective_allocation_status" => "allocated",
      "allocation_reason" => "selected_by_contention_resolution",
      "ground_station_id" => "equator_prime",
      "direction" => "downlink"
    }

    deferred_row = %{
      "contact_id" => "dl_deferred",
      "allocation_status" => "deferred",
      "effective_allocation_status" => "deferred",
      "allocation_reason" => "same_station_contention",
      "ground_station_id" => "equator_prime",
      "direction" => "downlink"
    }

    %{
      "schema_contract" => "contact_allocation_summary.v1",
      "model" => "artifact_only_contact_allocation_summary",
      "source_artifact_type" => "contact_allocation_report.v1",
      "source" => "unit_test.contact_allocation_summary",
      "input_contact_count" => 2,
      "allocated_contact_count" => 1,
      "returned_allocated_contact_count" => 1,
      "policy_blocked_allocated_contact_count" => 0,
      "deferred_contact_count" => 1,
      "blocked_contact_count" => 0,
      "invalid_contact_input_count" => 0,
      "status_blocked_contact_count" => 0,
      "resource_blocked_contact_count" => 0,
      "duplicate_contact_id_count" => 0,
      "allocation_status_counts" => %{"allocated" => 1, "deferred" => 1},
      "effective_allocation_status_counts" => %{"allocated" => 1, "deferred" => 1},
      "allocation_reason_counts" => %{
        "same_station_contention" => 1,
        "selected_by_contention_resolution" => 1
      },
      "contact_ids_by_allocation_reason" => %{
        "same_station_contention" => ["dl_deferred"],
        "selected_by_contention_resolution" => ["dl_allocated"]
      },
      "allocated_contact_ids" => ["dl_allocated"],
      "returned_allocated_contact_ids" => ["dl_allocated"],
      "deferred_contact_ids" => ["dl_deferred"],
      "blocked_contact_ids" => [],
      "review_contact_ids" => ["dl_deferred"],
      "rows" => [allocated_row, deferred_row],
      "review_rows" => [deferred_row],
      "assumptions" => %{
        "execution_boundary" => "artifact_only_no_provider_reservation_or_schedule_mutation"
      },
      "provenance" => %{"trust_boundary" => "allocation_fixture"}
    }
  end

  defp contact_allocation_station_pressure_summary_fixture do
    nominal_row = %{
      "contact_id" => "dl_nominal",
      "allocation_status" => "allocated",
      "effective_allocation_status" => "allocated",
      "allocation_reason" => "selected_by_contention_resolution",
      "ground_station_id" => "equator_prime",
      "direction" => "downlink"
    }

    station_pressure_row = %{
      "contact_id" => "dl_station_pressure",
      "allocation_status" => "deferred",
      "effective_allocation_status" => "deferred",
      "allocation_reason" => "same_station_contention",
      "ground_station_id" => "equator_prime",
      "direction" => "downlink",
      "station_calendar_entry_id" => "station_reserved_1",
      "station_calendar_overlap_availabilities" => ["reserved"],
      "station_calendar_precedence_availability" => "reserved",
      "station_calendar_precedence_rank" => 2,
      "station_calendar_status" => "reserved"
    }

    %{
      "schema_contract" => "contact_allocation_station_pressure_summary.v1",
      "model" => "artifact_only_contact_allocation_station_pressure_summary",
      "source_artifact_type" => "contact_allocation_report.v1",
      "source" => "unit_test.contact_allocation_station_pressure_summary",
      "input_contact_count" => 2,
      "station_pressure_contact_count" => 1,
      "station_pressure_review_contact_count" => 1,
      "station_pressure_contact_ids" => ["dl_station_pressure"],
      "station_pressure_review_contact_ids" => ["dl_station_pressure"],
      "station_pressure_contact_ids_by_ground_station_id" => %{
        "equator_prime" => ["dl_station_pressure"]
      },
      "station_pressure_contact_counts_by_ground_station_id" => %{"equator_prime" => 1},
      "station_pressure_contact_ids_by_availability" => %{"reserved" => ["dl_station_pressure"]},
      "station_pressure_contact_counts_by_availability" => %{"reserved" => 1},
      "station_pressure_contact_ids_by_precedence_availability" => %{
        "reserved" => ["dl_station_pressure"]
      },
      "station_pressure_contact_counts_by_precedence_availability" => %{"reserved" => 1},
      "station_pressure_contact_ids_by_precedence_rank" => %{"2" => ["dl_station_pressure"]},
      "station_pressure_contact_counts_by_precedence_rank" => %{"2" => 1},
      "station_pressure_contact_ids_by_status" => %{"reserved" => ["dl_station_pressure"]},
      "station_pressure_contact_counts_by_status" => %{"reserved" => 1},
      "station_pressure_contact_ids_by_direction" => %{
        "downlink" => ["dl_station_pressure"]
      },
      "station_pressure_contact_ids_by_direction_and_ground_station_id" => %{
        "downlink" => %{"equator_prime" => ["dl_station_pressure"]}
      },
      "rows" => [nominal_row, station_pressure_row],
      "review_rows" => [station_pressure_row],
      "assumptions" => %{
        "execution_boundary" => "artifact_only_no_provider_reservation_or_schedule_mutation",
        "source" => "contact_allocation_report.v1",
        "operator_authority" => "not_granted_by_station_pressure_summary"
      },
      "provenance" => %{"trust_boundary" => "station_pressure_fixture"}
    }
  end

  defp contact_allocation_reservation_conflict_summary_fixture do
    owner_row = %{
      "contact_id" => "dl_reserved_owner",
      "allocation_status" => "allocated",
      "effective_allocation_status" => "allocated",
      "allocation_reason" => "selected_by_contention_resolution",
      "ground_station_id" => "equator_prime",
      "direction" => "downlink",
      "station_reservation_id" => "reservation_1",
      "station_reservation_match_status" => "matched",
      "station_reservation_status" => "confirmed",
      "station_reserved_by" => "ops_team_b",
      "station_reservation_expires_at_s" => 360.0
    }

    conflict_row = %{
      "contact_id" => "dl_reserved_intruder",
      "allocation_status" => "deferred",
      "effective_allocation_status" => "deferred",
      "allocation_reason" => "same_station_contention",
      "ground_station_id" => "equator_prime",
      "direction" => "downlink",
      "station_reservation_id" => "reservation_1",
      "station_reservation_match_status" => "overlap",
      "station_reservation_status" => "confirmed",
      "station_reserved_by" => "ops_team_b",
      "station_reservation_expires_at_s" => 360.0
    }

    %{
      "schema_contract" => "contact_allocation_reservation_conflict_summary.v1",
      "model" => "artifact_only_contact_allocation_reservation_conflict_summary",
      "source_artifact_type" => "contact_allocation_report.v1",
      "source" => "unit_test.contact_allocation_reservation_conflict_summary",
      "input_contact_count" => 2,
      "station_reservation_contact_count" => 2,
      "reservation_conflict_contact_count" => 1,
      "reservation_review_contact_count" => 1,
      "station_reservation_match_status_counts" => %{"matched" => 1, "overlap" => 1},
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
      "station_reservation_contact_ids_by_status" => %{
        "confirmed" => ["dl_reserved_intruder", "dl_reserved_owner"]
      },
      "station_reservation_contact_ids_by_reserved_by" => %{
        "ops_team_b" => ["dl_reserved_intruder", "dl_reserved_owner"]
      },
      "station_reservation_contact_ids_by_expiration_status" => %{
        "expired" => ["dl_reserved_intruder", "dl_reserved_owner"]
      },
      "station_reservation_ids_by_match_status" => %{
        "matched" => ["reservation_1"],
        "overlap" => ["reservation_1"]
      },
      "reservation_conflict_reservation_ids_by_match_status" => %{
        "overlap" => ["reservation_1"]
      },
      "station_reservation_ids_by_status" => %{"confirmed" => ["reservation_1"]},
      "station_reservation_ids_by_reserved_by" => %{"ops_team_b" => ["reservation_1"]},
      "station_reservation_ids_by_expiration_status" => %{"expired" => ["reservation_1"]},
      "rows" => [owner_row, conflict_row],
      "reservation_conflict_rows" => [conflict_row],
      "reservation_review_rows" => [conflict_row],
      "assumptions" => %{
        "execution_boundary" => "artifact_only_no_provider_reservation_or_schedule_mutation",
        "source" => "contact_allocation_report.v1",
        "operator_authority" => "not_granted_by_reservation_conflict_summary"
      },
      "provenance" => %{"trust_boundary" => "reservation_conflict_fixture"}
    }
  end

  defp contact_allocation_capacity_pack_summary_fixture do
    primary_row = %{
      "contact_id" => "dl_capacity_primary",
      "allocation_status" => "allocated",
      "effective_allocation_status" => "allocated",
      "allocation_reason" => "selected_by_contention_resolution",
      "ground_station_id" => "equator_prime",
      "direction" => "downlink",
      "capacity_pack_status" => "selected_by_contention_resolution",
      "required_capacity_fraction" => 0.25,
      "required_capacity_fraction_source" => "contact_required_capacity_fraction"
    }

    secondary_row = %{
      "contact_id" => "dl_capacity_secondary",
      "allocation_status" => "allocated",
      "effective_allocation_status" => "allocated",
      "allocation_reason" => "selected_by_reduced_station_capacity_pack",
      "ground_station_id" => "equator_prime",
      "direction" => "downlink",
      "capacity_pack_status" => "selected_by_reduced_station_capacity_pack",
      "required_capacity_fraction" => 0.25,
      "required_capacity_fraction_source" => "contact_required_capacity_fraction"
    }

    overflow_row = %{
      "contact_id" => "dl_capacity_overflow",
      "allocation_status" => "deferred",
      "effective_allocation_status" => "deferred",
      "allocation_reason" => "deferred_by_reduced_station_capacity_pack",
      "ground_station_id" => "equator_prime",
      "direction" => "downlink",
      "capacity_pack_status" => "deferred_by_reduced_station_capacity_pack",
      "required_capacity_fraction" => 0.25,
      "required_capacity_fraction_source" => "contact_required_capacity_fraction"
    }

    pack_group = %{
      "contention_group_id" => "pack_equator_prime",
      "pack_status" => "capacity_limited",
      "ground_station_id" => "equator_prime",
      "capacity_fraction" => 0.5
    }

    %{
      "schema_contract" => "contact_allocation_capacity_pack_summary.v1",
      "model" => "artifact_only_contact_allocation_capacity_pack_summary",
      "source_artifact_type" => "contact_allocation_report.v1",
      "source" => "unit_test.contact_allocation_capacity_pack_summary",
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
      "reduced_capacity_packed_contact_ids" => ["dl_capacity_secondary"],
      "reduced_capacity_deferred_contact_ids" => ["dl_capacity_overflow"],
      "capacity_pack_group_ids" => ["pack_equator_prime"],
      "capacity_pack_group_ids_by_status" => %{
        "capacity_limited" => ["pack_equator_prime"]
      },
      "rows" => [primary_row, secondary_row, overflow_row],
      "reduced_capacity_pack_groups" => [pack_group],
      "review_rows" => [primary_row, secondary_row, overflow_row],
      "assumptions" => %{
        "execution_boundary" => "artifact_only_no_provider_reservation_or_schedule_mutation",
        "source" => "contact_allocation_report.v1",
        "operator_authority" => "not_granted_by_capacity_pack_summary"
      },
      "provenance" => %{"trust_boundary" => "capacity_pack_fixture"}
    }
  end
end
