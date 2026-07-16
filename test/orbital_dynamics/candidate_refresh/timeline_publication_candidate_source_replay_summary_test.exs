defmodule OrbitalDynamics.CandidateRefresh.TimelinePublicationCandidateSourceReplaySummaryTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.CandidateRefresh

  test "timeline publication replay reads strategy branch candidate-source summary metadata" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "candidate_source" => %{
        "candidate_refresh_request_source_report_summary" => %{
          "source_reports" => %{
            "timeline_publication_summary" => %{
              "contract" => "timeline_publication_summary.v1",
              "count" => 1,
              "row_count" => 1,
              "paths" => [
                "candidate_source.candidate_refresh_request.source_timeline_publication_summary"
              ],
              "publication_status_counts" => %{"review_required" => 1},
              "downstream_invalidation_status_counts" => %{"clear" => 1},
              "dependency_impact_status_counts" => %{"review_required" => 1},
              "publication_ids" => ["timeline_publication:branch"],
              "source_artifact_ids" => ["timeline:branch_plan"],
              "dependency_impact_row_count" => 1,
              "impacted_dependency_activity_ids" => ["branch_dependency"],
              "timeline_diff_review_required_count" => 1,
              "review_timeline_ids" => ["timeline:branch_review"],
              "trust_boundary_status" => "declared",
              "trust_boundaries" => ["branch_publication"]
            }
          }
        }
      },
      "provenance" => %{
        "source_reports" => %{
          "timeline_publication_summary" => %{
            "contract" => "timeline_publication_summary.v1",
            "count" => 9,
            "row_count" => 9,
            "publication_ids" => ["timeline_publication:stale"]
          }
        }
      }
    }

    summary = CandidateRefresh.timeline_publication_replay_summary(artifact)

    assert summary["source"] ==
             "candidate_refresh.candidate_source.candidate_refresh_request_source_report_summary.timeline_publication_summary"

    assert summary["source_report_count"] == 1
    assert summary["source_report_row_count"] == 1

    assert summary["source_report_paths"] == [
             "candidate_source.candidate_refresh_request.source_timeline_publication_summary"
           ]

    assert summary["publication_ids"] == ["timeline_publication:branch"]
    assert summary["source_artifact_ids"] == ["timeline:branch_plan"]
    assert summary["downstream_invalidation_status_counts"] == %{"clear" => 1}
    assert summary["dependency_impact_row_count"] == 1
    assert summary["impacted_dependency_activity_ids"] == ["branch_dependency"]
    assert summary["timeline_diff_review_required_count"] == 1
    assert summary["review_timeline_ids"] == ["timeline:branch_review"]
    assert summary["trust_boundaries"] == ["branch_publication"]
    assert summary["branch_local_timeline_publication_pressure"]
    assert summary["branch_local_timeline_publication_dependency_pressure"]
    assert summary["branch_local_timeline_publication_review_pressure"]

    assert summary["assumptions"]["replay_scope"] ==
             "timeline_publication_candidate_source_report_summary_only"
  end
end
