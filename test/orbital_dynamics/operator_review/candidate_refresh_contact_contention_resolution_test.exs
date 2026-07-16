defmodule OrbitalDynamics.OperatorReview.CandidateRefreshContactContentionResolutionTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.{CadenceImport, OperatorReview, Schema}

  test "candidate refresh source contact contention resolution reports become operator review rows" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "refresh_id" => "candidate_refresh:source_contact_contention_resolution_review:001",
      "source_contact_contention_resolution_report" => [
        %{
          "schema_contract" => "contact_contention_resolution_report.v1",
          "source" => "mission_state.source_contact_contention_resolution_report",
          "recommendations" => [
            %{
              "group_id" => "station:equator_prime:contention:1",
              "ground_station_id" => "equator_prime",
              "starts_at_s" => 100.0,
              "ends_at_s" => 220.0,
              "selected_contact_id" => "dl_1",
              "deferred_contact_ids" => ["dl_2"],
              "candidate_count" => 2,
              "selection_reason" => "highest_score_earliest_start",
              "action" => "recommend_preferred_contact_for_operator_review",
              "review_status" => "operator_review_required"
            }
          ]
        }
      ]
    }

    package = OperatorReview.from_candidate_refresh_artifact(artifact)

    assert %{
             "source_artifact_type" => "candidate_refresh.v1",
             "source_artifact_id" =>
               "candidate_refresh:source_contact_contention_resolution_review:001",
             "review_count" => 1,
             "contention_recommendation_count" => 1
           } = package

    assert [
             %{
               "review_type" => "contact_contention_recommendation",
               "source" =>
                 "candidate_refresh.source_contact_contention_resolution_report[0].recommendations",
               "subject_id" => "station:equator_prime:contention:1",
               "ground_station_id" => "equator_prime",
               "selected_contact_id" => "dl_1",
               "deferred_contact_ids" => ["dl_2"],
               "candidate_count" => 2,
               "selection_reason" => "highest_score_earliest_start",
               "required_operator_action" => "recommend_preferred_contact_for_operator_review",
               "approval_status" => "operator_review_required",
               "source_recommendation" => %{"selected_contact_id" => "dl_1"}
             } = row
           ] = package["rows"]

    assert row["starts_at_s"] == 100.0

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)
  end

  test "candidate refresh result artifact contact contention resolution reports become operator review rows" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "refresh_id" => "candidate_refresh:wrapped_contact_contention_resolution_review:001",
      "result_artifact" => [
        %{
          "schema_contract" => "result_artifact.v1",
          "contact_contention_resolution_report" => %{
            "schema_contract" => "contact_contention_resolution_report.v1",
            "source" => "wrapped.contact_contention_resolution_report",
            "recommendations" => [
              %{
                "group_id" => "station:equator_prime:wrapped_contention:1",
                "ground_station_id" => "equator_prime",
                "starts_at_s" => 100.0,
                "ends_at_s" => 220.0,
                "selected_contact_id" => "dl_wrapped_1",
                "deferred_contact_ids" => ["dl_wrapped_2"],
                "candidate_count" => 2,
                "selection_reason" => "highest_score_earliest_start",
                "action" => "recommend_preferred_contact_for_operator_review",
                "review_status" => "operator_review_required"
              }
            ]
          }
        }
      ]
    }

    package = OperatorReview.from_candidate_refresh_artifact(artifact)

    assert %{
             "source_artifact_type" => "candidate_refresh.v1",
             "source_artifact_id" =>
               "candidate_refresh:wrapped_contact_contention_resolution_review:001",
             "review_count" => 1,
             "contention_recommendation_count" => 1
           } = package

    assert [
             %{
               "review_type" => "contact_contention_recommendation",
               "source" =>
                 "candidate_refresh.result_artifact[0].contact_contention_resolution_report.recommendations",
               "subject_id" => "station:equator_prime:wrapped_contention:1",
               "ground_station_id" => "equator_prime",
               "selected_contact_id" => "dl_wrapped_1",
               "deferred_contact_ids" => ["dl_wrapped_2"],
               "candidate_count" => 2,
               "selection_reason" => "highest_score_earliest_start",
               "required_operator_action" => "recommend_preferred_contact_for_operator_review",
               "approval_status" => "operator_review_required",
               "source_recommendation" => %{"selected_contact_id" => "dl_wrapped_1"}
             } = row
           ] = package["rows"]

    assert row["starts_at_s"] == 100.0

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)
  end

  test "candidate refresh accepted planning state contact contention resolution summaries become review rows" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "refresh_id" => "candidate_refresh:accepted_contact_contention_resolution:001",
      "accepted_planning_state" => %{
        "source_contact_contention_resolution_summary" =>
          study_result_fixture("contact_contention_resolution_summary_v1.json")
      }
    }

    package = OperatorReview.from_candidate_refresh_artifact(artifact)

    assert %{
             "source_artifact_type" => "candidate_refresh.v1",
             "source_artifact_id" =>
               "candidate_refresh:accepted_contact_contention_resolution:001",
             "review_count" => 2,
             "review_type_counts" => %{"contact_contention_recommendation" => 2},
             "required_operator_action_counts" => %{
               "recommend_preferred_contact_for_operator_review" => 2
             }
           } = package

    assert Enum.map(package["rows"], & &1["source"]) == [
             "candidate_refresh.accepted_planning_state.source_contact_contention_resolution_summary.summary_recommendations",
             "candidate_refresh.accepted_planning_state.source_contact_contention_resolution_summary.summary_recommendations"
           ]

    assert %{
             "review_type" => "contact_contention_recommendation",
             "subject_id" => "spacecraft:sat_1:contention:1",
             "required_operator_action" => "recommend_preferred_contact_for_operator_review",
             "selected_contact_ids" => ["dl_3"],
             "deferred_contact_ids" => ["dl_4"],
             "review_contact_ids" => ["dl_3", "dl_4"],
             "source_summary_schema_contract" => "contact_contention_resolution_summary.v1",
             "source_summary_model" => "artifact_only_contact_contention_resolution_summary",
             "source_contact_contention_resolution_summary" => %{
               "schema_contract" => "contact_contention_resolution_summary.v1",
               "model" => "artifact_only_contact_contention_resolution_summary",
               "assumptions" => %{
                 "execution_boundary" =>
                   "artifact_only_no_provider_reservation_or_schedule_mutation",
                 "operator_authority" => "not_granted_by_summary"
               }
             }
           } =
             Enum.find(
               package["rows"],
               &(&1["subject_id"] == "spacecraft:sat_1:contention:1")
             )

    manifest = CadenceImport.from_candidate_refresh_artifact(artifact)

    assert %{
             "source_artifact_type" => "candidate_refresh.v1",
             "source_artifact_id" =>
               "candidate_refresh:accepted_contact_contention_resolution:001",
             "row_count" => 2,
             "source_review_type_counts" => %{"contact_contention_recommendation" => 2},
             "import_action_counts" => %{"review_contact_contention_resolution" => 2}
           } = manifest

    assert %{
             "import_action" => "review_contact_contention_resolution",
             "source_review_type" => "contact_contention_recommendation",
             "source_review_row" => %{
               "source" =>
                 "candidate_refresh.accepted_planning_state.source_contact_contention_resolution_summary.summary_recommendations",
               "source_contact_contention_resolution_summary" => %{
                 "schema_contract" => "contact_contention_resolution_summary.v1"
               }
             }
           } = List.first(manifest["rows"])

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(manifest)
  end

  test "candidate refresh mission state contact contention resolution summaries become review rows" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "refresh_id" => "candidate_refresh:mission_contact_contention_resolution:001",
      "mission_state" => %{
        "contact_contention_resolution_summary" =>
          study_result_fixture("contact_contention_resolution_summary_v1.json")
      }
    }

    package = OperatorReview.from_candidate_refresh_artifact(artifact)

    assert %{
             "source_artifact_type" => "candidate_refresh.v1",
             "source_artifact_id" =>
               "candidate_refresh:mission_contact_contention_resolution:001",
             "review_count" => 2,
             "review_type_counts" => %{"contact_contention_recommendation" => 2}
           } = package

    assert Enum.map(package["rows"], & &1["source"]) == [
             "candidate_refresh.mission_state.contact_contention_resolution_summary.summary_recommendations",
             "candidate_refresh.mission_state.contact_contention_resolution_summary.summary_recommendations"
           ]

    assert %{
             "review_type" => "contact_contention_recommendation",
             "subject_id" => "station:equator_prime:contention:1",
             "selected_contact_ids" => ["dl_1"],
             "deferred_contact_ids" => ["dl_2"],
             "review_contact_ids" => ["dl_1", "dl_2"],
             "source_contact_contention_resolution_summary" => %{
               "schema_contract" => "contact_contention_resolution_summary.v1",
               "review_recommendation_count" => 2
             }
           } =
             Enum.find(
               package["rows"],
               &(&1["subject_id"] == "station:equator_prime:contention:1")
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
