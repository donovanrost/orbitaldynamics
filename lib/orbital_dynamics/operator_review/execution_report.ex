defmodule OrbitalDynamics.OperatorReview.ExecutionReport do
  @moduledoc false

  alias OrbitalDynamics.OperatorReview.Capabilities
  alias OrbitalDynamics.OperatorReview.PackageBuilder

  @schema_contract "operator_review_package.v1"

  def package(report) do
    {rows, source_artifact_id, provenance} = package_input(report)

    build_package(rows, "execution_report.v1", source_artifact_id, provenance)
  end

  def package_input(report) do
    report = stringify_keys(report || %{})

    {
      rows(report),
      report_id(report),
      Map.get(report, "provenance", %{})
    }
  end

  def rows(report, source \\ "execution_report.failed_scenarios") do
    report
    |> Map.get("failed_scenarios", [])
    |> List.wrap()
    |> Enum.map(&stringify_keys/1)
    |> Enum.with_index(1)
    |> Enum.map(fn {failure, index} ->
      scenario_id = failure["scenario_id"] || "unknown_scenario"
      stage = failure["stage"] || "unknown_stage"

      %{
        "id" => review_id(["execution", scenario_id, stage, index]),
        "review_type" => "execution_review",
        "source" => source,
        "subject_id" => scenario_id,
        "scenario_id" => scenario_id,
        "scenario_index" => failure["scenario_index"],
        "action" => "review_execution_failure",
        "required_operator_action" => "review_execution_failure",
        "approval_status" => "operator_review_required",
        "reason" => "review execution failure for scenario #{scenario_id} during #{stage}",
        "execution_status" => report["status"],
        "execution_mode" => report["execution_mode"],
        "execution_stage" => stage,
        "execution_error" => failure["error"],
        "resumability" => failure["resumability"],
        "retry_recommendation" => failure["retry_recommendation"],
        "study_id" => report["study_id"],
        "run_id" => report["run_id"],
        "failed_scenario_count" => report["failed_scenario_count"],
        "completed_scenario_count" => report["completed_scenario_count"],
        "scenario_count" => report["scenario_count"],
        "source_execution_failure" => failure,
        "source_execution_report" => context(report)
      }
      |> compact_map()
    end)
  end

  def context(report) do
    Map.take(report, [
      "schema_contract",
      "study_id",
      "run_id",
      "status",
      "execution_mode",
      "scenario_count",
      "completed_scenario_count",
      "failed_scenario_count",
      "event_result_count",
      "model_limits",
      "execution_plan",
      "assumptions"
    ])
  end

  def report_id(report) do
    review_id([
      "execution",
      report["study_id"],
      report["run_id"] || report["status"]
    ])
  end

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
