defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactAllocation.DirectionRouting.InputFields.ValueMaps do
  @moduledoc false

  alias __MODULE__.{BaseFields, ProviderReservationFields}

  def values(reports) do
    BaseFields.values(reports) ++ ProviderReservationFields.values(reports)
  end
end
