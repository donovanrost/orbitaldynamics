defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.TimelineTransitionApplication.Summary.Pressure do
  @moduledoc false

  def fields(transition_fields, counts) do
    application_status_counts = Map.get(transition_fields, "application_status_counts", %{})
    transition_decision_counts = Map.get(transition_fields, "transition_decision_counts", %{})
    selected_activity_id_counts = Map.get(transition_fields, "selected_activity_id_counts", %{})
    review_activity_id_counts = Map.get(transition_fields, "review_activity_id_counts", %{})

    selected_integrity_issue_type_counts =
      Map.get(transition_fields, "selected_timeline_integrity_issue_type_counts", %{})

    required_action_counts =
      Map.get(transition_fields, "required_operator_action_counts", %{})

    duplicate_scope_counts =
      Map.get(transition_fields, "duplicate_timeline_identity_scope_counts", %{})

    review_action_count =
      required_action_counts
      |> Map.delete("none")
      |> map_size()

    selected_activity_pressure =
      counts.selected_activity_count > 0 or map_size(selected_activity_id_counts) > 0

    selected_integrity_pressure =
      counts.selected_integrity_review_count + counts.selected_integrity_issue_count > 0 or
        map_size(selected_integrity_issue_type_counts) > 0

    review_required_pressure =
      counts.review_required_count + counts.withheld_review_count > 0 or
        review_action_count > 0 or
        map_size(review_activity_id_counts) > 0 or selected_integrity_pressure

    preserved_transition_pressure =
      counts.preserved_source_count + counts.recorded_replacement_count > 0

    duplicate_identity_pressure =
      counts.duplicate_count + counts.duplicate_source_count + counts.duplicate_replacement_count >
        0 or map_size(duplicate_scope_counts) > 0

    application_evidence_pressure =
      counts.application_count > 0 or map_size(application_status_counts) > 0 or
        map_size(transition_decision_counts) > 0

    %{
      "branch_local_timeline_transition_application_pressure" =>
        application_evidence_pressure or selected_activity_pressure or
          review_required_pressure or preserved_transition_pressure or duplicate_identity_pressure,
      "branch_local_selected_activity_pressure" => selected_activity_pressure,
      "branch_local_selected_integrity_pressure" => selected_integrity_pressure,
      "branch_local_review_required_pressure" => review_required_pressure,
      "branch_local_preserved_transition_pressure" => preserved_transition_pressure,
      "branch_local_duplicate_identity_pressure" => duplicate_identity_pressure,
      "branch_local_operator_review_pressure" => review_action_count > 0
    }
  end
end
