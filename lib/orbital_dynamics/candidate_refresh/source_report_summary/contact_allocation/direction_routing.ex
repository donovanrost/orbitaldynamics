defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactAllocation.DirectionRouting do
  @moduledoc false

  alias __MODULE__.InputFields
  alias __MODULE__.RouteMap

  def fields(reports) do
    reports
    |> InputFields.values()
    |> RouteMap.route_values()
  end

  def fields_from_summary(summary) when is_map(summary) do
    summary
    |> then(&InputFields.values([&1]))
    |> Enum.map(fn {field, derived_value} ->
      explicit_value = Map.get(summary, Atom.to_string(field))
      {field, if(is_map(explicit_value), do: explicit_value, else: derived_value)}
    end)
    |> RouteMap.route_values()
  end

  def fields_from_summary(_summary), do: nil
end
