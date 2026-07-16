defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.OperationalReadiness.GateStatus.CountFields.GateCounts do
  @moduledoc false

  alias __MODULE__.MapFields
  alias __MODULE__.NumericFields

  def numeric_fields(reports) do
    NumericFields.fields(reports)
  end

  def status_map_fields(reports) do
    MapFields.fields(reports)
  end
end
