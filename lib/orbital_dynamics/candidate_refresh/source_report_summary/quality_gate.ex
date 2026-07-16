defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.QualityGate do
  @moduledoc false

  alias __MODULE__.InputSummary

  def report_input_summary([]), do: nil

  defdelegate report_input_summary(sources), to: InputSummary
end
