defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.LinkCapacity.DirectionFields.ThroughputMaps do
  @moduledoc false

  alias __MODULE__.ValueMaps

  def from_reports(reports) do
    ValueMaps.from_reports(reports)
  end

  def fields(%{} = values) do
    ValueMaps.fields(values)
  end
end
