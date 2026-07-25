defmodule OrbitalDynamics.OperatorReview.QualityGate do
  @moduledoc false

  alias OrbitalDynamics.OperatorReview.Capabilities
  alias OrbitalDynamics.OperatorReview.PackageBuilder

  @schema_contract "operator_review_package.v1"

  def package(report) do
    {rows, source_artifact_id, provenance} = package_input(report)

    rows
    |> build_package("quality_gate_report.v1", source_artifact_id, provenance)
    |> put_report_summary(report)
  end

  def package_input(report) do
    report = stringify_keys(report || %{})

    {
      rows(report),
      Map.get(report, "report_id") || "quality_gate_report",
      Map.get(report, "provenance", %{})
    }
  end

  def rows(report, source \\ "quality_gate_report.rows") do
    report
    |> Map.get("rows", [])
    |> List.wrap()
    |> Enum.map(&stringify_keys/1)
    |> Enum.filter(&quality_gate_reviewable_row?/1)
    |> Enum.with_index(1)
    |> Enum.map(fn {row, index} ->
      gate_id = row["gate_id"] || "quality_gate"
      gate_status = row["status"] || "review_required"
      classification = row["classification"] || "review_only"
      action = quality_gate_action(classification)
      row_id = row["id"] || review_id(["quality_gate", gate_id, index])

      %{
        "id" => review_id(["quality_gate_review", row_id]),
        "review_type" => "quality_gate_review",
        "source" => source,
        "subject_id" => row_id,
        "action" => action,
        "required_operator_action" => action,
        "approval_status" => quality_gate_approval_status(classification),
        "cadence_import_status" => quality_gate_cadence_import_status(classification),
        "reason" => row["reason"] || "quality gate #{gate_id} requires review",
        "source_artifact_type" => report["source_artifact_type"],
        "source_artifact_id" => report["source_artifact_id"],
        "readiness_level" => report["readiness_level"],
        "import_classification" => classification,
        "quality_gate_report_id" => report["report_id"],
        "quality_gate_id" => gate_id,
        "quality_gate_status" => gate_status,
        "quality_gate_classification" => classification,
        "quality_gate_reason" => row["reason"],
        "readiness_gate_id" => gate_id,
        "readiness_gate_status" => gate_status,
        "readiness_gate_classification" => classification,
        "readiness_gate_reason" => row["reason"],
        "analysis_mode" => row["analysis_mode"],
        "analysis_mode_source" => row["analysis_mode_source"],
        "source_quality_gate_row" => row,
        "source_quality_gate_report" => quality_gate_report_context(report)
      }
      |> Map.merge(quality_gate_row_import_readiness_context(row))
      |> Map.merge(quality_gate_row_resource_context(row))
      |> Map.merge(quality_gate_row_operator_training_context(row))
      |> compact_map()
    end)
  end

  defp quality_gate_import_readiness_summary?(%{} = summary) do
    schema_contract = summary["schema_contract"] || summary[:schema_contract]
    model = summary["model"] || summary[:model]

    schema_contract in [nil, "operational_quality_gate_import_readiness_summary.v1"] and
      model == "artifact_only_quality_gate_import_readiness_summary"
  end

  defp quality_gate_import_readiness_summary?(_summary), do: false

  defp quality_gate_summary?(%{} = summary) do
    schema_contract = summary["schema_contract"] || summary[:schema_contract]
    model = summary["model"] || summary[:model]

    schema_contract in [nil, "operational_quality_gate_summary.v1"] and
      model == "artifact_only_quality_gate_summary"
  end

  defp quality_gate_summary?(_summary), do: false

  defp quality_gate_unavailable_resource_summary?(%{} = summary) do
    schema_contract = summary["schema_contract"] || summary[:schema_contract]
    model = summary["model"] || summary[:model]

    schema_contract in [nil, "operational_quality_gate_unavailable_resource_summary.v1"] and
      model == "artifact_only_quality_gate_unavailable_resource_summary"
  end

  defp quality_gate_unavailable_resource_summary?(_summary), do: false

  defp quality_gate_operator_training_summary?(%{} = summary) do
    schema_contract = summary["schema_contract"] || summary[:schema_contract]
    model = summary["model"] || summary[:model]

    schema_contract in [nil, "operational_quality_gate_operator_training_summary.v1"] and
      model == "artifact_only_quality_gate_operator_training_summary"
  end

  defp quality_gate_operator_training_summary?(_summary), do: false

  defp quality_gate_schema_validation_summary?(%{} = summary) do
    schema_contract = summary["schema_contract"] || summary[:schema_contract]
    model = summary["model"] || summary[:model]

    schema_contract in [nil, "operational_quality_gate_schema_validation_summary.v1"] and
      model == "artifact_only_quality_gate_schema_validation_summary"
  end

  defp quality_gate_schema_validation_summary?(_summary), do: false

  defp quality_gate_report_from_quality_gate_summary(%{} = summary) do
    summary = stringify_keys(summary)
    row_ids_by_status = Map.get(summary, "quality_gate_row_ids_by_status") || %{}
    gate_ids_by_status = Map.get(summary, "gate_ids_by_status") || %{}

    status =
      summary["status"] || quality_gate_import_readiness_status_from_row_ids(row_ids_by_status)

    classification =
      summary["import_classification"] || quality_gate_import_readiness_classification(status)

    %{
      "schema_contract" => "quality_gate_report.v1",
      "model" => "preserved_operational_quality_gate_summary",
      "report_id" =>
        summary["source_quality_gate_report_id"] ||
          summary["source_artifact_id"] ||
          "quality_gate:operational_quality_gate_summary",
      "source" => summary["source"],
      "source_summary_model" => summary["model"],
      "source_summary_schema_contract" => summary["schema_contract"],
      "source_artifact_type" => summary["source_artifact_type"],
      "source_artifact_id" => summary["source_artifact_id"],
      "source_quality_gate_report_id" => summary["source_quality_gate_report_id"],
      "source_readiness_report_id" => summary["source_readiness_report_id"],
      "readiness_level" =>
        summary["readiness_level"] || quality_gate_import_readiness_level(classification),
      "import_classification" => classification,
      "status" => status,
      "gate_count" =>
        summary["gate_count"] ||
          quality_gate_import_readiness_row_count(summary, row_ids_by_status),
      "passed_gate_count" =>
        summary["passed_gate_count"] ||
          length(quality_gate_import_readiness_row_ids(row_ids_by_status, summary, "passed")),
      "review_gate_count" =>
        summary["review_gate_count"] ||
          length(
            quality_gate_import_readiness_row_ids(row_ids_by_status, summary, "review_required")
          ),
      "analysis_gate_count" =>
        summary["analysis_gate_count"] ||
          length(
            quality_gate_import_readiness_row_ids(row_ids_by_status, summary, "analysis_only")
          ),
      "blocked_gate_count" =>
        summary["blocked_gate_count"] ||
          length(quality_gate_import_readiness_row_ids(row_ids_by_status, summary, "blocked")),
      "gate_status_counts" =>
        summary["gate_status_counts"] ||
          quality_gate_import_readiness_status_counts(row_ids_by_status),
      "gate_classification_counts" =>
        summary["gate_classification_counts"] ||
          quality_gate_import_readiness_classification_counts(row_ids_by_status),
      "gate_ids_by_status" => gate_ids_by_status,
      "gate_ids_by_classification" => summary["gate_ids_by_classification"],
      "quality_gate_row_ids_by_status" => row_ids_by_status,
      "quality_gate_row_ids_by_classification" =>
        summary["quality_gate_row_ids_by_classification"],
      "passed_gate_ids" =>
        summary["passed_gate_ids"] || quality_gate_summary_values(gate_ids_by_status, "passed"),
      "review_required_gate_ids" =>
        summary["review_required_gate_ids"] ||
          quality_gate_summary_values(gate_ids_by_status, "review_required"),
      "analysis_only_gate_ids" =>
        summary["analysis_only_gate_ids"] ||
          quality_gate_summary_values(gate_ids_by_status, "analysis_only"),
      "blocked_gate_ids" =>
        summary["blocked_gate_ids"] || quality_gate_summary_values(gate_ids_by_status, "blocked"),
      "non_passed_quality_gate_row_ids" => summary["non_passed_quality_gate_row_ids"],
      "non_passed_gate_ids" => summary["non_passed_gate_ids"],
      "non_passed_gate_count" => summary["non_passed_gate_count"],
      "non_passed_rows" => summary["non_passed_rows"],
      "trust_boundary" => summary["trust_boundary"],
      "trust_boundaries" => summary["trust_boundaries"],
      "model_limits" => summary["model_limits"],
      "assumptions" => summary["assumptions"],
      "rows" => quality_gate_summary_rows(summary)
    }
    |> maybe_put("provenance", summary["provenance"])
    |> compact_map()
  end

  defp quality_gate_summary_rows(summary) do
    rows = summary["rows"] || summary["non_passed_rows"] || []

    rows
    |> List.wrap()
    |> Enum.map(&stringify_keys/1)
    |> Enum.map(fn row ->
      row
      |> Map.put_new("source_summary_schema_contract", summary["schema_contract"])
      |> Map.put_new("source_summary_model", summary["model"])
    end)
  end

  defp quality_gate_report_from_schema_validation_summary(%{} = summary) do
    summary = stringify_keys(summary)
    row_ids_by_status = Map.get(summary, "quality_gate_row_ids_by_status") || %{}
    status = quality_gate_schema_validation_status(summary, row_ids_by_status)
    classification = quality_gate_import_readiness_classification(status)

    %{
      "schema_contract" => "quality_gate_report.v1",
      "model" => "preserved_operational_quality_gate_schema_validation_summary",
      "report_id" =>
        summary["source_quality_gate_report_id"] ||
          summary["source_artifact_id"] ||
          "quality_gate:schema_validation_summary",
      "source" => summary["source"],
      "source_summary_model" => summary["model"],
      "source_summary_schema_contract" => summary["schema_contract"],
      "source_artifact_type" => summary["source_artifact_type"],
      "source_artifact_id" => summary["source_artifact_id"],
      "source_readiness_report_id" => summary["source_readiness_report_id"],
      "readiness_level" => quality_gate_import_readiness_level(classification),
      "import_classification" => classification,
      "status" => status,
      "gate_count" =>
        quality_gate_import_readiness_row_count(
          %{"gate_count" => summary["schema_validation_row_count"]},
          row_ids_by_status
        ),
      "passed_gate_count" =>
        length(quality_gate_import_readiness_row_ids(row_ids_by_status, summary, "passed")),
      "review_gate_count" =>
        length(
          quality_gate_import_readiness_row_ids(row_ids_by_status, summary, "review_required")
        ),
      "analysis_gate_count" =>
        length(quality_gate_import_readiness_row_ids(row_ids_by_status, summary, "analysis_only")),
      "blocked_gate_count" =>
        length(quality_gate_import_readiness_row_ids(row_ids_by_status, summary, "blocked")),
      "gate_status_counts" => quality_gate_import_readiness_status_counts(row_ids_by_status),
      "gate_classification_counts" =>
        quality_gate_import_readiness_classification_counts(row_ids_by_status),
      "schema_validation_row_count" => summary["schema_validation_row_count"],
      "schema_validation_pass_count" => summary["schema_validation_pass_count"],
      "schema_validation_fail_count" => summary["schema_validation_fail_count"],
      "schema_validation_error_count" => summary["schema_validation_error_count"],
      "schema_validation_warning_count" => summary["schema_validation_warning_count"],
      "schema_validation_remediation_count" => summary["schema_validation_remediation_count"],
      "schema_validation_status_counts" => summary["schema_validation_status_counts"],
      "schema_validation_status_ids" => summary["schema_validation_status_ids"],
      "quality_gate_row_ids_by_status" => row_ids_by_status,
      "quality_gate_ids_by_status" => summary["quality_gate_ids_by_status"],
      "passed_gate_ids" => quality_gate_import_readiness_gate_ids(summary, "passed"),
      "review_required_gate_ids" =>
        quality_gate_import_readiness_gate_ids(summary, "review_required"),
      "analysis_only_gate_ids" =>
        quality_gate_import_readiness_gate_ids(summary, "analysis_only"),
      "blocked_gate_ids" => quality_gate_import_readiness_gate_ids(summary, "blocked"),
      "model_limits" => summary["model_limits"],
      "assumptions" => summary["assumptions"],
      "rows" => quality_gate_schema_validation_rows(summary, row_ids_by_status)
    }
    |> compact_map()
  end

  defp quality_gate_schema_validation_rows(summary, row_ids_by_status) do
    ["review_required", "analysis_only", "blocked"]
    |> Enum.flat_map(fn status ->
      row_ids = quality_gate_import_readiness_row_ids(row_ids_by_status, summary, status)
      gate_ids = quality_gate_import_readiness_gate_ids(summary, status)

      row_ids
      |> Enum.with_index()
      |> Enum.map(fn {row_id, index} ->
        gate_id =
          Enum.at(gate_ids, index) ||
            List.first(summary["schema_validation_gate_ids"] || []) ||
            "cadence_import"

        %{
          "id" => row_id,
          "gate_id" => gate_id,
          "status" => status,
          "classification" => quality_gate_import_readiness_classification(status),
          "reason" => quality_gate_schema_validation_reason(status),
          "source_summary_schema_contract" => summary["schema_contract"],
          "source_summary_model" => summary["model"],
          "schema_validation_pass_count" => summary["schema_validation_pass_count"],
          "schema_validation_fail_count" => summary["schema_validation_fail_count"],
          "schema_validation_error_count" => summary["schema_validation_error_count"],
          "schema_validation_warning_count" => summary["schema_validation_warning_count"],
          "schema_validation_remediation_count" => summary["schema_validation_remediation_count"],
          "schema_validation_status_counts" => summary["schema_validation_status_counts"]
        }
        |> compact_map()
      end)
    end)
  end

  defp quality_gate_schema_validation_status(summary, row_ids_by_status) do
    cond do
      quality_gate_summary_values(row_ids_by_status, "blocked") != [] or
          summary["schema_validation_import_blocked"] == true ->
        "blocked"

      quality_gate_summary_values(row_ids_by_status, "analysis_only") != [] ->
        "analysis_only"

      quality_gate_summary_values(row_ids_by_status, "review_required") != [] ->
        "review_required"

      true ->
        "passed"
    end
  end

  defp quality_gate_schema_validation_reason("blocked"),
    do: "schema validation quality gate is blocked"

  defp quality_gate_schema_validation_reason("analysis_only"),
    do: "schema validation quality gate is analysis-only"

  defp quality_gate_schema_validation_reason(_status),
    do: "schema validation quality gate requires review"

  defp quality_gate_report_from_operator_training_summary(%{} = summary) do
    summary = stringify_keys(summary)
    row_ids_by_status = Map.get(summary, "quality_gate_row_ids_by_status") || %{}
    status = quality_gate_import_readiness_status_from_row_ids(row_ids_by_status)
    classification = quality_gate_import_readiness_classification(status)

    %{
      "schema_contract" => "quality_gate_report.v1",
      "model" => "preserved_operational_quality_gate_operator_training_summary",
      "report_id" =>
        summary["source_quality_gate_report_id"] ||
          summary["source_artifact_id"] ||
          "quality_gate:operator_training_summary",
      "source" => summary["source"],
      "source_summary_model" => summary["model"],
      "source_summary_schema_contract" => summary["schema_contract"],
      "source_artifact_type" => summary["source_artifact_type"],
      "source_artifact_id" => summary["source_artifact_id"],
      "source_readiness_report_id" => summary["source_readiness_report_id"],
      "readiness_level" => quality_gate_import_readiness_level(classification),
      "import_classification" => classification,
      "status" => status,
      "gate_count" =>
        quality_gate_import_readiness_row_count(
          %{"gate_count" => summary["operator_training_row_count"]},
          row_ids_by_status
        ),
      "passed_gate_count" =>
        length(quality_gate_import_readiness_row_ids(row_ids_by_status, summary, "passed")),
      "review_gate_count" =>
        length(
          quality_gate_import_readiness_row_ids(row_ids_by_status, summary, "review_required")
        ),
      "analysis_gate_count" =>
        length(quality_gate_import_readiness_row_ids(row_ids_by_status, summary, "analysis_only")),
      "blocked_gate_count" =>
        length(quality_gate_import_readiness_row_ids(row_ids_by_status, summary, "blocked")),
      "gate_status_counts" => quality_gate_import_readiness_status_counts(row_ids_by_status),
      "gate_classification_counts" =>
        quality_gate_import_readiness_classification_counts(row_ids_by_status),
      "operator_training_row_count" => summary["operator_training_row_count"],
      "operator_training_requirement_count" => summary["operator_training_requirement_count"],
      "operator_training_requirement_counts" => summary["operator_training_requirement_counts"],
      "operator_training_requirement_ids" => summary["operator_training_requirement_ids"],
      "required_operator_roles" => summary["required_operator_roles"],
      "required_training_ids" => summary["required_training_ids"],
      "required_certification_ids" => summary["required_certification_ids"],
      "required_qualification_ids" => summary["required_qualification_ids"],
      "quality_gate_row_ids_by_status" => row_ids_by_status,
      "quality_gate_row_ids_by_classification" =>
        summary["quality_gate_row_ids_by_classification"],
      "quality_gate_ids_by_status" => summary["quality_gate_ids_by_status"],
      "quality_gate_ids_by_classification" => summary["quality_gate_ids_by_classification"],
      "passed_gate_ids" => quality_gate_import_readiness_gate_ids(summary, "passed"),
      "review_required_gate_ids" =>
        quality_gate_import_readiness_gate_ids(summary, "review_required"),
      "analysis_only_gate_ids" =>
        quality_gate_import_readiness_gate_ids(summary, "analysis_only"),
      "blocked_gate_ids" => quality_gate_import_readiness_gate_ids(summary, "blocked"),
      "model_limits" => summary["model_limits"],
      "assumptions" => summary["assumptions"],
      "rows" => quality_gate_operator_training_rows(summary, row_ids_by_status)
    }
    |> compact_map()
  end

  defp quality_gate_operator_training_rows(summary, row_ids_by_status) do
    ["review_required", "analysis_only", "blocked"]
    |> Enum.flat_map(fn status ->
      row_ids = quality_gate_import_readiness_row_ids(row_ids_by_status, summary, status)
      gate_ids = quality_gate_import_readiness_gate_ids(summary, status)

      row_ids
      |> Enum.with_index()
      |> Enum.map(fn {row_id, index} ->
        gate_id =
          Enum.at(gate_ids, index) ||
            List.first(summary["operator_training_gate_ids"] || []) ||
            "operator_training"

        %{
          "id" => row_id,
          "gate_id" => gate_id,
          "status" => status,
          "classification" => quality_gate_import_readiness_classification(status),
          "reason" => quality_gate_operator_training_reason(status),
          "source_summary_schema_contract" => summary["schema_contract"],
          "source_summary_model" => summary["model"],
          "operator_training_requirement_count" => summary["operator_training_requirement_count"],
          "operator_training_requirement_counts" =>
            summary["operator_training_requirement_counts"],
          "operator_training_requirement_ids" => summary["operator_training_requirement_ids"],
          "required_operator_roles" => summary["required_operator_roles"],
          "required_training_ids" => summary["required_training_ids"],
          "required_certification_ids" => summary["required_certification_ids"],
          "required_qualification_ids" => summary["required_qualification_ids"]
        }
        |> compact_map()
      end)
    end)
  end

  defp quality_gate_operator_training_reason("blocked"),
    do: "operator training quality gate is blocked"

  defp quality_gate_operator_training_reason("analysis_only"),
    do: "operator training quality gate is analysis-only"

  defp quality_gate_operator_training_reason(_status),
    do: "operator training quality gate requires review"

  defp quality_gate_report_from_unavailable_resource_summary(%{} = summary) do
    summary = stringify_keys(summary)
    row_ids_by_status = Map.get(summary, "quality_gate_row_ids_by_status") || %{}
    status = quality_gate_import_readiness_status_from_row_ids(row_ids_by_status)
    classification = quality_gate_import_readiness_classification(status)
    reason_counts = quality_gate_unavailable_resource_reason_counts(summary)

    %{
      "schema_contract" => "quality_gate_report.v1",
      "model" => "preserved_operational_quality_gate_unavailable_resource_summary",
      "report_id" =>
        summary["source_quality_gate_report_id"] ||
          summary["source_artifact_id"] ||
          "quality_gate:unavailable_resource_summary",
      "source" => summary["source"],
      "source_summary_model" => summary["model"],
      "source_summary_schema_contract" => summary["schema_contract"],
      "source_artifact_type" => summary["source_artifact_type"],
      "source_artifact_id" => summary["source_artifact_id"],
      "source_readiness_report_id" => summary["source_readiness_report_id"],
      "readiness_level" => quality_gate_import_readiness_level(classification),
      "import_classification" => classification,
      "status" => status,
      "gate_count" =>
        quality_gate_import_readiness_row_count(
          %{"gate_count" => summary["resource_availability_row_count"]},
          row_ids_by_status
        ),
      "passed_gate_count" =>
        length(quality_gate_import_readiness_row_ids(row_ids_by_status, summary, "passed")),
      "review_gate_count" =>
        length(
          quality_gate_import_readiness_row_ids(row_ids_by_status, summary, "review_required")
        ),
      "analysis_gate_count" =>
        length(quality_gate_import_readiness_row_ids(row_ids_by_status, summary, "analysis_only")),
      "blocked_gate_count" =>
        length(quality_gate_import_readiness_row_ids(row_ids_by_status, summary, "blocked")),
      "gate_status_counts" => quality_gate_import_readiness_status_counts(row_ids_by_status),
      "gate_classification_counts" =>
        quality_gate_import_readiness_classification_counts(row_ids_by_status),
      "resource_availability_pressure_count" =>
        quality_gate_unavailable_resource_pressure_count(reason_counts),
      "resource_availability_reason_counts" => reason_counts,
      "resource_availability_reason_ids" => Map.keys(reason_counts) |> Enum.sort(),
      "station_availability_reason_counts" => summary["station_availability_reason_counts"],
      "station_availability_reason_ids" => summary["station_availability_reason_ids"],
      "unavailable_resource_reason_ids" => summary["unavailable_resource_reason_ids"],
      "resource_blocking_dimension_counts" => summary["resource_blocking_dimension_counts"],
      "resource_blocked_contact_ids_by_blocking_dimension" =>
        summary["blocked_contact_ids_by_blocking_dimension"],
      "resource_blocked_contact_ids_by_spacecraft_id" =>
        summary["blocked_contact_ids_by_spacecraft_id"],
      "quality_gate_row_ids_by_status" => row_ids_by_status,
      "quality_gate_ids_by_status" => summary["quality_gate_ids_by_status"],
      "passed_gate_ids" => quality_gate_import_readiness_gate_ids(summary, "passed"),
      "review_required_gate_ids" =>
        quality_gate_import_readiness_gate_ids(summary, "review_required"),
      "analysis_only_gate_ids" =>
        quality_gate_import_readiness_gate_ids(summary, "analysis_only"),
      "blocked_gate_ids" => quality_gate_import_readiness_gate_ids(summary, "blocked"),
      "model_limits" => summary["model_limits"],
      "assumptions" => summary["assumptions"],
      "rows" => quality_gate_unavailable_resource_rows(summary, row_ids_by_status, reason_counts)
    }
    |> compact_map()
  end

  defp quality_gate_unavailable_resource_rows(summary, row_ids_by_status, reason_counts) do
    ["review_required", "analysis_only", "blocked"]
    |> Enum.flat_map(fn status ->
      row_ids = quality_gate_import_readiness_row_ids(row_ids_by_status, summary, status)
      gate_ids = quality_gate_import_readiness_gate_ids(summary, status)

      row_ids
      |> Enum.with_index()
      |> Enum.map(fn {row_id, index} ->
        gate_id =
          Enum.at(gate_ids, index) ||
            List.first(summary["resource_availability_gate_ids"] || []) ||
            "resource_availability"

        %{
          "id" => row_id,
          "gate_id" => gate_id,
          "status" => status,
          "classification" => quality_gate_import_readiness_classification(status),
          "reason" => quality_gate_unavailable_resource_reason(status),
          "source_summary_schema_contract" => summary["schema_contract"],
          "source_summary_model" => summary["model"],
          "resource_availability_pressure_count" =>
            quality_gate_unavailable_resource_pressure_count(reason_counts),
          "resource_availability_reason_counts" => reason_counts,
          "resource_availability_reason_ids" => Map.keys(reason_counts) |> Enum.sort(),
          "station_availability_reason_counts" => summary["station_availability_reason_counts"],
          "station_availability_reason_ids" => summary["station_availability_reason_ids"],
          "unavailable_resource_reason_ids" => summary["unavailable_resource_reason_ids"],
          "resource_blocking_dimension_counts" => summary["resource_blocking_dimension_counts"],
          "resource_blocked_contact_ids_by_blocking_dimension" =>
            summary["blocked_contact_ids_by_blocking_dimension"],
          "resource_blocked_contact_ids_by_spacecraft_id" =>
            summary["blocked_contact_ids_by_spacecraft_id"],
          "resource_blocked_contact_ids_by_status" => summary["blocked_contact_ids_by_status"]
        }
        |> compact_map()
      end)
    end)
  end

  defp quality_gate_unavailable_resource_reason_counts(summary) do
    [
      summary["unavailable_resource_reason_counts"],
      summary["station_availability_reason_counts"]
    ]
    |> Enum.reduce(%{}, fn
      %{} = counts, acc ->
        Enum.reduce(counts, acc, fn {reason, count}, reason_counts ->
          Map.update(reason_counts, reason, count, &(&1 + count))
        end)

      _counts, acc ->
        acc
    end)
  end

  defp quality_gate_unavailable_resource_pressure_count(reason_counts) do
    reason_counts
    |> Map.values()
    |> Enum.filter(&is_number/1)
    |> Enum.sum()
  end

  defp quality_gate_unavailable_resource_reason("blocked"),
    do: "resource availability quality gate is blocked"

  defp quality_gate_unavailable_resource_reason("analysis_only"),
    do: "resource availability quality gate is analysis-only"

  defp quality_gate_unavailable_resource_reason(_status),
    do: "resource availability quality gate requires review"

  defp quality_gate_report_from_import_readiness_summary(%{} = summary) do
    summary = stringify_keys(summary)
    row_ids_by_status = Map.get(summary, "quality_gate_row_ids_by_status") || %{}
    status = quality_gate_import_readiness_status(summary)
    classification = quality_gate_import_readiness_classification(status)

    %{
      "schema_contract" => "quality_gate_report.v1",
      "model" => "preserved_operational_quality_gate_import_readiness_summary",
      "report_id" =>
        summary["source_quality_gate_report_id"] ||
          summary["source_artifact_id"] ||
          "quality_gate:import_readiness_summary",
      "source" => summary["source"],
      "source_summary_model" => summary["model"],
      "source_summary_schema_contract" => summary["schema_contract"],
      "source_artifact_type" => summary["source_artifact_type"],
      "source_artifact_id" => summary["source_artifact_id"],
      "source_readiness_report_id" => summary["source_readiness_report_id"],
      "readiness_level" => quality_gate_import_readiness_level(classification),
      "import_classification" => classification,
      "status" => status,
      "gate_count" => quality_gate_import_readiness_row_count(summary, row_ids_by_status),
      "passed_gate_count" =>
        length(quality_gate_import_readiness_row_ids(row_ids_by_status, summary, "passed")),
      "review_gate_count" =>
        length(
          quality_gate_import_readiness_row_ids(row_ids_by_status, summary, "review_required")
        ),
      "analysis_gate_count" =>
        length(quality_gate_import_readiness_row_ids(row_ids_by_status, summary, "analysis_only")),
      "blocked_gate_count" =>
        length(quality_gate_import_readiness_row_ids(row_ids_by_status, summary, "blocked")),
      "gate_status_counts" => quality_gate_import_readiness_status_counts(row_ids_by_status),
      "gate_classification_counts" =>
        quality_gate_import_readiness_classification_counts(row_ids_by_status),
      "gate_ids_by_status" => summary["quality_gate_ids_by_status"],
      "quality_gate_row_ids_by_status" => row_ids_by_status,
      "passed_gate_ids" => quality_gate_import_readiness_gate_ids(summary, "passed"),
      "review_required_gate_ids" =>
        quality_gate_import_readiness_gate_ids(summary, "review_required"),
      "analysis_only_gate_ids" =>
        quality_gate_import_readiness_gate_ids(summary, "analysis_only"),
      "blocked_gate_ids" => quality_gate_import_readiness_gate_ids(summary, "blocked"),
      "assumptions" => summary["assumptions"],
      "rows" => quality_gate_import_readiness_rows(summary, row_ids_by_status)
    }
    |> compact_map()
  end

  defp quality_gate_import_readiness_rows(summary, row_ids_by_status) do
    ["review_required", "analysis_only", "blocked"]
    |> Enum.flat_map(fn status ->
      row_ids = quality_gate_import_readiness_row_ids(row_ids_by_status, summary, status)
      gate_ids = quality_gate_import_readiness_gate_ids(summary, status)

      row_ids
      |> Enum.with_index()
      |> Enum.map(fn {row_id, index} ->
        gate_id =
          Enum.at(gate_ids, index) || List.first(summary["import_readiness_gate_ids"] || [])

        gate_id = gate_id || "cadence_import"

        %{
          "id" => row_id,
          "gate_id" => gate_id,
          "status" => status,
          "classification" => quality_gate_import_readiness_classification(status),
          "reason" => quality_gate_import_readiness_reason(status),
          "source_summary_schema_contract" => summary["schema_contract"],
          "source_summary_model" => summary["model"]
        }
        |> Map.merge(quality_gate_import_readiness_row_context(summary, gate_id))
        |> compact_map()
      end)
    end)
  end

  defp quality_gate_import_readiness_row_context(summary, "cadence_import") do
    Map.take(summary, [
      "ready_for_import_count",
      "manifest_review_required_count",
      "blocked_import_count",
      "missing_import_count",
      "invalid_cadence_import_count",
      "current_freshness_count",
      "stale_freshness_count",
      "unknown_freshness_count",
      "freshness_status_counts",
      "schema_validation_pass_count",
      "schema_validation_fail_count",
      "schema_validation_error_count",
      "schema_validation_warning_count",
      "schema_validation_remediation_count",
      "schema_validation_status_counts",
      "import_status_counts",
      "cadence_import_status_counts"
    ])
  end

  defp quality_gate_import_readiness_row_context(_summary, _gate_id), do: %{}

  defp quality_gate_import_readiness_status(%{} = summary) do
    case quality_gate_import_readiness_status_from_row_ids(
           summary["quality_gate_row_ids_by_status"]
         ) do
      nil -> quality_gate_import_readiness_status_from_summary(summary)
      status -> status
    end
  end

  defp quality_gate_import_readiness_status_from_summary(%{} = summary) do
    cond do
      quality_gate_import_readiness_values(summary["blocked_quality_gate_row_ids"]) != [] or
        positive_report_count?(summary, "blocked_import_count") or
          positive_report_count?(summary, "invalid_cadence_import_count") ->
        "blocked"

      quality_gate_import_readiness_values(summary["analysis_only_quality_gate_row_ids"]) != [] ->
        "analysis_only"

      quality_gate_import_readiness_values(summary["review_required_quality_gate_row_ids"]) != [] or
        quality_gate_import_readiness_values(
          summary["stale_or_unknown_freshness_quality_gate_row_ids"]
        ) != [] or
        quality_gate_import_readiness_values(summary["import_preparation_quality_gate_row_ids"]) !=
          [] or
        positive_report_count?(summary, "manifest_review_required_count") or
        positive_report_count?(summary, "stale_freshness_count") or
          positive_report_count?(summary, "unknown_freshness_count") ->
        "review_required"

      true ->
        "passed"
    end
  end

  defp quality_gate_import_readiness_status_from_row_ids(%{} = row_ids_by_status) do
    cond do
      quality_gate_summary_values(row_ids_by_status, "blocked") != [] -> "blocked"
      quality_gate_summary_values(row_ids_by_status, "analysis_only") != [] -> "analysis_only"
      quality_gate_summary_values(row_ids_by_status, "review_required") != [] -> "review_required"
      true -> "passed"
    end
  end

  defp quality_gate_import_readiness_status_from_row_ids(_row_ids_by_status), do: nil

  defp quality_gate_import_readiness_row_ids(%{} = row_ids_by_status, _summary, status) do
    quality_gate_summary_values(row_ids_by_status, status)
  end

  defp quality_gate_import_readiness_row_ids(_row_ids_by_status, summary, "passed"),
    do: quality_gate_import_readiness_values(summary["ready_quality_gate_row_ids"])

  defp quality_gate_import_readiness_row_ids(_row_ids_by_status, summary, "review_required"),
    do: quality_gate_import_readiness_values(summary["review_required_quality_gate_row_ids"])

  defp quality_gate_import_readiness_row_ids(_row_ids_by_status, summary, "analysis_only"),
    do: quality_gate_import_readiness_values(summary["analysis_only_quality_gate_row_ids"])

  defp quality_gate_import_readiness_row_ids(_row_ids_by_status, summary, "blocked"),
    do: quality_gate_import_readiness_values(summary["blocked_quality_gate_row_ids"])

  defp quality_gate_import_readiness_row_count(_summary, %{} = row_ids_by_status) do
    row_ids_by_status
    |> Map.values()
    |> Enum.flat_map(&quality_gate_import_readiness_values/1)
    |> length()
  end

  defp quality_gate_import_readiness_row_count(summary, _row_ids_by_status),
    do: summary["import_readiness_row_count"] || summary["gate_count"]

  defp quality_gate_import_readiness_gate_ids(summary, status) do
    case quality_gate_summary_values(summary["quality_gate_ids_by_status"], status) do
      [] ->
        if quality_gate_import_readiness_row_ids(
             summary["quality_gate_row_ids_by_status"],
             summary,
             status
           ) == [] do
          []
        else
          summary["import_readiness_gate_ids"] || []
        end

      gate_ids ->
        gate_ids
    end
  end

  defp quality_gate_import_readiness_status_counts(%{} = row_ids_by_status) do
    row_ids_by_status
    |> Enum.map(fn {status, row_ids} ->
      {to_string(status), length(quality_gate_import_readiness_values(row_ids))}
    end)
    |> Enum.reject(fn {_status, count} -> count == 0 end)
    |> Map.new()
  end

  defp quality_gate_import_readiness_status_counts(_row_ids_by_status), do: %{}

  defp quality_gate_import_readiness_classification_counts(%{} = row_ids_by_status) do
    row_ids_by_status
    |> Enum.reduce(%{}, fn {status, row_ids}, counts ->
      classification = quality_gate_import_readiness_classification(to_string(status))
      count = length(quality_gate_import_readiness_values(row_ids))
      Map.update(counts, classification, count, &(&1 + count))
    end)
    |> Enum.reject(fn {_classification, count} -> count == 0 end)
    |> Map.new()
  end

  defp quality_gate_import_readiness_classification_counts(_row_ids_by_status), do: %{}

  defp quality_gate_import_readiness_classification("blocked"), do: "blocked"
  defp quality_gate_import_readiness_classification("analysis_only"), do: "analysis_only"
  defp quality_gate_import_readiness_classification("review_required"), do: "review_only"
  defp quality_gate_import_readiness_classification(_status), do: "importable"

  defp quality_gate_import_readiness_level("blocked"), do: "blocked"
  defp quality_gate_import_readiness_level("analysis_only"), do: "analysis_only"
  defp quality_gate_import_readiness_level("review_only"), do: "operator_review"
  defp quality_gate_import_readiness_level(_classification), do: "import_eligible"

  defp quality_gate_import_readiness_reason("blocked"),
    do: "quality gate import readiness is blocked"

  defp quality_gate_import_readiness_reason("analysis_only"),
    do: "quality gate import readiness is analysis-only"

  defp quality_gate_import_readiness_reason(_status),
    do: "quality gate import readiness requires review"

  defp quality_gate_summary_values(%{} = values_by_key, key) do
    values_by_key
    |> Map.get(key, Map.get(values_by_key, String.to_atom(key), []))
    |> quality_gate_import_readiness_values()
  end

  defp quality_gate_summary_values(_values_by_key, _key), do: []

  defp quality_gate_import_readiness_values(values) when is_list(values), do: values
  defp quality_gate_import_readiness_values(_values), do: []

  defp positive_report_count?(summary, field) do
    case numeric_or_nil(summary[field]) do
      nil -> false
      value -> value > 0
    end
  end

  defp quality_gate_reviewable_row?(%{} = row),
    do: (row["status"] || row["classification"]) not in [nil, "passed", "importable"]

  defp quality_gate_reviewable_row?(_row), do: false

  defp quality_gate_action("analysis_only"), do: "record_quality_gate_analysis_only"
  defp quality_gate_action("blocked"), do: "review_blocked_quality_gate"
  defp quality_gate_action(_classification), do: "review_quality_gate"

  defp quality_gate_approval_status("analysis_only"), do: "not_required"
  defp quality_gate_approval_status("blocked"), do: "blocked_by_policy"
  defp quality_gate_approval_status(_classification), do: "operator_review_required"

  defp quality_gate_cadence_import_status("analysis_only"), do: "not_applicable"
  defp quality_gate_cadence_import_status(_classification), do: "present"

  defp quality_gate_row_import_readiness_context(%{"gate_id" => "cadence_import"} = row) do
    Map.take(row, [
      "ready_for_import_count",
      "manifest_review_required_count",
      "blocked_import_count",
      "missing_import_count",
      "invalid_cadence_import_count",
      "current_freshness_count",
      "stale_freshness_count",
      "unknown_freshness_count",
      "freshness_status_counts",
      "schema_validation_pass_count",
      "schema_validation_fail_count",
      "schema_validation_error_count",
      "schema_validation_warning_count",
      "schema_validation_remediation_count",
      "schema_validation_status_counts",
      "import_status_counts",
      "cadence_import_status_counts"
    ])
  end

  defp quality_gate_row_import_readiness_context(_row), do: %{}

  defp quality_gate_row_resource_context(row) do
    reason_counts = Map.get(row, "resource_availability_reason_counts") || %{}

    %{
      "resource_availability_pressure_count" => row["resource_availability_pressure_count"],
      "resource_availability_reason_counts" => reason_counts,
      "resource_availability_reason_ids" =>
        row["resource_availability_reason_ids"] ||
          operational_readiness_non_empty_list(operational_readiness_count_keys(reason_counts)),
      "station_availability_reason_ids" =>
        row["station_availability_reason_ids"] ||
          operational_readiness_non_empty_list(
            operational_readiness_station_reason_ids(reason_counts)
          ),
      "station_availability_reason_counts" =>
        row["station_availability_reason_counts"] ||
          non_empty_map(operational_readiness_station_reason_counts(reason_counts)),
      "unavailable_resource_reason_ids" =>
        row["unavailable_resource_reason_ids"] ||
          operational_readiness_non_empty_list(
            operational_readiness_unavailable_reason_ids(reason_counts)
          ),
      "resource_blocking_dimension_counts" => row["resource_blocking_dimension_counts"],
      "resource_blocked_contact_ids_by_blocking_dimension" =>
        row["resource_blocked_contact_ids_by_blocking_dimension"],
      "resource_blocked_contact_ids_by_spacecraft_id" =>
        row["resource_blocked_contact_ids_by_spacecraft_id"],
      "resource_source_quality_counts" => row["resource_source_quality_counts"],
      "resource_trust_boundary_status_counts" => row["resource_trust_boundary_status_counts"]
    }
  end

  defp quality_gate_row_operator_training_context(%{"gate_id" => "operator_training"} = row) do
    Map.take(row, [
      "operator_training_requirement_count",
      "operator_training_requirement_counts",
      "operator_training_requirement_ids",
      "required_operator_roles",
      "required_training_ids",
      "required_certification_ids",
      "required_qualification_ids"
    ])
  end

  defp quality_gate_row_operator_training_context(_row), do: %{}

  defp quality_gate_report_context(report) do
    Map.take(report, [
      "schema_contract",
      "report_id",
      "source_summary_model",
      "source_summary_schema_contract",
      "source_artifact_type",
      "source_artifact_id",
      "source_quality_gate_report_id",
      "source_readiness_report_id",
      "readiness_level",
      "import_classification",
      "status",
      "gate_count",
      "passed_gate_count",
      "review_gate_count",
      "analysis_gate_count",
      "blocked_gate_count",
      "gate_status_counts",
      "gate_classification_counts",
      "gate_ids_by_status",
      "gate_ids_by_classification",
      "quality_gate_row_ids_by_status",
      "quality_gate_row_ids_by_classification",
      "passed_gate_ids",
      "review_required_gate_ids",
      "analysis_only_gate_ids",
      "blocked_gate_ids",
      "non_passed_quality_gate_row_ids",
      "non_passed_gate_ids",
      "non_passed_gate_count",
      "model_limits",
      "assumptions"
    ])
  end

  def put_report_summary(package, report) do
    report = stringify_keys(report || %{})

    Map.merge(package, quality_gate_report_summary_context(report))
  end

  defp quality_gate_report_summary_context(report) do
    Map.take(report, [
      "source_readiness_report_id",
      "readiness_level",
      "import_classification",
      "status",
      "gate_count",
      "passed_gate_count",
      "review_gate_count",
      "analysis_gate_count",
      "blocked_gate_count",
      "gate_status_counts",
      "gate_classification_counts",
      "gate_ids_by_status",
      "gate_ids_by_classification",
      "quality_gate_row_ids_by_status",
      "quality_gate_row_ids_by_classification",
      "passed_gate_ids",
      "review_required_gate_ids",
      "analysis_only_gate_ids",
      "blocked_gate_ids"
    ])
  end

  def candidate_refresh_rows(artifact) do
    direct_rows =
      [
        {"candidate_refresh.accepted_planning_state.source_quality_gate_report",
         get_in(artifact, ["accepted_planning_state", "source_quality_gate_report"])},
        {"candidate_refresh.accepted_planning_state.quality_gate_report",
         get_in(artifact, ["accepted_planning_state", "quality_gate_report"])},
        {"candidate_refresh.accepted_planning_state.source_operational_quality_gate_import_readiness_summary",
         get_in(artifact, [
           "accepted_planning_state",
           "source_operational_quality_gate_import_readiness_summary"
         ])},
        {"candidate_refresh.accepted_planning_state.operational_quality_gate_import_readiness_summary",
         get_in(artifact, [
           "accepted_planning_state",
           "operational_quality_gate_import_readiness_summary"
         ])},
        {"candidate_refresh.accepted_planning_state.source_operational_quality_gate_summary",
         get_in(artifact, [
           "accepted_planning_state",
           "source_operational_quality_gate_summary"
         ])},
        {"candidate_refresh.accepted_planning_state.operational_quality_gate_summary",
         get_in(artifact, [
           "accepted_planning_state",
           "operational_quality_gate_summary"
         ])},
        {"candidate_refresh.accepted_planning_state.source_operational_quality_gate_unavailable_resource_summary",
         get_in(artifact, [
           "accepted_planning_state",
           "source_operational_quality_gate_unavailable_resource_summary"
         ])},
        {"candidate_refresh.accepted_planning_state.operational_quality_gate_unavailable_resource_summary",
         get_in(artifact, [
           "accepted_planning_state",
           "operational_quality_gate_unavailable_resource_summary"
         ])},
        {"candidate_refresh.accepted_planning_state.source_operational_quality_gate_operator_training_summary",
         get_in(artifact, [
           "accepted_planning_state",
           "source_operational_quality_gate_operator_training_summary"
         ])},
        {"candidate_refresh.accepted_planning_state.operational_quality_gate_operator_training_summary",
         get_in(artifact, [
           "accepted_planning_state",
           "operational_quality_gate_operator_training_summary"
         ])},
        {"candidate_refresh.accepted_planning_state.source_operational_quality_gate_schema_validation_summary",
         get_in(artifact, [
           "accepted_planning_state",
           "source_operational_quality_gate_schema_validation_summary"
         ])},
        {"candidate_refresh.accepted_planning_state.operational_quality_gate_schema_validation_summary",
         get_in(artifact, [
           "accepted_planning_state",
           "operational_quality_gate_schema_validation_summary"
         ])},
        {"candidate_refresh.mission_state.source_quality_gate_report",
         get_in(artifact, ["mission_state", "source_quality_gate_report"])},
        {"candidate_refresh.mission_state.quality_gate_report",
         get_in(artifact, ["mission_state", "quality_gate_report"])},
        {"candidate_refresh.mission_state.source_operational_quality_gate_import_readiness_summary",
         get_in(artifact, [
           "mission_state",
           "source_operational_quality_gate_import_readiness_summary"
         ])},
        {"candidate_refresh.mission_state.operational_quality_gate_import_readiness_summary",
         get_in(artifact, [
           "mission_state",
           "operational_quality_gate_import_readiness_summary"
         ])},
        {"candidate_refresh.mission_state.source_operational_quality_gate_summary",
         get_in(artifact, [
           "mission_state",
           "source_operational_quality_gate_summary"
         ])},
        {"candidate_refresh.mission_state.operational_quality_gate_summary",
         get_in(artifact, [
           "mission_state",
           "operational_quality_gate_summary"
         ])},
        {"candidate_refresh.mission_state.source_operational_quality_gate_unavailable_resource_summary",
         get_in(artifact, [
           "mission_state",
           "source_operational_quality_gate_unavailable_resource_summary"
         ])},
        {"candidate_refresh.mission_state.operational_quality_gate_unavailable_resource_summary",
         get_in(artifact, [
           "mission_state",
           "operational_quality_gate_unavailable_resource_summary"
         ])},
        {"candidate_refresh.mission_state.source_operational_quality_gate_operator_training_summary",
         get_in(artifact, [
           "mission_state",
           "source_operational_quality_gate_operator_training_summary"
         ])},
        {"candidate_refresh.mission_state.operational_quality_gate_operator_training_summary",
         get_in(artifact, [
           "mission_state",
           "operational_quality_gate_operator_training_summary"
         ])},
        {"candidate_refresh.mission_state.source_operational_quality_gate_schema_validation_summary",
         get_in(artifact, [
           "mission_state",
           "source_operational_quality_gate_schema_validation_summary"
         ])},
        {"candidate_refresh.mission_state.operational_quality_gate_schema_validation_summary",
         get_in(artifact, [
           "mission_state",
           "operational_quality_gate_schema_validation_summary"
         ])},
        {"candidate_refresh.source_quality_gate_report", artifact["source_quality_gate_report"]},
        {"candidate_refresh.quality_gate_report", artifact["quality_gate_report"]},
        {"candidate_refresh.source_operational_quality_gate_import_readiness_summary",
         artifact["source_operational_quality_gate_import_readiness_summary"]},
        {"candidate_refresh.operational_quality_gate_import_readiness_summary",
         artifact["operational_quality_gate_import_readiness_summary"]},
        {"candidate_refresh.source_operational_quality_gate_summary",
         artifact["source_operational_quality_gate_summary"]},
        {"candidate_refresh.operational_quality_gate_summary",
         artifact["operational_quality_gate_summary"]},
        {"candidate_refresh.source_operational_quality_gate_unavailable_resource_summary",
         artifact["source_operational_quality_gate_unavailable_resource_summary"]},
        {"candidate_refresh.operational_quality_gate_unavailable_resource_summary",
         artifact["operational_quality_gate_unavailable_resource_summary"]},
        {"candidate_refresh.source_operational_quality_gate_operator_training_summary",
         artifact["source_operational_quality_gate_operator_training_summary"]},
        {"candidate_refresh.operational_quality_gate_operator_training_summary",
         artifact["operational_quality_gate_operator_training_summary"]},
        {"candidate_refresh.source_operational_quality_gate_schema_validation_summary",
         artifact["source_operational_quality_gate_schema_validation_summary"]},
        {"candidate_refresh.operational_quality_gate_schema_validation_summary",
         artifact["operational_quality_gate_schema_validation_summary"]}
      ]
      |> Enum.flat_map(fn {source, report_or_reports} ->
        source_report_rows(report_or_reports, source)
      end)

    direct_rows ++ candidate_refresh_result_artifact_rows(artifact)
  end

  def source_report_rows(reports, source) when is_list(reports) do
    reports
    |> Enum.with_index()
    |> Enum.flat_map(fn {report, index} ->
      source_report_rows(report, "#{source}[#{index}]")
    end)
  end

  def source_report_rows(%{} = report, source) do
    report = stringify_keys(report)

    cond do
      quality_gate_import_readiness_summary?(report) ->
        report
        |> quality_gate_report_from_import_readiness_summary()
        |> rows(source)

      quality_gate_summary?(report) ->
        report
        |> quality_gate_report_from_quality_gate_summary()
        |> rows("#{source}.rows")

      quality_gate_unavailable_resource_summary?(report) ->
        report
        |> quality_gate_report_from_unavailable_resource_summary()
        |> rows(source)

      quality_gate_operator_training_summary?(report) ->
        report
        |> quality_gate_report_from_operator_training_summary()
        |> rows(source)

      quality_gate_schema_validation_summary?(report) ->
        report
        |> quality_gate_report_from_schema_validation_summary()
        |> rows(source)

      true ->
        rows(report, "#{source}.rows")
    end
  end

  def source_report_rows(_report, _source), do: []

  defp candidate_refresh_result_artifact_rows(artifact) do
    [
      {"candidate_refresh.source_result_artifact", artifact["source_result_artifact"]},
      {"candidate_refresh.result_artifact", artifact["result_artifact"]}
    ]
    |> Enum.flat_map(fn {source, artifact_or_artifacts} ->
      result_artifact_rows(artifact_or_artifacts, source)
    end)
  end

  defp result_artifact_rows(artifacts, source) when is_list(artifacts) do
    artifacts
    |> Enum.with_index()
    |> Enum.flat_map(fn {artifact, index} ->
      result_artifact_rows(artifact, "#{source}[#{index}]")
    end)
  end

  defp result_artifact_rows(
         %{"schema_contract" => "quality_gate_report.v1"} = report,
         source
       ) do
    source_report_rows(report, source)
  end

  defp result_artifact_rows(%{} = artifact, source) do
    artifact = stringify_keys(artifact)

    [
      {"#{source}.source_quality_gate_report", artifact["source_quality_gate_report"]},
      {"#{source}.quality_gate_report", artifact["quality_gate_report"]},
      {"#{source}.source_operational_quality_gate_import_readiness_summary",
       artifact["source_operational_quality_gate_import_readiness_summary"]},
      {"#{source}.operational_quality_gate_import_readiness_summary",
       artifact["operational_quality_gate_import_readiness_summary"]},
      {"#{source}.source_operational_quality_gate_summary",
       artifact["source_operational_quality_gate_summary"]},
      {"#{source}.operational_quality_gate_summary",
       artifact["operational_quality_gate_summary"]},
      {"#{source}.source_operational_quality_gate_unavailable_resource_summary",
       artifact["source_operational_quality_gate_unavailable_resource_summary"]},
      {"#{source}.operational_quality_gate_unavailable_resource_summary",
       artifact["operational_quality_gate_unavailable_resource_summary"]},
      {"#{source}.source_operational_quality_gate_operator_training_summary",
       artifact["source_operational_quality_gate_operator_training_summary"]},
      {"#{source}.operational_quality_gate_operator_training_summary",
       artifact["operational_quality_gate_operator_training_summary"]},
      {"#{source}.source_operational_quality_gate_schema_validation_summary",
       artifact["source_operational_quality_gate_schema_validation_summary"]},
      {"#{source}.operational_quality_gate_schema_validation_summary",
       artifact["operational_quality_gate_schema_validation_summary"]}
    ]
    |> Enum.flat_map(fn {report_source, report_or_reports} ->
      source_report_rows(report_or_reports, report_source)
    end)
  end

  defp result_artifact_rows(_artifact, _source), do: []

  defp review_id(parts) do
    parts
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.map(&encode_value/1)
    |> Enum.join(":")
  end

  defp stringify_keys(%{} = map) do
    Map.new(map, fn {key, value} -> {encode_value(key), stringify_keys(value)} end)
  end

  defp stringify_keys(values) when is_list(values), do: Enum.map(values, &stringify_keys/1)
  defp stringify_keys(value), do: encode_value(value)

  defp encode_value(nil), do: nil
  defp encode_value(:null), do: nil
  defp encode_value(value) when is_boolean(value), do: value
  defp encode_value(value) when is_atom(value), do: Atom.to_string(value)
  defp encode_value(value), do: value

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)

  defp compact_map(map) do
    map
    |> Enum.reject(fn {_key, value} -> is_nil(value) end)
    |> Map.new()
  end

  defp build_package(rows, source_artifact_type, source_artifact_id, provenance) do
    PackageBuilder.build(
      rows,
      source_artifact_type,
      source_artifact_id,
      provenance,
      @schema_contract,
      Capabilities.model_limits()
    )
  end

  defp numeric_or_nil(value) when is_integer(value) or is_float(value), do: value * 1.0

  defp numeric_or_nil(value) when is_binary(value) do
    case Float.parse(value) do
      {number, ""} -> number
      _other -> nil
    end
  end

  defp numeric_or_nil(_value), do: nil

  defp non_empty_map(%{} = map) when map_size(map) > 0, do: map
  defp non_empty_map(_map), do: nil

  defp operational_readiness_non_empty_list([_ | _] = values), do: values
  defp operational_readiness_non_empty_list(_values), do: nil

  defp operational_readiness_count_keys(counts) when is_map(counts) do
    counts
    |> Enum.filter(fn {_key, value} -> is_number(value) and value > 0 end)
    |> Enum.map(fn {key, _value} -> key end)
    |> Enum.sort()
  end

  defp operational_readiness_count_keys(_counts), do: nil

  defp operational_readiness_unavailable_reason_ids(counts) when is_map(counts) do
    counts
    |> operational_readiness_count_keys()
    |> List.wrap()
    |> Enum.reject(&String.starts_with?(&1, "station_"))
  end

  defp operational_readiness_unavailable_reason_ids(_counts), do: nil

  defp operational_readiness_station_reason_ids(counts) when is_map(counts) do
    counts
    |> operational_readiness_count_keys()
    |> List.wrap()
    |> Enum.filter(&String.starts_with?(&1, "station_"))
  end

  defp operational_readiness_station_reason_ids(_counts), do: nil

  defp operational_readiness_station_reason_counts(counts) when is_map(counts) do
    counts
    |> Enum.filter(fn {key, value} ->
      String.starts_with?(key, "station_") and is_number(value)
    end)
    |> Map.new()
  end

  defp operational_readiness_station_reason_counts(_counts), do: %{}
end
