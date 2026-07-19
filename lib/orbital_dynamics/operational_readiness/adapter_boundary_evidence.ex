defmodule OrbitalDynamics.OperationalReadiness.AdapterBoundaryEvidence do
  @moduledoc false

  def status_counts(artifact, review_rows, import_rows) do
    (artifact_adapter_boundary_statuses(artifact) ++
       row_adapter_boundary_statuses(review_rows) ++ row_adapter_boundary_statuses(import_rows))
    |> Enum.reject(&is_nil/1)
    |> Enum.frequencies()
  end

  defp artifact_adapter_boundary_statuses(%{} = artifact) do
    cond do
      adapter_boundary_context?(artifact) -> [adapter_boundary_status(artifact)]
      true -> []
    end
  end

  defp artifact_adapter_boundary_statuses(_artifact), do: []

  defp row_adapter_boundary_statuses(rows) do
    rows
    |> Enum.filter(&adapter_boundary_context?/1)
    |> Enum.map(&adapter_boundary_status/1)
  end

  defp adapter_boundary_context?(%{} = value) do
    direct_keys = ~w(
      provider
      adapter
      adapter_version
      import_adapter
      cadence_import_adapter
      cadence_import_adapter_version
      external_id
    )

    nested_values =
      [
        get_in(value, ["cadence_import", "provider"]),
        get_in(value, ["cadence_import", "adapter"]),
        get_in(value, ["cadence_import", "adapter_version"]),
        get_in(value, ["cadence_import", "external_id"]),
        get_in(value, ["source_review_row", "provider"]),
        get_in(value, ["source_review_row", "adapter"]),
        get_in(value, ["source_review_row", "adapter_version"]),
        get_in(value, ["source_review_row", "import_adapter"]),
        get_in(value, ["source_review_row", "cadence_import_adapter"]),
        get_in(value, ["source_review_row", "cadence_import_adapter_version"]),
        get_in(value, ["source_review_row", "cadence_import", "provider"]),
        get_in(value, ["source_review_row", "cadence_import", "adapter"]),
        get_in(value, ["source_review_row", "cadence_import", "adapter_version"]),
        get_in(value, ["source_review_row", "cadence_import", "external_id"])
      ]

    Enum.any?(direct_keys, &nonempty_string?(Map.get(value, &1))) or
      Enum.any?(nested_values, &nonempty_string?/1)
  end

  defp adapter_boundary_context?(_value), do: false

  defp adapter_boundary_status(%{} = value) do
    boundaries = adapter_trust_boundary_values(value)

    cond do
      boundaries == [] ->
        "missing"

      Enum.all?(boundaries, &adapter_missing_trust_boundary?/1) ->
        "missing"

      Enum.any?(boundaries, &adapter_untrusted_trust_boundary?/1) ->
        "untrusted"

      true ->
        "declared"
    end
  end

  defp adapter_trust_boundary_values(%{} = value) do
    [
      value["trust_boundary"],
      value["cadence_import_trust_boundary"],
      get_in(value, ["provenance", "trust_boundary"]),
      get_in(value, ["cadence_import", "trust_boundary"]),
      get_in(value, ["cadence_import", "provenance", "trust_boundary"]),
      get_in(value, ["source_review_row", "trust_boundary"]),
      get_in(value, ["source_review_row", "cadence_import_trust_boundary"]),
      get_in(value, ["source_review_row", "provenance", "trust_boundary"]),
      get_in(value, ["source_review_row", "cadence_import", "trust_boundary"]),
      get_in(value, ["source_review_row", "cadence_import", "provenance", "trust_boundary"])
    ]
    |> Enum.filter(&nonempty_string?/1)
  end

  defp nonempty_string?(value) when is_binary(value), do: String.trim(value) != ""
  defp nonempty_string?(_value), do: false

  defp adapter_missing_trust_boundary?(value) do
    normalized_trust_boundary_token(value) in ~w(missing none nil null undefined undeclared not_declared)
  end

  defp adapter_untrusted_trust_boundary?(value) do
    token = normalized_trust_boundary_token(value)

    token in ~w(unknown untrusted unverified unauthenticated unsigned rejected invalid not_trusted) or
      String.contains?(token, "untrusted") or
      String.contains?(token, "unknown") or
      String.contains?(token, "unverified") or
      String.contains?(token, "unauthenticated") or
      String.contains?(token, "not_trusted")
  end

  defp normalized_trust_boundary_token(value) do
    value
    |> to_string()
    |> String.trim()
    |> String.downcase()
    |> String.replace(~r/[^a-z0-9]+/, "_")
    |> String.trim("_")
  end
end
