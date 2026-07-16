defmodule OrbitalDynamics.CandidateRefresh.SourceReports.QualityGateStatusCollections do
  @moduledoc false

  def list_values(%{} = values_by_key, key) do
    values_by_key
    |> Map.get(key)
    |> list_value()
  end

  def list_values(_values_by_key, _key), do: []

  def row_count(%{} = row_ids_by_status, _fallback_count) do
    row_ids_by_status
    |> Map.values()
    |> Enum.flat_map(&list_value/1)
    |> length()
  end

  def row_count(_row_ids_by_status, fallback_count), do: fallback_count

  def status_count(row_ids_by_status, status) do
    row_ids_by_status
    |> list_values(status)
    |> length()
  end

  def status_counts(%{} = row_ids_by_status) do
    row_ids_by_status
    |> Enum.reduce(%{}, fn {status, ids}, acc ->
      count = ids |> list_value() |> length()

      if count > 0, do: Map.put(acc, status, count), else: acc
    end)
  end

  def status_counts(_row_ids_by_status), do: %{}

  def list_value(values) when is_list(values), do: values
  def list_value(_values), do: []
end
