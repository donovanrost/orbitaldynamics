defmodule OrbitalDynamics.CandidateRefresh.SourceReports.ContactFilterReportRowCounts do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.ContactFilterReportValueEncoding

  def count_rows(rows, field) do
    rows
    |> Enum.map(&normalized_source_report_token(Map.get(&1, field)))
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.frequencies()
    |> case do
      counts when counts == %{} -> nil
      counts -> counts
    end
  end

  defp normalized_source_report_token(value) do
    value
    |> ContactFilterReportValueEncoding.encode_value()
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
