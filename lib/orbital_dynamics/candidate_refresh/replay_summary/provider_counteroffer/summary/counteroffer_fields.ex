defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.ProviderCounteroffer.Summary.CounterofferFields do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.ValueEncoding

  def fields(counteroffer_summary) do
    %{
      "counteroffer_cost_delta_total" =>
        numeric_value(Map.get(counteroffer_summary, "counteroffer_cost_delta_total")) || 0.0,
      "earliest_counteroffer_lock_deadline_s" =>
        numeric_value(Map.get(counteroffer_summary, "earliest_counteroffer_lock_deadline_s")),
      "counteroffer_status_counts" =>
        Map.get(counteroffer_summary, "counteroffer_status_counts", %{}),
      "required_operator_action_counts" =>
        Map.get(counteroffer_summary, "required_operator_action_counts", %{}),
      "counteroffer_review_status_counts" =>
        Map.get(counteroffer_summary, "counteroffer_review_status_counts", %{}),
      "counteroffer_negotiation_state_counts" =>
        Map.get(counteroffer_summary, "counteroffer_negotiation_state_counts", %{}),
      "import_readiness_status_counts" =>
        Map.get(counteroffer_summary, "import_readiness_status_counts", %{}),
      "import_classification_counts" =>
        Map.get(counteroffer_summary, "import_classification_counts", %{}),
      "provider_counteroffer_import_status_counts" =>
        Map.get(counteroffer_summary, "provider_counteroffer_import_status_counts", %{}),
      "counteroffer_lock_deadline_status_counts" =>
        Map.get(counteroffer_summary, "counteroffer_lock_deadline_status_counts", %{}),
      "counteroffer_ids_by_import_status" =>
        Map.get(counteroffer_summary, "counteroffer_ids_by_import_status", %{}),
      "counteroffer_ids_by_required_import_action" =>
        Map.get(counteroffer_summary, "counteroffer_ids_by_required_import_action", %{}),
      "counteroffer_ids_by_lock_deadline_status" =>
        Map.get(counteroffer_summary, "counteroffer_ids_by_lock_deadline_status", %{}),
      "review_counteroffer_ids" => Map.get(counteroffer_summary, "review_counteroffer_ids", []),
      "no_import_required_counteroffer_ids" =>
        Map.get(counteroffer_summary, "no_import_required_counteroffer_ids", []),
      "plan_impact_status_counts" =>
        Map.get(counteroffer_summary, "plan_impact_status_counts", %{}),
      "affected_station_calendar_entry_ids" =>
        Map.get(counteroffer_summary, "affected_station_calendar_entry_ids", []),
      "affected_provider_entry_ids" =>
        Map.get(counteroffer_summary, "affected_provider_entry_ids", []),
      "impact_counteroffer_ids" => Map.get(counteroffer_summary, "impact_counteroffer_ids", []),
      "timing_shift_counteroffer_ids" =>
        Map.get(counteroffer_summary, "timing_shift_counteroffer_ids", []),
      "cost_delta_counteroffer_ids" =>
        Map.get(counteroffer_summary, "cost_delta_counteroffer_ids", [])
    }
  end

  defp numeric_value(value), do: ValueEncoding.numeric_value(value)
end
