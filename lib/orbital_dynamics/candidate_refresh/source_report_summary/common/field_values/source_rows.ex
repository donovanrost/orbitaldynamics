defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common.FieldValues.SourceRows do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common.EncodedValue

  def values(report) do
    values(report, "rows")
  end

  def values(report, field) do
    report
    |> Map.get(field, [])
    |> Enum.map(&EncodedValue.stringify_keys/1)
  end
end
