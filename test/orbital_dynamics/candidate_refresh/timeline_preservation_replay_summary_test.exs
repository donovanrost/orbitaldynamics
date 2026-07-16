defmodule OrbitalDynamics.CandidateRefresh.TimelinePreservationReplaySummaryTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.{CadenceImport, CandidateRefresh, OperatorReview, Schema, Timeline}

  test "operator review and import lift timeline preservation artifacts from candidate refresh artifacts" do
    preservation_report = fn source ->
      Timeline.preservation_report(
        [
          %{
            id: :"#{source}_locked_contact",
            type: :planned_contact,
            locked: true,
            approval_status: :pending,
            metadata: %{timeline_id: "timeline:#{source}:locked_contact"}
          },
          %{
            id: :"#{source}_executed_obs",
            type: :observe,
            status: :completed,
            metadata: %{timeline_id: "timeline:#{source}:executed_obs"}
          },
          %{
            id: :"#{source}_bad_missing_type",
            status: :planned,
            metadata: %{timeline_id: "timeline:#{source}:bad_missing_type"}
          }
        ],
        source: source
      )
    end

    preservation_status = fn source ->
      Timeline.preservation_status(%{
        id: :"#{source}_locked_downlink",
        type: :downlink,
        locked: true,
        metadata: %{timeline_id: "timeline:#{source}:locked_downlink"}
      })
    end

    direct_report = preservation_report.("direct_preservation_report")
    canonical_report = preservation_report.("canonical_preservation_report")
    wrapped_report = preservation_report.("wrapped_preservation_report")
    direct_status = preservation_status.("direct_preservation_status")
    canonical_status = preservation_status.("canonical_preservation_status")
    wrapped_status = preservation_status.("wrapped_preservation_status")

    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "refresh_id" => "candidate_refresh:timeline_preservation_handoff",
      "source_timeline_preservation_report" => [direct_report],
      "timeline_preservation_report" => canonical_report,
      "source_timeline_preservation_status" => [direct_status],
      "timeline_preservation_status" => canonical_status,
      "source_result_artifact" => [
        wrapped_report,
        %{
          "schema_contract" => "result_artifact.v1",
          "timeline_preservation_status" => wrapped_status
        }
      ]
    }

    review = OperatorReview.from_candidate_refresh_artifact(artifact)
    import = CadenceImport.from_candidate_refresh_artifact(artifact)
    source_summary = CandidateRefresh.source_report_summary(artifact)
    replay_summary = CandidateRefresh.timeline_preservation_replay_summary(artifact)

    preservation_rows =
      Enum.filter(review["rows"], &(&1["review_type"] == "timeline_preservation_review"))

    expected_source_paths = [
      "candidate_refresh.source_result_artifact[0].rows",
      "candidate_refresh.source_result_artifact[1].timeline_preservation_status.status",
      "candidate_refresh.source_timeline_preservation_report[0].rows",
      "candidate_refresh.source_timeline_preservation_status[0].status",
      "candidate_refresh.timeline_preservation_report.rows",
      "candidate_refresh.timeline_preservation_status.status"
    ]

    assert length(preservation_rows) == 12

    assert %{
             "model" => "artifact_only_candidate_refresh_timeline_preservation_replay_summary",
             "source" => "candidate_refresh.review_provenance.timeline_preservation",
             "source_artifact_count" => 6,
             "source_report_row_count" => 12,
             "source_report_paths" => ^expected_source_paths,
             "source_summary_schema_contract_counts" => %{
               "timeline_preservation_report.v1" => 9,
               "timeline_preservation_status.v1" => 3
             },
             "source_summary_model_counts" => %{
               "artifact_only_lifecycle_preservation_status" => 3,
               "artifact_only_lifecycle_preservation_summary" => 9
             },
             "timeline_preservation_status_counts" => %{
               "preservation_required" => 9,
               "review_required" => 3
             },
             "required_operator_action_counts" => %{
               "record_timeline_preservation" => 9,
               "review_timeline_preservation" => 3
             },
             "protection_decision_counts" => %{"preserve" => 9, "review_change" => 3},
             "protection_category_counts" => %{
               "executed" => 3,
               "locked_or_approved" => 6
             },
             "preservation_required_activity_ids" => [
               "canonical_preservation_report_executed_obs",
               "canonical_preservation_report_locked_contact",
               "canonical_preservation_status_locked_downlink",
               "direct_preservation_report_executed_obs",
               "direct_preservation_report_locked_contact",
               "direct_preservation_status_locked_downlink",
               "wrapped_preservation_report_executed_obs",
               "wrapped_preservation_report_locked_contact",
               "wrapped_preservation_status_locked_downlink"
             ],
             "review_required_activity_ids" => [
               "canonical_preservation_report_bad_missing_type",
               "direct_preservation_report_bad_missing_type",
               "wrapped_preservation_report_bad_missing_type"
             ],
             "action_routing" => %{
               "record_timeline_preservation" => %{
                 "review_count" => 9,
                 "timeline_preservation_statuses" => ["preservation_required"],
                 "protection_decisions" => ["preserve"],
                 "protection_categories" => ["executed", "locked_or_approved"]
               },
               "review_timeline_preservation" => %{
                 "review_count" => 3,
                 "timeline_preservation_statuses" => ["review_required"],
                 "protection_decisions" => ["review_change"]
               }
             },
             "trust_boundary_status" => "missing",
             "trust_boundaries" => [],
             "branch_local_timeline_preservation_pressure" => true,
             "branch_local_timeline_preservation_review_pressure" => true,
             "branch_local_timeline_preservation_record_pressure" => true,
             "branch_local_timeline_preservation_action_pressure" => true,
             "branch_local_timeline_preservation_routing_pressure" => true,
             "assumptions" => %{
               "timeline_preservation_application" => "not_performed_by_summary",
               "operator_authority" => "not_granted_by_timeline_preservation_replay_summary",
               "import_approval" => "not_granted_by_timeline_preservation_replay_summary",
               "timeline_mutation" => "not_performed_by_summary"
             }
           } = replay_summary

    assert replay_summary ==
             OrbitalDynamics.candidate_refresh_timeline_preservation_replay_summary(artifact)

    assert %{
             "source_report_timeline_preservation_branch_local_timeline_preservation_pressure" =>
               true,
             "source_report_timeline_preservation_branch_local_review_pressure" => true,
             "source_report_timeline_preservation_branch_local_record_pressure" => true,
             "source_report_timeline_preservation_branch_local_action_pressure" => true,
             "source_report_timeline_preservation_branch_local_routing_pressure" => true
           } = source_summary

    assert %{
             "source_artifact_type" => "candidate_refresh.v1",
             "timeline_preservation_review_count" => 12,
             "review_type_counts" => %{"timeline_preservation_review" => 12}
           } = review

    assert Enum.sort(Enum.map(preservation_rows, & &1["source"]) |> Enum.uniq()) == [
             "candidate_refresh.source_result_artifact[0].rows",
             "candidate_refresh.source_result_artifact[1].timeline_preservation_status.status",
             "candidate_refresh.source_timeline_preservation_report[0].rows",
             "candidate_refresh.source_timeline_preservation_status[0].status",
             "candidate_refresh.timeline_preservation_report.rows",
             "candidate_refresh.timeline_preservation_status.status"
           ]

    assert Enum.any?(
             preservation_rows,
             &match?(
               %{
                 "source" => "candidate_refresh.timeline_preservation_report.rows",
                 "activity_id" => "canonical_preservation_report_bad_missing_type",
                 "timeline_preservation_status" => "review_required",
                 "required_operator_action" => "review_timeline_preservation",
                 "invalid_activity_input" => true,
                 "source_timeline_preservation" => %{
                   "protection_decision" => "review_change"
                 }
               },
               &1
             )
           )

    assert Enum.any?(
             preservation_rows,
             &match?(
               %{
                 "source" => "candidate_refresh.timeline_preservation_status.status",
                 "activity_id" => "canonical_preservation_status_locked_downlink",
                 "timeline_preservation_status" => "preservation_required",
                 "required_operator_action" => "record_timeline_preservation",
                 "timeline_preservation_protection_category" => "locked_or_approved",
                 "source_timeline_preservation" => %{
                   "schema_contract" => "timeline_preservation_status.v1"
                 }
               },
               &1
             )
           )

    import_rows =
      Enum.filter(import["rows"], &(&1["source_review_type"] == "timeline_preservation_review"))

    assert length(import_rows) == 12

    assert %{
             "source_artifact_type" => "candidate_refresh.v1",
             "import_action_counts" => %{"review_timeline_preservation" => 12},
             "source_review_type_counts" => %{"timeline_preservation_review" => 12}
           } = import

    assert Enum.count(import_rows, &(&1["import_status"] == "ready_for_import")) == 9
    assert Enum.count(import_rows, &(&1["import_status"] == "review_required_before_import")) == 3

    assert Enum.all?(
             import_rows,
             &(&1["import_action"] == "review_timeline_preservation" and
                 &1["source_review_row"]["source_timeline_preservation"])
           )

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(review)

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(import)
  end

  test "source report summary omits preservation branch pressure for absent preservation rows" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{
        "source_reports" => %{
          "timeline_feedback_report" => %{
            "contract" => "timeline_feedback_report.v1",
            "count" => 1,
            "row_count" => 1,
            "paths" => ["source_timeline_feedback_report"]
          }
        }
      }
    }

    assert %{
             "source_report_timeline_preservation_branch_local_timeline_preservation_pressure" =>
               false,
             "source_report_timeline_preservation_branch_local_review_pressure" => false,
             "source_report_timeline_preservation_branch_local_record_pressure" => false,
             "source_report_timeline_preservation_branch_local_action_pressure" => false,
             "source_report_timeline_preservation_branch_local_routing_pressure" => false
           } = CandidateRefresh.source_report_summary(artifact)
  end
end
