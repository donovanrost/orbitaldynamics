defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactIntent.CompactSummary.SummaryNormalization do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common.EncodedValue
  alias __MODULE__.RowSummary

  def normalize(%{} = summary) do
    summary
    |> EncodedValue.stringify_keys()
    |> normalize_row_summary()
  end

  def normalize(summary), do: summary

  defp normalize_row_summary(summary) do
    case RowSummary.from_summary(summary) do
      nil ->
        summary

      row_summary ->
        row_summary
    end
  end
end
