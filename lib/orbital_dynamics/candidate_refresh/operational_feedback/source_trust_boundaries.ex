defmodule OrbitalDynamics.CandidateRefresh.OperationalFeedback.SourceTrustBoundaries do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.OperationalFeedback.RowValues

  def source_result_artifact_trust_boundaries(sources) when is_list(sources) do
    sources
    |> Enum.map(fn {_path, _feedback, trust_boundary} ->
      RowValues.encode_value(trust_boundary)
    end)
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.uniq()
    |> Enum.sort()
  end

  def source_result_artifact_trust_boundaries(_sources), do: []

  def put_source_result_artifact_trust_boundary(feedback, sources) do
    case source_result_artifact_trust_boundaries(sources) do
      [trust_boundary] -> Map.put_new(feedback, "trust_boundary", trust_boundary)
      _trust_boundaries -> feedback
    end
  end

  def source_timeline_feedback_trust_boundaries(reports) when is_list(reports) do
    reports
    |> Enum.flat_map(&source_timeline_feedback_trust_boundaries/1)
    |> normalize_trust_boundaries()
  end

  def source_timeline_feedback_trust_boundaries(
        %{"operational_feedback_provenance" => %{"sources" => sources}} = report
      )
      when is_list(sources) do
    sources
    |> Enum.flat_map(&List.wrap(Map.get(&1, "trust_boundaries")))
    |> Kernel.++([
      Map.get(report, "trust_boundary"),
      get_in(report, ["provenance", "trust_boundary"])
    ])
    |> normalize_trust_boundaries()
  end

  def source_timeline_feedback_trust_boundaries(%{"rows" => rows} = report) when is_list(rows) do
    row_trust_boundaries =
      rows
      |> Enum.flat_map(fn row ->
        row = RowValues.stringify_keys(row)

        [
          row["realized_trust_boundary"],
          row["trust_boundary"],
          get_in(row, ["realized_provenance", "trust_boundary"])
        ]
      end)

    row_trust_boundaries
    |> Kernel.++([
      Map.get(report, "trust_boundary"),
      get_in(report, ["provenance", "trust_boundary"])
    ])
    |> normalize_trust_boundaries()
  end

  def source_timeline_feedback_trust_boundaries(_report), do: []

  def source_operational_timeline_trust_boundaries(reports) when is_list(reports) do
    reports
    |> Enum.flat_map(&source_operational_timeline_trust_boundaries/1)
    |> normalize_trust_boundaries()
  end

  def source_operational_timeline_trust_boundaries(%{"rows" => rows} = report)
      when is_list(rows) do
    row_trust_boundaries =
      rows
      |> Enum.flat_map(fn row ->
        row = RowValues.stringify_keys(row)

        [
          row["trust_boundary"],
          get_in(row, ["provenance", "trust_boundary"]),
          get_in(row, ["resource_provenance", "trust_boundary"]),
          get_in(row, ["activity_context", "trust_boundary"]),
          get_in(row, ["activity_context", "provenance", "trust_boundary"]),
          get_in(row, ["activity_context", "resource_provenance", "trust_boundary"]),
          get_in(row, ["source_activity_context", "trust_boundary"]),
          get_in(row, ["source_activity_context", "provenance", "trust_boundary"]),
          get_in(row, ["source_activity_context", "resource_provenance", "trust_boundary"]),
          get_in(row, ["import_activity_context", "trust_boundary"]),
          get_in(row, ["import_activity_context", "provenance", "trust_boundary"]),
          get_in(row, ["import_activity_context", "resource_provenance", "trust_boundary"]),
          get_in(row, ["source_operational_timeline", "trust_boundary"]),
          get_in(row, ["source_operational_timeline", "provenance", "trust_boundary"])
        ]
      end)

    row_trust_boundaries
    |> Kernel.++([
      Map.get(report, "trust_boundary"),
      get_in(report, ["provenance", "trust_boundary"])
    ])
    |> normalize_trust_boundaries()
  end

  def source_operational_timeline_trust_boundaries(_report), do: []

  def put_source_operational_timeline_trust_boundary(feedback, reports) do
    put_single_source_trust_boundary(
      feedback,
      reports,
      &source_operational_timeline_trust_boundaries/1
    )
  end

  def put_source_timeline_feedback_trust_boundary(feedback, reports) do
    put_single_source_trust_boundary(
      feedback,
      reports,
      &source_timeline_feedback_trust_boundaries/1
    )
  end

  def source_timeline_diff_trust_boundaries(reports) when is_list(reports) do
    reports
    |> Enum.flat_map(&source_timeline_diff_trust_boundaries/1)
    |> normalize_trust_boundaries()
  end

  def source_timeline_diff_trust_boundaries(%{"rows" => rows} = report)
      when is_list(rows) do
    row_trust_boundaries =
      rows
      |> Enum.flat_map(fn row ->
        row = RowValues.stringify_keys(row)

        [
          row["source_trust_boundary"],
          row["trust_boundary"],
          get_in(row, ["source_activity_context", "trust_boundary"]),
          get_in(row, ["source_activity_context", "provenance", "trust_boundary"])
        ]
      end)

    row_trust_boundaries
    |> Kernel.++([
      Map.get(report, "trust_boundary"),
      get_in(report, ["provenance", "trust_boundary"])
    ])
    |> normalize_trust_boundaries()
  end

  def source_timeline_diff_trust_boundaries(_report), do: []

  def put_source_timeline_diff_trust_boundary(feedback, reports) do
    put_single_source_trust_boundary(feedback, reports, &source_timeline_diff_trust_boundaries/1)
  end

  def source_command_window_trust_boundaries(reports) when is_list(reports) do
    reports
    |> Enum.flat_map(&source_command_window_trust_boundaries/1)
    |> normalize_trust_boundaries()
  end

  def source_command_window_trust_boundaries(%{"rows" => rows} = report)
      when is_list(rows) do
    row_trust_boundaries =
      rows
      |> Enum.flat_map(fn row ->
        row = RowValues.stringify_keys(row)

        [
          row["trust_boundary"],
          get_in(row, ["provenance", "trust_boundary"]),
          get_in(row, ["activity_context", "trust_boundary"]),
          get_in(row, ["source_activity_context", "trust_boundary"]),
          get_in(row, ["source_command_window", "trust_boundary"]),
          get_in(row, ["source_command_window", "provenance", "trust_boundary"])
        ]
      end)

    row_trust_boundaries
    |> Kernel.++([
      Map.get(report, "trust_boundary"),
      get_in(report, ["provenance", "trust_boundary"])
    ])
    |> normalize_trust_boundaries()
  end

  def source_command_window_trust_boundaries(_report), do: []

  def put_source_command_window_trust_boundary(feedback, reports) do
    put_single_source_trust_boundary(feedback, reports, &source_command_window_trust_boundaries/1)
  end

  def source_maneuver_review_trust_boundaries(reports) when is_list(reports) do
    reports
    |> Enum.flat_map(&source_maneuver_review_trust_boundaries/1)
    |> normalize_trust_boundaries()
  end

  def source_maneuver_review_trust_boundaries(%{"rows" => rows} = report)
      when is_list(rows) do
    row_trust_boundaries =
      rows
      |> Enum.flat_map(fn row ->
        row = RowValues.stringify_keys(row)

        [
          row["trust_boundary"],
          get_in(row, ["provenance", "trust_boundary"]),
          get_in(row, ["source_recommendation", "trust_boundary"]),
          get_in(row, ["source_recommendation", "provenance", "trust_boundary"]),
          get_in(row, ["source_maneuver_review", "trust_boundary"]),
          get_in(row, ["source_maneuver_review", "provenance", "trust_boundary"])
        ]
      end)

    row_trust_boundaries
    |> Kernel.++([
      Map.get(report, "trust_boundary"),
      get_in(report, ["provenance", "trust_boundary"])
    ])
    |> normalize_trust_boundaries()
  end

  def source_maneuver_review_trust_boundaries(_report), do: []

  def put_source_maneuver_review_trust_boundary(feedback, reports) do
    put_single_source_trust_boundary(
      feedback,
      reports,
      &source_maneuver_review_trust_boundaries/1
    )
  end

  defp put_single_source_trust_boundary(feedback, reports, trust_boundaries_fun) do
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

  defp normalize_trust_boundaries(values) do
    values
    |> Enum.map(&RowValues.encode_value/1)
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.uniq()
    |> Enum.sort()
  end
end
