defmodule OrbitalDynamics.CampaignPlanner.TimelineSourceReports.ResultArtifacts do
  @moduledoc false

  @timeline_diff_report_keys ["source_timeline_diff_report", "timeline_diff_report"]
  @timeline_integrity_report_keys [
    "source_timeline_integrity_report",
    "timeline_integrity_report"
  ]

  @timeline_dependency_impact_summary_keys [
    "source_timeline_dependency_impact_summary",
    "timeline_dependency_impact_summary"
  ]

  @timeline_publication_summary_keys [
    "source_timeline_publication_summary",
    "timeline_publication_summary"
  ]

  @timeline_lifecycle_state_summary_keys [
    "source_timeline_lifecycle_state_summary",
    "timeline_lifecycle_state_summary"
  ]

  @timeline_activity_lifecycle_state_keys [
    "source_timeline_activity_lifecycle_state",
    "timeline_activity_lifecycle_state"
  ]

  @timeline_activity_precondition_summary_keys [
    "source_timeline_activity_precondition_summary",
    "timeline_activity_precondition_summary"
  ]

  @timeline_preservation_report_keys [
    "source_timeline_preservation_report",
    "timeline_preservation_report"
  ]

  @timeline_preservation_status_keys [
    "source_timeline_preservation_status",
    "timeline_preservation_status"
  ]

  @timeline_transition_application_report_keys [
    "source_timeline_transition_application_report",
    "timeline_transition_application_report"
  ]

  def timeline_diff_reports(container, opts) do
    result_artifact_embedded_reports(container, @timeline_diff_report_keys, opts)
  end

  def timeline_integrity_reports(container, opts) do
    result_artifact_typed_or_embedded_reports(
      container,
      "timeline_integrity_report.v1",
      @timeline_integrity_report_keys,
      opts
    )
  end

  def timeline_dependency_impact_summaries(container, opts) do
    result_artifact_typed_or_embedded_reports(
      container,
      "timeline_dependency_impact_summary.v1",
      @timeline_dependency_impact_summary_keys,
      opts
    )
  end

  def timeline_publication_summaries(container, opts) do
    result_artifact_typed_or_embedded_reports(
      container,
      "timeline_publication_summary.v1",
      @timeline_publication_summary_keys,
      opts
    )
  end

  def timeline_lifecycle_state_summaries(container, opts) do
    container
    |> result_artifact_typed_or_embedded_reports(
      "timeline_lifecycle_state_summary.v1",
      @timeline_lifecycle_state_summary_keys,
      opts,
      transform: &put_timeline_lifecycle_state_summary_trust_boundary/1
    )
  end

  def timeline_activity_lifecycle_states(container, opts) do
    result_artifact_typed_or_embedded_reports(
      container,
      "timeline_activity_lifecycle_state.v1",
      @timeline_activity_lifecycle_state_keys,
      opts,
      inherit_self_trust_boundary?: true
    )
  end

  def timeline_activity_precondition_summaries(container, opts) do
    result_artifact_typed_or_embedded_reports(
      container,
      "timeline_activity_precondition_summary.v1",
      @timeline_activity_precondition_summary_keys,
      opts,
      inherit_self_trust_boundary?: true
    )
  end

  def timeline_preservation_reports(container, opts) do
    result_artifact_typed_or_embedded_reports(
      container,
      "timeline_preservation_report.v1",
      @timeline_preservation_report_keys,
      opts,
      inherit_self_trust_boundary?: true
    )
  end

  def timeline_preservation_statuses(container, opts) do
    result_artifact_typed_or_embedded_reports(
      container,
      "timeline_preservation_status.v1",
      @timeline_preservation_status_keys,
      opts,
      inherit_self_trust_boundary?: true
    )
  end

  def timeline_transition_application_reports(container, opts) do
    result_artifact_embedded_reports(
      container,
      @timeline_transition_application_report_keys,
      opts,
      path_suffix: ".applications"
    )
  end

  defp result_artifact_typed_or_embedded_reports(container, contract, report_keys, opts) do
    result_artifact_typed_or_embedded_reports(container, contract, report_keys, opts, [])
  end

  defp result_artifact_typed_or_embedded_reports(container, contract, report_keys, opts, options) do
    callbacks = callbacks!(opts)
    transform = Keyword.get(options, :transform, & &1)
    inherit_self_trust_boundary? = Keyword.get(options, :inherit_self_trust_boundary?, false)

    container
    |> callbacks.result_artifacts_with_source.()
    |> Enum.flat_map(fn {artifact, source_path} ->
      if artifact["schema_contract"] == contract do
        artifact =
          if inherit_self_trust_boundary? do
            callbacks.put_inherited_result_artifact_trust_boundary.(artifact, artifact)
          else
            artifact
          end

        [{transform.(artifact), source_path}]
      else
        artifact
        |> embedded_report_entries(source_path, report_keys, callbacks)
        |> Enum.map(fn {report, path} -> {transform.(report), path} end)
      end
    end)
  end

  defp result_artifact_embedded_reports(container, report_keys, opts, options \\ []) do
    callbacks = callbacks!(opts)
    path_suffix = Keyword.get(options, :path_suffix, "")

    container
    |> callbacks.result_artifacts_with_source.()
    |> Enum.flat_map(fn {artifact, source_path} ->
      embedded_report_entries(artifact, source_path, report_keys, callbacks, path_suffix)
    end)
  end

  defp embedded_report_entries(artifact, source_path, report_keys, callbacks, path_suffix \\ "") do
    Enum.flat_map(report_keys, fn report_key ->
      callbacks.result_artifact_embedded_report_entries.(
        Map.get(artifact, report_key),
        artifact,
        "#{source_path}.#{report_key}#{path_suffix}"
      )
    end)
  end

  defp put_timeline_lifecycle_state_summary_trust_boundary(summary) do
    trust_boundary =
      Map.get(summary, "trust_boundary") ||
        get_in(summary, ["provenance", "trust_boundary"]) ||
        get_in(summary, ["metadata", "trust_boundary"])

    if trust_boundary in [nil, ""] do
      summary
    else
      Map.put(summary, "trust_boundary", trust_boundary)
    end
  end

  defp callbacks!(opts) do
    %{
      result_artifacts_with_source: Keyword.fetch!(opts, :result_artifacts_with_source),
      result_artifact_embedded_report_entries:
        Keyword.fetch!(opts, :result_artifact_embedded_report_entries),
      put_inherited_result_artifact_trust_boundary:
        Keyword.fetch!(opts, :put_inherited_result_artifact_trust_boundary)
    }
  end
end
