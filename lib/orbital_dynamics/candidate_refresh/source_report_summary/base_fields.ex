defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.BaseFields do
  @moduledoc false

  alias __MODULE__.Counts
  alias __MODULE__.Paths

  def fields(source_reports) when is_map(source_reports) do
    source_reports
    |> base_fields()
    |> Map.merge(Counts.fields(source_reports))
    |> Map.merge(Paths.fields(source_reports))
  end

  defp base_fields(source_reports) do
    %{
      "model" => "artifact_only_candidate_refresh_source_report_summary",
      "source" => "candidate_refresh.source_report_provenance",
      "source_report_family_count" => map_size(source_reports),
      "source_report_families" => source_reports |> Map.keys() |> Enum.sort(),
      "source_reports" => non_empty_map(source_reports),
      "assumptions" => %{
        "execution_boundary" => "artifact_only_no_refresh_replay_mutation",
        "replay_scope" => "input_provenance_summary_only"
      }
    }
  end

  defp non_empty_map(map) when map_size(map) == 0, do: nil
  defp non_empty_map(map), do: map
end
