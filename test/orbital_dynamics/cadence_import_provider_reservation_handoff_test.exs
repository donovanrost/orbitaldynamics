defmodule OrbitalDynamics.CadenceImportProviderReservationHandoffTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.{CadenceImport, Schema}

  test "candidate refresh import preserves provider-reservation request summary handoff rows" do
    artifact = %{
      "refresh_id" => "refresh:provider_reservation_handoff",
      "source_contact_allocation_provider_reservation_request_summary" =>
        provider_reservation_request_summary()
    }

    manifest = CadenceImport.from_candidate_refresh_artifact(artifact)

    assert %{
             "source_artifact_type" => "candidate_refresh.v1",
             "source_artifact_id" => "refresh:provider_reservation_handoff",
             "row_count" => 2,
             "review_required_count" => 2,
             "import_action_counts" => %{
               "review_contact_allocation" => 1,
               "review_provider_reservation_request" => 1
             },
             "provider_reservation_candidate_contact_count" => 2,
             "provider_reservation_request_contact_count" => 1,
             "provider_reservation_review_contact_count" => 1,
             "provider_reservation_no_request_contact_count" => 1,
             "provider_reservation_request_status_counts" => %{"review_required" => 1},
             "provider_reservation_request_contact_ids" => ["dl_reserved_owner"],
             "provider_reservation_review_contact_ids" => ["dl_review_overlap"],
             "provider_reservation_no_request_contact_ids" => ["dl_unreserved"]
           } = manifest

    assert manifest["provider_reservation_request_contact_ids_by_ground_station_id"] == %{
             "equator_prime" => ["dl_reserved_owner"]
           }

    assert manifest["provider_reservation_review_contact_ids_by_ground_station_id"] == %{
             "equator_prime" => ["dl_review_overlap"]
           }

    assert manifest["provider_reservation_no_request_contact_ids_by_direction"] == %{
             "uplink" => ["dl_unreserved"]
           }

    assert manifest["provider_reservation_request_contact_ids_by_direction"] == %{
             "downlink" => ["dl_reserved_owner"]
           }

    assert manifest["provider_reservation_review_contact_ids_by_direction"] == %{
             "command" => ["dl_review_overlap"]
           }

    assert manifest[
             "provider_reservation_no_request_contact_ids_by_direction_and_ground_station_id"
           ] == %{
             "uplink" => %{"equator_prime" => ["dl_unreserved"]}
           }

    assert manifest[
             "provider_reservation_request_contact_ids_by_direction_and_ground_station_id"
           ] == %{
             "downlink" => %{"equator_prime" => ["dl_reserved_owner"]}
           }

    assert manifest[
             "provider_reservation_review_contact_ids_by_direction_and_ground_station_id"
           ] == %{
             "command" => %{"equator_prime" => ["dl_review_overlap"]}
           }

    assert manifest["provider_reservation_request_contact_ids_by_match_status"] == %{
             "matched" => ["dl_reserved_owner"]
           }

    assert manifest["provider_reservation_review_contact_ids_by_match_status"] == %{
             "overlap" => ["dl_review_overlap"]
           }

    assert manifest["provider_reservation_request_ids_by_match_status"] == %{
             "matched" => ["reservation_1"]
           }

    assert manifest["provider_reservation_review_ids_by_match_status"] == %{
             "overlap" => ["reservation_review"]
           }

    request_row = Enum.find(manifest["rows"], &(&1["contact_id"] == "dl_reserved_owner"))
    review_row = Enum.find(manifest["rows"], &(&1["contact_id"] == "dl_review_overlap"))

    assert %{
             "import_action" => "review_provider_reservation_request",
             "source_review_type" => "contact_allocation_review",
             "source_review_action" => "review_provider_reservation_request",
             "contact_id" => "dl_reserved_owner",
             "station_reservation_id" => "reservation_1",
             "station_reservation_match_status" => "matched",
             "provider_reservation_request_status" => "request_ready",
             "provider_reservation_request_summary_schema_contract" =>
               "contact_allocation_provider_reservation_request_summary.v1",
             "provider_reservation_request_execution_boundary" =>
               "artifact_only_no_provider_reservation_or_schedule_mutation",
             "provider_reservation_execution" => "not_performed_by_summary",
             "source_provider_reservation_request_summary" => %{
               "schema_contract" => "contact_allocation_provider_reservation_request_summary.v1",
               "provider_reservation_request_status" => "review_required"
             },
             "source_contact_allocation" => %{
               "provider_reservation_request_status" => "request_ready",
               "station_reservation_id" => "reservation_1"
             },
             "source_review_row" => %{
               "provider_reservation_request_status" => "request_ready",
               "source_provider_reservation_request_summary" => %{
                 "schema_contract" =>
                   "contact_allocation_provider_reservation_request_summary.v1",
                 "provider_reservation_request_status" => "review_required"
               }
             }
           } = request_row

    assert %{
             "import_action" => "review_contact_allocation",
             "contact_id" => "dl_review_overlap",
             "station_reservation_id" => "reservation_review",
             "station_reservation_match_status" => "overlap",
             "provider_reservation_request_status" => "review_required",
             "source_contact_allocation" => %{
               "provider_reservation_request_status" => "review_required",
               "station_reservation_id" => "reservation_review"
             }
           } = review_row

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(manifest)
  end

  test "candidate refresh import preserves station-reservation hold import-readiness handoff rows" do
    artifact = %{
      "refresh_id" => "refresh:station_reservation_hold_import_readiness",
      "source_station_reservation_hold_import_readiness_summary" =>
        station_reservation_hold_import_readiness_summary()
    }

    manifest = CadenceImport.from_candidate_refresh_artifact(artifact)

    assert %{
             "source_artifact_type" => "candidate_refresh.v1",
             "source_artifact_id" => "refresh:station_reservation_hold_import_readiness",
             "row_count" => 2,
             "review_required_count" => 2,
             "import_action_counts" => %{"review_station_reservation" => 2}
           } = manifest

    affected_row = Enum.find(manifest["rows"], &(&1["contact_id"] == "dl_source_reserved"))

    assert %{
             "import_action" => "review_station_reservation",
             "source_review_type" => "station_reservation_review",
             "contact_id" => "dl_source_reserved",
             "ground_station_id" => "equator_prime",
             "station_reservation_id" => "reservation_expired",
             "station_calendar_reservation_overlap_count" => 1,
             "station_calendar_reservation_ids" => ["reservation_expired"],
             "station_calendar_reserved_by" => ["ops_calendar"],
             "station_calendar_reservation_statuses" => ["held"],
             "station_reservation_hold_import_status" => "review_required_before_import",
             "station_reservation_hold_import_readiness_status" => "review_required",
             "station_reservation_hold_import_classification" => "review_only",
             "station_reservation_hold_ids_by_direction" => %{
               "downlink" => ["reservation_expired"],
               "uplink" => ["reservation_missing"]
             },
             "station_reservation_hold_contact_ids_by_direction" => %{
               "downlink" => ["dl_source_reserved"]
             },
             "station_reservation_hold_import_execution_boundary" =>
               "artifact_only_no_provider_or_cadence_writes",
             "station_reservation_hold_provider_write" => "not_performed_by_summary",
             "station_reservation_hold_cadence_write" => "not_performed_by_summary",
             "station_reservation_hold_reservation_acceptance" => "not_performed_by_summary",
             "source_station_reservation_hold_import_readiness_summary" => %{
               "model" => "artifact_only_station_reservation_hold_import_readiness_summary",
               "import_readiness_status" => "review_required",
               "reservation_hold_ids_by_direction" => %{
                 "downlink" => ["reservation_expired"],
                 "uplink" => ["reservation_missing"]
               }
             },
             "source_station_reservation" => %{
               "station_reservation_hold_import_status" => "review_required_before_import"
             },
             "source_review_row" => %{
               "station_reservation_hold_import_status" => "review_required_before_import",
               "source_station_reservation_hold_import_readiness_summary" => %{
                 "reservation_hold_count" => 2
               }
             }
           } = affected_row

    assert %{
             "import_action" => "review_station_reservation",
             "provider_calendar_contention_reservation_ids" => ["reservation_missing"],
             "provider_calendar_contention_reserved_by" => ["partner_calendar"],
             "provider_calendar_contention_reservation_statuses" => ["held"],
             "station_reservation_hold_import_status" => "review_required_before_import",
             "station_reservation_hold_ids_by_direction_and_ground_station_id" => %{
               "downlink" => %{"equator_prime" => ["reservation_expired"]},
               "uplink" => %{"polar_prime" => ["reservation_missing"]}
             },
             "station_reservation_hold_ids_by_required_import_action" => %{
               "review_station_provider_contention" => ["reservation_missing"],
               "review_station_reservation_overlap" => ["reservation_expired"]
             },
             "source_station_reservation" => %{
               "reservation_review_row_type" => "provider_calendar_contention_group",
               "station_reservation_hold_import_status" => "review_required_before_import"
             }
           } =
             Enum.find(
               manifest["rows"],
               &(&1["provider_calendar_contention_reservation_ids"] == ["reservation_missing"])
             )

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(manifest)
  end

  test "candidate refresh import preserves wrapped station-reservation hold import-readiness rows" do
    artifact = %{
      "refresh_id" => "refresh:wrapped_station_reservation_hold_import_readiness",
      "source_result_artifact" => [
        %{
          "schema_contract" => "result_artifact.v1",
          "source_station_reservation_hold_import_readiness_summary" =>
            station_reservation_hold_import_readiness_summary()
        }
      ]
    }

    manifest = CadenceImport.from_candidate_refresh_artifact(artifact)

    assert %{
             "source_artifact_type" => "candidate_refresh.v1",
             "source_artifact_id" => "refresh:wrapped_station_reservation_hold_import_readiness",
             "row_count" => 2,
             "review_required_count" => 2,
             "import_action_counts" => %{"review_station_reservation" => 2}
           } = manifest

    assert %{
             "import_action" => "review_station_reservation",
             "source_review_type" => "station_reservation_review",
             "contact_id" => "dl_source_reserved",
             "station_reservation_id" => "reservation_expired",
             "station_reservation_hold_import_status" => "review_required_before_import",
             "station_reservation_hold_import_readiness_status" => "review_required",
             "station_reservation_hold_import_execution_boundary" =>
               "artifact_only_no_provider_or_cadence_writes",
             "source_station_reservation_hold_import_readiness_summary" => %{
               "reservation_hold_count" => 2
             },
             "source_review_row" => %{
               "source" =>
                 "candidate_refresh.source_result_artifact[0].source_station_reservation_hold_import_readiness_summary.import_readiness_rows.affected_contacts",
               "source_station_reservation_hold_import_readiness_summary" => %{
                 "import_readiness_status" => "review_required"
               }
             }
           } =
             Enum.find(manifest["rows"], &(&1["contact_id"] == "dl_source_reserved"))

    assert %{
             "import_action" => "review_station_reservation",
             "provider_calendar_contention_reservation_ids" => ["reservation_missing"],
             "station_reservation_hold_provider_write" => "not_performed_by_summary",
             "station_reservation_hold_cadence_write" => "not_performed_by_summary",
             "station_reservation_hold_reservation_acceptance" => "not_performed_by_summary"
           } =
             Enum.find(
               manifest["rows"],
               &(&1["provider_calendar_contention_reservation_ids"] == ["reservation_missing"])
             )

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(manifest)
  end

  defp provider_reservation_request_summary do
    %{
      "schema_contract" => "contact_allocation_provider_reservation_request_summary.v1",
      "model" => "artifact_only_contact_allocation_provider_reservation_request_summary",
      "source_artifact_type" => "contact_allocation_report.v1",
      "source" => "unit_test.provider_reservation_request_summary",
      "provider_reservation_candidate_contact_count" => 2,
      "provider_reservation_request_contact_count" => 1,
      "provider_reservation_review_contact_count" => 1,
      "provider_reservation_no_request_contact_count" => 1,
      "provider_reservation_request_status" => "review_required",
      "provider_reservation_request_contact_ids" => ["dl_reserved_owner"],
      "provider_reservation_review_contact_ids" => ["dl_review_overlap"],
      "provider_reservation_no_request_contact_ids" => ["dl_unreserved"],
      "provider_reservation_request_contact_ids_by_ground_station_id" => %{
        "equator_prime" => ["dl_reserved_owner"]
      },
      "provider_reservation_review_contact_ids_by_ground_station_id" => %{
        "equator_prime" => ["dl_review_overlap"]
      },
      "provider_reservation_no_request_contact_ids_by_direction" => %{
        "uplink" => ["dl_unreserved"]
      },
      "provider_reservation_request_contact_ids_by_direction" => %{
        "downlink" => ["dl_reserved_owner"]
      },
      "provider_reservation_review_contact_ids_by_direction" => %{
        "command" => ["dl_review_overlap"]
      },
      "provider_reservation_no_request_contact_ids_by_direction_and_ground_station_id" => %{
        "uplink" => %{"equator_prime" => ["dl_unreserved"]}
      },
      "provider_reservation_request_contact_ids_by_direction_and_ground_station_id" => %{
        "downlink" => %{"equator_prime" => ["dl_reserved_owner"]}
      },
      "provider_reservation_review_contact_ids_by_direction_and_ground_station_id" => %{
        "command" => %{"equator_prime" => ["dl_review_overlap"]}
      },
      "provider_reservation_request_contact_ids_by_match_status" => %{
        "matched" => ["dl_reserved_owner"]
      },
      "provider_reservation_review_contact_ids_by_match_status" => %{
        "overlap" => ["dl_review_overlap"]
      },
      "provider_reservation_request_ids_by_match_status" => %{
        "matched" => ["reservation_1"]
      },
      "provider_reservation_review_ids_by_match_status" => %{
        "overlap" => ["reservation_review"]
      },
      "provider_reservation_request_rows" => [
        %{
          "contact_id" => "dl_reserved_owner",
          "allocation_status" => "allocated",
          "ground_station_id" => "equator_prime",
          "direction" => "downlink",
          "station_reservation_id" => "reservation_1",
          "station_reservation_match_status" => "matched",
          "station_reservation_status" => "confirmed"
        }
      ],
      "provider_reservation_review_rows" => [
        %{
          "contact_id" => "dl_review_overlap",
          "allocation_status" => "allocated",
          "ground_station_id" => "equator_prime",
          "direction" => "command",
          "station_reservation_id" => "reservation_review",
          "station_reservation_match_status" => "overlap",
          "station_reservation_status" => "confirmed"
        }
      ],
      "assumptions" => %{
        "execution_boundary" => "artifact_only_no_provider_reservation_or_schedule_mutation",
        "provider_reservation_execution" => "not_performed_by_summary"
      }
    }
  end

  defp station_reservation_hold_import_readiness_summary do
    %{
      "model" => "artifact_only_station_reservation_hold_import_readiness_summary",
      "source_artifact_type" => "station_reservation_report.v1",
      "source" => "station_calendar_report.reservation_evidence",
      "reservation_hold_count" => 2,
      "import_readiness_status" => "review_required",
      "import_classification" => "review_only",
      "ready_for_import_count" => 0,
      "review_required_before_import_count" => 2,
      "no_import_required_count" => 0,
      "reservation_hold_import_status_counts" => %{
        "review_required_before_import" => 2
      },
      "required_import_action_counts" => %{
        "review_station_provider_contention" => 1,
        "review_station_reservation_overlap" => 1
      },
      "reservation_hold_ids" => ["reservation_expired", "reservation_missing"],
      "reservation_hold_ids_by_import_status" => %{
        "review_required_before_import" => ["reservation_expired", "reservation_missing"]
      },
      "reservation_hold_ids_by_required_import_action" => %{
        "review_station_provider_contention" => ["reservation_missing"],
        "review_station_reservation_overlap" => ["reservation_expired"]
      },
      "reservation_hold_ids_by_direction" => %{
        "downlink" => ["reservation_expired"],
        "uplink" => ["reservation_missing"]
      },
      "reservation_hold_ids_by_direction_and_ground_station_id" => %{
        "downlink" => %{"equator_prime" => ["reservation_expired"]},
        "uplink" => %{"polar_prime" => ["reservation_missing"]}
      },
      "reservation_hold_contact_ids_by_import_status" => %{
        "review_required_before_import" => ["dl_source_reserved"]
      },
      "reservation_hold_contact_ids_by_expiration_status" => %{
        "expired" => ["dl_source_reserved"]
      },
      "reservation_hold_contact_ids_by_direction" => %{
        "downlink" => ["dl_source_reserved"]
      },
      "reservation_hold_contact_ids_by_direction_and_ground_station_id" => %{
        "downlink" => %{"equator_prime" => ["dl_source_reserved"]}
      },
      "import_readiness_rows" => [
        %{
          "reservation_review_row_type" => "affected_contact",
          "contact_id" => "dl_source_reserved",
          "direction" => "downlink",
          "ground_station_id" => "equator_prime",
          "starts_at_s" => 100.0,
          "ends_at_s" => 160.0,
          "reservation_ids" => ["reservation_expired"],
          "reservation_statuses" => ["held"],
          "reserved_by" => ["ops_calendar"],
          "station_reservation_expiration_status" => "expired",
          "station_reservation_hold_import_status" => "review_required_before_import",
          "required_operator_action" => "review_station_reservation_overlap"
        },
        %{
          "reservation_review_row_type" => "provider_calendar_contention_group",
          "ground_station_id" => "equator_prime",
          "starts_at_s" => 95.0,
          "ends_at_s" => 165.0,
          "reservation_ids" => ["reservation_missing"],
          "reservation_statuses" => ["held"],
          "reserved_by" => ["partner_calendar"],
          "directions" => ["uplink"],
          "station_reservation_expiration_status" => "missing",
          "station_reservation_hold_import_status" => "review_required_before_import",
          "required_operator_action" => "review_station_provider_contention"
        }
      ],
      "assumptions" => %{
        "execution_boundary" => "artifact_only_no_provider_or_cadence_writes",
        "provider_write" => "not_performed_by_summary",
        "cadence_write" => "not_performed_by_summary",
        "reservation_acceptance" => "not_performed_by_summary"
      }
    }
  end
end
