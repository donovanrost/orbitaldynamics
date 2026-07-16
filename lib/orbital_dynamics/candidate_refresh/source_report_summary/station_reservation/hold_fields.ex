defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.StationReservation.HoldFields do
  @moduledoc false

  alias __MODULE__.CountStatusFields
  alias __MODULE__.HoldIds
  alias __MODULE__.ImportReadiness

  def fields(reports) do
    CountStatusFields.fields(reports)
    |> Map.merge(HoldIds.fields(reports))
    |> Map.merge(ImportReadiness.fields(reports))
  end
end
