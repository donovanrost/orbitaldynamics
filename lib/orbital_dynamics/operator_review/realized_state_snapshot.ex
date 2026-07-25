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

    {
      review_rows(snapshot, "realized_state_snapshot.activities"),
      source_artifact_id(snapshot),
      provenance(snapshot)
    }
  end

  def source_rows(nil, _source), do: []

  def source_rows(snapshots, source) when is_list(snapshots) do
    snapshots
    |> Enum.with_index()
    |> Enum.flat_map(fn {snapshot, index} ->
      source_rows(snapshot, "#{source}[#{index}]")
    end)
  end

  def source_rows(%{} = snapshot, source) do
    snapshot = ValueEncoding.stringify_keys(snapshot)

    snapshot
    |> review_rows("#{source}.activities")
    |> Enum.map(&Map.put(&1, "source_realized_state_snapshot", snapshot))
  end

  def source_rows(_snapshot, _source), do: []

  defp review_rows(snapshot, source) do
    snapshot
    |> Map.get("activities", [])
    |> then(&OrbitalDynamics.TimelineFeedback.reconcile([], &1))
    |> Map.get("rows", [])
    |> TimelineFeedback.rows(source)
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
