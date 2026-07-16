defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.ContactAllocation.SourceReportFields.Allocation.Report.Rows.RowValues.ContactMaps do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.ContactAllocation.SourceReportFields.Allocation.Report.Rows.RowValues.Normalization
  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common

  import Common, only: [sorted_string_values: 1]

  def map_value_lists(%{} = value_map) do
    value_map
    |> Enum.reduce(%{}, fn {key, values}, acc ->
      case sorted_string_values(List.wrap(values)) do
        [] -> acc
        values -> Map.put(acc, to_string(key), values)
      end
    end)
    |> non_empty_map()
  end

  def map_value_lists(_value), do: nil

  def id_map_counts(%{} = contact_ids_by_key) do
    contact_ids_by_key
    |> Enum.map(fn {key, contact_ids} ->
      {to_string(key), contact_ids |> List.wrap() |> sorted_string_values()}
    end)
    |> Enum.reject(fn {key, contact_ids} -> key in [nil, ""] or contact_ids in [nil, []] end)
    |> Map.new(fn {key, contact_ids} -> {key, length(contact_ids)} end)
    |> non_empty_map()
  end

  def id_map_counts(_contact_ids_by_key), do: nil

  def sorted_non_empty_values(values) do
    case sorted_string_values(values) do
      [] -> nil
      values -> values
    end
  end

  def grouped_contact_ids(pairs) do
    pairs
    |> Enum.reject(fn {key, contact_id} -> key in [nil, ""] or contact_id in [nil, ""] end)
    |> Enum.group_by(fn {key, _contact_id} -> key end, fn {_key, contact_id} -> contact_id end)
    |> Map.new(fn {key, contact_ids} -> {key, sorted_non_empty_values(contact_ids)} end)
    |> non_empty_map()
  end

  def grouped_contact_counts(pairs) do
    pairs
    |> Enum.reject(fn {key, contact_id} -> key in [nil, ""] or contact_id in [nil, ""] end)
    |> Enum.group_by(fn {key, _contact_id} -> key end, fn {_key, contact_id} -> contact_id end)
    |> Map.new(fn {key, contact_ids} ->
      {key, contact_ids |> sorted_string_values() |> length()}
    end)
    |> non_empty_map()
  end

  def non_empty_map(map), do: Normalization.non_empty_map(map)
end
