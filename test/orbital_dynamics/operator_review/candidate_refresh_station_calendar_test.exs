defmodule OrbitalDynamics.OperatorReview.CandidateRefreshStationCalendarTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.{CadenceImport, OperatorReview, Schema}

  test "candidate refresh source station calendar reports become operator review rows" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "refresh_id" => "candidate_refresh:station_calendar_review:001",
      "source_station_calendar_report" => %{
        "schema_contract" => "station_calendar_report.v1",
        "affected_contacts" => [
          %{
            "contact_id" => "dl_station_unavailable",
            "scenario_id" => "leo_1",
            "contact_type" => "planned_contact",
            "direction" => "downlink",
            "ground_station_id" => "equator_prime",
            "starts_at_s" => 100.0,
            "ends_at_s" => 160.0,
            "station_calendar_entry_id" => "calendar_unavailable_1",
            "station_calendar_provider_id" => "ops_calendar",
            "station_calendar_provider_entry_id" => "provider_unavailable_1",
            "station_calendar_directions" => ["downlink"],
            "station_availability" => "unavailable",
            "station_contention_status" => "station_unavailable",
            "station_calendar_trust_boundary_status" => "declared",
            "trust_boundary" => "mission_state_station_calendar_report",
            "required_operator_action" => "review_station_calendar_contact",
            "approval_status" => "operator_review_required",
            "source_station_calendar_entry" => %{
              "id" => "calendar_unavailable_1",
              "availability" => "unavailable"
            }
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
            "entry_ids" => ["calendar_unavailable_1", "calendar_reserved_1"],
            "provider_ids" => ["ops_calendar"],
            "provider_entry_ids" => ["provider_unavailable_1", "provider_reserved_1"],
            "availabilities" => ["unavailable", "reserved"],
            "directions" => ["downlink"]
          }
        ]
      }
    }

    package = OperatorReview.from_candidate_refresh_artifact(artifact)

    assert %{
             "source_artifact_type" => "candidate_refresh.v1",
             "source_artifact_id" => "candidate_refresh:station_calendar_review:001",
             "review_count" => 2,
             "station_calendar_review_count" => 2
           } = package

    assert %{
             "review_type" => "station_calendar_review",
             "source" => "candidate_refresh.source_station_calendar_report.affected_contacts",
             "contact_id" => "dl_station_unavailable",
             "ground_station_id" => "equator_prime",
             "station_calendar_entry_id" => "calendar_unavailable_1",
             "station_calendar_provider_id" => "ops_calendar",
             "station_calendar_provider_entry_id" => "provider_unavailable_1",
             "station_availability" => "unavailable",
             "station_contention_status" => "station_unavailable",
             "station_calendar_trust_boundary_status" => "declared",
             "trust_boundary" => "mission_state_station_calendar_report",
             "required_operator_action" => "review_station_calendar_contact",
             "source_station_calendar_entry" => %{
               "id" => "calendar_unavailable_1",
               "availability" => "unavailable"
             },
             "source_station_calendar_review" => %{
               "contact_id" => "dl_station_unavailable",
               "station_contention_status" => "station_unavailable"
             }
           } =
             Enum.find(
               package["rows"],
               &(&1["source"] ==
                   "candidate_refresh.source_station_calendar_report.affected_contacts")
             )

    assert %{
             "review_type" => "station_calendar_review",
             "source" =>
               "candidate_refresh.source_station_calendar_report.provider_calendar_contention_groups",
             "ground_station_id" => "equator_prime",
             "provider_calendar_contention_status" => "provider_calendar_overlap",
             "provider_calendar_contention_entry_count" => 2,
             "provider_calendar_contention_entry_ids" => [
               "calendar_unavailable_1",
               "calendar_reserved_1"
             ],
             "provider_calendar_contention_provider_ids" => ["ops_calendar"],
             "required_operator_action" => "review_station_provider_contention",
             "source_station_calendar_provider_contention" => %{
               "id" => "station_calendar_provider_contention:equator_prime:1",
               "entry_count" => 2
             }
           } =
             Enum.find(
               package["rows"],
               &(&1["source"] ==
                   "candidate_refresh.source_station_calendar_report.provider_calendar_contention_groups")
             )

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)
  end

  test "candidate refresh station calendar precedence summaries become operator review rows" do
    summary = study_result_fixture("station_calendar_precedence_summary_v1.json")

    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "refresh_id" => "candidate_refresh:station_calendar_precedence_summary:001",
      "source_station_calendar_precedence_summary" => summary
    }

    package = OperatorReview.from_candidate_refresh_artifact(artifact)

    assert %{
             "source_artifact_type" => "candidate_refresh.v1",
             "source_artifact_id" => "candidate_refresh:station_calendar_precedence_summary:001",
             "review_count" => 1,
             "station_calendar_review_count" => 1
           } = package

    assert [
             %{
               "review_type" => "station_calendar_review",
               "source" => "candidate_refresh.source_station_calendar_precedence_summary",
               "subject_id" => "ops_calendar",
               "required_operator_action" => "review_station_calendar",
               "station_calendar_precedence_review_status" => "review_required",
               "station_calendar_precedence_affected_contact_count" => 1,
               "station_calendar_precedence_applied_availability_counts" => %{
                 "unavailable" => 1
               },
               "station_calendar_precedence_overlap_availability_counts" => %{
                 "reduced_capacity" => 1,
                 "reserved" => 1,
                 "unavailable" => 1
               },
               "station_calendar_precedence_reserved_under_higher_precedence_contact_ids" => [
                 "dl_1"
               ],
               "station_calendar_precedence_model_limits" => [
                 "declared_data_only",
                 "no_network_calls",
                 "no_provider_reservation",
                 "no_schedule_mutation",
                 "no_conflict_resolution"
               ],
               "source_station_calendar_precedence_summary" => %{
                 "schema_contract" => "station_calendar_precedence_summary.v1",
                 "source_summary_schema_contract" => "station_calendar_precedence_summary.v1",
                 "source_summary_model" => "artifact_only_station_calendar_precedence_summary",
                 "assumptions" => %{
                   "execution_boundary" => "artifact_only_no_provider_reservation",
                   "operator_authority" => "not_granted_by_summary"
                 }
               }
             }
           ] = package["rows"]

    manifest = CadenceImport.from_candidate_refresh_artifact(artifact)

    assert %{
             "source_artifact_type" => "candidate_refresh.v1",
             "source_artifact_id" => "candidate_refresh:station_calendar_precedence_summary:001",
             "row_count" => 1,
             "source_review_type_counts" => %{"station_calendar_review" => 1},
             "import_action_counts" => %{"review_station_calendar" => 1}
           } = manifest

    assert [
             %{
               "import_action" => "review_station_calendar",
               "source_review_type" => "station_calendar_review",
               "source_review_row" => %{
                 "source" => "candidate_refresh.source_station_calendar_precedence_summary",
                 "station_calendar_precedence_review_status" => "review_required",
                 "source_station_calendar_precedence_summary" => %{
                   "schema_contract" => "station_calendar_precedence_summary.v1"
                 }
               }
             }
           ] = manifest["rows"]

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(manifest)
  end

  test "candidate refresh result artifact station calendar precedence summaries become review rows" do
    summary = study_result_fixture("station_calendar_precedence_summary_v1.json")

    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "refresh_id" => "candidate_refresh:wrapped_station_calendar_precedence_summary:001",
      "source_result_artifact" => [
        %{
          "schema_contract" => "result_artifact.v1",
          "source_station_calendar_precedence_summary" => summary,
          "station_calendar_precedence_summary" => summary
        }
      ]
    }

    package = OperatorReview.from_candidate_refresh_artifact(artifact)

    assert %{
             "source_artifact_type" => "candidate_refresh.v1",
             "source_artifact_id" =>
               "candidate_refresh:wrapped_station_calendar_precedence_summary:001",
             "review_count" => 2,
             "station_calendar_review_count" => 2
           } = package

    assert Enum.map(package["rows"], & &1["source"]) == [
             "candidate_refresh.source_result_artifact[0].source_station_calendar_precedence_summary",
             "candidate_refresh.source_result_artifact[0].station_calendar_precedence_summary"
           ]

    assert %{
             "review_type" => "station_calendar_review",
             "source" =>
               "candidate_refresh.source_result_artifact[0].station_calendar_precedence_summary",
             "station_calendar_precedence_reserved_under_higher_precedence_contact_count" => 1,
             "source_station_calendar_precedence_summary" => %{
               "source_summary_schema_contract" => "station_calendar_precedence_summary.v1",
               "model_limits" => [
                 "declared_data_only",
                 "no_network_calls",
                 "no_provider_reservation",
                 "no_schedule_mutation",
                 "no_conflict_resolution"
               ]
             }
           } =
             Enum.find(
               package["rows"],
               &(&1["source"] ==
                   "candidate_refresh.source_result_artifact[0].station_calendar_precedence_summary")
             )

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)
  end

  test "candidate refresh result artifact station calendar reports become operator review rows" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "refresh_id" => "candidate_refresh:wrapped_station_calendar_review:001",
      "source_result_artifact" => %{
        "schema_contract" => "result_artifact.v1",
        "station_calendar_report" => %{
          "schema_contract" => "station_calendar_report.v1",
          "affected_contacts" => [
            %{
              "contact_id" => "dl_wrapped_station_unavailable",
              "scenario_id" => "leo_1",
              "contact_type" => "planned_contact",
              "direction" => "downlink",
              "ground_station_id" => "equator_prime",
              "starts_at_s" => 100.0,
              "ends_at_s" => 160.0,
              "station_calendar_entry_id" => "calendar_unavailable_wrapped",
              "station_calendar_provider_id" => "ops_calendar",
              "station_calendar_provider_entry_id" => "provider_unavailable_wrapped",
              "station_calendar_directions" => ["downlink"],
              "station_availability" => "unavailable",
              "station_contention_status" => "station_unavailable",
              "station_calendar_trust_boundary_status" => "declared",
              "trust_boundary" => "mission_state_station_calendar_report",
              "required_operator_action" => "review_station_calendar_contact",
              "approval_status" => "operator_review_required",
              "source_station_calendar_entry" => %{
                "id" => "calendar_unavailable_wrapped",
                "availability" => "unavailable"
              }
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
              "entry_ids" => ["calendar_unavailable_wrapped", "calendar_reserved_wrapped"],
              "provider_ids" => ["ops_calendar"],
              "provider_entry_ids" => [
                "provider_unavailable_wrapped",
                "provider_reserved_wrapped"
              ],
              "availabilities" => ["unavailable", "reserved"],
              "directions" => ["downlink"]
            }
          ]
        }
      }
    }

    package = OperatorReview.from_candidate_refresh_artifact(artifact)

    assert %{
             "source_artifact_type" => "candidate_refresh.v1",
             "source_artifact_id" => "candidate_refresh:wrapped_station_calendar_review:001",
             "review_count" => 2,
             "station_calendar_review_count" => 2
           } = package

    assert %{
             "review_type" => "station_calendar_review",
             "source" =>
               "candidate_refresh.source_result_artifact.station_calendar_report.affected_contacts",
             "contact_id" => "dl_wrapped_station_unavailable",
             "ground_station_id" => "equator_prime",
             "station_calendar_entry_id" => "calendar_unavailable_wrapped",
             "station_calendar_provider_id" => "ops_calendar",
             "station_calendar_provider_entry_id" => "provider_unavailable_wrapped",
             "station_availability" => "unavailable",
             "station_contention_status" => "station_unavailable",
             "source_station_calendar_entry" => %{
               "id" => "calendar_unavailable_wrapped",
               "availability" => "unavailable"
             }
           } =
             Enum.find(
               package["rows"],
               &(&1["source"] ==
                   "candidate_refresh.source_result_artifact.station_calendar_report.affected_contacts")
             )

    assert %{
             "review_type" => "station_calendar_review",
             "source" =>
               "candidate_refresh.source_result_artifact.station_calendar_report.provider_calendar_contention_groups",
             "ground_station_id" => "equator_prime",
             "provider_calendar_contention_status" => "provider_calendar_overlap",
             "provider_calendar_contention_entry_count" => 2,
             "provider_calendar_contention_entry_ids" => [
               "calendar_unavailable_wrapped",
               "calendar_reserved_wrapped"
             ],
             "provider_calendar_contention_provider_ids" => ["ops_calendar"],
             "required_operator_action" => "review_station_provider_contention",
             "source_station_calendar_provider_contention" => %{
               "id" => "station_calendar_provider_contention:equator_prime:wrapped",
               "entry_count" => 2
             }
           } =
             Enum.find(
               package["rows"],
               &(&1["source"] ==
                   "candidate_refresh.source_result_artifact.station_calendar_report.provider_calendar_contention_groups")
             )

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)
  end

  defp study_result_fixture(filename) do
    ["study_results", filename]
    |> Path.join()
    |> File.read!()
    |> :json.decode()
  end
end
