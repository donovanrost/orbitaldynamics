defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.CandidateDiffRejection.CandidateRejectionFields.RowCountFields do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.CandidateDiffRejection.CandidateRejectionFields.RowValues

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [merge_count_maps: 1]

  def fields(reports) do
    %{}
    |> Map.merge(reason_fields(reports))
    |> Map.merge(identity_fields(reports))
  end

  defp reason_fields(reports) do
    %{
      "rejection_reason_counts" => count_map(reports, &RowValues.rejection_reason_counts/1),
      "required_operator_action_counts" => count_map(reports, &RowValues.required_action_counts/1)
    }
  end

  defp identity_fields(reports) do
    %{
      "candidate_rejection_candidate_id_counts" =>
        count_map(reports, &RowValues.candidate_id_counts/1),
      "candidate_rejection_ground_station_counts" =>
        count_map(reports, &RowValues.ground_station_counts/1)
    }
  end

  defp count_map(reports, extractor) do
    reports
    |> Enum.map(extractor)
    |> merge_count_maps()
  end
end
