defmodule OrbitalDynamics.CandidateRefresh.SourceReports.TimelineDependencyImpactRowValues do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.TimelineDependencyImpactRowEncoding

  def summary_values(%{} = source, field) do
    case Map.get(source, field) do
      values when is_list(values) -> values
      value when value in [nil, ""] -> []
      value -> [value]
    end
  end

  def row_scope(row) do
    (dependency_impact_row_alias(row, "scope") || Map.get(row, "scope"))
    |> normalized_timeline_diff_token()
  end

  def stringify_keys(value), do: TimelineDependencyImpactRowEncoding.stringify_keys(value)

  defp dependency_impact_row_alias(row, "scope"), do: row["dependency_impact_scope"]
  defp dependency_impact_row_alias(_row, _field), do: nil

  defp normalized_timeline_diff_token(value) do
    value = TimelineDependencyImpactRowEncoding.encode_value(value)

    value
    |> case do
      nil ->
        nil

      value ->
        value
        |> String.trim()
        |> String.downcase()
        |> String.replace(~r/[\s-]+/, "_")
        |> String.trim("_")
    end
  end
end
