defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineLifecycleState.RowFields.TransitionProvenance do
  @moduledoc false

  alias __MODULE__.Counts

  def fields(summaries) do
    %{
      "transition_application_provenance_count" => Counts.total(summaries),
      "transition_application_provenance_helper_counts" =>
        Counts.field_counts(summaries, "helper"),
      "transition_application_provenance_category_counts" =>
        Counts.field_counts(summaries, "transition_category"),
      "transition_application_provenance_operator_action_reason_counts" =>
        Counts.field_counts(summaries, "operator_action_reason")
    }
  end
end
