defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ResourceFilter.CandidateGroups.RowValues do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceObjectives.ObjectiveSatisfaction,
    as: ObjectiveSatisfactionSourceObjectives

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common.EncodedValue
  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common.NormalizedToken
  alias __MODULE__.ResourceIds

  def rows(report) do
    report
    |> Map.get("suppressed_candidates", [])
    |> Enum.map(&EncodedValue.stringify_keys/1)
  end

  def suppressed_reason(row) do
    normalized_field(row, "suppressed_reason")
  end

  def blocking_dimension(row) do
    normalized_field(row, "resource_blocking_dimension")
  end

  def normalized_field(row, field) do
    row
    |> Map.get(field)
    |> NormalizedToken.value()
  end

  def resource_id(row) do
    ResourceIds.value(row)
  end

  def spacecraft_id(row) do
    ObjectiveSatisfactionSourceObjectives.spacecraft_id(row)
  end
end
