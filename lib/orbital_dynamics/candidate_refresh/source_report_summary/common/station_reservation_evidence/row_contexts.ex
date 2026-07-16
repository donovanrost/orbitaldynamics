defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common.StationReservationEvidence.RowContexts do
  @moduledoc false

  alias __MODULE__.Contexts
  alias __MODULE__.ValuePresence

  def has_any?(row, fields) do
    row
    |> Contexts.values()
    |> Enum.any?(fn context -> context_has_any?(context, fields) end)
  end

  defp context_has_any?(context, fields) do
    Enum.any?(fields, fn field ->
      context
      |> Map.get(field)
      |> ValuePresence.present?()
    end)
  end
end
