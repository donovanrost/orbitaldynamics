defmodule OrbitalDynamics.CandidateRefresh.SourceReports.ResourceProjectionReviewRowValues do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.ResourceProjectionReviewRowClassification
  alias OrbitalDynamics.CandidateRefresh.SourceReports.ResourceProjectionReviewRowEncoding

  def split_embedded_rows(rows) do
    ResourceProjectionReviewRowClassification.split_embedded_rows(rows, &stringify_keys/1)
  end

  def count_resource_projection_rows(rows, field) do
    rows
    |> Enum.map(&normalized_source_report_token(Map.get(&1, field)))
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.frequencies()
    |> case do
      counts when counts == %{} -> nil
      counts -> counts
    end
  end

  def stringify_keys(value), do: ResourceProjectionReviewRowEncoding.stringify_keys(value)

  defp normalized_source_report_token(value) do
    value
    |> ResourceProjectionReviewRowEncoding.encode_value()
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
