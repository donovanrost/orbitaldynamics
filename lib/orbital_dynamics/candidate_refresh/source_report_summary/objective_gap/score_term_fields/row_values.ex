defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ObjectiveGap.ScoreTermFields.RowValues do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common.EncodedValue

  alias __MODULE__.CountMapFields

  alias OrbitalDynamics.CandidateRefresh.SourceObjectives.ScoreTerm,
    as: ScoreTermSourceObjectives

  def rows(report) do
    report
    |> Map.get("rows", [])
    |> Enum.map(&EncodedValue.stringify_keys/1)
  end

  def trust_boundary(row) do
    ScoreTermSourceObjectives.trust_boundary(row)
  end

  def count_map_fields(reports) do
    reports
    |> Enum.map(&rows/1)
    |> CountMapFields.fields()
  end
end
