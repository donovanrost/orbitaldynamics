defmodule OrbitalDynamics.OperatorReview.ManeuverExecutionDelta do
  @moduledoc false

  alias OrbitalDynamics.OperatorReview.Capabilities
  alias OrbitalDynamics.OperatorReview.PackageBuilder
  alias OrbitalDynamics.OperatorReview.TimelineFeedback
  alias OrbitalDynamics.OperatorReview.ValueEncoding

  @schema_contract "operator_review_package.v1"

  def package(delta) do
    {rows, source_artifact_id, provenance} = package_input(delta)

    build_package(rows, "maneuver_execution_delta.v1", source_artifact_id, provenance)
  end

  def package_input(delta) do
    delta = ValueEncoding.stringify_keys(delta || %{})

    realized_activity =
      delta
      |> Map.put_new("id", Map.get(delta, "activity_id"))
      |> Map.put_new("type", "impulsive_burn")

    report =
      OrbitalDynamics.TimelineFeedback.reconcile([], [realized_activity])

    rows =
      report
      |> Map.get("rows", [])
      |> TimelineFeedback.rows("maneuver_execution_delta")

    {rows, source_artifact_id(delta), Map.get(delta, "provenance", %{})}
  end

  defp source_artifact_id(delta) do
    Map.get(delta, "id") || Map.get(delta, "activity_id") || "maneuver_execution_delta"
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
