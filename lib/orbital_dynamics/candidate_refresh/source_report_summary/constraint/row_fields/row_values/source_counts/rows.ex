defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.Constraint.RowFields.RowValues.SourceCounts.Rows do
  @moduledoc false

  alias __MODULE__.SourceObjectiveValues

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common.NormalizedToken

  def rows(report), do: Map.get(report, "rows", [])

  def downlink_gap?(row), do: SourceObjectiveValues.downlink_gap?(row)

  def resource_margin_gap?(row), do: SourceObjectiveValues.resource_margin_gap?(row)

  def token_value(row, field) do
    row
    |> Map.get(field)
    |> NormalizedToken.value()
  end

  def station_id(row), do: SourceObjectiveValues.station_id(row)

  def metric(row), do: SourceObjectiveValues.metric(row)

  def constraint_id(row), do: SourceObjectiveValues.constraint_id(row)

  def resource_id(row), do: SourceObjectiveValues.resource_id(row)

  def spacecraft_id(row), do: SourceObjectiveValues.spacecraft_id(row)

  def source_activity_ids(row), do: SourceObjectiveValues.source_activity_ids(row)
end
