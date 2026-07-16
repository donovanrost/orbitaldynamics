defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ResourceProjection.PressureFields.CountFields.CountMaps.PressureCounts do
  @moduledoc false

  alias __MODULE__.StatusCounts
  alias __MODULE__.TypeCounts

  def status_counts(report) do
    StatusCounts.from_report(report)
  end

  def type_counts(report) do
    TypeCounts.from_report(report)
  end
end
