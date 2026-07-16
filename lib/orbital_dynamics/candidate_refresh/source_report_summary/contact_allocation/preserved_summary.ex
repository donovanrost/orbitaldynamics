defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactAllocation.PreservedSummary do
  @moduledoc false

  alias __MODULE__.BaseFields
  alias __MODULE__.CapacityPackFields
  alias __MODULE__.ReservationConflictFields
  alias __MODULE__.StationPressureFields
  alias __MODULE__.StationReservationFields

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [compact_map: 1]

  def report_from_summary(%{} = summary) do
    summary
    |> BaseFields.fields()
    |> Map.merge(CapacityPackFields.fields(summary))
    |> Map.merge(ReservationConflictFields.fields(summary))
    |> Map.merge(StationReservationFields.fields(summary))
    |> Map.merge(StationPressureFields.fields(summary))
    |> compact_map()
  end
end
