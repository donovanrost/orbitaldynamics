defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineActivityState.LifecycleSummary.TransitionCounts do
  @moduledoc false

  alias __MODULE__.CountMaps
  alias __MODULE__.ProtectionCounts

  def fields(states) do
    %{
      "transition_decision_counts" => CountMaps.field(states, "transition_decision"),
      "status_transition_decision_counts" =>
        CountMaps.field(states, "status_transition_decision"),
      "approval_transition_decision_counts" =>
        CountMaps.field(states, "approval_transition_decision"),
      "status_transition_category_counts" =>
        CountMaps.nested(states, [
          "status_transition",
          "transition_category"
        ]),
      "approval_transition_category_counts" =>
        CountMaps.nested(states, [
          "approval_transition",
          "transition_category"
        ])
    }
    |> Map.merge(ProtectionCounts.fields(states))
  end
end
