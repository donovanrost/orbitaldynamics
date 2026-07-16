defmodule OrbitalDynamics.OperatorReview.RealizedActivity do
  @moduledoc false

  alias OrbitalDynamics.OperatorReview.Capabilities
  alias OrbitalDynamics.OperatorReview.PackageBuilder
  alias OrbitalDynamics.OperatorReview.TimelineFeedback
  alias OrbitalDynamics.OperatorReview.ValueEncoding

  @schema_contract "operator_review_package.v1"

  def package(activity) do
    {rows, source_artifact_id, provenance} = package_input(activity)

    build_package(rows, "realized_activity.v1", source_artifact_id, provenance)
  end

  def package_input(activity) do
    activity = ValueEncoding.stringify_keys(activity || %{})

    report =
      OrbitalDynamics.TimelineFeedback.reconcile([], [activity])

    rows =
      report
      |> Map.get("rows", [])
      |> TimelineFeedback.rows("realized_activity")

    {rows, source_artifact_id(activity), Map.get(activity, "provenance", %{})}
  end

  defp source_artifact_id(activity) do
    Map.get(activity, "id") || Map.get(activity, "realized_activity_id") || "realized_activity"
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
