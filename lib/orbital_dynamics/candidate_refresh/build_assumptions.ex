defmodule OrbitalDynamics.CandidateRefresh.BuildAssumptions do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common.EncodedValue

  def build(refresh, result_set_assumptions) do
    %{
      "refresh_model" => "accepted_planning_state_to_sampled_windows_v1",
      "candidate_builder" => "windows_to_observe_and_downlink_candidates",
      "candidate_diff" => "candidate_id_set_diff_with_semantic_change_reasons",
      "freshness_model" => "accepted_snapshot_horizon_and_quality_freshness",
      "contact_filter" => "thin_ground_network_availability_filter",
      "contact_allocation" => "deterministic_station_contact_allocation",
      "resource_filter" => "resource_summary_availability_and_margin_filter",
      "candidate_limit" => "deterministic_score_order_budget_after_filters",
      "cadence_integration" => "artifact_only_no_api_or_database_writes",
      "model_assumptions" => Map.get(refresh, "model_assumptions", %{}),
      "constraints" => Map.get(refresh, "constraints", %{}),
      "scoring_policy" => Map.get(refresh, "scoring_policy", %{}),
      "candidate_limit_policy" => Map.get(refresh, "candidate_limit_policy", %{}),
      "propagator" => encoded_value(Map.get(result_set_assumptions, :propagator)),
      "propagator_opts" => encoded_value(Map.get(result_set_assumptions, :propagator_opts)),
      "outputs" => encoded_value(Map.get(result_set_assumptions, :outputs, []))
    }
  end

  defp encoded_value(value), do: EncodedValue.value_with_keyword_maps(value)
end
