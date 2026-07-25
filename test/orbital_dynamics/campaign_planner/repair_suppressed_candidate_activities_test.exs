defmodule OrbitalDynamics.CampaignPlanner.RepairSuppressedCandidateActivitiesTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.CampaignPlanner.RepairCandidateInputs

  test "preserves exact suppressed candidates in source order with string keys" do
    contact_candidate = %{
      id: "contact_suppressed",
      score: 10.0,
      score_terms: %{contact_value: 10.0}
    }

    allocation_candidate = %{
      "id" => "allocation_suppressed",
      "score" => 9.0,
      "score_terms" => %{"contact_value" => 9.0}
    }

    budget_candidate = %{
      id: "budget_suppressed",
      score: 8.0,
      score_terms: %{contact_value: 8.0}
    }

    resource_candidate = %{
      "id" => "resource_suppressed",
      "score" => 7.0,
      "score_terms" => %{"contact_value" => 7.0}
    }

    eligible_candidate = %{"id" => "eligible", "score" => 6.0, "score_terms" => %{}}

    candidate_refresh = %{
      "candidate_activities" => [
        contact_candidate,
        :invalid_candidate,
        allocation_candidate,
        budget_candidate,
        eligible_candidate,
        resource_candidate
      ],
      "contact_filter_report" => %{
        "suppressed_candidates" => [%{"contact_id" => "contact_suppressed"}]
      },
      "contact_allocation_report" => %{
        "rows" => [
          %{
            "contact_id" => "allocation_suppressed",
            "allocation_status" => "deferred"
          }
        ]
      },
      "refresh_budget_report" => %{
        "dropped_candidate_ids" => ["budget_suppressed"]
      },
      "resource_filter_report" => %{
        "suppressed_candidates" => [%{"activity_id" => "resource_suppressed"}]
      }
    }

    assert RepairCandidateInputs.suppressed_candidate_activities(candidate_refresh) == [
             %{
               "id" => "contact_suppressed",
               "score" => 10.0,
               "score_terms" => %{"contact_value" => 10.0}
             },
             allocation_candidate,
             %{
               "id" => "budget_suppressed",
               "score" => 8.0,
               "score_terms" => %{"contact_value" => 8.0}
             },
             resource_candidate
           ]
  end

  test "omits suppressed candidates without a CandidateRefresh candidate collection" do
    assert RepairCandidateInputs.suppressed_candidate_activities(nil) == []
    assert RepairCandidateInputs.suppressed_candidate_activities(%{}) == []
  end
end
