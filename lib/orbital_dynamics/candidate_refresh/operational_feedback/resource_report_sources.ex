defmodule OrbitalDynamics.CandidateRefresh.OperationalFeedback.ResourceReportSources do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.OperationalFeedback
  alias OrbitalDynamics.CandidateRefresh.OperationalFeedback.RowValues
  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary

  def resource_projection_feedback(reports) when is_list(reports) do
    reports
    |> Enum.reduce(%{}, fn {_path, report}, feedback ->
      derived_feedback =
        report
        |> Map.get("projected_resources", [])
        |> Enum.reduce(%{}, fn row, feedback ->
          OperationalFeedback.merge(
            feedback,
            OperationalFeedback.resource_projection_row_feedback(
              row,
              row
              |> RowValues.stringify_keys_with_keyword_maps()
              |> SourceReportSummary.ResourceProjection.resource_projection_spacecraft_id()
            )
          )
        end)
        |> normalized_feedback()

      OperationalFeedback.merge(feedback, derived_feedback)
    end)
    |> put_single_trust_boundary(
      reports,
      &SourceReportSummary.ResourceProjection.source_resource_projection_report_trust_boundaries/1
    )
    |> OperationalFeedback.compact()
  end

  def resource_projection_feedback(_reports), do: %{}

  def resource_filter_feedback(reports) when is_list(reports) do
    reports
    |> Enum.reduce(%{}, fn {_path, report}, feedback ->
      derived_feedback =
        report
        |> Map.get("suppressed_candidates", [])
        |> Enum.reduce(%{}, fn row, feedback ->
          OperationalFeedback.merge(
            feedback,
            OperationalFeedback.resource_filter_row_feedback(row)
          )
        end)
        |> normalized_feedback()

      OperationalFeedback.merge(feedback, derived_feedback)
    end)
    |> put_single_trust_boundary(
      reports,
      &SourceReportSummary.ResourceFilter.source_resource_filter_report_trust_boundaries/1
    )
    |> OperationalFeedback.compact()
  end

  def resource_filter_feedback(_reports), do: %{}

  def link_capacity_feedback(reports) when is_list(reports) do
    reports
    |> Enum.reduce(%{}, fn {_path, report}, feedback ->
      derived_feedback =
        report
        |> OperationalFeedback.link_capacity_feedback_rows()
        |> Enum.reduce(%{}, fn row, feedback ->
          OperationalFeedback.merge(
            feedback,
            OperationalFeedback.link_capacity_row_feedback(
              row,
              OperationalFeedback.link_capacity_station_id(row)
            )
          )
        end)
        |> normalized_feedback()

      OperationalFeedback.merge(feedback, derived_feedback)
    end)
    |> put_single_trust_boundary(
      reports,
      &SourceReportSummary.LinkCapacity.source_link_capacity_report_trust_boundaries/1
    )
    |> OperationalFeedback.compact()
  end

  def link_capacity_feedback(_reports), do: %{}

  defp normalized_feedback(feedback) do
    feedback
    |> OperationalFeedback.normalize_explicit()
    |> Map.drop(["provenance", "trust_boundary"])
  end

  defp put_single_trust_boundary(feedback, reports, trust_boundaries_fun) do
    trust_boundaries =
      reports
      |> Enum.flat_map(fn {_path, report} -> trust_boundaries_fun.(report) end)
      |> Enum.uniq()
      |> Enum.sort()

    case trust_boundaries do
      [trust_boundary] -> Map.put_new(feedback, "trust_boundary", trust_boundary)
      _trust_boundaries -> feedback
    end
  end
end
