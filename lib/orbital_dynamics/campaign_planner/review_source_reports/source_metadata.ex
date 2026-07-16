defmodule OrbitalDynamics.CampaignPlanner.ReviewSourceReports.SourceMetadata do
  @moduledoc false

  alias __MODULE__.TimelineFeedback

  def command_window_source_metadata(reports_with_sources, feedback_rows, opts) do
    callbacks = command_window_metadata_callbacks!(opts)
    {reports, source_paths} = reports_and_source_paths(reports_with_sources)

    feedback_source_metadata(
      "command_window_report.v1",
      reports,
      source_paths,
      report_row_count(reports),
      feedback_rows,
      callbacks
    )
  end

  def maneuver_review_source_metadata(
        reports_with_sources,
        feedback_rows,
        source_rows,
        extra_metadata,
        opts
      ) do
    callbacks = maneuver_review_metadata_callbacks!(opts)
    {reports, source_paths} = reports_and_source_paths(reports_with_sources)

    extra_metadata =
      %{
        "source_execution_uncertainty_declared_count" =>
          callbacks.execution_uncertainty_status_count.(source_rows, "declared"),
        "source_execution_uncertainty_missing_count" =>
          callbacks.execution_uncertainty_status_count.(source_rows, "missing")
      }
      |> Map.merge(extra_metadata || %{})

    feedback_source_metadata(
      "maneuver_review_report.v1",
      reports,
      source_paths,
      report_row_count(reports),
      feedback_rows,
      callbacks,
      include_trust_boundaries?: false,
      extra_metadata: extra_metadata
    )
  end

  def operational_timeline_source_metadata(reports_with_sources, feedback_rows, opts) do
    callbacks = operational_timeline_metadata_callbacks!(opts)
    {reports, source_paths} = reports_and_source_paths(reports_with_sources)

    feedback_source_metadata(
      "operational_timeline_report.v1",
      reports,
      source_paths,
      length(feedback_rows),
      feedback_rows,
      callbacks
    )
  end

  def timeline_feedback_source_metadata(reports_with_sources, opts) do
    TimelineFeedback.source_metadata(reports_with_sources, opts)
  end

  def timeline_feedback_report_row_count(report) do
    TimelineFeedback.report_row_count(report)
  end

  defp feedback_source_metadata(
         contract,
         reports,
         source_paths,
         source_report_row_count,
         feedback_rows,
         callbacks,
         opts \\ []
       ) do
    weighted_feedback_row_count = callbacks.weighted_feedback_row_count.(feedback_rows)
    feedback_weight_sources = callbacks.feedback_weight_sources.(feedback_rows)

    %{
      "source_report_contract" => contract,
      "source_report_count" => length(reports),
      "source_report_paths" => if(source_paths == [], do: nil, else: source_paths),
      "source_report_row_count" => source_report_row_count,
      "weighted_feedback_row_count" =>
        if(weighted_feedback_row_count > 0, do: weighted_feedback_row_count),
      "feedback_weight_sources" =>
        if(feedback_weight_sources == [], do: nil, else: feedback_weight_sources)
    }
    |> maybe_put_source_report_trust_boundaries(
      reports,
      Keyword.get(opts, :include_trust_boundaries?, true)
    )
    |> maybe_put_feedback_trust_boundaries(
      feedback_rows,
      callbacks,
      Keyword.get(opts, :include_trust_boundaries?, true)
    )
    |> Map.merge(Keyword.get(opts, :extra_metadata, %{}))
    |> compact_map()
  end

  defp command_window_metadata_callbacks!(opts) do
    %{
      weighted_feedback_row_count: Keyword.fetch!(opts, :weighted_feedback_row_count),
      feedback_weight_sources: Keyword.fetch!(opts, :feedback_weight_sources),
      feedback_trust_boundaries: Keyword.fetch!(opts, :feedback_trust_boundaries)
    }
  end

  defp maneuver_review_metadata_callbacks!(opts) do
    %{
      weighted_feedback_row_count: Keyword.fetch!(opts, :weighted_feedback_row_count),
      feedback_weight_sources: Keyword.fetch!(opts, :feedback_weight_sources),
      execution_uncertainty_status_count:
        Keyword.fetch!(opts, :execution_uncertainty_status_count)
    }
  end

  defp operational_timeline_metadata_callbacks!(opts) do
    %{
      weighted_feedback_row_count: Keyword.fetch!(opts, :weighted_feedback_row_count),
      feedback_weight_sources: Keyword.fetch!(opts, :feedback_weight_sources),
      feedback_trust_boundaries: Keyword.fetch!(opts, :feedback_trust_boundaries)
    }
  end

  defp reports_and_source_paths(reports_with_sources) do
    reports = Enum.map(reports_with_sources, fn {report, _source_path} -> report end)
    source_paths = Enum.map(reports_with_sources, fn {_report, source_path} -> source_path end)

    {reports, source_paths}
  end

  defp maybe_put_source_report_trust_boundaries(metadata, _reports, false), do: metadata

  defp maybe_put_source_report_trust_boundaries(metadata, reports, _include?) do
    trust_boundaries = report_trust_boundaries(reports)

    metadata
    |> Map.put(
      "trust_boundary_status",
      if(trust_boundaries in [nil, []], do: nil, else: "declared")
    )
    |> Map.put("trust_boundaries", trust_boundaries)
  end

  defp maybe_put_feedback_trust_boundaries(metadata, _feedback_rows, _callbacks, false),
    do: metadata

  defp maybe_put_feedback_trust_boundaries(metadata, feedback_rows, callbacks, _include?) do
    Map.put(
      metadata,
      "feedback_trust_boundaries",
      callbacks.feedback_trust_boundaries.(feedback_rows)
    )
  end

  defp report_trust_boundaries(reports) do
    reports
    |> Enum.flat_map(fn report ->
      [
        Map.get(report, "trust_boundary"),
        get_in(report, ["provenance", "trust_boundary"])
      ]
    end)
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.uniq()
    |> Enum.sort()
    |> case do
      [] -> nil
      boundaries -> boundaries
    end
  end

  defp report_row_count(reports) do
    reports
    |> Enum.flat_map(&(Map.get(&1, "rows", []) || []))
    |> length()
  end

  defp compact_map(map) do
    Map.reject(map, fn {_key, value} -> is_nil(value) end)
  end
end
