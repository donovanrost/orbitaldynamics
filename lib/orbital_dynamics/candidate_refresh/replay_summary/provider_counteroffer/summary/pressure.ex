defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.ProviderCounteroffer.Summary.Pressure do
  @moduledoc false

  def fields(counteroffer_fields, counts) do
    status_counts = Map.get(counteroffer_fields, "counteroffer_status_counts", %{})
    required_action_counts = Map.get(counteroffer_fields, "required_operator_action_counts", %{})

    review_status_counts =
      Map.get(counteroffer_fields, "counteroffer_review_status_counts", %{})

    negotiation_state_counts =
      Map.get(counteroffer_fields, "counteroffer_negotiation_state_counts", %{})

    import_readiness_status_counts =
      Map.get(counteroffer_fields, "import_readiness_status_counts", %{})

    import_classification_counts =
      Map.get(counteroffer_fields, "import_classification_counts", %{})

    import_status_counts =
      Map.get(counteroffer_fields, "provider_counteroffer_import_status_counts", %{})

    ids_by_import_status =
      Map.get(counteroffer_fields, "counteroffer_ids_by_import_status", %{})

    ids_by_required_import_action =
      Map.get(counteroffer_fields, "counteroffer_ids_by_required_import_action", %{})

    no_import_required_counteroffer_ids =
      Map.get(counteroffer_fields, "no_import_required_counteroffer_ids", [])

    plan_impact_status_counts = Map.get(counteroffer_fields, "plan_impact_status_counts", %{})

    affected_station_entry_ids =
      Map.get(counteroffer_fields, "affected_station_calendar_entry_ids", [])

    affected_provider_entry_ids = Map.get(counteroffer_fields, "affected_provider_entry_ids", [])
    impact_counteroffer_ids = Map.get(counteroffer_fields, "impact_counteroffer_ids", [])

    timing_shift_counteroffer_ids =
      Map.get(counteroffer_fields, "timing_shift_counteroffer_ids", [])

    cost_delta_counteroffer_ids = Map.get(counteroffer_fields, "cost_delta_counteroffer_ids", [])

    review_pressure =
      counts.review_summary_count > 0 or counts.reviewable_count > 0 or
        map_size(required_action_counts) > 0 or
        map_size(review_status_counts) > 0 or map_size(negotiation_state_counts) > 0

    cost_pressure =
      counts.cost_delta_count > 0 or length(cost_delta_counteroffer_ids) > 0

    timing_pressure =
      counts.timing_shift_count + counts.start_delta_count + counts.end_delta_count +
        counts.duration_delta_count > 0 or
        length(timing_shift_counteroffer_ids) > 0

    lock_pressure = counts.lock_deadline_count > 0 or is_number(counts.earliest_lock_deadline_s)

    import_readiness_pressure =
      counts.import_readiness_summary_count > 0 or
        map_size(import_readiness_status_counts) > 0 or
        map_size(import_classification_counts) > 0 or map_size(import_status_counts) > 0 or
        map_size(ids_by_import_status) > 0 or map_size(ids_by_required_import_action) > 0 or
        length(no_import_required_counteroffer_ids) > 0

    plan_impact_pressure =
      counts.plan_impact_summary_count > 0 or map_size(plan_impact_status_counts) > 0 or
        length(affected_station_entry_ids) > 0 or length(affected_provider_entry_ids) > 0 or
        length(impact_counteroffer_ids) > 0

    %{
      "branch_local_counteroffer_pressure" =>
        review_pressure or cost_pressure or timing_pressure or lock_pressure or
          import_readiness_pressure or plan_impact_pressure or map_size(status_counts) > 0,
      "branch_local_counteroffer_review_pressure" => review_pressure,
      "branch_local_counteroffer_cost_pressure" => cost_pressure,
      "branch_local_counteroffer_timing_pressure" => timing_pressure,
      "branch_local_counteroffer_lock_pressure" => lock_pressure,
      "branch_local_counteroffer_import_readiness_pressure" => import_readiness_pressure,
      "branch_local_plan_impact_pressure" => plan_impact_pressure
    }
  end
end
