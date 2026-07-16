defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.StationCalendar do
  @moduledoc false

  alias __MODULE__.InputSummary

  def report_input_summary([]), do: nil

  def report_input_summary(sources), do: InputSummary.report_input_summary(sources)
end
