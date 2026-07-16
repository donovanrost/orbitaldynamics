defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineActivityState do
  @moduledoc false

  alias __MODULE__.ActivityStateMetrics
  alias __MODULE__.LifecycleSummary

  def report_input_summary([]), do: nil

  def report_input_summary(sources) do
    ActivityStateMetrics.input_summary(sources)
  end

  def lifecycle_state_input_summary([]), do: nil

  def lifecycle_state_input_summary(sources) do
    LifecycleSummary.input_summary(sources)
  end
end
