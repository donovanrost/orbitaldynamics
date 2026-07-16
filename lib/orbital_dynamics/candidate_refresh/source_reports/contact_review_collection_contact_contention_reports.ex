defmodule OrbitalDynamics.CandidateRefresh.SourceReports.ContactReviewCollectionContactContentionReports do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.ContactContention

  alias OrbitalDynamics.CandidateRefresh.SourceReports.ContactReviewCollectionContactContentionArtifactReports

  def contact_contention_reports(
        refresh,
        source_result_artifacts_fun,
        inherit_result_artifact_trust_boundary_fun
      ) do
    refresh
    |> direct_contact_contention_reports()
    |> Kernel.++(
      ContactReviewCollectionContactContentionArtifactReports.contact_contention_reports(
        refresh,
        source_result_artifacts_fun,
        inherit_result_artifact_trust_boundary_fun
      )
    )
    |> Enum.filter(fn {_path, report} -> ContactContention.report?(report) end)
    |> Enum.map(fn {path, report} ->
      {path, ContactReviewCollectionContactContentionArtifactReports.stringify_keys(report)}
    end)
  end

  defp direct_contact_contention_reports(refresh) do
    [
      {"accepted_planning_state.source_contact_contention_report",
       get_in(refresh, ["accepted_planning_state", "source_contact_contention_report"])},
      {"accepted_planning_state.contact_contention_report",
       get_in(refresh, ["accepted_planning_state", "contact_contention_report"])},
      {"mission_state.source_contact_contention_report",
       get_in(refresh, ["mission_state", "source_contact_contention_report"])},
      {"mission_state.contact_contention_report",
       get_in(refresh, ["mission_state", "contact_contention_report"])},
      {"source_contact_contention_report", Map.get(refresh, "source_contact_contention_report")},
      {"contact_contention_report", Map.get(refresh, "contact_contention_report")}
    ]
    |> Enum.flat_map(fn {path, report_or_reports} ->
      ContactContention.entries(path, report_or_reports)
    end)
  end
end
