defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.QualityGate do
  @moduledoc false

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [
      compact_map: 1,
      count_source_report_values: 1,
      merge_count_maps: 1,
      merge_string_list_maps: 1,
      numeric_report_count: 2,
      sorted_string_values: 1,
      source_report_trust_boundaries: 1,
      source_report_trust_boundary_status: 1,
      sum_report_count: 2
    ]

  def report_input_summary([], _callbacks), do: nil

  def report_input_summary(sources, callbacks) do
    reports = Enum.map(sources, fn {_path, report} -> report end)

    %{
      "paths" => Enum.map(sources, fn {path, _report} -> path end),
      "contract" => "quality_gate_report.v1",
      "count" => length(sources),
      "row_count" => sum_report_count(reports, &quality_gate_report_row_count/1),
      "readiness_level_counts" =>
        reports
        |> Enum.map(&quality_gate_report_readiness_level/1)
        |> count_source_report_values(),
      "import_classification_counts" =>
        reports
        |> Enum.map(&quality_gate_report_import_classification/1)
        |> count_source_report_values(),
      "status_counts" =>
        reports
        |> Enum.map(&quality_gate_report_status/1)
        |> count_source_report_values(),
      "gate_count" => sum_report_count(reports, &quality_gate_report_gate_count/1),
      "passed_gate_count" =>
        sum_report_count(reports, &quality_gate_report_status_count(&1, "passed")),
      "review_gate_count" =>
        sum_report_count(reports, &quality_gate_report_status_count(&1, "review_required")),
      "analysis_gate_count" =>
        sum_report_count(reports, &quality_gate_report_status_count(&1, "analysis_only")),
      "analysis_mode_counts" =>
        reports
        |> Enum.map(&quality_gate_analysis_mode_counts/1)
        |> merge_count_maps(),
      "blocked_gate_count" =>
        sum_report_count(reports, &quality_gate_report_status_count(&1, "blocked")),
      "gate_status_counts" =>
        reports
        |> Enum.map(&quality_gate_report_count_map(&1, "gate_status_counts"))
        |> merge_count_maps(),
      "gate_classification_counts" =>
        reports
        |> Enum.map(&quality_gate_report_count_map(&1, "gate_classification_counts"))
        |> merge_count_maps(),
      "non_passed_gate_count" => sum_report_count(reports, &quality_gate_non_passed_gate_count/1),
      "quality_gate_row_ids_by_classification" =>
        reports
        |> Enum.map(&quality_gate_string_list_map(&1, "quality_gate_row_ids_by_classification"))
        |> merge_string_list_maps(),
      "quality_gate_ids_by_classification" =>
        reports
        |> Enum.map(&quality_gate_ids_by_classification_map/1)
        |> merge_string_list_maps(),
      "passed_gate_ids" =>
        reports
        |> Enum.flat_map(&quality_gate_gate_ids_by_status(&1, "passed", "passed_gate_ids"))
        |> sorted_string_values(),
      "review_required_gate_ids" =>
        reports
        |> Enum.flat_map(
          &quality_gate_gate_ids_by_status(&1, "review_required", "review_required_gate_ids")
        )
        |> sorted_string_values(),
      "analysis_only_gate_ids" =>
        reports
        |> Enum.flat_map(
          &quality_gate_gate_ids_by_status(&1, "analysis_only", "analysis_only_gate_ids")
        )
        |> sorted_string_values(),
      "blocked_gate_ids" =>
        reports
        |> Enum.flat_map(&quality_gate_gate_ids_by_status(&1, "blocked", "blocked_gate_ids"))
        |> sorted_string_values(),
      "non_passed_gate_ids" =>
        reports
        |> Enum.flat_map(&quality_gate_non_passed_gate_ids/1)
        |> sorted_string_values(),
      "non_passed_quality_gate_row_ids" =>
        reports
        |> Enum.flat_map(&quality_gate_non_passed_row_ids/1)
        |> sorted_string_values(),
      "ready_for_import_count" =>
        sum_report_count(reports, &quality_gate_row_count(&1, "ready_for_import_count")),
      "manifest_review_required_count" =>
        sum_report_count(reports, &quality_gate_row_count(&1, "manifest_review_required_count")),
      "blocked_import_count" =>
        sum_report_count(reports, &quality_gate_row_count(&1, "blocked_import_count")),
      "missing_import_count" =>
        sum_report_count(reports, &quality_gate_row_count(&1, "missing_import_count")),
      "invalid_cadence_import_count" =>
        sum_report_count(reports, &quality_gate_row_count(&1, "invalid_cadence_import_count")),
      "current_freshness_count" =>
        sum_report_count(reports, &quality_gate_row_count(&1, "current_freshness_count")),
      "stale_freshness_count" =>
        sum_report_count(reports, &quality_gate_row_count(&1, "stale_freshness_count")),
      "unknown_freshness_count" =>
        sum_report_count(reports, &quality_gate_row_count(&1, "unknown_freshness_count")),
      "freshness_status_counts" =>
        reports
        |> Enum.map(&quality_gate_row_count_map(&1, "freshness_status_counts"))
        |> merge_count_maps(),
      "freshness_status_ids" =>
        reports
        |> Enum.flat_map(&quality_gate_string_list(&1, "freshness_status_ids"))
        |> sorted_string_values(),
      "schema_validation_pass_count" =>
        sum_report_count(reports, &quality_gate_row_count(&1, "schema_validation_pass_count")),
      "schema_validation_fail_count" =>
        sum_report_count(reports, &quality_gate_row_count(&1, "schema_validation_fail_count")),
      "schema_validation_error_count" =>
        sum_report_count(reports, &quality_gate_row_count(&1, "schema_validation_error_count")),
      "schema_validation_warning_count" =>
        sum_report_count(reports, &quality_gate_row_count(&1, "schema_validation_warning_count")),
      "schema_validation_remediation_count" =>
        sum_report_count(
          reports,
          &quality_gate_row_count(&1, "schema_validation_remediation_count")
        ),
      "schema_validation_status_counts" =>
        reports
        |> Enum.map(&quality_gate_row_count_map(&1, "schema_validation_status_counts"))
        |> merge_count_maps(),
      "schema_validation_status_ids" =>
        reports
        |> Enum.flat_map(&quality_gate_string_list(&1, "schema_validation_status_ids"))
        |> sorted_string_values(),
      "failed_schema_validation_quality_gate_row_ids" =>
        reports
        |> Enum.flat_map(
          &quality_gate_string_list(&1, "failed_schema_validation_quality_gate_row_ids")
        )
        |> sorted_string_values(),
      "schema_validation_gate_ids" =>
        reports
        |> Enum.flat_map(&quality_gate_string_list(&1, "schema_validation_gate_ids"))
        |> sorted_string_values(),
      "operator_training_requirement_count" =>
        sum_report_count(
          reports,
          &quality_gate_row_count(&1, "operator_training_requirement_count")
        ),
      "operator_training_requirement_counts" =>
        reports
        |> Enum.map(&quality_gate_row_count_map(&1, "operator_training_requirement_counts"))
        |> merge_count_maps(),
      "operator_training_requirement_ids" =>
        reports
        |> Enum.flat_map(&quality_gate_string_list(&1, "operator_training_requirement_ids"))
        |> sorted_string_values(),
      "required_operator_roles" =>
        reports
        |> Enum.flat_map(&quality_gate_string_list(&1, "required_operator_roles"))
        |> sorted_string_values(),
      "required_training_ids" =>
        reports
        |> Enum.flat_map(&quality_gate_string_list(&1, "required_training_ids"))
        |> sorted_string_values(),
      "required_certification_ids" =>
        reports
        |> Enum.flat_map(&quality_gate_string_list(&1, "required_certification_ids"))
        |> sorted_string_values(),
      "required_qualification_ids" =>
        reports
        |> Enum.flat_map(&quality_gate_string_list(&1, "required_qualification_ids"))
        |> sorted_string_values(),
      "review_only_quality_gate_row_ids" =>
        reports
        |> Enum.flat_map(&quality_gate_string_list(&1, "review_only_quality_gate_row_ids"))
        |> sorted_string_values(),
      "operator_training_gate_ids" =>
        reports
        |> Enum.flat_map(&quality_gate_string_list(&1, "operator_training_gate_ids"))
        |> sorted_string_values(),
      "import_status_counts" =>
        reports
        |> Enum.map(&quality_gate_row_count_map(&1, "import_status_counts"))
        |> merge_count_maps(),
      "import_status_ids" =>
        reports
        |> Enum.flat_map(&quality_gate_string_list(&1, "import_status_ids"))
        |> sorted_string_values(),
      "cadence_import_status_counts" =>
        reports
        |> Enum.map(&quality_gate_row_count_map(&1, "cadence_import_status_counts"))
        |> merge_count_maps(),
      "cadence_import_status_ids" =>
        reports
        |> Enum.flat_map(&quality_gate_string_list(&1, "cadence_import_status_ids"))
        |> sorted_string_values(),
      "source_summary_model_counts" =>
        reports
        |> Enum.map(&quality_gate_source_summary_model/1)
        |> count_source_report_values(),
      "source_summary_schema_contract_counts" =>
        reports
        |> Enum.map(&quality_gate_source_summary_schema_contract/1)
        |> count_source_report_values(),
      "source_artifact_type_counts" =>
        reports
        |> Enum.map(&quality_gate_source_artifact_type/1)
        |> count_source_report_values(),
      "quality_gate_row_ids_by_status" =>
        reports
        |> Enum.map(&quality_gate_string_list_map(&1, "quality_gate_row_ids_by_status"))
        |> merge_string_list_maps(),
      "quality_gate_ids_by_status" =>
        reports
        |> Enum.map(&quality_gate_string_list_map(&1, "quality_gate_ids_by_status"))
        |> merge_string_list_maps(),
      "review_required_quality_gate_row_ids" =>
        reports
        |> Enum.flat_map(
          &quality_gate_status_row_ids(
            &1,
            "review_required",
            "review_required_quality_gate_row_ids"
          )
        )
        |> sorted_string_values(),
      "blocked_quality_gate_row_ids" =>
        reports
        |> Enum.flat_map(
          &quality_gate_status_row_ids(&1, "blocked", "blocked_quality_gate_row_ids")
        )
        |> sorted_string_values(),
      "ready_quality_gate_row_ids" =>
        reports
        |> Enum.flat_map(&quality_gate_status_row_ids(&1, "passed", "ready_quality_gate_row_ids"))
        |> sorted_string_values(),
      "analysis_only_quality_gate_row_ids" =>
        reports
        |> Enum.flat_map(
          &quality_gate_status_row_ids(&1, "analysis_only", "analysis_only_quality_gate_row_ids")
        )
        |> sorted_string_values(),
      "stale_or_unknown_freshness_quality_gate_row_ids" =>
        reports
        |> Enum.flat_map(
          &quality_gate_string_list(&1, "stale_or_unknown_freshness_quality_gate_row_ids")
        )
        |> sorted_string_values(),
      "import_preparation_quality_gate_row_ids" =>
        reports
        |> Enum.flat_map(&quality_gate_string_list(&1, "import_preparation_quality_gate_row_ids"))
        |> sorted_string_values(),
      "blocked_import_quality_gate_row_ids" =>
        reports
        |> Enum.flat_map(&quality_gate_string_list(&1, "blocked_import_quality_gate_row_ids"))
        |> sorted_string_values(),
      "import_readiness_gate_ids" =>
        reports
        |> Enum.flat_map(&quality_gate_string_list(&1, "import_readiness_gate_ids"))
        |> sorted_string_values(),
      "adapter_context_count" =>
        sum_report_count(reports, &quality_gate_row_count(&1, "adapter_context_count")),
      "adapter_trust_boundary_declared_count" =>
        sum_report_count(
          reports,
          &quality_gate_row_count(&1, "adapter_trust_boundary_declared_count")
        ),
      "adapter_trust_boundary_missing_count" =>
        sum_report_count(
          reports,
          &quality_gate_row_count(&1, "adapter_trust_boundary_missing_count")
        ),
      "adapter_trust_boundary_untrusted_count" =>
        sum_report_count(
          reports,
          &quality_gate_row_count(&1, "adapter_trust_boundary_untrusted_count")
        ),
      "adapter_boundary_status_counts" =>
        reports
        |> Enum.map(&quality_gate_row_count_map(&1, "adapter_boundary_status_counts"))
        |> merge_count_maps(),
      "resource_availability_pressure_count" =>
        sum_report_count(reports, &quality_gate_resource_availability_pressure_count/1),
      "resource_availability_reason_counts" =>
        reports
        |> Enum.map(&quality_gate_resource_availability_reason_counts/1)
        |> merge_count_maps(),
      "resource_availability_reason_ids" =>
        reports
        |> Enum.flat_map(&quality_gate_resource_availability_reason_ids/1)
        |> sorted_non_empty_values(),
      "station_availability_reason_ids" =>
        reports
        |> Enum.flat_map(&quality_gate_station_reason_ids(&1, callbacks))
        |> sorted_non_empty_values(),
      "station_availability_reason_counts" =>
        reports
        |> Enum.map(&quality_gate_station_reason_counts(&1, callbacks))
        |> merge_count_maps(),
      "unavailable_resource_reason_ids" =>
        reports
        |> Enum.flat_map(&quality_gate_unavailable_resource_reason_ids(&1, callbacks))
        |> sorted_non_empty_values(),
      "resource_blocking_dimension_counts" =>
        reports
        |> Enum.map(&quality_gate_resource_blocking_dimension_counts/1)
        |> merge_count_maps(),
      "blocked_contact_ids_by_blocking_dimension" =>
        reports
        |> Enum.map(
          &quality_gate_string_list_map(&1, "blocked_contact_ids_by_blocking_dimension")
        )
        |> merge_string_list_maps(),
      "blocked_contact_ids_by_spacecraft_id" =>
        reports
        |> Enum.map(&quality_gate_string_list_map(&1, "blocked_contact_ids_by_spacecraft_id"))
        |> merge_string_list_maps(),
      "blocked_contact_ids_by_status" =>
        reports
        |> Enum.map(&quality_gate_string_list_map(&1, "blocked_contact_ids_by_status"))
        |> merge_string_list_maps(),
      "source_readiness_report_count" =>
        reports
        |> Enum.map(&Map.get(&1, "source_readiness_report_id"))
        |> Enum.reject(&(&1 in [nil, ""]))
        |> length(),
      "trust_boundary_status" => source_report_trust_boundary_status(reports),
      "trust_boundaries" => source_report_trust_boundaries(reports)
    }
    |> Map.merge(quality_gate_timeline_publication_input_summary(reports))
    |> compact_map()
  end

  defp quality_gate_report_gate_count(report) do
    case quality_gate_report_rows(report) do
      [] -> numeric_report_count(report, "gate_count")
      rows -> length(rows)
    end
  end

  defp quality_gate_report_row_count(report) do
    case quality_gate_report_rows(report) do
      [] ->
        case numeric_report_count(report, "import_readiness_row_count") do
          0 -> numeric_report_count(report, "gate_count")
          count -> count
        end

      rows ->
        length(rows)
    end
  end

  defp quality_gate_report_status_count(report, status) do
    report
    |> quality_gate_report_rows()
    |> case do
      [] -> numeric_report_count(report, quality_gate_report_status_count_field(status))
      rows -> Enum.count(rows, &(&1["status"] == status))
    end
  end

  defp quality_gate_report_status_count_field("passed"), do: "passed_gate_count"
  defp quality_gate_report_status_count_field("review_required"), do: "review_gate_count"
  defp quality_gate_report_status_count_field("analysis_only"), do: "analysis_gate_count"
  defp quality_gate_report_status_count_field("blocked"), do: "blocked_gate_count"

  defp quality_gate_report_count_map(report, field) do
    rows = quality_gate_report_rows(report)

    cond do
      field == "gate_status_counts" and rows != [] ->
        rows |> Enum.map(&Map.get(&1, "status")) |> count_source_report_values() || %{}

      field == "gate_classification_counts" and rows != [] ->
        rows |> Enum.map(&Map.get(&1, "classification")) |> count_source_report_values() || %{}

      true ->
        case Map.get(report, field) do
          %{} = count_map -> count_map
          _value -> %{}
        end
    end
  end

  defp quality_gate_report_readiness_level(report) do
    report
    |> quality_gate_report_import_classification()
    |> case do
      "importable" -> "import_eligible"
      "review_only" -> "operator_review"
      "analysis_only" -> "analysis_only"
      "blocked" -> "blocked"
      _classification -> Map.get(report, "readiness_level")
    end
  end

  defp quality_gate_report_status(report) do
    report
    |> quality_gate_report_import_classification()
    |> case do
      "importable" -> "passed"
      "review_only" -> "review_required"
      "analysis_only" -> "analysis_only"
      "blocked" -> "blocked"
      _classification -> Map.get(report, "status")
    end
  end

  defp quality_gate_report_import_classification(report) do
    case quality_gate_report_rows(report) do
      [] ->
        Map.get(report, "import_classification")

      rows ->
        statuses = Enum.map(rows, &Map.get(&1, "status"))

        cond do
          "blocked" in statuses -> "blocked"
          "analysis_only" in statuses -> "analysis_only"
          "review_required" in statuses -> "review_only"
          true -> "importable"
        end
    end
  end

  defp quality_gate_report_rows(report) do
    report
    |> Map.get("rows", [])
    |> Enum.filter(&is_map/1)
  end

  defp quality_gate_analysis_mode_counts(report) do
    row_counts =
      report
      |> quality_gate_report_rows()
      |> Enum.map(&Map.get(&1, "analysis_mode"))
      |> count_source_report_values()

    case row_counts do
      %{} = counts when map_size(counts) > 0 -> counts
      _counts -> Map.get(report, "analysis_mode_counts", %{})
    end
  end

  defp quality_gate_row_count(report, field) do
    case quality_gate_report_rows(report) do
      [] ->
        numeric_report_count(report, field)

      rows ->
        rows
        |> Enum.map(&numeric_report_count(&1, field))
        |> Enum.sum()
    end
  end

  defp quality_gate_row_count_map(report, field) do
    case quality_gate_report_rows(report) do
      [] ->
        case Map.get(report, field) do
          %{} = count_map -> count_map
          _value -> %{}
        end

      rows ->
        rows
        |> Enum.map(&Map.get(&1, field))
        |> merge_count_maps()
    end
  end

  defp quality_gate_string_list(report, field) do
    report
    |> Map.get(field)
    |> list_value()
  end

  defp quality_gate_status_row_ids(report, status, fallback_field) do
    case Map.get(report, "quality_gate_row_ids_by_status") do
      %{} = row_ids_by_status ->
        quality_gate_summary_list_map_values(row_ids_by_status, status)

      _row_ids_by_status ->
        quality_gate_string_list(report, fallback_field)
    end
  end

  defp quality_gate_gate_ids_by_status(report, status, fallback_field) do
    case quality_gate_ids_by_status_map(report) do
      %{} = ids_by_status ->
        quality_gate_summary_list_map_values(ids_by_status, status)

      _ids_by_status ->
        quality_gate_string_list(report, fallback_field)
    end
  end

  defp quality_gate_non_passed_gate_count(report) do
    case numeric_report_count(report, "non_passed_gate_count") do
      0 -> length(quality_gate_non_passed_gate_ids(report))
      count -> count
    end
  end

  defp quality_gate_non_passed_gate_ids(report) do
    case quality_gate_ids_by_status_map(report) do
      %{} = ids_by_status ->
        non_passed_ids_by_status(ids_by_status)

      _ids_by_status ->
        case quality_gate_string_list(report, "non_passed_gate_ids") do
          [] ->
            ["review_required", "analysis_only", "blocked"]
            |> Enum.flat_map(&quality_gate_string_list(report, "#{&1}_gate_ids"))
            |> sorted_string_values()

          ids ->
            ids
        end
    end
  end

  defp quality_gate_non_passed_row_ids(report) do
    case Map.get(report, "quality_gate_row_ids_by_status") do
      %{} = row_ids_by_status ->
        non_passed_ids_by_status(row_ids_by_status)

      _row_ids_by_status ->
        case quality_gate_string_list(report, "non_passed_quality_gate_row_ids") do
          [] ->
            ["review_required", "analysis_only", "blocked"]
            |> Enum.flat_map(
              &quality_gate_status_row_ids(report, &1, "#{&1}_quality_gate_row_ids")
            )
            |> sorted_string_values()

          ids ->
            ids
        end
    end
  end

  defp non_passed_ids_by_status(%{} = ids_by_status) do
    ["review_required", "analysis_only", "blocked"]
    |> Enum.flat_map(&quality_gate_summary_list_map_values(ids_by_status, &1))
    |> sorted_string_values()
  end

  defp quality_gate_ids_by_status_map(report) do
    cond do
      is_map(Map.get(report, "quality_gate_ids_by_status")) ->
        Map.get(report, "quality_gate_ids_by_status")

      is_map(Map.get(report, "gate_ids_by_status")) ->
        Map.get(report, "gate_ids_by_status")

      true ->
        nil
    end
  end

  defp quality_gate_string_list_map(report, field) do
    case Map.get(report, field) do
      %{} = list_map -> list_map
      _value -> %{}
    end
  end

  defp quality_gate_ids_by_classification_map(report) do
    case quality_gate_string_list_map(report, "quality_gate_ids_by_classification") do
      map when map_size(map) > 0 -> map
      _map -> quality_gate_string_list_map(report, "gate_ids_by_classification")
    end
  end

  defp quality_gate_timeline_publication_input_summary(reports) do
    %{
      "publication_status_counts" =>
        reports
        |> Enum.map(&quality_gate_row_count_map(&1, "publication_status_counts"))
        |> merge_count_maps(),
      "dependency_impact_status_counts" =>
        reports
        |> Enum.map(&quality_gate_row_count_map(&1, "dependency_impact_status_counts"))
        |> merge_count_maps(),
      "publication_authority_counts" =>
        reports
        |> Enum.map(&quality_gate_row_count_map(&1, "publication_authority_counts"))
        |> merge_count_maps(),
      "timeline_publication_source_artifact_type_counts" =>
        reports
        |> Enum.map(&quality_gate_row_count_map(&1, "source_artifact_type_counts"))
        |> merge_count_maps(),
      "publication_ids" =>
        reports
        |> Enum.flat_map(&quality_gate_row_string_list(&1, "publication_ids"))
        |> sorted_string_values(),
      "source_artifact_ids" =>
        reports
        |> Enum.flat_map(&quality_gate_row_string_list(&1, "source_artifact_ids"))
        |> sorted_string_values(),
      "supersedes_artifact_ids" =>
        reports
        |> Enum.flat_map(&quality_gate_row_string_list(&1, "supersedes_artifact_ids"))
        |> sorted_string_values(),
      "downstream_product_ids" =>
        reports
        |> Enum.flat_map(&quality_gate_row_string_list(&1, "downstream_product_ids"))
        |> sorted_string_values(),
      "invalidated_downstream_product_ids" =>
        reports
        |> Enum.flat_map(&quality_gate_row_string_list(&1, "invalidated_downstream_product_ids"))
        |> sorted_string_values(),
      "dependency_impact_row_count" =>
        sum_report_count(reports, &quality_gate_row_count(&1, "dependency_impact_row_count")),
      "impacted_dependency_activity_ids" =>
        reports
        |> Enum.flat_map(&quality_gate_row_string_list(&1, "impacted_dependency_activity_ids"))
        |> sorted_string_values(),
      "impacted_dependency_timeline_ids" =>
        reports
        |> Enum.flat_map(&quality_gate_row_string_list(&1, "impacted_dependency_timeline_ids"))
        |> sorted_string_values(),
      "impacted_exclusive_with_activity_ids" =>
        reports
        |> Enum.flat_map(
          &quality_gate_row_string_list(&1, "impacted_exclusive_with_activity_ids")
        )
        |> sorted_string_values(),
      "impacted_exclusive_with_timeline_ids" =>
        reports
        |> Enum.flat_map(
          &quality_gate_row_string_list(&1, "impacted_exclusive_with_timeline_ids")
        )
        |> sorted_string_values(),
      "timeline_diff_row_count" =>
        sum_report_count(reports, &quality_gate_row_count(&1, "timeline_diff_row_count")),
      "timeline_diff_changed_count" =>
        sum_report_count(reports, &quality_gate_row_count(&1, "timeline_diff_changed_count")),
      "timeline_diff_review_required_count" =>
        sum_report_count(
          reports,
          &quality_gate_row_count(&1, "timeline_diff_review_required_count")
        ),
      "changed_field_counts" =>
        reports
        |> Enum.map(&quality_gate_row_count_map(&1, "changed_field_counts"))
        |> merge_count_maps(),
      "changed_timeline_ids" =>
        reports
        |> Enum.flat_map(&quality_gate_row_string_list(&1, "changed_timeline_ids"))
        |> sorted_string_values(),
      "review_timeline_ids" =>
        reports
        |> Enum.flat_map(&quality_gate_row_string_list(&1, "review_timeline_ids"))
        |> sorted_string_values(),
      "timeline_ids_by_changed_field" =>
        reports
        |> Enum.map(&quality_gate_row_string_list_map(&1, "timeline_ids_by_changed_field"))
        |> merge_string_list_maps()
    }
    |> compact_map()
  end

  defp quality_gate_row_string_list(report, field) do
    case quality_gate_report_rows(report) do
      [] ->
        quality_gate_string_list(report, field)

      rows ->
        Enum.flat_map(rows, &(Map.get(&1, field) |> list_value()))
    end
  end

  defp quality_gate_row_string_list_map(report, field) do
    case quality_gate_report_rows(report) do
      [] ->
        quality_gate_string_list_map(report, field)

      rows ->
        rows
        |> Enum.map(&Map.get(&1, field))
        |> merge_string_list_maps()
        |> case do
          nil -> %{}
          map -> map
        end
    end
  end

  defp quality_gate_source_summary_model(report),
    do: Map.get(report, "source_summary_model") || Map.get(report, "model")

  defp quality_gate_source_summary_schema_contract(report),
    do: Map.get(report, "source_summary_schema_contract") || Map.get(report, "schema_contract")

  defp quality_gate_source_artifact_type(report), do: Map.get(report, "source_artifact_type")

  defp quality_gate_resource_availability_pressure_count(report) do
    case quality_gate_report_rows(report) do
      [] ->
        numeric_report_count(report, "resource_availability_pressure_count")

      rows ->
        rows
        |> Enum.map(&numeric_report_count(&1, "resource_availability_pressure_count"))
        |> Enum.sum()
    end
  end

  defp quality_gate_resource_availability_reason_counts(report) do
    case quality_gate_report_rows(report) do
      [] ->
        Map.get(report, "resource_availability_reason_counts", %{})

      rows ->
        rows
        |> Enum.map(&Map.get(&1, "resource_availability_reason_counts"))
        |> merge_count_maps()
    end
  end

  defp quality_gate_resource_availability_reason_ids(report) do
    case quality_gate_report_rows(report) do
      [] ->
        list_value(Map.get(report, "resource_availability_reason_ids")) ++
          Map.keys(Map.get(report, "resource_availability_reason_counts") || %{})

      rows ->
        Enum.flat_map(rows, fn row ->
          list_value(Map.get(row, "resource_availability_reason_ids")) ++
            Map.keys(Map.get(row, "resource_availability_reason_counts") || %{})
        end)
    end
  end

  defp quality_gate_unavailable_resource_reason_ids(report, callbacks) do
    reason_ids =
      case quality_gate_report_rows(report) do
        [] ->
          list_value(Map.get(report, "unavailable_resource_reason_ids")) ++
            Map.keys(Map.get(report, "unavailable_resource_reason_counts") || %{})

        rows ->
          Enum.flat_map(rows, fn row ->
            list_value(Map.get(row, "unavailable_resource_reason_ids")) ++
              Map.keys(Map.get(row, "resource_availability_reason_counts") || %{})
          end)
      end

    callback!(callbacks, :filter_resource_reason_ids).(
      reason_ids,
      callback!(callbacks, :operational_readiness_unavailable_reasons).()
    )
  end

  defp quality_gate_station_reason_ids(report, callbacks) do
    reason_ids =
      case quality_gate_report_rows(report) do
        [] ->
          list_value(Map.get(report, "station_availability_reason_ids")) ++
            Map.keys(Map.get(report, "station_availability_reason_counts") || %{})

        rows ->
          Enum.flat_map(rows, fn row ->
            list_value(Map.get(row, "station_availability_reason_ids")) ++
              Map.keys(Map.get(row, "resource_availability_reason_counts") || %{})
          end)
      end

    callback!(callbacks, :filter_resource_reason_ids).(
      reason_ids,
      callback!(callbacks, :operational_readiness_station_reasons).()
    )
  end

  defp quality_gate_station_reason_counts(report, callbacks) do
    case quality_gate_report_rows(report) do
      [] ->
        callback!(callbacks, :station_availability_reason_count_map).(
          Map.get(report, "station_availability_reason_counts", %{})
        )

      rows ->
        rows
        |> Enum.map(callback!(callbacks, :station_availability_reason_counts_from_context))
        |> merge_count_maps()
    end
  end

  defp quality_gate_resource_blocking_dimension_counts(report) do
    case quality_gate_report_rows(report) do
      [] ->
        Map.get(report, "resource_blocking_dimension_counts", %{})

      rows ->
        rows
        |> Enum.map(&Map.get(&1, "resource_blocking_dimension_counts"))
        |> merge_count_maps()
    end
  end

  defp quality_gate_summary_list_map_values(%{} = list_map, key) do
    list_map
    |> Map.get(key)
    |> list_value()
  end

  defp callback!(callbacks, key), do: Keyword.fetch!(callbacks, key)

  defp sorted_non_empty_values(values) do
    values
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.map(&to_string/1)
    |> Enum.uniq()
    |> Enum.sort()
    |> case do
      [] -> nil
      values -> values
    end
  end

  defp list_value(values) when is_list(values), do: values
  defp list_value(_values), do: []
end
