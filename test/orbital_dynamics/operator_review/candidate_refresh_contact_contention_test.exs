defmodule OrbitalDynamics.OperatorReview.CandidateRefreshContactContentionTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.{OperatorReview, Schema}

  test "candidate refresh source contact contention reports become operator review rows" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "refresh_id" => "candidate_refresh:source_contact_contention_review:001",
      "source_contact_contention_report" => [
        %{
          "schema_contract" => "contact_contention_report.v1",
          "source" => "mission_state.source_contact_contention_report",
          "invalid_contact_inputs" => [
            %{
              "id" => "invalid_contact:malformed_contact",
              "contact_id" => "malformed_contact",
              "ground_station_id" => "equator_prime",
              "starts_at_s" => 90.0,
              "ends_at_s" => 120.0,
              "direction" => "downlink",
              "required_operator_action" => "review_invalid_contact_contention_input",
              "approval_status" => "operator_review_required",
              "operator_action_reason" => "invalid_contact_shape",
              "invalid_contact_input_reason" => "invalid_contact_shape"
            }
          ],
          "conflict_groups" => [
            %{
              "id" => "station:equator_prime:contention:1",
              "ground_station_id" => "equator_prime",
              "contact_count" => 2,
              "starts_at_s" => 100.0,
              "ends_at_s" => 220.0,
              "direction" => "downlink",
              "required_operator_action" => "review_contact_contention",
              "approval_status" => "operator_review_required",
              "operator_action_reason" => "same_station_overlapping_contact_windows",
              "contact_ids" => ["dl_1", "dl_2"],
              "source_window_ids" => [
                "window:leo_1:ground_station_access:equator_prime:1",
                "window:leo_2:ground_station_access:equator_prime:1"
              ],
              "scenario_ids" => ["leo_1", "leo_2"]
            }
          ]
        }
      ]
    }

    package = OperatorReview.from_candidate_refresh_artifact(artifact)

    assert %{
             "source_artifact_type" => "candidate_refresh.v1",
             "source_artifact_id" => "candidate_refresh:source_contact_contention_review:001",
             "review_count" => 2,
             "contention_review_count" => 2
           } = package

    assert [invalid_row, group_row] = package["rows"]

    assert %{
             "review_type" => "contact_contention_review",
             "source" =>
               "candidate_refresh.source_contact_contention_report[0].invalid_contact_inputs",
             "subject_id" => "invalid_contact:malformed_contact",
             "contact_id" => "malformed_contact",
             "ground_station_id" => "equator_prime",
             "direction" => "downlink",
             "required_operator_action" => "review_invalid_contact_contention_input",
             "invalid_contact_input" => true,
             "invalid_contact_input_reason" => "invalid_contact_shape",
             "source_invalid_contact_input" => %{
               "contact_id" => "malformed_contact",
               "invalid_contact_input_reason" => "invalid_contact_shape"
             }
           } = invalid_row

    assert invalid_row["starts_at_s"] == 90.0

    assert %{
             "review_type" => "contact_contention_review",
             "source" => "candidate_refresh.source_contact_contention_report[0].conflict_groups",
             "subject_id" => "station:equator_prime:contention:1",
             "ground_station_id" => "equator_prime",
             "direction" => "downlink",
             "contact_count" => 2,
             "contact_ids" => ["dl_1", "dl_2"],
             "source_window_ids" => [
               "window:leo_1:ground_station_access:equator_prime:1",
               "window:leo_2:ground_station_access:equator_prime:1"
             ],
             "scenario_ids" => ["leo_1", "leo_2"],
             "required_operator_action" => "review_contact_contention",
             "approval_status" => "operator_review_required",
             "source_contention_group" => %{"contact_ids" => ["dl_1", "dl_2"]}
           } = group_row

    assert group_row["starts_at_s"] == 100.0

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)
  end

  test "candidate refresh result artifact contact contention reports become operator review rows" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "refresh_id" => "candidate_refresh:wrapped_contact_contention_review:001",
      "source_result_artifact" => %{
        "schema_contract" => "result_artifact.v1",
        "contact_allocation_report" => %{
          "schema_contract" => "contact_allocation_report.v1",
          "contact_contention_report" => %{
            "schema_contract" => "contact_contention_report.v1",
            "invalid_contact_inputs" => [
              %{
                "id" => "invalid_contact:wrapped_malformed_contact",
                "contact_id" => "wrapped_malformed_contact",
                "ground_station_id" => "equator_prime",
                "starts_at_s" => 90.0,
                "ends_at_s" => 120.0,
                "direction" => "downlink",
                "required_operator_action" => "review_invalid_contact_contention_input",
                "approval_status" => "operator_review_required",
                "operator_action_reason" => "invalid_contact_shape",
                "invalid_contact_input_reason" => "invalid_contact_shape"
              }
            ],
            "conflict_groups" => [
              %{
                "id" => "station:equator_prime:wrapped_contention:1",
                "ground_station_id" => "equator_prime",
                "contact_count" => 2,
                "starts_at_s" => 100.0,
                "ends_at_s" => 220.0,
                "direction" => "downlink",
                "required_operator_action" => "review_contact_contention",
                "approval_status" => "operator_review_required",
                "operator_action_reason" => "same_station_overlapping_contact_windows",
                "contact_ids" => ["dl_wrapped_1", "dl_wrapped_2"],
                "source_window_ids" => [
                  "window:leo_1:ground_station_access:equator_prime:1",
                  "window:leo_2:ground_station_access:equator_prime:1"
                ],
                "scenario_ids" => ["leo_1", "leo_2"]
              }
            ]
          }
        }
      }
    }

    package = OperatorReview.from_candidate_refresh_artifact(artifact)

    assert %{
             "source_artifact_type" => "candidate_refresh.v1",
             "source_artifact_id" => "candidate_refresh:wrapped_contact_contention_review:001",
             "review_count" => 2,
             "contention_review_count" => 2
           } = package

    assert [invalid_row, group_row] = package["rows"]

    assert %{
             "review_type" => "contact_contention_review",
             "source" =>
               "candidate_refresh.source_result_artifact.contact_allocation_report.contact_contention_report.invalid_contact_inputs",
             "subject_id" => "invalid_contact:wrapped_malformed_contact",
             "contact_id" => "wrapped_malformed_contact",
             "ground_station_id" => "equator_prime",
             "direction" => "downlink",
             "required_operator_action" => "review_invalid_contact_contention_input",
             "invalid_contact_input" => true,
             "invalid_contact_input_reason" => "invalid_contact_shape",
             "source_invalid_contact_input" => %{
               "contact_id" => "wrapped_malformed_contact",
               "invalid_contact_input_reason" => "invalid_contact_shape"
             }
           } = invalid_row

    assert invalid_row["starts_at_s"] == 90.0

    assert %{
             "review_type" => "contact_contention_review",
             "source" =>
               "candidate_refresh.source_result_artifact.contact_allocation_report.contact_contention_report.conflict_groups",
             "subject_id" => "station:equator_prime:wrapped_contention:1",
             "ground_station_id" => "equator_prime",
             "direction" => "downlink",
             "contact_count" => 2,
             "contact_ids" => ["dl_wrapped_1", "dl_wrapped_2"],
             "scenario_ids" => ["leo_1", "leo_2"],
             "required_operator_action" => "review_contact_contention",
             "approval_status" => "operator_review_required",
             "source_contention_group" => %{
               "contact_ids" => ["dl_wrapped_1", "dl_wrapped_2"]
             }
           } = group_row

    assert group_row["starts_at_s"] == 100.0

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)
  end
end
