defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactAllocation.DirectionRouting do
  @moduledoc false

  alias __MODULE__.{Correlation, InputFields, RouteMap}

  def fields(reports) do
    reports
    |> InputFields.values()
    |> RouteMap.route_values()
  end

  def fields_from_summary(summary) when is_map(summary) do
    summary
    |> direction_fields_from_summary()
    |> Map.get("direction_routing")
  end

  def fields_from_summary(_summary), do: nil

  def direction_fields_from_summary(summary) when is_map(summary) do
    fields = compact_fields_from_summary(summary)
    direction_counts = fields |> Keyword.get(:direction_counts) |> Correlation.direction_counts()

    contact_ids_by_direction =
      Correlation.contact_ids_by_direction(
        direction_counts,
        Keyword.get(fields, :contact_ids_by_direction)
      )

    correlated_fields =
      fields
      |> Keyword.put(:direction_counts, direction_counts)
      |> Keyword.put(:contact_ids_by_direction, contact_ids_by_direction)

    %{
      "direction_counts" => non_empty_map(direction_counts),
      "contact_ids_by_direction" => contact_ids_by_direction,
      "direction_routing" => RouteMap.route_values(correlated_fields)
    }
  end

  def direction_fields_from_summary(_summary) do
    %{
      "direction_counts" => nil,
      "contact_ids_by_direction" => nil,
      "direction_routing" => nil
    }
  end

  defp compact_fields_from_summary(summary) do
    summary
    |> then(&InputFields.values([&1]))
    |> Enum.map(fn {field, derived_value} ->
      explicit_value = Map.get(summary, Atom.to_string(field))
      {field, if(is_map(explicit_value), do: explicit_value, else: derived_value)}
    end)
  end

  defp non_empty_map(map) when map_size(map) == 0, do: nil
  defp non_empty_map(map), do: map
end
