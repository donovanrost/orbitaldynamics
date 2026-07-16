defmodule OrbitalDynamics.CampaignPlanner.TimelineSourceReports.PressureRows do
  @moduledoc false

  def pressure_entries(entries) do
    entries
    |> Enum.with_index(1)
    |> Enum.map(fn {{entry, source_path}, index} -> {entry, source_path, index} end)
  end

  def timeline_preservation_report_pressure_rows(reports, opts) do
    callbacks = callbacks!(opts)

    reports
    |> Enum.flat_map(fn {report, source_path} ->
      report = callbacks.stringify_keys.(report)

      trust_boundary =
        Map.get(report, "trust_boundary") || get_in(report, ["provenance", "trust_boundary"])

      report_context = timeline_preservation_report_pressure_context(report, callbacks)

      report
      |> Map.get("rows", [])
      |> List.wrap()
      |> Enum.map(&callbacks.stringify_keys.(&1))
      |> Enum.with_index(1)
      |> Enum.map(fn {row, index} ->
        row =
          report_context
          |> Map.merge(row)
          |> Map.put("_source_report_trust_boundary", trust_boundary)

        {row, "#{source_path}.rows[#{index - 1}]", index}
      end)
    end)
  end

  def timeline_preservation_status_pressure_rows(statuses, opts) do
    callbacks = callbacks!(opts)

    statuses
    |> Enum.with_index(1)
    |> Enum.map(fn {{status, source_path}, index} ->
      {callbacks.stringify_keys.(status), source_path, index}
    end)
  end

  def timeline_transition_application_pressure_row(row, opts) do
    callbacks = callbacks!(opts)
    row = callbacks.stringify_keys.(row)

    row
    |> Map.get("source_timeline_diff", %{})
    |> callbacks.stringify_keys.()
    |> Map.merge(Map.drop(row, ["source_timeline_diff"]))
    |> Map.put("source_timeline_application", row)
  end

  def timeline_diff_pressure_rows(diff_reports, transition_application_reports, opts) do
    diff_rows =
      diff_reports
      |> report_pressure_rows("rows", opts)

    transition_application_rows =
      transition_application_reports
      |> report_pressure_rows("applications", opts,
        transform: &timeline_transition_application_pressure_row(&1, opts)
      )

    diff_rows ++ transition_application_rows
  end

  def timeline_integrity_pressure_rows(reports, opts) do
    callbacks = callbacks!(opts)

    reports
    |> Enum.flat_map(fn {report, source_path} ->
      trust_boundary =
        Map.get(report, "trust_boundary") || get_in(report, ["provenance", "trust_boundary"])

      report
      |> Map.get("rows", [])
      |> Enum.map(&callbacks.stringify_keys.(&1))
      |> Enum.with_index(1)
      |> Enum.map(fn {row, index} ->
        {
          Map.put(row, "_source_report_trust_boundary", trust_boundary),
          "#{source_path}.rows",
          index
        }
      end)
    end)
  end

  def timeline_dependency_impact_pressure_rows(summaries, opts) do
    callbacks = callbacks!(opts)

    summaries
    |> Enum.flat_map(fn {summary, source_path} ->
      trust_boundary =
        Map.get(summary, "trust_boundary") || get_in(summary, ["provenance", "trust_boundary"])

      summary
      |> Map.get("dependency_impact_rows", [])
      |> Enum.map(&callbacks.stringify_keys.(&1))
      |> Enum.with_index(1)
      |> Enum.map(fn {row, index} ->
        {
          Map.put(row, "_source_report_trust_boundary", trust_boundary),
          "#{source_path}.dependency_impact_rows",
          index
        }
      end)
    end)
  end

  defp report_pressure_rows(reports, row_key, opts) do
    report_pressure_rows(reports, row_key, opts, transform: & &1)
  end

  defp report_pressure_rows(reports, row_key, opts, options) do
    callbacks = callbacks!(opts)
    transform = Keyword.fetch!(options, :transform)

    reports
    |> Enum.flat_map(fn {report, source_path} ->
      trust_boundary =
        Map.get(report, "trust_boundary") || get_in(report, ["provenance", "trust_boundary"])

      report
      |> Map.get(row_key, [])
      |> Enum.map(&transform.(&1))
      |> Enum.map(&callbacks.stringify_keys.(&1))
      |> Enum.with_index(1)
      |> Enum.map(fn {row, index} ->
        {Map.put(row, "_source_report_trust_boundary", trust_boundary), source_path, index}
      end)
    end)
  end

  defp timeline_preservation_report_pressure_context(report, callbacks) do
    %{
      "timeline_preservation_status" => report["timeline_preservation_status"],
      "activity_count" => report["activity_count"],
      "mutable_activity_count" => report["mutable_activity_count"],
      "preserve_activity_count" => report["preserve_activity_count"],
      "review_change_activity_count" => report["review_change_activity_count"],
      "preservation_sensitive_activity_count" => report["preservation_sensitive_activity_count"],
      "protection_decision_counts" => report["protection_decision_counts"],
      "protection_category_counts" => report["protection_category_counts"],
      "protection_reason_counts" => report["protection_reason_counts"],
      "preserve_activity_ids" => report["preserve_activity_ids"],
      "preserve_timeline_ids" => report["preserve_timeline_ids"],
      "review_change_activity_ids" => report["review_change_activity_ids"],
      "review_change_timeline_ids" => report["review_change_timeline_ids"],
      "preservation_sensitive_activity_ids" => report["preservation_sensitive_activity_ids"],
      "preservation_sensitive_timeline_ids" => report["preservation_sensitive_timeline_ids"],
      "activity_id_sets_by_protection_decision" =>
        report["activity_id_sets_by_protection_decision"],
      "timeline_id_sets_by_protection_decision" =>
        report["timeline_id_sets_by_protection_decision"],
      "activity_id_sets_by_protection_category" =>
        report["activity_id_sets_by_protection_category"],
      "timeline_id_sets_by_protection_category" =>
        report["timeline_id_sets_by_protection_category"],
      "activity_id_sets_by_protection_reason" => report["activity_id_sets_by_protection_reason"],
      "timeline_id_sets_by_protection_reason" => report["timeline_id_sets_by_protection_reason"],
      "assumptions" => report["assumptions"],
      "source" => report["source"]
    }
    |> callbacks.reject_empty_values.()
  end

  defp callbacks!(opts) do
    %{
      source_report_entries: Keyword.fetch!(opts, :source_report_entries),
      result_artifacts_with_source: Keyword.fetch!(opts, :result_artifacts_with_source),
      result_artifact_embedded_report_entries:
        Keyword.fetch!(opts, :result_artifact_embedded_report_entries),
      put_inherited_result_artifact_trust_boundary:
        Keyword.fetch!(opts, :put_inherited_result_artifact_trust_boundary),
      stringify_keys: Keyword.fetch!(opts, :stringify_keys),
      reject_empty_values: Keyword.fetch!(opts, :reject_empty_values)
    }
  end
end
