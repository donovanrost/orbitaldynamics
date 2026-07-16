defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.CandidateDiffRejection.CandidateRejectionFields.RowValues do
  @moduledoc false

  alias __MODULE__.CountValues
  alias __MODULE__.RejectionActionCounts
  alias __MODULE__.Rows

  def trust_boundaries(reports) do
    Enum.flat_map(reports, fn report ->
      report
      |> Map.get("rows", [])
      |> Enum.flat_map(&Rows.trust_boundary_values/1)
    end)
  end

  def rejection_reason_counts(report) do
    RejectionActionCounts.rejection_reason_counts(report)
  end

  def required_action_counts(report) do
    RejectionActionCounts.required_action_counts(report)
  end

  def candidate_id_counts(report) do
    report
    |> rows()
    |> Enum.map(&Rows.candidate_id/1)
    |> CountValues.count()
  end

  def ground_station_counts(report) do
    report
    |> rows()
    |> Enum.map(&Rows.ground_station_id/1)
    |> CountValues.count()
  end

  defp rows(report), do: Rows.rows(report)
end
