defmodule OrbitalDynamics.CandidateRefresh.SourceReports.TimelineTransitionApplicationReviewImportReportCounts do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.TimelineTransitionApplicationReviewImportRows

  def fields(applications) do
    %{
      "selected_activity_count" => selected_activity_count(applications),
      "review_required_count" =>
        Enum.count(applications, &(&1["requires_operator_review"] == true)),
      "preserved_source_count" =>
        Enum.count(applications, &(&1["application_status"] == "source_preserved_pending_review")),
      "recorded_replacement_count" =>
        Enum.count(applications, &(&1["application_status"] == "replacement_recorded")),
      "withheld_review_count" =>
        Enum.count(applications, &(&1["application_status"] == "operator_review_required")),
      "duplicate_timeline_identity_count" =>
        Enum.count(
          applications,
          &TimelineTransitionApplicationReviewImportRows.duplicate_identity_row?/1
        ),
      "duplicate_source_timeline_identity_count" =>
        duplicate_identity_scope_count(applications, "source"),
      "duplicate_replacement_timeline_identity_count" =>
        duplicate_identity_scope_count(applications, "replacement"),
      "application_status_counts" => count_rows(applications, "application_status"),
      "transition_decision_counts" => count_rows(applications, "transition_decision"),
      "required_operator_action_counts" => count_rows(applications, "required_operator_action"),
      "duplicate_timeline_identity_scope_counts" =>
        count_rows(applications, "duplicate_timeline_identity_scope")
    }
  end

  defp selected_activity_count(applications) do
    Enum.count(
      applications,
      &(is_map(&1["selected_activity"]) or &1["selected_activity_source"] not in [nil, ""])
    )
  end

  defp duplicate_identity_scope_count(applications, scope) do
    Enum.count(
      applications,
      &TimelineTransitionApplicationReviewImportRows.duplicate_identity_scope?(&1, scope)
    )
  end

  defp count_rows(applications, field) do
    TimelineTransitionApplicationReviewImportRows.count_rows(applications, field)
  end
end
