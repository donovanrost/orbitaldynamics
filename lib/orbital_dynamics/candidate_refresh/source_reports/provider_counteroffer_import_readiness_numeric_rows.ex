defmodule OrbitalDynamics.CandidateRefresh.SourceReports.ProviderCounterofferImportReadinessNumericRows do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.ProviderCounterofferImportReadinessRowNormalization,
    as: RowNormalization

  @timing_shift_fields [
    "provider_counteroffer_start_delta_s",
    "provider_counteroffer_end_delta_s",
    "provider_counteroffer_duration_delta_s"
  ]

  def timing_shift_rows(rows) do
    Enum.filter(rows, fn row ->
      Enum.any?(@timing_shift_fields, fn field ->
        case numeric_value(Map.get(row, field)) do
          nil -> false
          value -> value != 0.0
        end
      end)
    end)
  end

  def numeric_value_count(rows, field) do
    rows
    |> numeric_values(field)
    |> length()
  end

  def numeric_value_sum(rows, field) do
    rows
    |> numeric_values(field)
    |> Enum.sum()
  end

  def numeric_value_min(rows, field) do
    rows
    |> numeric_values(field)
    |> Enum.min(fn -> nil end)
  end

  def numeric_value(value), do: RowNormalization.numeric_value(value)

  defp numeric_values(rows, field) do
    rows
    |> Enum.map(&(Map.get(&1, field) |> RowNormalization.numeric_value()))
    |> Enum.reject(&is_nil/1)
  end
end
