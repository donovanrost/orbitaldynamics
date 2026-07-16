defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineTransitionApplication.ReportShape.Counts.FirstCount do
  @moduledoc false

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [report_count: 1]

  def value(report, fields) do
    fields
    |> Enum.find_value(fn field ->
      case Map.get(report, field) do
        value when is_integer(value) -> report_count(value)
        value when is_float(value) -> report_count(value)
        value when is_binary(value) -> report_count(value)
        _value -> nil
      end
    end)
    |> Kernel.||(0)
  end
end
