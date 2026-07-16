defmodule OrbitalDynamics.OperatorReview.ResultArtifact do
  @moduledoc false

  alias OrbitalDynamics.OperatorReview.Capabilities
  alias OrbitalDynamics.OperatorReview.ConstraintObjective
  alias OrbitalDynamics.OperatorReview.ExecutionReport
  alias OrbitalDynamics.OperatorReview.ManeuverReview
  alias OrbitalDynamics.OperatorReview.PackageBuilder

  @schema_contract "operator_review_package.v1"

  def package(artifact) do
    {rows, source_artifact_id, provenance} = package_input(artifact)

    build_package(rows, "result_artifact.v1", source_artifact_id, provenance)
  end

  def package_input(artifact) do
    artifact = stringify_keys(artifact || %{})

    {
      rows(artifact),
      id(artifact),
      Map.get(artifact, "metadata", %{})
    }
  end

  def rows(%{} = artifact) do
    execution_rows(artifact) ++
      constraint_rows(artifact) ++
      ManeuverReview.result_artifact_rows(artifact)
  end

  def id(%{} = artifact) do
    review_id([
      "result_artifact",
      artifact["study_id"],
      get_in(artifact, ["run", "id"]) || get_in(artifact, ["execution_report", "run_id"])
    ])
  end

  defp execution_rows(artifact) do
    case Map.get(artifact, "execution_report") do
      %{} = report ->
        report
        |> stringify_keys()
        |> Map.put_new("study_id", Map.get(artifact, "study_id"))
        |> Map.put_new("run_id", get_in(artifact, ["run", "id"]))
        |> ExecutionReport.rows("result_artifact.execution_report.failed_scenarios")

      _value ->
        []
    end
  end

  defp constraint_rows(artifact) do
    artifact
    |> get_in(["constraint_report", "rows"])
    |> List.wrap()
    |> ConstraintObjective.constraint_rows("result_artifact.constraint_report.rows")
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
