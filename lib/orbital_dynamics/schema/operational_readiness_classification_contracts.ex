defmodule OrbitalDynamics.Schema.OperationalReadinessClassificationContracts do
  @moduledoc false

  @required_assumptions [
    "classification_uses_declared_operator_review_and_cadence_import_manifest_evidence",
    "cadence_import_manifest_rows_are_adapter_handoff_not_external_import_writes"
  ]

  def validate_assumptions(issues, path, report, callbacks) do
    assumptions = Map.get(report, "assumptions")

    if is_list(assumptions) and Enum.all?(@required_assumptions, &(&1 in assumptions)) do
      issues
    else
      [
        error(
          path <> ".assumptions",
          "must include operational readiness artifact-only assumptions",
          callbacks
        )
        | issues
      ]
    end
  end

  def validate_classification(issues, path, report, gates, callbacks) when is_list(gates) do
    import_classification = import_classification(gates)
    readiness_level = readiness_level(import_classification)
    status = report_status(import_classification)

    issues
    |> expect_field_equals(
      path,
      report,
      "import_classification",
      import_classification,
      "must match gate-derived import classification",
      callbacks
    )
    |> expect_field_equals(
      path,
      report,
      "readiness_level",
      readiness_level,
      "must match gate-derived readiness level",
      callbacks
    )
    |> expect_field_equals(
      path,
      report,
      "status",
      status,
      "must match gate-derived report status",
      callbacks
    )
  end

  def validate_classification(issues, _path, _report, _gates, _callbacks), do: issues

  def import_classification(gates) when is_list(gates) do
    statuses =
      gates
      |> Enum.filter(&is_map/1)
      |> Enum.map(&Map.get(&1, "status"))

    cond do
      "blocked" in statuses -> "blocked"
      "analysis_only" in statuses -> "analysis_only"
      "review_required" in statuses -> "review_only"
      true -> "importable"
    end
  end

  def readiness_level("importable"), do: "import_eligible"
  def readiness_level("review_only"), do: "operator_review"
  def readiness_level("analysis_only"), do: "analysis_only"
  def readiness_level("blocked"), do: "blocked"

  def report_status("importable"), do: "passed"
  def report_status("review_only"), do: "review_required"
  def report_status("analysis_only"), do: "analysis_only"
  def report_status("blocked"), do: "blocked"

  defp expect_field_equals(issues, path, data, field, expected, message, callbacks) do
    callbacks
    |> Keyword.fetch!(:expect_field_equals)
    |> then(& &1.(issues, path, data, field, expected, message))
  end

  defp error(path, message, callbacks) do
    callbacks
    |> Keyword.fetch!(:error)
    |> then(& &1.(path, message))
  end
end
