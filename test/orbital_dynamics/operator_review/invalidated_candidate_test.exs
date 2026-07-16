defmodule OrbitalDynamics.OperatorReview.InvalidatedCandidateTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.{OperatorReview, Schema}

  test "invalidated candidate source ids fall back through defaults" do
    assert %{"source_artifact_id" => "invalidated:candidate"} =
             OperatorReview.from_invalidated_candidate(%{id: :"invalidated:candidate"})

    assert %{"source_artifact_id" => "invalidated:candidate:id"} =
             OperatorReview.from_invalidated_candidate(%{
               invalidated_candidate_id: :"invalidated:candidate:id"
             })

    assert %{"source_artifact_id" => "invalidated_candidate"} =
             OperatorReview.from_invalidated_candidate(%{})
  end

  test "builds standalone invalidated candidate review package" do
    candidate = %{
      "schema_contract" => "invalidated_candidate.v1",
      "id" => "old_refresh_observe",
      "type" => "observe",
      "scenario_id" => "leo_1",
      "target_id" => "target_a",
      "source_window_id" => "window:leo_1:target_visibility:target_a:old",
      "starts_at_s" => 90.0,
      "ends_at_s" => 150.0,
      "replacement_candidate_id" => "refresh_observe",
      "invalidated_reason" => "replaced_by_semantically_similar_candidate",
      "semantic_change_reasons" => ["starts_at_s_changed", "source_window_id_changed"]
    }

    package = OperatorReview.from_invalidated_candidate(candidate)
    assert OrbitalDynamics.operator_review_package(candidate) == package

    assert %{
             "source_artifact_type" => "invalidated_candidate.v1",
             "source_artifact_id" => "old_refresh_observe",
             "review_count" => 1,
             "candidate_diff_review_count" => 1,
             "rows" => [
               %{
                 "review_type" => "candidate_diff_review",
                 "source" => "invalidated_candidate",
                 "activity_id" => "old_refresh_observe",
                 "target_id" => "target_a",
                 "required_operator_action" => "review_candidate_diff",
                 "replacement_candidate_id" => "refresh_observe",
                 "source_candidate_diff" => %{"schema_contract" => "invalidated_candidate.v1"}
               }
             ]
           } = package

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)
  end
end
