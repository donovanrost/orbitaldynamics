defmodule OrbitalDynamics.Validation.SafetyCaseSummary do
  @moduledoc false

  def build(evidence, opts, context) when is_list(opts) and is_map(context) do
    rows =
      evidence
      |> safety_case_inputs()
      |> Enum.map(&safety_case_evidence_row/1)
      |> safety_case_ranked_evidence_rows()

    %{
      "schema_contract" => context.schema_contract,
      "schema_version" => 1,
      "model" => "artifact_only_validation_safety_case_summary",
      "source" => "validation.safety_case_evidence",
      "summary_id" =>
        Keyword.get(opts, :summary_id) ||
          safety_case_summary_id(Keyword.get(opts, :case_id), rows),
      "case_id" => Keyword.get(opts, :case_id),
      "status" => safety_case_status(rows),
      "evidence_count" => length(rows),
      "input_contracts" =>
        rows |> Enum.map(& &1["schema_contract"]) |> Enum.uniq() |> Enum.sort(),
      "evidence_status_counts" =>
        rows
        |> Enum.map(& &1["status"])
        |> Enum.reject(&is_nil/1)
        |> Enum.frequencies(),
      "evidence_refs_by_status" => safety_case_evidence_refs_by(rows, "status"),
      "evidence_refs_by_contract" => safety_case_evidence_refs_by(rows, "schema_contract"),
      "blocked_evidence_count" => Enum.count(rows, &(&1["status"] == "blocked")),
      "review_required_evidence_count" => Enum.count(rows, &(&1["status"] == "review_required")),
      "accepted_evidence_count" => Enum.count(rows, &(&1["status"] == "accepted_for_use")),
      "model_accepted_count" => safety_case_sum(rows, "model_accepted_count"),
      "model_review_required_count" => safety_case_sum(rows, "model_review_required_count"),
      "model_blocked_count" => safety_case_sum(rows, "model_blocked_count"),
      "unknown_model_count" => safety_case_sum(rows, "unknown_model_count"),
      "readiness_review_required_count" =>
        safety_case_sum(rows, "readiness_review_required_count"),
      "readiness_blocked_count" => safety_case_sum(rows, "readiness_blocked_count"),
      "ready_for_import_count" => safety_case_sum(rows, "ready_for_import_count"),
      "quality_gate_review_count" => safety_case_sum(rows, "quality_gate_review_count"),
      "quality_gate_blocked_count" => safety_case_sum(rows, "quality_gate_blocked_count"),
      "schema_error_count" => safety_case_sum(rows, "schema_error_count"),
      "schema_warning_count" => safety_case_sum(rows, "schema_warning_count"),
      "schema_validation_report_count" => safety_case_sum(rows, "schema_validation_report_count"),
      "schema_validation_failed_report_count" =>
        safety_case_sum(rows, "schema_validation_failed_report_count"),
      "fixture_passed_count" => safety_case_sum(rows, "fixture_passed_count"),
      "fixture_failed_count" => safety_case_sum(rows, "fixture_failed_count"),
      "evidence" => rows,
      "assumptions" => %{
        "execution_boundary" => "artifact_only_no_cadence_write",
        "certification_authority" => "not_granted_by_summary",
        "operator_authority" => "not_granted_by_summary"
      },
      "model_limits" => context.known_limits
    }
    |> compact_validation_map()
  end

  defp safety_case_inputs(evidence) when is_list(evidence) do
    Enum.flat_map(evidence, &safety_case_inputs/1)
  end

  defp safety_case_inputs(%{} = evidence) do
    evidence = stringify_keys(evidence)

    direct =
      if Map.has_key?(evidence, "schema_contract") do
        [evidence]
      else
        []
      end

    nested =
      [
        "model_acceptance_report",
        "source_model_acceptance_report",
        "operational_readiness_report",
        "source_operational_readiness_report",
        "quality_gate_report",
        "source_quality_gate_report",
        "schema_validation_report",
        "source_schema_validation_report",
        "schema_validation_batch_report",
        "source_schema_validation_batch_report",
        "validation_reference_fixture_report",
        "source_validation_reference_fixture_report"
      ]
      |> Enum.flat_map(fn key -> safety_case_inputs(Map.get(evidence, key)) end)

    direct ++ nested ++ safety_case_handoff_inputs(evidence)
  end

  defp safety_case_inputs(_evidence), do: []

  defp safety_case_handoff_inputs(%{} = evidence) do
    direct =
      case Map.get(evidence, "schema_contract") do
        "operator_review_package.v1" -> safety_case_handoff_container_inputs(evidence)
        "cadence_import_manifest.v1" -> safety_case_handoff_container_inputs(evidence)
        _contract -> []
      end

    nested =
      [
        "operator_review_package",
        "source_operator_review_package",
        "cadence_import_manifest",
        "source_cadence_import_manifest"
      ]
      |> Enum.flat_map(fn key -> safety_case_handoff_container_inputs(Map.get(evidence, key)) end)

    direct ++ nested
  end

  defp safety_case_handoff_container_inputs(containers) when is_list(containers) do
    containers
    |> Enum.flat_map(&safety_case_handoff_container_inputs/1)
  end

  defp safety_case_handoff_container_inputs(%{} = container) do
    container
    |> Map.get("rows", [])
    |> List.wrap()
    |> Enum.flat_map(&safety_case_handoff_row_inputs/1)
    |> Enum.uniq()
  end

  defp safety_case_handoff_container_inputs(_container), do: []

  defp safety_case_handoff_row_inputs(%{} = row) do
    row = stringify_keys(row)

    [
      row["source_model_acceptance_report"],
      row["source_operational_readiness_report"],
      row["source_quality_gate_report"],
      row["source_schema_validation_report"],
      row["source_schema_validation_batch_report"],
      row["source_validation_reference_fixture_report"],
      get_in(row, ["source_review_row", "source_model_acceptance_report"]),
      get_in(row, ["source_review_row", "source_operational_readiness_report"]),
      get_in(row, ["source_review_row", "source_quality_gate_report"]),
      get_in(row, ["source_review_row", "source_schema_validation_report"]),
      get_in(row, ["source_review_row", "source_schema_validation_batch_report"]),
      get_in(row, ["source_review_row", "source_validation_reference_fixture_report"])
    ]
    |> Enum.flat_map(&safety_case_inputs/1)
  end

  defp safety_case_handoff_row_inputs(_row), do: []

  defp safety_case_evidence_row(%{"schema_contract" => "model_acceptance_report.v1"} = report) do
    rows = map_rows(report, "rows")
    intended_use = Map.get(report, "intended_use")

    %{
      "schema_contract" => "model_acceptance_report.v1",
      "status" => safety_case_model_acceptance_status(report, rows),
      "report_id" => Map.get(report, "report_id"),
      "intended_use" => intended_use,
      "model_accepted_count" =>
        model_acceptance_row_count_or_report_count(rows, report, "accepted", "accepted_count"),
      "model_review_required_count" =>
        model_acceptance_row_count_or_report_count(
          rows,
          report,
          "review_required",
          "review_required_count"
        ),
      "model_blocked_count" =>
        model_acceptance_row_count_or_report_count(rows, report, "blocked", "blocked_count"),
      "unknown_model_count" => model_acceptance_unknown_count_or_report_count(rows, report),
      "status_counts" => model_acceptance_rows_or_report_value(rows, report, "status_counts"),
      "model_ids_by_status" =>
        model_acceptance_rows_or_report_value(rows, report, "model_ids_by_status"),
      "model_ids_by_validation_level" =>
        model_acceptance_rows_or_report_value(rows, report, "model_ids_by_validation_level"),
      "model_ids_by_intended_use" =>
        model_acceptance_rows_or_report_value(rows, report, "model_ids_by_intended_use")
    }
    |> compact_validation_map()
  end

  defp safety_case_evidence_row(
         %{"schema_contract" => "operational_readiness_report.v1"} = report
       ) do
    evidence = Map.get(report, "evidence", %{})
    gates = map_rows(report, "gates")

    %{
      "schema_contract" => "operational_readiness_report.v1",
      "status" => safety_case_readiness_status(report, gates),
      "report_id" => Map.get(report, "report_id"),
      "readiness_level" => Map.get(report, "readiness_level"),
      "import_classification" => Map.get(report, "import_classification"),
      "readiness_review_required_count" =>
        readiness_gate_count_or_report_count(
          gates,
          report,
          evidence,
          ["review_required", "analysis_only"],
          ["review_required_count", "review_gate_count", "analysis_gate_count"]
        ),
      "readiness_blocked_count" =>
        readiness_gate_count_or_report_count(
          gates,
          report,
          evidence,
          ["blocked"],
          ["blocked_count", "blocked_gate_count"]
        ),
      "ready_for_import_count" =>
        readiness_gate_sum_or_evidence_count(gates, evidence, "ready_for_import_count")
    }
    |> compact_validation_map()
  end

  defp safety_case_evidence_row(%{"schema_contract" => "quality_gate_report.v1"} = report) do
    rows = map_rows(report, "rows")

    %{
      "schema_contract" => "quality_gate_report.v1",
      "status" => safety_case_quality_gate_status(report, rows),
      "report_id" => Map.get(report, "report_id"),
      "source_readiness_report_id" => Map.get(report, "source_readiness_report_id"),
      "readiness_level" => Map.get(report, "readiness_level"),
      "import_classification" => Map.get(report, "import_classification"),
      "quality_gate_review_count" =>
        quality_gate_row_count_or_report_count(
          rows,
          report,
          "review_required",
          "review_gate_count"
        ) +
          quality_gate_row_count_or_report_count(
            rows,
            report,
            "analysis_only",
            "analysis_gate_count"
          ),
      "quality_gate_blocked_count" =>
        quality_gate_row_count_or_report_count(rows, report, "blocked", "blocked_gate_count")
    }
    |> compact_validation_map()
  end

  defp safety_case_evidence_row(%{"schema_contract" => "schema_validation_report.v1"} = report) do
    errors = schema_validation_issue_rows(report, "errors")
    warnings = schema_validation_issue_rows(report, "warnings")

    %{
      "schema_contract" => "schema_validation_report.v1",
      "status" => safety_case_schema_validation_status(report, errors, warnings),
      "artifact_path" => Map.get(report, "artifact_path"),
      "validated_contract" => Map.get(report, "validated_contract"),
      "schema_error_count" =>
        schema_validation_issue_count_or_report_count(errors, report, "error_count"),
      "schema_warning_count" =>
        schema_validation_issue_count_or_report_count(warnings, report, "warning_count")
    }
    |> compact_validation_map()
  end

  defp safety_case_evidence_row(
         %{"schema_contract" => "schema_validation_batch_report.v1"} = report
       ) do
    reports = Map.get(report, "reports") || []

    %{
      "schema_contract" => "schema_validation_batch_report.v1",
      "status" => safety_case_schema_validation_batch_status(report, reports),
      "input_dir" => Map.get(report, "input_dir"),
      "validation_mode" => Map.get(report, "validation_mode"),
      "schema_error_count" => numeric_count(report, "error_count"),
      "schema_warning_count" => numeric_count(report, "warning_count"),
      "schema_validation_report_count" => count(report, "reports"),
      "schema_validation_failed_report_count" =>
        schema_validation_batch_blocking_report_count(reports)
    }
    |> compact_validation_map()
  end

  defp safety_case_evidence_row(
         %{"schema_contract" => "validation_reference_fixture_report.v1"} = report
       ) do
    reports = Map.get(report, "reports", [])

    %{
      "schema_contract" => "validation_reference_fixture_report.v1",
      "status" => safety_case_fixture_status(report),
      "report_id" => Map.get(report, "report_id"),
      "fixture_passed_count" => fixture_status_count(reports, "pass"),
      "fixture_failed_count" =>
        fixture_status_count(reports, "fail") + fixture_status_count(reports, "error")
    }
    |> compact_validation_map()
  end

  defp safety_case_evidence_row(%{"schema_contract" => schema_contract}) do
    %{"schema_contract" => schema_contract, "status" => "review_required"}
  end

  defp safety_case_ranked_evidence_rows(rows) do
    rows
    |> Enum.with_index(1)
    |> Enum.map(fn {row, rank} ->
      row
      |> Map.put("rank", rank)
      |> Map.put("evidence_ref", safety_case_evidence_ref(row, rank))
    end)
  end

  defp safety_case_evidence_ref(row, rank) do
    contract = Map.get(row, "schema_contract") || "unknown_contract"

    identity =
      [
        Map.get(row, "report_id"),
        Map.get(row, "source_readiness_report_id"),
        Map.get(row, "artifact_path"),
        Map.get(row, "validated_contract"),
        Map.get(row, "input_dir"),
        Map.get(row, "validation_mode"),
        Map.get(row, "intended_use")
      ]
      |> Enum.find(&(not is_nil(&1) and to_string(&1) != ""))

    "#{contract}:#{normalize_safety_case_evidence_ref_part(identity || rank)}"
  end

  defp normalize_safety_case_evidence_ref_part(value) do
    value
    |> to_string()
    |> String.replace(~r/[^A-Za-z0-9._:@-]/, "_")
  end

  defp safety_case_evidence_refs_by(rows, field) do
    rows
    |> Enum.group_by(
      &(Map.get(&1, field) || "unknown"),
      &Map.get(&1, "evidence_ref")
    )
    |> Map.new(fn {value, refs} ->
      {to_string(value), Enum.reject(refs, &is_nil/1)}
    end)
  end

  defp safety_case_summary_id(case_id, rows) do
    identity =
      case_id ||
        rows
        |> Enum.map(&Map.get(&1, "evidence_ref"))
        |> Enum.reject(&is_nil/1)
        |> Enum.join("__")

    identity =
      case identity do
        nil -> "missing_evidence"
        "" -> "missing_evidence"
        value -> value
      end

    "validation_safety_case:#{normalize_safety_case_evidence_ref_part(identity)}"
  end

  defp safety_case_model_acceptance_status(_report, rows) when is_list(rows) and rows != [] do
    cond do
      model_acceptance_status_count(rows, "blocked") > 0 -> "blocked"
      model_acceptance_status_count(rows, "review_required") > 0 -> "review_required"
      true -> "accepted_for_use"
    end
  end

  defp safety_case_model_acceptance_status(%{"status" => "blocked"}, _rows), do: "blocked"

  defp safety_case_model_acceptance_status(%{"status" => "review_required"}, _rows),
    do: "review_required"

  defp safety_case_model_acceptance_status(_report, _rows), do: "accepted_for_use"

  defp model_acceptance_row_count_or_report_count(rows, _report, status, _field)
       when is_list(rows) and rows != [] do
    model_acceptance_status_count(rows, status)
  end

  defp model_acceptance_row_count_or_report_count(_rows, report, _status, field) do
    numeric_count(report, field)
  end

  defp model_acceptance_unknown_count_or_report_count(rows, _report)
       when is_list(rows) and rows != [] do
    Enum.count(rows, &(Map.get(&1, "validation_level") == "unknown"))
  end

  defp model_acceptance_unknown_count_or_report_count(_rows, report) do
    numeric_count(report, "unknown_model_count")
  end

  defp model_acceptance_rows_or_report_value(rows, _report, "status_counts")
       when is_list(rows) and rows != [] do
    model_acceptance_status_counts(rows)
  end

  defp model_acceptance_rows_or_report_value(rows, _report, "model_ids_by_status")
       when is_list(rows) and rows != [] do
    model_acceptance_model_ids_by(rows, "status")
  end

  defp model_acceptance_rows_or_report_value(rows, _report, "model_ids_by_validation_level")
       when is_list(rows) and rows != [] do
    model_acceptance_model_ids_by(rows, "validation_level")
  end

  defp model_acceptance_rows_or_report_value(rows, report, "model_ids_by_intended_use")
       when is_list(rows) and rows != [] do
    intended_use = Map.get(report, "intended_use") || "unknown"

    %{
      to_string(intended_use) =>
        rows |> Enum.map(&Map.get(&1, "model_id")) |> Enum.reject(&is_nil/1)
    }
  end

  defp model_acceptance_rows_or_report_value(_rows, report, field) do
    Map.get(report, field)
  end

  defp safety_case_readiness_status(_report, gates) when is_list(gates) and gates != [] do
    cond do
      count_rows_matching(gates, "status", "blocked") > 0 ->
        "blocked"

      count_rows_matching(gates, "status", "review_required") > 0 or
          count_rows_matching(gates, "status", "analysis_only") > 0 ->
        "review_required"

      true ->
        "accepted_for_use"
    end
  end

  defp safety_case_readiness_status(%{"status" => status}, _gates)
       when status in ["blocked", "fail"],
       do: "blocked"

  defp safety_case_readiness_status(%{"status" => status}, _gates)
       when status in ["review_required", "not_ready", "analysis_only"],
       do: "review_required"

  defp safety_case_readiness_status(_report, _gates), do: "accepted_for_use"

  defp readiness_gate_count_or_report_count(gates, _report, _evidence, statuses, _fields)
       when is_list(gates) and gates != [] do
    Enum.sum(Enum.map(statuses, &count_rows_matching(gates, "status", &1)))
  end

  defp readiness_gate_count_or_report_count(_gates, report, evidence, _statuses, fields) do
    fields
    |> Enum.map(&(numeric_count(evidence, &1) + numeric_count(report, &1)))
    |> Enum.sum()
  end

  defp readiness_gate_sum_or_evidence_count(gates, _evidence, field)
       when is_list(gates) and gates != [] do
    sum_rows_numeric(gates, field)
  end

  defp readiness_gate_sum_or_evidence_count(_gates, evidence, field) do
    numeric_count(evidence, field)
  end

  defp safety_case_quality_gate_status(_report, rows) when is_list(rows) and rows != [] do
    cond do
      count_rows_matching(rows, "status", "blocked") > 0 ->
        "blocked"

      count_rows_matching(rows, "status", "review_required") > 0 or
          count_rows_matching(rows, "status", "analysis_only") > 0 ->
        "review_required"

      true ->
        "accepted_for_use"
    end
  end

  defp safety_case_quality_gate_status(report, _rows) do
    cond do
      numeric_count(report, "blocked_gate_count") > 0 -> "blocked"
      numeric_count(report, "review_gate_count") > 0 -> "review_required"
      numeric_count(report, "analysis_gate_count") > 0 -> "review_required"
      true -> "accepted_for_use"
    end
  end

  defp quality_gate_row_count_or_report_count(rows, _report, status, _field)
       when is_list(rows) and rows != [] do
    count_rows_matching(rows, "status", status)
  end

  defp quality_gate_row_count_or_report_count(_rows, report, _status, field) do
    numeric_count(report, field)
  end

  defp safety_case_schema_validation_status(report, errors, warnings) do
    cond do
      is_list(errors) and errors != [] ->
        "blocked"

      is_list(warnings) and warnings != [] ->
        "review_required"

      is_list(errors) and is_list(warnings) ->
        "accepted_for_use"

      true ->
        safety_case_schema_validation_status(report)
    end
  end

  defp safety_case_schema_validation_status(report) do
    cond do
      numeric_count(report, "error_count") > 0 or Map.get(report, "status") in ["fail", "error"] ->
        "blocked"

      numeric_count(report, "warning_count") > 0 ->
        "review_required"

      true ->
        "accepted_for_use"
    end
  end

  defp schema_validation_issue_rows(report, field) do
    if Map.has_key?(report, field) and is_list(Map.get(report, field)) do
      Map.get(report, field)
    end
  end

  defp schema_validation_issue_count_or_report_count(rows, _report, _field) when is_list(rows) do
    length(rows)
  end

  defp schema_validation_issue_count_or_report_count(_rows, report, field) do
    numeric_count(report, field)
  end

  defp safety_case_schema_validation_batch_status(report, reports) do
    cond do
      schema_validation_batch_blocking_report_count(reports) > 0 ->
        "blocked"

      schema_validation_batch_report_status_count(reports, "warn") > 0 or
          schema_validation_batch_report_status_count(reports, "warning") > 0 ->
        "review_required"

      true ->
        safety_case_schema_validation_status(report)
    end
  end

  defp safety_case_fixture_status(%{"reports" => reports})
       when is_list(reports) and reports != [] do
    if Enum.all?(reports, &(Map.get(&1, "status") == "pass")) do
      "accepted_for_use"
    else
      "blocked"
    end
  end

  defp safety_case_fixture_status(%{"status" => "pass"}), do: "accepted_for_use"
  defp safety_case_fixture_status(_report), do: "blocked"

  defp schema_validation_batch_blocking_report_count(reports) do
    schema_validation_batch_report_status_count(reports, "fail") +
      schema_validation_batch_report_status_count(reports, "error")
  end

  defp schema_validation_batch_report_status_count(reports, status) when is_list(reports) do
    reports
    |> Enum.map(&stringify_keys/1)
    |> Enum.count(&(get_in(&1, ["report", "status"]) == status))
  end

  defp safety_case_status([]), do: "missing_evidence"

  defp safety_case_status(rows) do
    statuses = Enum.map(rows, & &1["status"])

    cond do
      "blocked" in statuses -> "blocked"
      "review_required" in statuses -> "review_required"
      true -> "accepted_for_use"
    end
  end

  defp safety_case_sum(rows, field) do
    rows
    |> Enum.map(&numeric_count(&1, field))
    |> Enum.sum()
  end

  defp fixture_status_count(reports, status) when is_list(reports) do
    reports
    |> Enum.map(&stringify_keys/1)
    |> Enum.count(&(Map.get(&1, "status") == status))
  end

  defp fixture_status_count(_reports, _status), do: 0

  defp model_acceptance_status_count(rows, status),
    do: Enum.count(rows, &(Map.get(&1, "status") == status))

  defp model_acceptance_status_counts(rows) do
    rows
    |> Enum.map(&Map.get(&1, "status", "unknown"))
    |> Enum.frequencies()
    |> Map.new(fn {status, count} -> {to_string(status), count} end)
  end

  defp model_acceptance_model_ids_by(rows, field) do
    rows
    |> Enum.group_by(
      &(Map.get(&1, field) || "unknown"),
      &Map.get(&1, "model_id")
    )
    |> Map.new(fn {value, model_ids} ->
      {to_string(value), Enum.reject(model_ids, &is_nil/1)}
    end)
  end

  defp count(map, key) do
    case Map.get(map, key) do
      values when is_list(values) -> length(values)
      _value -> 0
    end
  end

  defp map_rows(map, key) do
    case Map.get(map, key) do
      rows when is_list(rows) -> Enum.filter(rows, &is_map/1)
      _rows -> []
    end
  end

  defp count_rows_matching(rows, key, value) do
    Enum.count(rows, &(Map.get(&1, key) == value))
  end

  defp sum_rows_numeric(rows, key) do
    rows
    |> Enum.map(&numeric_count(&1, key))
    |> Enum.sum()
  end

  defp numeric_count(report, field) when is_map(report) do
    case Map.get(report, field) do
      value when is_integer(value) and value >= 0 -> value
      value when is_float(value) and value >= 0 -> trunc(value)
      _value -> 0
    end
  end

  defp numeric_count(_report, _field), do: 0

  defp compact_validation_map(map) do
    map
    |> Enum.reject(fn {_key, value} -> value in [nil, %{}, []] end)
    |> Map.new()
  end

  defp stringify_keys(%{} = map) do
    Map.new(map, fn
      {key, value} when is_atom(key) -> {Atom.to_string(key), stringify_keys(value)}
      {key, value} when is_binary(key) -> {key, stringify_keys(value)}
      {key, value} -> {key, stringify_keys(value)}
    end)
  end

  defp stringify_keys(values) when is_list(values), do: Enum.map(values, &stringify_keys/1)

  defp stringify_keys(value), do: value
end
