defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.InputProvenance.Summary.Deduplication do
  @moduledoc false

  alias __MODULE__.{SourceReportFingerprints, SourceReportPaths}

  def deduplicate_shadowed_result_artifact_sources(sources, shadowed_report_keys \\ :all) do
    direct_fingerprints =
      sources
      |> Enum.filter(fn {path, report} ->
        SourceReportPaths.direct_source_report?(path) and
          SourceReportFingerprints.branch_local?(report)
      end)
      |> Enum.map(fn {_path, report} -> SourceReportFingerprints.fingerprint(report) end)
      |> MapSet.new()

    Enum.reject(sources, fn
      {path, report} when is_binary(path) ->
        SourceReportPaths.result_artifact_source_report?(path, shadowed_report_keys) and
          SourceReportFingerprints.branch_local?(report) and
          MapSet.member?(direct_fingerprints, SourceReportFingerprints.fingerprint(report))

      {_path, _report} ->
        false
    end)
  end
end
