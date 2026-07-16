defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ResourceProjection.PressureIdRouting.PressureRows do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common.EncodedValue
  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common.NormalizedToken
  alias __MODULE__.TypeValues

  def normalized_projected_resource_rows(report) do
    report
    |> Map.get("projected_resources", [])
    |> Enum.map(&EncodedValue.stringify_keys/1)
  end

  def pressure_types(row) do
    row |> Map.get("resource_pressure_types") |> TypeValues.normalized()
  end

  def pressure_status(row) do
    NormalizedToken.value(row["resource_pressure_status"])
  end
end
