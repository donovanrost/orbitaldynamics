defmodule OrbitalDynamics.Optimizer.SourceEvidenceRegistry do
  @moduledoc false

  alias OrbitalDynamics.Schema.JsonSafety

  @schema_contract "local_search_source_evidence_registry.v1"
  @trust_boundary "caller_supplied_trusted_composition_snapshot"
  @algorithm "erlang_term_to_binary_deterministic_sha256.v1"
  @stable_id ~r/^[A-Za-z0-9][A-Za-z0-9._:@-]*$/
  @sha256 ~r/^[0-9a-f]{64}$/
  @fields ~w(schema_contract id trust_boundary entries)
  @entry_fields ~w(
    parameter_revision parameter_content_identity
    resource_state_trace_id downlink_link_budget_id
  )

  def schema_contract, do: @schema_contract
  def trust_boundary, do: @trust_boundary
  def algorithm, do: @algorithm

  def entry(
        alternative_id,
        parameter_revision,
        parameters,
        resource_state_trace_id,
        downlink_link_budget_id
      ) do
    alternative_id = stable_id!(alternative_id, "alternative_id")

    {alternative_id,
     normalize_entry!(%{
       "parameter_revision" => parameter_revision,
       "parameter_content_identity" => parameter_content_identity(parameters),
       "resource_state_trace_id" => resource_state_trace_id,
       "downlink_link_budget_id" => downlink_link_budget_id
     })}
  end

  def build(entries) when is_map(entries) do
    entries = normalize_entries!(entries)

    core = %{
      "schema_contract" => @schema_contract,
      "trust_boundary" => @trust_boundary,
      "entries" => entries
    }

    Map.put(core, "id", registry_id(core))
  end

  def build(_entries), do: raise(ArgumentError, "source evidence registry entries must be a map")

  def normalize!(registry) when is_map(registry) do
    registry = JsonSafety.normalize_input!(registry, "source evidence registry")

    if Enum.sort(Map.keys(registry)) != Enum.sort(@fields) do
      raise ArgumentError, "source evidence registry must contain exactly #{inspect(@fields)}"
    end

    require_equal!(registry["schema_contract"], @schema_contract, "schema_contract")
    require_equal!(registry["trust_boundary"], @trust_boundary, "trust_boundary")
    stable_id!(registry["id"], "id")

    entries = normalize_entries!(registry["entries"])
    core = Map.drop(registry, ["id"])
    require_equal!(registry["id"], registry_id(core), "content identity")
    Map.put(registry, "entries", entries)
  end

  def normalize!(_registry),
    do: raise(ArgumentError, "hard_feasibility.evidence_registry must be a map")

  def parameter_content_identity(parameters) when is_map(parameters) do
    parameters = JsonSafety.normalize_input!(parameters, "parameters")

    unless map_size(parameters) > 0 and
             Enum.all?(parameters, fn {key, value} ->
               Regex.match?(~r/^[A-Za-z][A-Za-z0-9_.-]*$/, key) and finite_number?(value)
             end) do
      raise ArgumentError, "parameters must be a non-empty finite numeric map"
    end

    digest = parameters |> deterministic_digest()
    %{"algorithm" => @algorithm, "sha256" => digest}
  end

  def parameter_content_identity(_parameters),
    do: raise(ArgumentError, "parameters must be a non-empty finite numeric map")

  defp normalize_entries!(entries) when is_map(entries) do
    entries = JsonSafety.normalize_input!(entries, "source evidence registry entries")

    Map.new(entries, fn {alternative_id, entry} ->
      {stable_id!(alternative_id, "alternative_id"), normalize_entry!(entry)}
    end)
  end

  defp normalize_entries!(_entries),
    do: raise(ArgumentError, "source evidence registry entries must be a map")

  defp normalize_entry!(entry) when is_map(entry) do
    entry = JsonSafety.normalize_input!(entry, "source evidence registry entry")

    if Enum.sort(Map.keys(entry)) != Enum.sort(@entry_fields) do
      raise ArgumentError,
            "source evidence registry entry must contain exactly #{inspect(@entry_fields)}"
    end

    stable_id!(entry["parameter_revision"], "parameter_revision")
    stable_id!(entry["resource_state_trace_id"], "resource_state_trace_id")
    stable_id!(entry["downlink_link_budget_id"], "downlink_link_budget_id")
    validate_content_identity!(entry["parameter_content_identity"])
    entry
  end

  defp normalize_entry!(_entry),
    do: raise(ArgumentError, "source evidence registry entry must be a map")

  defp validate_content_identity!(%{"algorithm" => @algorithm, "sha256" => digest} = identity)
       when map_size(identity) == 2 and is_binary(digest) do
    unless Regex.match?(@sha256, digest) do
      raise ArgumentError, "registry parameter SHA-256 must be lowercase hexadecimal"
    end
  end

  defp validate_content_identity!(_identity) do
    raise ArgumentError,
          "registry parameter content identity must declare the supported algorithm and SHA-256"
  end

  defp stable_id!(value, field) when is_binary(value) do
    if Regex.match?(@stable_id, value),
      do: value,
      else: raise(ArgumentError, "source evidence registry #{field} must be a stable identity")
  end

  defp stable_id!(_value, field),
    do: raise(ArgumentError, "source evidence registry #{field} must be a stable identity")

  defp require_equal!(actual, expected, field) do
    unless actual == expected,
      do: raise(ArgumentError, "source evidence registry #{field} mismatch")
  end

  defp registry_id(core),
    do: "local_search_source_evidence_registry:" <> deterministic_digest(core)

  defp deterministic_digest(value) do
    value
    |> :erlang.term_to_binary([:deterministic])
    |> then(&:crypto.hash(:sha256, &1))
    |> Base.encode16(case: :lower)
  end

  defp finite_number?(value) when is_integer(value), do: true

  defp finite_number?(value) when is_float(value),
    do: value == value and value <= 1.7976931348623157e308 and value >= -1.7976931348623157e308

  defp finite_number?(_value), do: false
end
