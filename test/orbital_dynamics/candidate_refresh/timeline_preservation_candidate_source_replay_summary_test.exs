defmodule OrbitalDynamics.CandidateRefresh.TimelinePreservationCandidateSourceReplaySummaryTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.{CandidateRefresh, Timeline}

  test "timeline preservation replay reads branch candidate-source preservation rows" do
    branch_report =
      Timeline.preservation_report(
        [
          %{
            id: :branch_locked_contact,
            type: :contact,
            locked: true,
            metadata: %{timeline_id: :"timeline:branch:locked_contact"}
          },
          %{
            id: :branch_bad_missing_type,
            status: :planned,
            metadata: %{timeline_id: :"timeline:branch:bad_missing_type"}
          }
        ],
        source: "branch_preservation_report"
      )

    provenance_report =
      Timeline.preservation_report(
        [
          %{
            id: :provenance_locked_contact,
            type: :contact,
            locked: true,
            metadata: %{timeline_id: :"timeline:provenance:locked_contact"}
          }
        ],
        source: "provenance_preservation_report"
      )

    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "candidate_source" => %{
        "candidate_refresh_request_source_report_summary" => %{},
        "source_timeline_preservation_report" => branch_report
      },
      "source_timeline_preservation_report" => provenance_report
    }

    summary = CandidateRefresh.timeline_preservation_replay_summary(artifact)

    assert summary["source"] ==
             "candidate_refresh.candidate_source.candidate_refresh_request.timeline_preservation"

    assert summary["source_artifact_count"] == 1
    assert summary["source_report_row_count"] == 2

    assert summary["source_report_paths"] == [
             "candidate_source.candidate_refresh_request.source_timeline_preservation_report.rows"
           ]

    assert summary["source_summary_schema_contract_counts"] == %{
             "timeline_preservation_report.v1" => 2
           }

    assert summary["timeline_preservation_status_counts"] == %{
             "preservation_required" => 1,
             "review_required" => 1
           }

    assert summary["required_operator_action_counts"] == %{
             "record_timeline_preservation" => 1,
             "review_timeline_preservation" => 1
           }

    assert summary["preservation_required_activity_ids"] == ["branch_locked_contact"]
    assert summary["review_required_activity_ids"] == ["branch_bad_missing_type"]
    refute "provenance_locked_contact" in summary["preservation_required_activity_ids"]
    assert summary["branch_local_timeline_preservation_pressure"]
    assert summary["branch_local_timeline_preservation_review_pressure"]
    assert summary["branch_local_timeline_preservation_record_pressure"]

    assert summary["assumptions"]["replay_scope"] ==
             "timeline_preservation_candidate_source_review_provenance_only"

    assert OrbitalDynamics.candidate_refresh_timeline_preservation_replay_summary(artifact) ==
             summary
  end

  test "timeline preservation replay labels direct candidate-source preservation rows" do
    branch_status =
      Timeline.preservation_status(%{
        id: :direct_branch_locked_downlink,
        type: :downlink,
        locked: true,
        metadata: %{timeline_id: :"timeline:direct_branch:locked_downlink"}
      })

    candidate_source = %{
      "candidate_refresh_request_source_report_summary" => %{},
      "source_timeline_preservation_status" => branch_status
    }

    summary = CandidateRefresh.timeline_preservation_replay_summary(candidate_source)

    assert summary["source"] ==
             "candidate_refresh.candidate_source.candidate_refresh_request.timeline_preservation"

    assert summary["source_artifact_count"] == 1
    assert summary["source_report_row_count"] == 1

    assert summary["source_report_paths"] == [
             "candidate_source.candidate_refresh_request.source_timeline_preservation_status.status"
           ]

    assert summary["source_summary_schema_contract_counts"] == %{
             "timeline_preservation_status.v1" => 1
           }

    assert summary["preservation_required_activity_ids"] == ["direct_branch_locked_downlink"]
    assert summary["preserve_activity_ids"] == ["direct_branch_locked_downlink"]

    assert summary["assumptions"]["replay_scope"] ==
             "timeline_preservation_candidate_source_review_provenance_only"
  end

  test "timeline preservation replay falls back when branch has no preservation rows" do
    provenance_status =
      Timeline.preservation_status(%{
        id: :provenance_locked_downlink,
        type: :downlink,
        locked: true,
        metadata: %{timeline_id: :"timeline:provenance:locked_downlink"}
      })

    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "candidate_source" => %{
        "candidate_refresh_request_source_report_summary" => %{},
        "source_command_window_report" => %{
          "schema_contract" => "command_window_report.v1",
          "rows" => []
        }
      },
      "source_timeline_preservation_status" => provenance_status
    }

    summary = CandidateRefresh.timeline_preservation_replay_summary(artifact)

    assert summary["source"] == "candidate_refresh.review_provenance.timeline_preservation"

    assert summary["source_report_paths"] == [
             "candidate_refresh.source_timeline_preservation_status.status"
           ]

    assert summary["preservation_required_activity_ids"] == ["provenance_locked_downlink"]

    assert summary["assumptions"]["replay_scope"] ==
             "timeline_preservation_review_provenance_only"
  end

  test "timeline preservation replay ignores unmarked nested candidate-source preservation rows" do
    unmarked_branch_status =
      Timeline.preservation_status(%{
        id: :unmarked_branch_locked_downlink,
        type: :downlink,
        locked: true,
        metadata: %{timeline_id: :"timeline:unmarked_branch:locked_downlink"}
      })

    provenance_status =
      Timeline.preservation_status(%{
        id: :marked_provenance_locked_downlink,
        type: :downlink,
        locked: true,
        metadata: %{timeline_id: :"timeline:marked_provenance:locked_downlink"}
      })

    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "candidate_source" => %{
        "source_timeline_preservation_status" => unmarked_branch_status
      },
      "source_timeline_preservation_status" => provenance_status
    }

    summary = CandidateRefresh.timeline_preservation_replay_summary(artifact)

    assert summary["source"] == "candidate_refresh.review_provenance.timeline_preservation"

    assert summary["source_report_paths"] == [
             "candidate_refresh.source_timeline_preservation_status.status"
           ]

    assert summary["preservation_required_activity_ids"] == [
             "marked_provenance_locked_downlink"
           ]

    refute "unmarked_branch_locked_downlink" in summary["preservation_required_activity_ids"]

    assert summary["assumptions"]["replay_scope"] ==
             "timeline_preservation_review_provenance_only"
  end

  test "timeline preservation replay treats unmarked direct candidate-source input as review provenance" do
    unmarked_status =
      Timeline.preservation_status(%{
        id: :unmarked_direct_locked_downlink,
        type: :downlink,
        locked: true,
        metadata: %{timeline_id: :"timeline:unmarked_direct:locked_downlink"}
      })

    candidate_source = %{
      "source_timeline_preservation_status" => unmarked_status
    }

    summary = CandidateRefresh.timeline_preservation_replay_summary(candidate_source)

    assert summary["source"] == "candidate_refresh.review_provenance.timeline_preservation"

    assert summary["source_report_paths"] == [
             "candidate_refresh.source_timeline_preservation_status.status"
           ]

    assert summary["preservation_required_activity_ids"] == [
             "unmarked_direct_locked_downlink"
           ]

    assert summary["assumptions"]["replay_scope"] ==
             "timeline_preservation_review_provenance_only"
  end

  test "timeline preservation replay prefers partial branch rows over provenance" do
    branch_status =
      Timeline.preservation_status(%{
        id: :partial_branch_locked_downlink,
        type: :downlink,
        locked: true,
        metadata: %{timeline_id: :"timeline:partial_branch:locked_downlink"}
      })

    provenance_report =
      Timeline.preservation_report(
        [
          %{
            id: :partial_provenance_locked_contact,
            type: :contact,
            locked: true,
            metadata: %{timeline_id: :"timeline:partial_provenance:locked_contact"}
          },
          %{
            id: :partial_provenance_executed_obs,
            type: :observe,
            status: :executed,
            metadata: %{timeline_id: :"timeline:partial_provenance:executed_obs"}
          }
        ],
        source: "partial_provenance_preservation_report"
      )

    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "candidate_source" => %{
        "candidate_refresh_request_source_report_summary" => %{},
        "source_timeline_preservation_status" => branch_status
      },
      "source_timeline_preservation_report" => provenance_report
    }

    summary = CandidateRefresh.timeline_preservation_replay_summary(artifact)

    assert summary["source"] ==
             "candidate_refresh.candidate_source.candidate_refresh_request.timeline_preservation"

    assert summary["source_report_row_count"] == 1
    assert summary["preservation_required_activity_ids"] == ["partial_branch_locked_downlink"]
    refute "partial_provenance_locked_contact" in summary["preservation_required_activity_ids"]
    refute "partial_provenance_executed_obs" in summary["preservation_required_activity_ids"]

    assert summary["assumptions"]["replay_scope"] ==
             "timeline_preservation_candidate_source_review_provenance_only"
  end
end
