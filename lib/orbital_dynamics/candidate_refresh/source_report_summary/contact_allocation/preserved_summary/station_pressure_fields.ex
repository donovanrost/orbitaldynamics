defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactAllocation.PreservedSummary.StationPressureFields do
  @moduledoc false

  alias __MODULE__.ContactIdFields
  alias __MODULE__.ReviewFields

  def fields(summary) do
    Map.merge(ReviewFields.fields(summary), ContactIdFields.fields(summary))
  end
end
