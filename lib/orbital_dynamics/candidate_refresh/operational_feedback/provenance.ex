defmodule OrbitalDynamics.CandidateRefresh.OperationalFeedback.Provenance do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.CandidateDiffReport
  alias OrbitalDynamics.CandidateRefresh.OperationalFeedback
  alias OrbitalDynamics.CandidateRefresh.OperationalFeedback.Assembly
  alias OrbitalDynamics.CandidateRefresh.OperationalFeedback.Input
  alias OrbitalDynamics.CandidateRefresh.OperationalFeedback.RealizedActivitySourceRows
  alias OrbitalDynamics.CandidateRefresh.OperationalFeedback.ResultArtifactSources
  alias OrbitalDynamics.CandidateRefresh.OperationalFeedback.SourceDetails
  alias OrbitalDynamics.CandidateRefresh.OperationalFeedback.SourceReports
  alias OrbitalDynamics.CandidateRefresh.ResultArtifactTrustBoundary
  alias OrbitalDynamics.CandidateRefresh.ValueEncoding

  def build(refresh) do
    feedback = Assembly.build(refresh)
    invalid_sections = Input.invalid_sections(refresh)

    cond do
      Input.invalid?(refresh) ->
        %{
          "trust_boundary_status" => "missing",
          "input_keys" => ["invalid_operational_feedback_input"],
          "invalid_operational_feedback_input" => true,
          "invalid_operational_feedback_input_reason" => "operational_feedback_must_be_object",
          "source_path" => Input.source_path(refresh),
          "source_operational_feedback" => %{
            "invalid_feedback_shape" => ValueEncoding.encode_value(Input.raw(refresh))
          }
        }

      OperationalFeedback.data_keys(feedback) == [] and invalid_sections == [] ->
        nil

      true ->
        provenance =
          feedback
          |> Map.get("provenance", %{})
          |> case do
            provenance when is_map(provenance) -> provenance
            _provenance -> %{}
          end

        trust_boundary =
          Map.get(feedback, "trust_boundary") || Map.get(provenance, "trust_boundary")

        %{
          "trust_boundary_status" =>
            if(trust_boundary in [nil, ""], do: "missing", else: "declared"),
          "trust_boundary" => trust_boundary,
          "input_keys" => OperationalFeedback.data_keys(feedback),
          "source_path" => Input.source_path(refresh),
          "provenance" => provenance
        }
        |> OperationalFeedback.put_invalid_sections_provenance(invalid_sections)
        |> put_source_result_artifact_operational_feedback_provenance(refresh)
        |> put_source_operational_timeline_report_provenance(refresh)
        |> put_source_timeline_feedback_report_provenance(refresh)
        |> put_source_timeline_diff_report_provenance(refresh)
        |> put_source_command_window_report_provenance(refresh)
        |> put_source_maneuver_review_report_provenance(refresh)
        |> put_source_realized_activity_feedback_provenance(refresh)
        |> put_realized_activity_feedback_provenance(refresh)
        |> Enum.reject(fn {_key, value} -> value in [nil, %{}, []] end)
        |> Map.new()
    end
  end

  defp put_source_operational_timeline_report_provenance(provenance, refresh) do
    put_source_report_provenance(
      provenance,
      refresh,
      :source_operational_timeline_reports,
      &SourceDetails.operational_timeline_report_sources/2,
      &SourceDetails.operational_timeline_report_paths/2,
      &OperationalFeedback.put_operational_timeline_source_provenance/3
    )
  end

  defp put_source_result_artifact_operational_feedback_provenance(
         provenance,
         refresh
       ) do
    provenance
    |> OperationalFeedback.put_source_result_artifact_provenance(
      ResultArtifactSources.sources_for_refresh(
        refresh,
        &ResultArtifactTrustBoundary.boundary/1
      )
    )
  end

  defp put_source_timeline_feedback_report_provenance(provenance, refresh) do
    put_source_report_provenance(
      provenance,
      refresh,
      :source_timeline_feedback_reports,
      &SourceDetails.timeline_feedback_report_sources/2,
      &SourceDetails.timeline_feedback_report_paths/2,
      &OperationalFeedback.put_timeline_feedback_source_provenance/3
    )
  end

  defp put_source_timeline_diff_report_provenance(provenance, refresh) do
    put_source_report_provenance(
      provenance,
      refresh,
      :source_timeline_diff_reports,
      &SourceDetails.timeline_diff_report_sources/2,
      &SourceDetails.timeline_diff_report_paths/2,
      &OperationalFeedback.put_timeline_diff_source_provenance/3
    )
  end

  defp put_source_command_window_report_provenance(provenance, refresh) do
    put_source_report_provenance(
      provenance,
      refresh,
      :source_command_window_reports,
      &SourceDetails.command_window_report_sources/2,
      &SourceDetails.command_window_report_paths/2,
      &OperationalFeedback.put_command_window_source_provenance/3
    )
  end

  defp put_source_maneuver_review_report_provenance(provenance, refresh) do
    put_source_report_provenance(
      provenance,
      refresh,
      :source_maneuver_review_reports,
      &SourceDetails.maneuver_review_report_sources/2,
      &SourceDetails.maneuver_review_report_paths/2,
      &OperationalFeedback.put_maneuver_review_source_provenance/3
    )
  end

  defp put_realized_activity_feedback_provenance(provenance, refresh) do
    feedback =
      refresh
      |> Input.raw()
      |> ValueEncoding.stringify_keys()

    case Map.get(feedback, "realized_activities") do
      rows when is_list(rows) and rows != [] ->
        timeline_source =
          feedback
          |> OperationalFeedback.realized_activity_report(prior_candidate_activities(refresh))
          |> OperationalFeedback.realized_activity_source()

        provenance
        |> Map.put("derived_from_realized_activities", true)
        |> Map.put("source_realized_activity_count", length(rows))
        |> maybe_put(
          "source_weighted_feedback_row_count",
          Map.get(timeline_source, "weighted_feedback_row_count")
        )
        |> maybe_put(
          "feedback_weight_sources",
          Map.get(timeline_source, "feedback_weight_sources")
        )
        |> maybe_put(
          "feedback_trust_boundaries",
          Map.get(timeline_source, "feedback_trust_boundaries")
        )
        |> maybe_put(
          "source_realized_source_quality_counts",
          Map.get(timeline_source, "source_realized_source_quality_counts")
        )
        |> OperationalFeedback.put_timeline_feedback_source_identity(timeline_source)
        |> OperationalFeedback.put_timeline_feedback_source_counts(timeline_source)
        |> Map.update("input_keys", ["realized_activities"], fn keys ->
          keys
          |> Kernel.++(["realized_activities"])
          |> Enum.uniq()
          |> Enum.sort()
        end)

      _rows ->
        provenance
    end
  end

  defp put_source_realized_activity_feedback_provenance(provenance, refresh) do
    rows_with_sources =
      RealizedActivitySourceRows.rows_for_refresh(
        refresh,
        &ResultArtifactTrustBoundary.inherit/2,
        &ResultArtifactTrustBoundary.boundary/1
      )

    if rows_with_sources == [] do
      provenance
    else
      rows = Enum.map(rows_with_sources, fn {_path, row} -> row end)

      timeline_source =
        rows
        |> OperationalFeedback.realized_activity_report_for_rows(
          prior_candidate_activities(refresh)
        )
        |> OperationalFeedback.realized_activity_source()

      input_keys = Map.get(timeline_source, "input_keys", [])

      provenance
      |> Map.put("derived_from_source_realized_activities", true)
      |> Map.put(
        "source_realized_activity_paths",
        rows_with_sources
        |> Enum.map(fn {path, _row} -> path end)
        |> Enum.uniq()
        |> Enum.sort()
      )
      |> Map.put("source_realized_activity_count", length(rows_with_sources))
      |> OperationalFeedback.put_source_realized_activity_summary(rows)
      |> maybe_put(
        "source_weighted_feedback_row_count",
        Map.get(timeline_source, "weighted_feedback_row_count")
      )
      |> maybe_put(
        "feedback_weight_sources",
        Map.get(timeline_source, "feedback_weight_sources")
      )
      |> maybe_put(
        "feedback_trust_boundaries",
        Map.get(timeline_source, "feedback_trust_boundaries")
      )
      |> OperationalFeedback.put_timeline_feedback_source_identity(timeline_source)
      |> OperationalFeedback.put_timeline_feedback_source_counts(timeline_source)
      |> Map.update("input_keys", input_keys, fn keys ->
        keys
        |> Kernel.++(input_keys)
        |> Enum.uniq()
        |> Enum.sort()
      end)
    end
  end

  defp put_source_report_provenance(
         provenance,
         refresh,
         source_key,
         sources_fun,
         paths_fun,
         put_fun
       ) do
    source_reports_fun = &SourceReports.reports(&1, source_key)

    put_fun.(
      provenance,
      sources_fun.(refresh, source_reports_fun),
      paths_fun.(refresh, source_reports_fun)
    )
  end

  defp prior_candidate_activities(refresh) do
    CandidateDiffReport.valid_prior_candidate_activities(refresh)
  end

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)
end
