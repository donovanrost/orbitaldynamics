defmodule OrbitalDynamics.CampaignPlanner.RepairCandidateRefreshAssumptionsSourceTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.CampaignPlanner.RepairSourceReports

  test "preserves the exact normalized CandidateRefresh assumptions map" do
    assumptions = %{
      model_assumptions: %{event_boundaries: "sampled_outputs_with_linear_interpolation"},
      constraints: %{avoid_eclipse: true},
      scoring_policy: %{target_value_weight: 2.0},
      propagator_opts: %{max_step_s: 10.0},
      outputs: ["trajectories", "access_windows"]
    }

    assert RepairSourceReports.candidate_refresh_assumptions(%{assumptions: assumptions}) == %{
             "model_assumptions" => %{
               "event_boundaries" => "sampled_outputs_with_linear_interpolation"
             },
             "constraints" => %{"avoid_eclipse" => true},
             "scoring_policy" => %{"target_value_weight" => 2.0},
             "propagator_opts" => %{"max_step_s" => 10.0},
             "outputs" => ["trajectories", "access_windows"]
           }
  end

  test "distinguishes an empty assumptions map from an absent source map" do
    assert RepairSourceReports.candidate_refresh_assumptions(%{"assumptions" => %{}}) == %{}
    assert RepairSourceReports.candidate_refresh_assumptions(%{}) == nil
    assert RepairSourceReports.candidate_refresh_assumptions(nil) == nil
  end
end
