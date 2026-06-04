defmodule OrbitalDynamics.Constraints.ArtifactMetric do
  @moduledoc """
  Deterministic constraints over persisted study artifact scenario metrics.

  This is intentionally artifact-level. It evaluates the same compact metrics
  used by reports and rankings, so constraint results can be reproduced from a
  saved JSON artifact without rerunning propagation.
  """

  @behaviour OrbitalDynamics.Constraint

  alias OrbitalDynamics.ResultSet.Report

  @operators ["<", "<=", "==", ">=", ">"]

  @doc """
  Declares the artifact-level constraint model and known limits.
  """
  @impl OrbitalDynamics.Constraint
  def capabilities do
    %{
      constraint: :artifact_metric,
      model: :artifact_metric_threshold,
      validation_level: :artifact_contract,
      operators: @operators,
      supported_metrics: Report.supported_objectives(),
      outputs: [
        :constraint_rows,
        :constraint_report
      ],
      known_limits: [
        :artifact_level_only,
        :no_rerun_propagation,
        :missing_or_nil_values_fail,
        :numeric_threshold_violations_can_be_warnings,
        :uses_report_metric_rows
      ]
    }
  end

  @doc """
  Evaluates one artifact metric constraint.
  """
  @impl OrbitalDynamics.Constraint
  def evaluate(%{} = artifact, opts) when is_list(opts) do
    with {:ok, constraint} <- Keyword.fetch(opts, :constraint),
         {:ok, rows} <- evaluate_constraint(artifact, constraint) do
      {:ok, %{status: aggregate_status(rows), metadata: %{rows: rows}}}
    else
      :error -> {:error, {:missing_option, :constraint}}
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Evaluates all artifact metric constraints and returns one row per
  scenario/constraint pair.
  """
  def evaluate_all(%{} = artifact, constraints) when is_list(constraints) do
    constraints
    |> Enum.reduce_while({:ok, []}, fn constraint, {:ok, rows} ->
      case evaluate_constraint(artifact, constraint) do
        {:ok, constraint_rows} -> {:cont, {:ok, rows ++ constraint_rows}}
        {:error, reason} -> {:halt, {:error, reason}}
      end
    end)
  end

  def evaluate_all(%{} = _artifact, _constraints), do: {:error, {:invalid_field, "constraints"}}

  @doc """
  Builds a deterministic `constraint_report.v1` artifact from constraints.
  """
  def report(%{} = artifact, constraints) when is_list(constraints) do
    with {:ok, rows} <- evaluate_all(artifact, constraints) do
      report_rows =
        rows
        |> Enum.map(&report_row/1)
        |> Enum.sort_by(&{&1["constraint_id"], &1["scenario_id"], &1["metric"]})

      status_counts = status_counts(report_rows)

      {:ok,
       %{
         "schema_contract" => "constraint_report.v1",
         "model" => "artifact_metric_threshold",
         "model_limits" => model_limits(),
         "constraint_count" => length(constraints),
         "row_count" => length(report_rows),
         "status" => report_status(status_counts),
         "status_counts" => status_counts,
         "rows" => report_rows,
         "assumptions" => %{
           "constraint_model" => "artifact_level_metric_thresholds",
           "source" => "study_metadata.constraints",
           "missing_or_nil_values" => "fail"
         }
       }}
    end
  end

  def report(%{} = _artifact, _constraints), do: {:error, {:invalid_field, "constraints"}}

  defp model_limits do
    capabilities()
    |> Map.fetch!(:known_limits)
    |> Enum.map(&Atom.to_string/1)
  end

  defp evaluate_constraint(artifact, constraint) do
    with {:ok, spec} <- normalize_constraint(constraint) do
      rows =
        artifact
        |> Report.scenario_metrics()
        |> Enum.map(&evaluate_row(&1, spec))

      {:ok, rows}
    end
  end

  defp normalize_constraint(%{} = constraint) do
    constraint
    |> stringify_keys()
    |> normalize_string_keyed_constraint()
  end

  defp normalize_constraint(_constraint), do: {:error, {:invalid_field, "constraints"}}

  defp normalize_string_keyed_constraint(constraint) do
    with {:ok, id} <- required_string(constraint, "id"),
         {:ok, metric} <- required_metric(constraint),
         {:ok, operator} <- required_operator(constraint),
         {:ok, threshold} <- required_number(constraint, "value"),
         {:ok, severity} <- optional_violation_severity(constraint) do
      {:ok,
       %{
         id: id,
         metric: metric,
         operator: operator,
         threshold: threshold,
         violation_severity: severity
       }}
    end
  end

  defp evaluate_row(row, spec) do
    value = Map.get(row, metric_key(spec.metric))

    status =
      cond do
        not is_number(value) -> :fail
        compare(value, spec.operator, spec.threshold) -> :pass
        spec.violation_severity == "warning" -> :warning
        true -> :fail
      end

    %{
      constraint_id: spec.id,
      scenario_id: row.scenario_id,
      metric: spec.metric,
      operator: spec.operator,
      threshold: spec.threshold,
      value: value,
      violation_severity: spec.violation_severity,
      status: status,
      score: if(is_number(value), do: score(value, spec.operator, spec.threshold), else: nil)
    }
  end

  defp aggregate_status(rows) do
    cond do
      Enum.any?(rows, &(&1.status == :fail)) -> :fail
      Enum.any?(rows, &(&1.status == :warning)) -> :warning
      true -> :pass
    end
  end

  defp report_row(row) do
    %{
      "constraint_id" => row.constraint_id,
      "scenario_id" => row.scenario_id,
      "metric" => row.metric,
      "operator" => row.operator,
      "threshold" => row.threshold,
      "violation_severity" => row.violation_severity,
      "value" => row.value,
      "status" => Atom.to_string(row.status),
      "score" => row.score
    }
    |> Enum.reject(fn {_key, value} -> is_nil(value) end)
    |> Map.new()
  end

  defp status_counts(rows) do
    %{
      "pass" => Enum.count(rows, &(&1["status"] == "pass")),
      "fail" => Enum.count(rows, &(&1["status"] == "fail")),
      "warning" => Enum.count(rows, &(&1["status"] == "warning"))
    }
  end

  defp report_status(%{"fail" => fail_count}) when fail_count > 0, do: "fail"
  defp report_status(%{"warning" => warning_count}) when warning_count > 0, do: "warning"
  defp report_status(_status_counts), do: "pass"

  defp compare(value, "<", threshold), do: value < threshold
  defp compare(value, "<=", threshold), do: value <= threshold
  defp compare(value, "==", threshold), do: value == threshold
  defp compare(value, ">=", threshold), do: value >= threshold
  defp compare(value, ">", threshold), do: value > threshold

  defp score(value, operator, threshold) when operator in ["<", "<="], do: threshold - value
  defp score(value, operator, threshold) when operator in [">", ">="], do: value - threshold
  defp score(value, "==", threshold), do: -abs(value - threshold)

  defp required_string(map, key) do
    case Map.fetch(map, key) do
      {:ok, value} when is_binary(value) and value != "" -> {:ok, value}
      {:ok, _value} -> {:error, {:invalid_field, key}}
      :error -> {:error, {:missing_field, key}}
    end
  end

  defp required_metric(map) do
    case Map.fetch(map, "metric") do
      {:ok, metric} when is_binary(metric) ->
        if metric in Report.supported_objectives() do
          {:ok, metric}
        else
          {:error, {:invalid_field, "metric"}}
        end

      {:ok, _metric} ->
        {:error, {:invalid_field, "metric"}}

      :error ->
        {:error, {:missing_field, "metric"}}
    end
  end

  defp required_operator(map) do
    case Map.fetch(map, "operator") do
      {:ok, operator} when operator in @operators -> {:ok, operator}
      {:ok, _operator} -> {:error, {:invalid_field, "operator"}}
      :error -> {:error, {:missing_field, "operator"}}
    end
  end

  defp required_number(map, key) do
    case Map.fetch(map, key) do
      {:ok, value} when is_integer(value) or is_float(value) -> {:ok, value * 1.0}
      {:ok, value} when is_binary(value) -> parse_numeric_string(value, key)
      {:ok, _value} -> {:error, {:invalid_field, key}}
      :error -> {:error, {:missing_field, key}}
    end
  end

  defp parse_numeric_string(value, key) do
    case Float.parse(String.trim(value)) do
      {number, ""} -> {:ok, number}
      _other -> {:error, {:invalid_field, key}}
    end
  end

  defp optional_violation_severity(map) do
    severity = Map.get(map, "severity", Map.get(map, "violation_severity", "fail"))

    case severity do
      "fail" -> {:ok, "fail"}
      :fail -> {:ok, "fail"}
      "warning" -> {:ok, "warning"}
      :warning -> {:ok, "warning"}
      _other -> {:error, {:invalid_field, "severity"}}
    end
  end

  defp stringify_keys(map) do
    Map.new(map, fn
      {key, value} when is_atom(key) -> {Atom.to_string(key), stringify_value(value)}
      {key, value} -> {key, stringify_value(value)}
    end)
  end

  defp stringify_value(value) when is_atom(value), do: Atom.to_string(value)
  defp stringify_value(value), do: value

  defp metric_key("final_radius_km"), do: :final_radius_km
  defp metric_key("final_speed_km_s"), do: :final_speed_km_s
  defp metric_key("min_radius_km"), do: :min_radius_km
  defp metric_key("max_radius_km"), do: :max_radius_km
  defp metric_key("min_altitude_km"), do: :min_altitude_km
  defp metric_key("max_altitude_km"), do: :max_altitude_km
  defp metric_key("semi_major_axis_km"), do: :semi_major_axis_km
  defp metric_key("eccentricity"), do: :eccentricity
  defp metric_key("perigee_radius_km"), do: :perigee_radius_km
  defp metric_key("apogee_radius_km"), do: :apogee_radius_km
  defp metric_key("perigee_altitude_km"), do: :perigee_altitude_km
  defp metric_key("apogee_altitude_km"), do: :apogee_altitude_km
  defp metric_key("access_duration_s"), do: :access_duration_s
  defp metric_key("eclipse_duration_s"), do: :eclipse_duration_s
  defp metric_key("total_delta_v_km_s"), do: :total_delta_v_km_s
end
