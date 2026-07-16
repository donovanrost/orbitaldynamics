defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.CandidateDiffRejection.CandidateRejectionFields.RowValues.Rows do
  @moduledoc false

  alias __MODULE__.IdentityValues
  alias __MODULE__.RejectionReasons
  alias __MODULE__.TrustBoundaryValues
  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common.EncodedValue
  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common.NormalizedToken

  def rows(report) do
    report
    |> Map.get("rows", [])
    |> Enum.map(&EncodedValue.stringify_keys/1)
  end

  def rejection_reasons(row) do
    RejectionReasons.from_row(row)
  end

  def required_action(row) do
    row
    |> Map.get("required_operator_action")
    |> NormalizedToken.value()
  end

  def candidate_id(row) do
    IdentityValues.candidate_id(row)
  end

  def ground_station_id(row), do: IdentityValues.ground_station_id(row)

  def trust_boundary_values(row) do
    TrustBoundaryValues.from_row(row)
  end
end
