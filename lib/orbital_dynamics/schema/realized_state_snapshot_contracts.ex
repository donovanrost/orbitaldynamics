defmodule OrbitalDynamics.Schema.RealizedStateSnapshotContracts do
  @moduledoc false

  import OrbitalDynamics.Schema.CollectionValidation, only: [validate_rows: 4]
  import OrbitalDynamics.Schema.StableIdValidation, only: [validate_stable_ids: 4]

  import OrbitalDynamics.Schema.PrimitiveValidation,
    only: [
      error: 2,
      expect_equal: 5,
      expect_field_equals: 6,
      expect_optional_list: 4,
      expect_optional_type: 5,
      expect_type: 5,
      require_fields: 4,
      validate_string_list_items: 4
    ]

  alias OrbitalDynamics.Schema.{CollectionAggregation, RealizedActivityContracts}

  def validate(issues, path, snapshot) do
    issues
    |> require_fields(path, snapshot, [
      "schema_contract",
      "activities",
      "spacecraft_states",
      "metadata"
    ])
    |> expect_equal(path, snapshot, "schema_contract", "realized_state_snapshot.v1")
    |> expect_type(path, snapshot, "activities", :list)
    |> expect_type(path, snapshot, "spacecraft_states", :list)
    |> expect_type(path, snapshot, "metadata", :map)
    |> expect_optional_list(path, snapshot, "model_limits")
    |> validate_string_list_items(path, snapshot, "model_limits")
    |> validate_metadata(path <> ".metadata", Map.get(snapshot, "metadata", %{}))
    |> validate_model_limits(path, snapshot)
    |> validate_rows(
      path <> ".activities",
      Map.get(snapshot, "activities", []),
      &RealizedActivityContracts.validate/3
    )
    |> validate_rows(
      path <> ".spacecraft_states",
      Map.get(snapshot, "spacecraft_states", []),
      fn acc, row_path, row ->
        OrbitalDynamics.Schema.RealizedSpacecraftStateContracts.validate(
          acc,
          row_path,
          row
        )
      end
    )
    |> validate_counts(path, snapshot)
  end

  defp validate_counts(issues, path, snapshot) do
    activities = snapshot |> Map.get("activities", []) |> Enum.filter(&is_map/1)
    spacecraft_states = snapshot |> Map.get("spacecraft_states", []) |> Enum.filter(&is_map/1)

    issues
    |> expect_field_equals(path, snapshot, "activity_count", length(activities))
    |> expect_field_equals(
      path,
      snapshot,
      "spacecraft_state_count",
      length(spacecraft_states)
    )
    |> expect_field_equals(
      path,
      snapshot,
      "activity_status_counts",
      CollectionAggregation.frequency_map(activities, "status"),
      "must equal row-derived activity status counts"
    )
    |> expect_field_equals(
      path,
      snapshot,
      "spacecraft_state_status_counts",
      CollectionAggregation.frequency_map(spacecraft_states, "status"),
      "must equal row-derived spacecraft state status counts"
    )
    |> expect_field_equals(
      path,
      snapshot,
      "degraded_count",
      degraded_count(activities, spacecraft_states),
      "must equal row-derived degraded count"
    )
  end

  defp degraded_count(activities, spacecraft_states) do
    [activities, spacecraft_states]
    |> Enum.flat_map(& &1)
    |> Enum.count(&(Map.get(&1, "degraded") == true))
  end

  defp validate_metadata(issues, path, metadata) do
    issues
    |> expect_optional_type(path, metadata, "snapshot_id", :binary)
    |> expect_optional_type(path, metadata, "mission_state_id", :binary)
    |> expect_optional_type(path, metadata, "captured_at", :binary)
    |> expect_optional_type(path, metadata, "source", :binary)
    |> expect_optional_type(path, metadata, "feedback_boundary", :binary)
    |> expect_optional_type(path, metadata, "provider", :binary)
    |> expect_optional_type(path, metadata, "adapter", :binary)
    |> expect_optional_type(path, metadata, "adapter_version", :binary)
    |> expect_optional_type(path, metadata, "external_id", :binary)
    |> expect_optional_type(path, metadata, "trust_boundary", :binary)
    |> expect_optional_type(path, metadata, "received_at", :binary)
    |> expect_optional_type(path, metadata, "ingested_at", :binary)
    |> expect_optional_type(
      path,
      metadata,
      "dropped_identityless_spacecraft_state_count",
      :integer
    )
    |> expect_optional_type(
      path,
      metadata,
      "dropped_invalid_identity_spacecraft_state_count",
      :integer
    )
    |> expect_optional_type(path, metadata, "provenance", :map)
    |> validate_stable_ids(path, metadata, ["external_id"])
    |> validate_non_negative_optional_integer(
      path,
      metadata,
      "dropped_identityless_spacecraft_state_count"
    )
    |> validate_non_negative_optional_integer(
      path,
      metadata,
      "dropped_invalid_identity_spacecraft_state_count"
    )
    |> require_metadata_trust_boundary(path, metadata)
  end

  defp validate_model_limits(issues, path, snapshot) do
    case Map.get(snapshot, "model_limits") do
      nil ->
        issues

      limits when is_list(limits) ->
        expected_limits = realized_state_snapshot_model_limits()

        if Enum.sort(limits) == Enum.sort(expected_limits) do
          issues
        else
          [
            error(
              path <> ".model_limits",
              "must match realized state snapshot model limits"
            )
            | issues
          ]
        end

      _other ->
        issues
    end
  end

  defp require_metadata_trust_boundary(issues, path, metadata) do
    provider_context_fields = ["provider", "adapter", "adapter_version", "external_id"]

    has_provider_context? =
      Enum.any?(provider_context_fields, fn field ->
        value = Map.get(metadata, field)
        is_binary(value) and value != ""
      end)

    trust_boundary = Map.get(metadata, "trust_boundary")
    provenance_trust_boundary = get_in(metadata, ["provenance", "trust_boundary"])

    cond do
      not has_provider_context? ->
        issues

      is_binary(trust_boundary) and trust_boundary != "" ->
        issues

      is_binary(provenance_trust_boundary) and provenance_trust_boundary != "" ->
        issues

      true ->
        [
          error(
            path <> ".trust_boundary",
            "realized_state_snapshot.v1 metadata requires trust_boundary or provenance.trust_boundary when provider context is present"
          )
          | issues
        ]
    end
  end

  defp validate_non_negative_optional_integer(issues, path, map, field) do
    case Map.get(map, field) do
      value when is_integer(value) and value < 0 ->
        [error(path <> ".#{field}", "must be greater than or equal to 0") | issues]

      _value ->
        issues
    end
  end

  defp realized_state_snapshot_model_limits,
    do: OrbitalDynamics.CampaignPlanner.realized_state_snapshot_model_limits()

  defp expect_field_equals(issues, path, map, field, expected),
    do: expect_field_equals(issues, path, map, field, expected, "must equal #{expected}")
end
