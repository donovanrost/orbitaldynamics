defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactAllocation.DirectionRouting do
  @moduledoc false

  alias __MODULE__.{Correlation, InputFields, RouteMap}

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactAllocation.ReservationConflictCorrelation

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
    fields =
      summary
      |> ReservationConflictCorrelation.fields()
      |> compact_fields_from_summary()

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
      {field, compact_field_value(field, explicit_value, derived_value)}
    end)
  end

  defp compact_field_value(:reservation_conflict_direction_counts, explicit_value, _derived),
    do: explicit_value

  defp compact_field_value(_field, %{} = explicit_value, _derived), do: explicit_value
  defp compact_field_value(_field, _explicit_value, derived_value), do: derived_value

  defp non_empty_map(map) when map_size(map) == 0, do: nil
  defp non_empty_map(map), do: map
end
