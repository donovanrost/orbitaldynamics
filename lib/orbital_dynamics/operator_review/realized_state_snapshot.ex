defmodule OrbitalDynamics.OperatorReview.RealizedStateSnapshot do
  @moduledoc false

  alias OrbitalDynamics.OperatorReview.Capabilities
  alias OrbitalDynamics.OperatorReview.PackageBuilder
  alias OrbitalDynamics.OperatorReview.TimelineFeedback
  alias OrbitalDynamics.OperatorReview.ValueEncoding

  @schema_contract "operator_review_package.v1"

  def package(snapshot) do
    {rows, source_artifact_id, provenance} = package_input(snapshot)

    build_package(rows, "realized_state_snapshot.v1", source_artifact_id, provenance)
  end

  def package_input(snapshot) do
    snapshot = ValueEncoding.stringify_keys(snapshot || %{})
    activities = Map.get(snapshot, "activities", [])

    report =
      OrbitalDynamics.TimelineFeedback.reconcile([], activities)

    rows =
      report
      |> Map.get("rows", [])
      |> TimelineFeedback.rows("realized_state_snapshot.activities")

    {rows, source_artifact_id(snapshot), provenance(snapshot)}
  end

  defp source_artifact_id(snapshot) do
    Map.get(snapshot, "snapshot_id") ||
      get_in(snapshot, ["metadata", "snapshot_id"]) ||
      "realized_state_snapshot"
  end

  defp provenance(snapshot),
    do: Map.get(snapshot, "provenance") || Map.get(snapshot, "metadata", %{})

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
