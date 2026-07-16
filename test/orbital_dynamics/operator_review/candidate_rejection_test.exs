defmodule OrbitalDynamics.OperatorReview.CandidateRejectionTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.{OperatorReview, Schema}

  test "candidate rejection report source ids fall back through defaults" do
    assert %{"source_artifact_id" => "candidate-rejection:report"} =
             OperatorReview.from_candidate_rejection_report(%{
               id: :"candidate-rejection:report"
             })

    assert %{"source_artifact_id" => "candidate-rejection:source"} =
             OperatorReview.from_candidate_rejection_report(%{
               source: :"candidate-rejection:source"
             })

    assert %{"source_artifact_id" => "candidate_rejection_report"} =
             OperatorReview.from_candidate_rejection_report(%{})
  end

  test "builds candidate rejection review package from reviewable rejected candidates" do
    report =
      OrbitalDynamics.candidate_rejection_report(
        [
          %{
            id: :dl_reserved,
            type: :downlink,
            timeline_id: :candidate_timeline,
            ground_station_id: :dss_14,
            station_availability: "Reservation Hold",
            starts_at_s: 30.0,
            ends_at_s: 35.0,
            min_duration_s: 10.0,
            violated_constraint: :station_calendar,
            required_margin: 10.0,
            actual_margin: 5.0
          },
          %{id: :cmd_ready, type: :command, reviewable: false},
          %{
            id: :obs_blocked_by_policy,
            type: :observe,
            rejection_reasons: [:policy_blocked],
            reviewable: false
          }
        ],
        source: :candidate_refresh
      )

    package = OperatorReview.from_candidate_rejection_report(report)
    assert OrbitalDynamics.operator_review_package(report) == package

    assert %{
             "source_artifact_type" => "candidate_rejection_report.v1",
             "source_artifact_id" => "candidate_refresh",
             "review_count" => 1,
             "candidate_rejection_review_count" => 1,
             "rows" => [
               %{
                 "review_type" => "candidate_rejection_review",
                 "source" => "candidate_rejection_report.rows",
                 "subject_id" => "dl_reserved",
                 "candidate_id" => "dl_reserved",
                 "activity_id" => "dl_reserved",
                 "timeline_id" => "candidate_timeline",
                 "activity_type" => "downlink",
                 "required_operator_action" => "review_candidate_rejection",
                 "approval_status" => "operator_review_required",
                 "candidate_rejection_status" => "rejected",
                 "primary_rejection_reason" => "contact_too_short",
                 "candidate_rejection_reason_count" => 2,
                 "violated_constraint" => "station_calendar",
                 "required_margin" => 10.0,
                 "actual_margin" => 5.0,
                 "activity_context" => %{"ground_station_id" => "dss_14"},
                 "source_candidate_rejection" => %{"candidate_id" => "dl_reserved"}
               }
             ]
           } = package

    [row] = package["rows"]
    assert "contact_too_short" in row["candidate_rejection_reasons"]
    assert "station_reserved" in row["candidate_rejection_reasons"]

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)

    invalid_source_evidence =
      update_in(package, ["rows"], fn [row] ->
        [
          put_in(
            row,
            ["source_candidate_rejection", "candidate_id"],
            "candidate rejection with spaces"
          )
        ]
      end)

    assert {:error, report} = Schema.validate_artifact(invalid_source_evidence)

    assert Enum.any?(
             report["errors"],
             &(&1["path"] == "$.rows[0].source_candidate_rejection.candidate_id")
           )

    stale_source_evidence =
      put_in(
        package,
        ["rows", Access.at(0), "source_candidate_rejection", "primary_rejection_reason"],
        "station_reserved"
      )

    assert {:error, stale_source_report} = Schema.validate_artifact(stale_source_evidence)

    assert Enum.any?(
             stale_source_report["errors"],
             &(&1["path"] == "$.rows[0].primary_rejection_reason" and
                 &1["message"] ==
                   "must match source_candidate_rejection.primary_rejection_reason")
           )
  end
end
