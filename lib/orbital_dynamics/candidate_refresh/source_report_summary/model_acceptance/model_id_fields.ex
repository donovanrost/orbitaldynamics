defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ModelAcceptance.ModelIdFields do
  @moduledoc false

  alias __MODULE__.GroupedIds

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [
      merge_string_list_maps: 1
    ]

  def fields(reports) do
    %{
      "model_ids_by_status" =>
        reports
        |> Enum.map(&GroupedIds.by_status/1)
        |> merge_string_list_maps(),
      "model_ids_by_validation_level" =>
        reports
        |> Enum.map(&GroupedIds.by_validation_level/1)
        |> merge_string_list_maps(),
      "model_ids_by_intended_use" =>
        reports
        |> Enum.map(&GroupedIds.by_intended_use/1)
        |> merge_string_list_maps()
    }
  end
end
