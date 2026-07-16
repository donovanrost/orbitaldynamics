defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineActivityState.LifecycleSummary.MetricFields.InvalidActivityFields do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineActivityState.LifecycleStateMetrics.InvalidInputs

  def fields(states) do
    %{
      "invalid_activity_input_count" =>
        states
        |> Enum.map(&InvalidInputs.count/1)
        |> Enum.sum(),
      "invalid_activity_input_reason_counts" => InvalidInputs.reason_counts(states),
      "invalid_activity_input_reasons" => InvalidInputs.reasons(states)
    }
  end
end
