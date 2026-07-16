defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.CandidateDiffRejection.CandidateDiffFields.RowIdentities do
  @moduledoc false

  alias __MODULE__.IdentityValues

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [count_source_report_values: 1]

  def fields(rows) do
    %{
      "candidate_diff_candidate_id_counts" => candidate_id_counts(rows),
      "candidate_diff_ground_station_counts" => ground_station_counts(rows)
    }
  end

  defp candidate_id_counts(rows) do
    rows
    |> Enum.map(&IdentityValues.candidate_id/1)
    |> count_source_report_values()
  end

  defp ground_station_counts(rows) do
    rows
    |> Enum.map(&IdentityValues.ground_station_id/1)
    |> count_source_report_values()
  end
end
