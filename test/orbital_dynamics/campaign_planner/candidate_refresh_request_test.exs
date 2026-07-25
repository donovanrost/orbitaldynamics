defmodule OrbitalDynamics.CampaignPlanner.CandidateRefreshRequestTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.CampaignPlanner.CandidateRefreshRequest

  test "builds deterministic planner-generated refresh run IDs" do
    generated_at = ~U[2026-05-14 00:00:00Z]

    assert CandidateRefreshRequest.run_id("branch_refresh_derived", generated_at) ==
             "branch_refresh_derived-1778716800000000"

    assert CandidateRefreshRequest.run_id(
             "branch_refresh_derived",
             DateTime.add(generated_at, 1, :second)
           ) == "branch_refresh_derived-1778716801000000"

    assert CandidateRefreshRequest.deterministic_run_opts(
             [max_concurrency: 2, git_revision: "checkout-revision"],
             "branch_refresh_derived",
             generated_at
           ) == [
             git_revision: nil,
             run_id: "branch_refresh_derived-1778716800000000",
             max_concurrency: 2
           ]
  end
end
