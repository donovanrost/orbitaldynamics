defmodule OrbitalDynamics.OperatorReview.CandidateRefreshStationReservationTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.{OperatorReview, Schema}

  test "candidate refresh source station reservation reports become operator review rows" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "refresh_id" => "candidate_refresh:station_reservation_review:001",
      "source_station_reservation_report" => %{
        "schema_contract" => "station_reservation_report.v1",
        "source" => "ops_calendar",
        "affected_contacts" => [
          %{
            "contact_id" => "dl_reserved",
            "ground_station_id" => "equator_prime",
            "starts_at_s" => 100.0,
            "ends_at_s" => 160.0,
            "station_calendar_entry_id" => "calendar_reserved_1",
            "station_calendar_provider_id" => "ops_calendar",
            "station_calendar_provider_entry_id" => "provider_reserved_1",
            "station_contention_status" => "reserved_overlap",
            "station_reservation_match_status" => "owned",
            "station_reservation_id" => "reservation_1",
            "station_reserved_by" => "network_partner",
            "station_reservation_status" => "held",
            "station_calendar_reservation_overlap_count" => 1,
            "station_calendar_reservation_ids" => ["reservation_1"],
            "station_calendar_reserved_by" => ["network_partner"],
            "station_calendar_reservation_statuses" => ["held"],
            "station_calendar_reservation_expires_at_s" => [240.0],
            "required_operator_action" => "review_station_reservation_overlap"
          }
        ],
        "provider_calendar_contention_groups" => [
          %{
            "id" => "station_calendar_provider_contention:equator_prime:1",
            "provider_calendar_contention_status" => "provider_calendar_overlap",
            "required_operator_action" => "review_station_provider_contention",
            "ground_station_id" => "equator_prime",
            "starts_at_s" => 95.0,
            "ends_at_s" => 165.0,
            "entry_count" => 2,
            "entry_ids" => ["calendar_reserved_1", "calendar_reserved_2"],
            "reservation_ids" => ["reservation_1", "reservation_2"],
            "reservation_statuses" => ["held", "confirmed"]
          }
        ]
      }
    }

    package = OperatorReview.from_candidate_refresh_artifact(artifact)

    assert %{
             "source_artifact_type" => "candidate_refresh.v1",
             "source_artifact_id" => "candidate_refresh:station_reservation_review:001",
             "review_count" => 2,
             "station_reservation_review_count" => 2
           } = package

    assert %{
             "review_type" => "station_reservation_review",
             "source" => "candidate_refresh.source_station_reservation_report.affected_contacts",
             "contact_id" => "dl_reserved",
             "ground_station_id" => "equator_prime",
             "station_calendar_provider_id" => "ops_calendar",
             "station_calendar_provider_entry_id" => "provider_reserved_1",
             "station_reservation_id" => "reservation_1",
             "station_reserved_by" => "network_partner",
             "station_reservation_status" => "held",
             "station_reservation_match_status" => "owned",
             "required_operator_action" => "review_station_reservation_overlap",
             "source_station_reservation" => %{
               "contact_id" => "dl_reserved",
               "station_reservation_id" => "reservation_1"
             }
           } =
             Enum.find(
               package["rows"],
               &(&1["source"] ==
                   "candidate_refresh.source_station_reservation_report.affected_contacts")
             )

    assert %{
             "review_type" => "station_reservation_review",
             "source" =>
               "candidate_refresh.source_station_reservation_report.provider_calendar_contention_groups",
             "provider_calendar_contention_group_id" =>
               "station_calendar_provider_contention:equator_prime:1",
             "provider_calendar_contention_reservation_ids" => [
               "reservation_1",
               "reservation_2"
             ],
             "required_operator_action" => "review_station_provider_contention",
             "source_station_reservation" => %{
               "id" => "station_calendar_provider_contention:equator_prime:1"
             }
           } =
             Enum.find(
               package["rows"],
               &(&1["source"] ==
                   "candidate_refresh.source_station_reservation_report.provider_calendar_contention_groups")
             )

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)
  end

  test "candidate refresh station reservation summaries become operator review rows" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "refresh_id" => "candidate_refresh:station_reservation_summaries:001",
      "source_station_reservation_review_summary" =>
        station_reservation_summary_fixture("station_reservation_review_summary_v1.json"),
      "source_station_reservation_hold_summary" =>
        station_reservation_summary_fixture("station_reservation_hold_summary_v1.json")
    }

    package = OperatorReview.from_candidate_refresh_artifact(artifact)

    assert %{
             "source_artifact_type" => "candidate_refresh.v1",
             "source_artifact_id" => "candidate_refresh:station_reservation_summaries:001",
             "review_count" => 5,
             "station_reservation_review_count" => 5
           } = package

    assert %{
             "review_type" => "station_reservation_review",
             "source" =>
               "candidate_refresh.source_station_reservation_review_summary.review_rows.affected_contacts",
             "contact_id" => "dl_source_reserved",
             "station_reservation_id" => "reservation_expired",
             "source_station_reservation" => %{
               "station_reservation_summary_model" =>
                 "artifact_only_station_reservation_review_summary",
               "station_reservation_summary_schema_contract" =>
                 "station_reservation_review_summary.v1",
               "source_station_reservation_summary" => %{
                 "reservation_review_status" => "review_required"
               }
             }
           } =
             Enum.find(
               package["rows"],
               &(&1["source"] ==
                   "candidate_refresh.source_station_reservation_review_summary.review_rows.affected_contacts")
             )

    assert %{
             "review_type" => "station_reservation_review",
             "source" =>
               "candidate_refresh.source_station_reservation_hold_summary.review_rows.affected_contacts",
             "contact_id" => "dl_source_reserved",
             "station_reservation_hold_count" => 2,
             "station_reservation_hold_ids" => ["reservation_expired", "reservation_missing"],
             "source_station_reservation" => %{
               "station_reservation_summary_model" =>
                 "artifact_only_station_reservation_hold_summary",
               "source_station_reservation_summary" => %{
                 "reservation_hold_review_status" => "review_required",
                 "reservation_hold_count" => 2
               }
             }
           } =
             Enum.find(
               package["rows"],
               &(&1["source"] ==
                   "candidate_refresh.source_station_reservation_hold_summary.review_rows.affected_contacts")
             )

    assert %{
             "review_type" => "station_reservation_review",
             "source" =>
               "candidate_refresh.source_station_reservation_hold_summary.review_rows.provider_calendar_contention_groups",
             "provider_calendar_contention_group_id" =>
               "station_reservation_summary:provider_calendar_contention_group:polar_prime:reservation_missing",
             "station_reservation_hold_count" => 2,
             "required_operator_action" => "review_station_provider_contention",
             "source_station_reservation" => %{
               "reservation_review_row_type" => "provider_calendar_contention_group",
               "station_reservation_id" => "reservation_missing"
             }
           } =
             Enum.find(
               package["rows"],
               &(&1["source"] ==
                   "candidate_refresh.source_station_reservation_hold_summary.review_rows.provider_calendar_contention_groups")
             )

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)
  end

  test "candidate refresh hold import-readiness summaries become station reservation review rows" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "refresh_id" => "candidate_refresh:hold_import_readiness_review:001",
      "source_station_reservation_hold_import_readiness_summary" =>
        station_reservation_hold_import_readiness_summary()
    }

    package = OperatorReview.from_candidate_refresh_artifact(artifact)

    assert %{
             "source_artifact_type" => "candidate_refresh.v1",
             "source_artifact_id" => "candidate_refresh:hold_import_readiness_review:001",
             "review_count" => 2,
             "station_reservation_review_count" => 2,
             "required_operator_action_counts" => %{
               "review_station_provider_contention" => 1,
               "review_station_reservation_overlap" => 1
             }
           } = package

    affected_row = Enum.find(package["rows"], &(&1["contact_id"] == "dl_source_reserved"))

    assert %{
             "review_type" => "station_reservation_review",
             "source" =>
               "candidate_refresh.source_station_reservation_hold_import_readiness_summary.import_readiness_rows.affected_contacts",
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
             "required_operator_action" => "review_station_reservation_overlap",
             "source_station_reservation_hold_import_readiness_summary" => %{
               "model" => "artifact_only_station_reservation_hold_import_readiness_summary",
               "import_readiness_status" => "review_required",
               "reservation_hold_count" => 2,
               "reservation_hold_ids_by_direction" => %{
                 "downlink" => ["reservation_expired"],
                 "uplink" => ["reservation_missing"]
               }
             },
             "source_station_reservation" => %{
               "station_reservation_hold_import_status" => "review_required_before_import",
               "source_station_reservation_hold_import_readiness_summary" => %{
                 "import_readiness_status" => "review_required"
               }
             }
           } = affected_row

    assert %{
             "review_type" => "station_reservation_review",
             "source" =>
               "candidate_refresh.source_station_reservation_hold_import_readiness_summary.import_readiness_rows.provider_calendar_contention_groups",
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
             "required_operator_action" => "review_station_provider_contention",
             "source_station_reservation" => %{
               "reservation_review_row_type" => "provider_calendar_contention_group",
               "station_reservation_hold_import_status" => "review_required_before_import"
             }
           } =
             Enum.find(
               package["rows"],
               &(&1["source"] ==
                   "candidate_refresh.source_station_reservation_hold_import_readiness_summary.import_readiness_rows.provider_calendar_contention_groups")
             )

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)
  end

  test "candidate refresh result artifact station reservation reports become operator review rows" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "refresh_id" => "candidate_refresh:wrapped_station_reservation_review:001",
      "result_artifact" => [
        %{
          "schema_contract" => "result_artifact.v1",
          "station_reservation_report" => %{
            "schema_contract" => "station_reservation_report.v1",
            "source" => "ops_calendar",
            "affected_contacts" => [
              %{
                "contact_id" => "dl_wrapped_reserved",
                "ground_station_id" => "equator_prime",
                "starts_at_s" => 100.0,
                "ends_at_s" => 160.0,
                "station_calendar_entry_id" => "calendar_wrapped_reserved_1",
                "station_calendar_provider_id" => "ops_calendar",
                "station_calendar_provider_entry_id" => "provider_wrapped_reserved_1",
                "station_contention_status" => "reserved_overlap",
                "station_reservation_match_status" => "owned",
                "station_reservation_id" => "reservation_wrapped_1",
                "station_reserved_by" => "network_partner",
                "station_reservation_status" => "held",
                "station_calendar_reservation_overlap_count" => 1,
                "station_calendar_reservation_ids" => ["reservation_wrapped_1"],
                "station_calendar_reserved_by" => ["network_partner"],
                "station_calendar_reservation_statuses" => ["held"],
                "station_calendar_reservation_expires_at_s" => [240.0],
                "required_operator_action" => "review_station_reservation_overlap"
              }
            ],
            "provider_calendar_contention_groups" => [
              %{
                "id" => "station_calendar_provider_contention:equator_prime:wrapped",
                "provider_calendar_contention_status" => "provider_calendar_overlap",
                "required_operator_action" => "review_station_provider_contention",
                "ground_station_id" => "equator_prime",
                "starts_at_s" => 95.0,
                "ends_at_s" => 165.0,
                "entry_count" => 2,
                "entry_ids" => ["calendar_wrapped_reserved_1", "calendar_wrapped_reserved_2"],
                "reservation_ids" => ["reservation_wrapped_1", "reservation_wrapped_2"],
                "reservation_statuses" => ["held", "confirmed"]
              }
            ]
          }
        }
      ]
    }

    package = OperatorReview.from_candidate_refresh_artifact(artifact)

    assert %{
             "source_artifact_type" => "candidate_refresh.v1",
             "source_artifact_id" => "candidate_refresh:wrapped_station_reservation_review:001",
             "review_count" => 2,
             "station_reservation_review_count" => 2
           } = package

    assert %{
             "review_type" => "station_reservation_review",
             "source" =>
               "candidate_refresh.result_artifact[0].station_reservation_report.affected_contacts",
             "contact_id" => "dl_wrapped_reserved",
             "ground_station_id" => "equator_prime",
             "station_calendar_provider_id" => "ops_calendar",
             "station_calendar_provider_entry_id" => "provider_wrapped_reserved_1",
             "station_reservation_id" => "reservation_wrapped_1",
             "station_reserved_by" => "network_partner",
             "station_reservation_status" => "held",
             "station_reservation_match_status" => "owned",
             "required_operator_action" => "review_station_reservation_overlap",
             "source_station_reservation" => %{
               "contact_id" => "dl_wrapped_reserved",
               "station_reservation_id" => "reservation_wrapped_1"
             }
           } =
             Enum.find(
               package["rows"],
               &(&1["source"] ==
                   "candidate_refresh.result_artifact[0].station_reservation_report.affected_contacts")
             )

    assert %{
             "review_type" => "station_reservation_review",
             "source" =>
               "candidate_refresh.result_artifact[0].station_reservation_report.provider_calendar_contention_groups",
             "provider_calendar_contention_group_id" =>
               "station_calendar_provider_contention:equator_prime:wrapped",
             "provider_calendar_contention_reservation_ids" => [
               "reservation_wrapped_1",
               "reservation_wrapped_2"
             ],
             "required_operator_action" => "review_station_provider_contention",
             "source_station_reservation" => %{
               "id" => "station_calendar_provider_contention:equator_prime:wrapped"
             }
           } =
             Enum.find(
               package["rows"],
               &(&1["source"] ==
                   "candidate_refresh.result_artifact[0].station_reservation_report.provider_calendar_contention_groups")
             )

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)
  end

  test "candidate refresh result artifact hold import-readiness summaries become station reservation review rows" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "refresh_id" => "candidate_refresh:wrapped_hold_import_readiness_review:001",
      "source_result_artifact" => [
        %{
          "schema_contract" => "result_artifact.v1",
          "source_station_reservation_hold_import_readiness_summary" =>
            station_reservation_hold_import_readiness_summary()
        }
      ]
    }

    package = OperatorReview.from_candidate_refresh_artifact(artifact)

    assert %{
             "source_artifact_type" => "candidate_refresh.v1",
             "source_artifact_id" => "candidate_refresh:wrapped_hold_import_readiness_review:001",
             "review_count" => 2,
             "station_reservation_review_count" => 2
           } = package

    assert %{
             "review_type" => "station_reservation_review",
             "source" =>
               "candidate_refresh.source_result_artifact[0].source_station_reservation_hold_import_readiness_summary.import_readiness_rows.affected_contacts",
             "contact_id" => "dl_source_reserved",
             "station_reservation_id" => "reservation_expired",
             "station_reservation_hold_import_status" => "review_required_before_import",
             "station_reservation_hold_import_readiness_status" => "review_required",
             "station_reservation_hold_import_execution_boundary" =>
               "artifact_only_no_provider_or_cadence_writes",
             "source_station_reservation_hold_import_readiness_summary" => %{
               "reservation_hold_count" => 2,
               "import_readiness_status" => "review_required"
             }
           } =
             Enum.find(
               package["rows"],
               &(&1["source"] ==
                   "candidate_refresh.source_result_artifact[0].source_station_reservation_hold_import_readiness_summary.import_readiness_rows.affected_contacts")
             )

    assert %{
             "review_type" => "station_reservation_review",
             "source" =>
               "candidate_refresh.source_result_artifact[0].source_station_reservation_hold_import_readiness_summary.import_readiness_rows.provider_calendar_contention_groups",
             "provider_calendar_contention_reservation_ids" => ["reservation_missing"],
             "station_reservation_hold_provider_write" => "not_performed_by_summary",
             "station_reservation_hold_cadence_write" => "not_performed_by_summary",
             "station_reservation_hold_reservation_acceptance" => "not_performed_by_summary",
             "required_operator_action" => "review_station_provider_contention"
           } =
             Enum.find(
               package["rows"],
               &(&1["source"] ==
                   "candidate_refresh.source_result_artifact[0].source_station_reservation_hold_import_readiness_summary.import_readiness_rows.provider_calendar_contention_groups")
             )

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)
  end

  test "candidate refresh result artifact station reservation summaries become operator review rows" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "refresh_id" => "candidate_refresh:wrapped_station_reservation_summaries:001",
      "source_result_artifact" => [
        %{
          "schema_contract" => "result_artifact.v1",
          "source_station_reservation_review_summary" =>
            station_reservation_summary_fixture("station_reservation_review_summary_v1.json"),
          "station_reservation_hold_summary" =>
            station_reservation_summary_fixture("station_reservation_hold_summary_v1.json")
        }
      ]
    }

    package = OperatorReview.from_candidate_refresh_artifact(artifact)

    assert %{
             "source_artifact_type" => "candidate_refresh.v1",
             "source_artifact_id" =>
               "candidate_refresh:wrapped_station_reservation_summaries:001",
             "review_count" => 5,
             "station_reservation_review_count" => 5
           } = package

    assert %{
             "review_type" => "station_reservation_review",
             "source" =>
               "candidate_refresh.source_result_artifact[0].source_station_reservation_review_summary.review_rows.affected_contacts",
             "station_reservation_id" => "reservation_expired",
             "source_station_reservation" => %{
               "source_station_reservation_summary" => %{
                 "schema_contract" => "station_reservation_review_summary.v1"
               }
             }
           } =
             Enum.find(
               package["rows"],
               &(&1["source"] ==
                   "candidate_refresh.source_result_artifact[0].source_station_reservation_review_summary.review_rows.affected_contacts")
             )

    assert %{
             "review_type" => "station_reservation_review",
             "source" =>
               "candidate_refresh.source_result_artifact[0].station_reservation_hold_summary.review_rows.provider_calendar_contention_groups",
             "station_reservation_hold_count" => 2,
             "source_station_reservation" => %{
               "source_station_reservation_summary" => %{
                 "schema_contract" => "station_reservation_hold_summary.v1"
               }
             }
           } =
             Enum.find(
               package["rows"],
               &(&1["source"] ==
                   "candidate_refresh.source_result_artifact[0].station_reservation_hold_summary.review_rows.provider_calendar_contention_groups")
             )

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)
  end

  defp station_reservation_summary_fixture(filename) do
    study_result_fixture(filename)
  end

  defp study_result_fixture(filename) do
    ["study_results", filename]
    |> Path.join()
    |> File.read!()
    |> :json.decode()
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
