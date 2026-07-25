defmodule OrbitalDynamics.OperatorReview.SchemaValidation do
  @moduledoc false

  alias OrbitalDynamics.OperatorReview.Capabilities
  alias OrbitalDynamics.OperatorReview.PackageBuilder

  @schema_contract "operator_review_package.v1"

  def report_package(report) do
    {rows, source_artifact_id, provenance} = report_package_input(report)

    build_package(rows, "schema_validation_report.v1", source_artifact_id, provenance)
  end

  def batch_package(report) do
    {rows, source_artifact_id, provenance} = batch_package_input(report)

    build_package(rows, "schema_validation_batch_report.v1", source_artifact_id, provenance)
  end

  def report_package_input(report) do
    report = stringify_keys(report || %{})

    {
      rows(report),
      report_id(report),
      Map.get(report, "provenance", %{})
    }
  end

  def batch_package_input(report) do
    report = stringify_keys(report || %{})

    {
      report
      |> Map.get("reports", [])
      |> List.wrap()
      |> Enum.flat_map(&batch_report_rows/1),
      batch_report_id(report),
      Map.get(report, "provenance", %{})
    }
  end

  def batch_report_rows(entry) do
    entry = stringify_keys(entry)

    entry
    |> Map.get("report", %{})
    |> stringify_keys()
    |> Map.put_new("artifact_path", entry["path"])
    |> Map.put("batch_entry_path", entry["path"])
    |> rows("schema_validation_batch_report.reports.report")
  end

  def rows(report, source_prefix \\ "schema_validation_report") do
    issues =
      report
      |> Map.get("errors", [])
      |> Enum.map(&issue_row(&1, source_prefix <> ".errors"))
      |> Kernel.++(
        report
        |> Map.get("warnings", [])
        |> Enum.map(&issue_row(&1, source_prefix <> ".warnings"))
      )

    if issues == [] do
      []
    else
      remediation_by_path =
        report
        |> Map.get("remediation", [])
        |> Enum.map(&stringify_keys/1)
        |> Map.new(&{&1["path"], &1})

      issues
      |> Enum.with_index(1)
      |> Enum.map(fn {issue, index} ->
        remediation = Map.get(remediation_by_path, issue["path"])
        severity = Map.get(issue, "severity", "error")

        %{
          "id" =>
            review_id([
              "schema_validation",
              report["validated_contract"],
              report["validation_mode"],
              stable_id_fragment(report["batch_entry_path"]),
              stable_id_fragment(issue["path"]),
              index
            ]),
          "review_type" => "schema_validation_review",
          "source" => issue["source"],
          "subject_id" => report["validated_contract"] || "schema_validation_report",
          "action" => action(severity),
          "required_operator_action" => "review_schema_validation",
          "approval_status" => "operator_review_required",
          "reason" => reason(report, issue),
          "validation_status" => report["status"],
          "validation_mode" => report["validation_mode"],
          "validated_contract" => report["validated_contract"],
          "validated_artifact_family" => report["validated_artifact_family"],
          "artifact_path" => report["artifact_path"],
          "issue_severity" => severity,
          "issue_path" => issue["path"],
          "issue_message" => issue["message"],
          "error_count" => report["error_count"],
          "warning_count" => report["warning_count"],
          "remediation_count" => report["remediation_count"],
          "remediation_category" => remediation && remediation["category"],
          "remediation_action" => remediation && remediation["action"],
          "source_validation_issue" => Map.delete(issue, "source"),
          "source_validation_remediation" => remediation,
          "source_schema_validation_report" => report
        }
        |> compact_map()
      end)
    end
  end

  def report_id(report) do
    review_id([
      "schema_validation",
      report["validated_contract"],
      report["validation_mode"],
      report["status"]
    ])
  end

  def batch_report_id(report) do
    review_id([
      "schema_validation_batch",
      report["validation_mode"],
      stable_id_fragment(report["input_dir"]),
      report["status"]
    ])
  end

  def candidate_refresh_rows(artifact) do
    artifact = stringify_keys(artifact)

    direct_rows =
      [
        {"candidate_refresh.accepted_planning_state.source_schema_validation_report",
         get_in(artifact, ["accepted_planning_state", "source_schema_validation_report"])},
        {"candidate_refresh.accepted_planning_state.schema_validation_report",
         get_in(artifact, ["accepted_planning_state", "schema_validation_report"])},
        {"candidate_refresh.accepted_planning_state.source_schema_validation_batch_report",
         get_in(artifact, ["accepted_planning_state", "source_schema_validation_batch_report"])},
        {"candidate_refresh.accepted_planning_state.schema_validation_batch_report",
         get_in(artifact, ["accepted_planning_state", "schema_validation_batch_report"])},
        {"candidate_refresh.mission_state.source_schema_validation_report",
         get_in(artifact, ["mission_state", "source_schema_validation_report"])},
        {"candidate_refresh.mission_state.schema_validation_report",
         get_in(artifact, ["mission_state", "schema_validation_report"])},
        {"candidate_refresh.mission_state.source_schema_validation_batch_report",
         get_in(artifact, ["mission_state", "source_schema_validation_batch_report"])},
        {"candidate_refresh.mission_state.schema_validation_batch_report",
         get_in(artifact, ["mission_state", "schema_validation_batch_report"])},
        {"candidate_refresh.source_schema_validation_report",
         artifact["source_schema_validation_report"]},
        {"candidate_refresh.schema_validation_report", artifact["schema_validation_report"]},
        {"candidate_refresh.source_schema_validation_batch_report",
         artifact["source_schema_validation_batch_report"]},
        {"candidate_refresh.schema_validation_batch_report",
         artifact["schema_validation_batch_report"]}
      ]
      |> Enum.flat_map(fn {source, report_or_reports} ->
        source_report_rows(report_or_reports, source)
      end)

    direct_rows ++ candidate_refresh_container_rows(artifact)
  end

  def source_batch_rows(report_or_reports, source),
    do: source_report_rows(report_or_reports, source)

  defp source_report_rows(reports, source) when is_list(reports) do
    reports
    |> Enum.with_index()
    |> Enum.flat_map(fn {report, index} ->
      source_report_rows(report, "#{source}[#{index}]")
    end)
  end

  defp source_report_rows(%{} = report, source) do
    report = stringify_keys(report)

    case report["schema_contract"] do
      "schema_validation_batch_report.v1" ->
        source_batch_report_rows(report, source)

      _contract ->
        rows(report, source)
    end
  end

  defp source_report_rows(_report, _source), do: []

  defp source_batch_report_rows(report, source) do
    report
    |> Map.get("reports", [])
    |> List.wrap()
    |> Enum.with_index()
    |> Enum.flat_map(fn {entry, index} ->
      entry = stringify_keys(entry)

      entry
      |> Map.get("report", %{})
      |> stringify_keys()
      |> Map.put_new("artifact_path", entry["path"])
      |> Map.put("batch_entry_path", entry["path"])
      |> rows("#{source}.reports[#{index}].report")
    end)
  end

  defp candidate_refresh_container_rows(artifact) do
    [
      {:operator_review_package, "candidate_refresh.source_operator_review_package",
       artifact["source_operator_review_package"]},
      {:operator_review_package, "candidate_refresh.operator_review_package",
       artifact["operator_review_package"]},
      {:cadence_import_manifest, "candidate_refresh.source_cadence_import_manifest",
       artifact["source_cadence_import_manifest"]},
      {:cadence_import_manifest, "candidate_refresh.cadence_import_manifest",
       artifact["cadence_import_manifest"]}
    ]
    |> Enum.flat_map(fn {kind, source, package_or_manifest} ->
      container_rows(kind, package_or_manifest, source)
    end)
    |> Kernel.++(candidate_refresh_result_artifact_rows(artifact))
  end

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

  defp result_artifact_rows(%{} = artifact, source) do
    artifact = stringify_keys(artifact)

    [
      {"#{source}.source_schema_validation_report", artifact["source_schema_validation_report"]},
      {"#{source}.schema_validation_report", artifact["schema_validation_report"]},
      {"#{source}.source_schema_validation_batch_report",
       artifact["source_schema_validation_batch_report"]},
      {"#{source}.schema_validation_batch_report", artifact["schema_validation_batch_report"]}
    ]
    |> Enum.flat_map(fn {report_source, report_or_reports} ->
      source_report_rows(report_or_reports, report_source)
    end)
    |> Kernel.++(
      container_rows(
        :operator_review_package,
        artifact["operator_review_package"],
        "#{source}.operator_review_package"
      )
    )
    |> Kernel.++(
      container_rows(
        :cadence_import_manifest,
        artifact["cadence_import_manifest"],
        "#{source}.cadence_import_manifest"
      )
    )
  end

  defp result_artifact_rows(_artifact, _source), do: []

  defp container_rows(kind, containers, source) when is_list(containers) do
    containers
    |> Enum.with_index()
    |> Enum.flat_map(fn {container, index} ->
      container_rows(kind, container, "#{source}[#{index}]")
    end)
  end

  defp container_rows(:operator_review_package, %{} = package, source) do
    package = stringify_keys(package)

    package
    |> Map.get("rows", [])
    |> Enum.map(&stringify_keys/1)
    |> Enum.filter(&(&1["review_type"] == "schema_validation_review"))
    |> rows_from_review_or_import_rows(source, package)
  end

  defp container_rows(:cadence_import_manifest, %{} = manifest, source) do
    manifest = stringify_keys(manifest)

    manifest
    |> Map.get("rows", [])
    |> Enum.map(&stringify_keys/1)
    |> Enum.filter(fn row ->
      row["source_review_type"] == "schema_validation_review" or
        row["import_action"] == "review_schema_validation"
    end)
    |> rows_from_review_or_import_rows(source, manifest)
  end

  defp container_rows(_kind, _container, _source), do: []

  defp rows_from_review_or_import_rows([], _source, _artifact), do: []

  defp rows_from_review_or_import_rows(rows, source, artifact) do
    report_source = "#{source}.rows.source_schema_validation_report"

    rows
    |> report_from_review_or_import_rows(artifact)
    |> source_report_rows(report_source)
  end

  defp report_from_review_or_import_rows(rows, artifact) do
    report =
      rows
      |> Enum.map(&embedded_report/1)
      |> Enum.reject(&is_nil/1)
      |> case do
        [embedded_report | _reports] ->
          stringify_keys(embedded_report)

        [] ->
          report_from_review_or_import_rows(rows)
      end

    artifact = stringify_keys(artifact)

    report
    |> Map.put("source", "preserved_schema_validation_review_rows")
    |> maybe_put("provenance", Map.get(artifact, "provenance"))
    |> compact_map()
  end

  defp report_from_review_or_import_rows(rows) do
    errors =
      rows
      |> Enum.filter(&error_row?/1)
      |> Enum.map(&issue_from_row/1)
      |> Enum.reject(&(&1 == %{}))

    warnings =
      rows
      |> Enum.filter(&warning_row?/1)
      |> Enum.map(&issue_from_row/1)
      |> Enum.reject(&(&1 == %{}))

    remediation =
      rows
      |> Enum.map(&remediation_from_row/1)
      |> Enum.reject(&(&1 == %{}))

    %{
      "schema_contract" => "schema_validation_report.v1",
      "model" => "preserved_schema_validation_review_rows",
      "validation_mode" => row_value(rows, ["validation_mode"]),
      "validated_contract" => row_value(rows, ["validated_contract", "subject_id"]),
      "validated_artifact_family" => row_value(rows, ["validated_artifact_family"]),
      "status" => report_status_from_rows(rows),
      "error_count" => length(errors),
      "warning_count" => length(warnings),
      "errors" => errors,
      "warnings" => warnings,
      "artifact_path" => row_value(rows, ["artifact_path"]),
      "remediation_count" => length(remediation),
      "remediation" => remediation
    }
    |> compact_map()
  end

  defp embedded_report(%{} = row) do
    cond do
      is_map(get_in(row, ["source_review_row", "source_schema_validation_report"])) ->
        get_in(row, ["source_review_row", "source_schema_validation_report"])

      is_map(row["source_schema_validation_report"]) ->
        row["source_schema_validation_report"]

      true ->
        nil
    end
  end

  defp report_status_from_rows(rows) do
    cond do
      Enum.any?(rows, &error_row?/1) ->
        "fail"

      status = row_value(rows, ["validation_status", "schema_validation_gate_status"]) ->
        status

      true ->
        "fail"
    end
  end

  defp error_row?(row) do
    row["issue_severity"] in [nil, "", "error"] and
      (row["validation_status"] == "fail" or row["schema_validation_gate_status"] == "fail" or
         row["issue_path"] not in [nil, ""] or is_map(row["source_validation_issue"]))
  end

  defp warning_row?(row), do: row["issue_severity"] == "warning"

  defp issue_from_row(row) do
    issue =
      case row["source_validation_issue"] do
        %{} = issue -> stringify_keys(issue)
        _issue -> %{}
      end

    %{
      "path" => issue["path"] || row["issue_path"],
      "message" => issue["message"] || row["issue_message"],
      "severity" => issue["severity"] || row["issue_severity"]
    }
    |> compact_map()
  end

  defp remediation_from_row(row) do
    remediation =
      case row["source_validation_remediation"] do
        %{} = remediation -> stringify_keys(remediation)
        _remediation -> %{}
      end

    %{
      "path" => remediation["path"] || row["issue_path"],
      "category" => remediation["category"] || row["remediation_category"],
      "action" => remediation["action"] || row["remediation_action"]
    }
    |> compact_map()
  end

  defp row_value(rows, keys) do
    rows
    |> Enum.find_value(fn row ->
      Enum.find_value(keys, fn key ->
        value = row[key]
        if value not in [nil, "", []], do: value
      end)
    end)
  end

  defp issue_row(issue, source) do
    issue
    |> stringify_keys()
    |> Map.put("source", source)
  end

  defp action("warning"), do: "review_schema_validation_warning"
  defp action(_severity), do: "review_schema_validation_failure"

  defp reason(report, issue) do
    contract = report["validated_contract"] || "artifact"
    severity = issue["severity"] || "error"
    path = issue["path"] || "$"
    message = issue["message"] || "schema validation issue"

    "#{contract} #{severity} at #{path}: #{message}"
  end

  defp review_id(parts) do
    parts
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.map(&encode_value/1)
    |> Enum.join(":")
  end

  defp stable_id_fragment(nil), do: nil

  defp stable_id_fragment(value) when is_binary(value) do
    value
    |> String.replace(~r/[^A-Za-z0-9._:@-]/, "_")
    |> String.trim("_")
    |> case do
      "" ->
        "root"

      fragment ->
        if Regex.match?(~r/^[A-Za-z0-9]/, fragment) do
          fragment
        else
          "path:#{fragment}"
        end
    end
  end

  defp stable_id_fragment(value), do: encode_value(value)

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
end
