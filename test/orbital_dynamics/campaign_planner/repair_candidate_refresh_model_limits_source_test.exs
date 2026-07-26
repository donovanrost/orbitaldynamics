defmodule OrbitalDynamics.CampaignPlanner.RepairCandidateRefreshModelLimitsSourceTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.CampaignPlanner.RepairSourceReports

  test "preserves the exact CandidateRefresh model-limit list" do
    model_limits = OrbitalDynamics.CandidateRefresh.model_limits()

    assert RepairSourceReports.candidate_refresh_model_limits(%{model_limits: model_limits}) ==
             model_limits
  end

  test "keeps an absent or non-list model-limit value absent" do
    assert RepairSourceReports.candidate_refresh_model_limits(%{}) == nil
    assert RepairSourceReports.candidate_refresh_model_limits(%{"model_limits" => %{}}) == nil
    assert RepairSourceReports.candidate_refresh_model_limits(nil) == nil
  end
end
