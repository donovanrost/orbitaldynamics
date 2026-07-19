defmodule OrbitalDynamics.OperationalReadiness.EvidenceNormalization do
  @moduledoc false

  def rows(%{"rows" => rows}) when is_list(rows), do: Enum.filter(rows, &is_map/1)
  def rows(_artifact), do: []

  def row_counts(rows, field) do
    rows
    |> Enum.map(&Map.get(&1, field))
    |> Enum.reject(&is_nil/1)
    |> Enum.frequencies()
  end

  def freshness_status_counts(artifact, review_rows, import_rows) do
    (artifact_statuses(artifact) ++
       row_freshness_statuses(review_rows) ++ row_freshness_statuses(import_rows))
    |> Enum.map(&normalized_freshness_status/1)
    |> Enum.reject(&is_nil/1)
    |> Enum.frequencies()
  end

  defp artifact_statuses(%{"schema_contract" => "freshness_report.v1", "status" => status}) do
    [status]
  end

  defp artifact_statuses(%{} = artifact) do
    [
      get_in(artifact, ["freshness_report", "status"]),
      get_in(artifact, ["source_freshness_report", "status"])
    ]
  end

  defp artifact_statuses(_artifact), do: []

  defp row_freshness_statuses(rows) do
    rows
    |> Enum.map(fn row ->
      first_present([
        row["freshness_status"],
        get_in(row, ["source_freshness_report", "status"]),
        get_in(row, ["source_review_row", "freshness_status"]),
        get_in(row, ["source_review_row", "source_freshness_report", "status"])
      ])
    end)
  end

  defp first_present(values) do
    Enum.find(values, &(&1 not in [nil, ""]))
  end

  defp normalized_freshness_status(value) when value in ["current", "stale", "unknown"], do: value

  defp normalized_freshness_status(value) when is_binary(value) do
    value
    |> String.trim()
    |> String.downcase()
    |> case do
      status when status in ["current", "stale", "unknown"] -> status
      _status -> nil
    end
  end

  defp normalized_freshness_status(_value), do: nil

  def schema_validation_status_counts(artifact, review_rows, import_rows) do
    (artifact_schema_validation_statuses(artifact) ++
       row_schema_validation_statuses(review_rows) ++ row_schema_validation_statuses(import_rows))
    |> Enum.map(&normalized_schema_validation_status/1)
    |> Enum.reject(&is_nil/1)
    |> Enum.frequencies()
  end

  defp artifact_schema_validation_statuses(%{
         "schema_contract" => "schema_validation_report.v1",
         "status" => status
       }) do
    [status]
  end

  defp artifact_schema_validation_statuses(%{} = artifact) do
    [
      get_in(artifact, ["schema_validation_report", "status"]),
      get_in(artifact, ["source_schema_validation_report", "status"])
    ]
  end

  defp artifact_schema_validation_statuses(_artifact), do: []

  defp row_schema_validation_statuses(rows) do
    rows
    |> Enum.map(fn row ->
      first_present([
        row["validation_status"],
        row["schema_validation_gate_status"],
        get_in(row, ["source_schema_validation_report", "status"]),
        get_in(row, ["source_review_row", "validation_status"]),
        get_in(row, ["source_review_row", "source_schema_validation_report", "status"])
      ])
    end)
  end

  defp normalized_schema_validation_status(value) when value in ["pass", "fail"], do: value

  defp normalized_schema_validation_status(value) when is_binary(value) do
    value
    |> String.trim()
    |> String.downcase()
    |> case do
      status when status in ["pass", "fail"] -> status
      _status -> nil
    end
  end

  defp normalized_schema_validation_status(_value), do: nil

  def schema_validation_issue_count(artifact, review_rows, import_rows, field) do
    (artifact_schema_validation_issue_counts(artifact, field) ++
       row_schema_validation_issue_counts(review_rows, field) ++
       row_schema_validation_issue_counts(import_rows, field))
    |> Enum.map(&integer_value/1)
    |> Enum.reject(&is_nil/1)
    |> Enum.sum()
  end

  defp artifact_schema_validation_issue_counts(
         %{"schema_contract" => "schema_validation_report.v1"} = report,
         field
       ) do
    [Map.get(report, field)]
  end

  defp artifact_schema_validation_issue_counts(%{} = artifact, field) do
    [
      get_in(artifact, ["schema_validation_report", field]),
      get_in(artifact, ["source_schema_validation_report", field])
    ]
  end

  defp artifact_schema_validation_issue_counts(_artifact, _field), do: []

  defp row_schema_validation_issue_counts(rows, field) do
    rows
    |> Enum.map(fn row ->
      first_present([
        row[field],
        get_in(row, ["source_schema_validation_report", field]),
        get_in(row, ["source_review_row", field]),
        get_in(row, ["source_review_row", "source_schema_validation_report", field])
      ])
    end)
  end

  def integer_value(value) when is_integer(value), do: value
  def integer_value(value) when is_float(value), do: trunc(value)

  def integer_value(value) when is_binary(value) do
    case Integer.parse(String.trim(value)) do
      {integer, ""} -> integer
      _parse_error -> nil
    end
  end

  def integer_value(_value), do: nil

  def source_model_counts(artifact, review_rows, import_rows) do
    (artifact_model_values(artifact) ++
       row_model_values(review_rows) ++ row_model_values(import_rows))
    |> Enum.map(&normalized_evidence_string/1)
    |> Enum.reject(&is_nil/1)
    |> Enum.frequencies()
  end

  defp artifact_model_values(%{} = artifact) do
    [
      artifact["model"],
      get_in(artifact, ["freshness_report", "model"]),
      get_in(artifact, ["source_freshness_report", "model"]),
      get_in(artifact, ["schema_validation_report", "model"]),
      get_in(artifact, ["source_schema_validation_report", "model"])
    ]
  end

  defp artifact_model_values(_artifact), do: []

  defp row_model_values(rows) do
    rows
    |> Enum.flat_map(fn row ->
      [
        row["model"],
        get_in(row, ["source_freshness_report", "model"]),
        get_in(row, ["source_schema_validation_report", "model"]),
        get_in(row, ["source_review_row", "model"]),
        get_in(row, ["source_review_row", "source_freshness_report", "model"]),
        get_in(row, ["source_review_row", "source_schema_validation_report", "model"])
      ]
    end)
  end

  def source_model_limit_counts(artifact, review_rows, import_rows) do
    (artifact_model_limits(artifact) ++
       row_model_limits(review_rows) ++ row_model_limits(import_rows))
    |> Enum.map(&normalized_evidence_string/1)
    |> Enum.reject(&is_nil/1)
    |> Enum.frequencies()
  end

  defp artifact_model_limits(%{} = artifact) do
    list_value(artifact["model_limits"]) ++
      list_value(get_in(artifact, ["freshness_report", "model_limits"])) ++
      list_value(get_in(artifact, ["source_freshness_report", "model_limits"])) ++
      list_value(get_in(artifact, ["schema_validation_report", "model_limits"])) ++
      list_value(get_in(artifact, ["source_schema_validation_report", "model_limits"]))
  end

  defp artifact_model_limits(_artifact), do: []

  defp row_model_limits(rows) do
    rows
    |> Enum.flat_map(fn row ->
      list_value(row["model_limits"]) ++
        list_value(get_in(row, ["source_freshness_report", "model_limits"])) ++
        list_value(get_in(row, ["source_schema_validation_report", "model_limits"])) ++
        list_value(get_in(row, ["source_review_row", "model_limits"])) ++
        list_value(get_in(row, ["source_review_row", "source_freshness_report", "model_limits"])) ++
        list_value(
          get_in(row, ["source_review_row", "source_schema_validation_report", "model_limits"])
        )
    end)
  end

  def list_value(values) when is_list(values), do: values
  def list_value(value) when value in [nil, ""], do: []
  def list_value(value), do: [value]

  def normalized_evidence_string(value) when value in [nil, :null], do: nil

  def normalized_evidence_string(value) when is_binary(value) do
    value
    |> String.trim()
    |> case do
      "" -> nil
      normalized -> normalized
    end
  end

  def normalized_evidence_string(value) when is_atom(value), do: value |> Atom.to_string()
  def normalized_evidence_string(_value), do: nil

  def map_value_count(counts) when is_map(counts) do
    counts
    |> Map.values()
    |> Enum.filter(&is_integer/1)
    |> Enum.sum()
  end

  def policy_classification_counts(artifact, review_rows, import_rows) do
    (artifact_policy_classifications(artifact) ++
       row_policy_classifications(review_rows) ++ row_policy_classifications(import_rows))
    |> Enum.map(&normalized_policy_classification/1)
    |> Enum.reject(&is_nil/1)
    |> Enum.frequencies()
  end

  defp artifact_policy_classifications(%{"schema_contract" => "policy_decision.v1"} = decision) do
    [decision["classification"]]
  end

  defp artifact_policy_classifications(%{} = artifact) do
    [
      artifact["policy_classification"],
      get_in(artifact, ["policy_decision", "classification"]),
      get_in(artifact, ["source_policy_decision", "classification"])
    ]
  end

  defp artifact_policy_classifications(_artifact), do: []

  defp row_policy_classifications(rows) do
    rows
    |> Enum.flat_map(fn row ->
      [
        row["policy_classification"],
        get_in(row, ["policy_decision", "classification"]),
        get_in(row, ["source_policy_decision", "classification"]),
        get_in(row, ["source_review_row", "policy_classification"]),
        get_in(row, ["source_review_row", "policy_decision", "classification"]),
        get_in(row, ["source_review_row", "source_policy_decision", "classification"])
      ]
    end)
  end

  defp normalized_policy_classification(value)
       when value in ["auto_approvable", "operator_review_required", "blocked_by_policy"],
       do: value

  defp normalized_policy_classification(value) do
    value
    |> normalized_evidence_string()
    |> case do
      classification
      when classification in [
             "auto_approvable",
             "operator_review_required",
             "blocked_by_policy"
           ] ->
        classification

      _classification ->
        nil
    end
  end
end
