defmodule OrbitalDynamics.CadenceImport.OperationalFeedbackManifestContext do
  @moduledoc false

  def build(%{} = provenance, callbacks) when is_list(callbacks) do
    %{
      "operational_feedback_trust_boundary_status" =>
        operational_feedback_trust_boundary_status(provenance, callbacks),
      "operational_feedback_trust_boundary" =>
        operational_feedback_trust_boundary(provenance, callbacks),
      "operational_feedback_trust_boundaries" =>
        operational_feedback_trust_boundaries(provenance, callbacks),
      "operational_feedback_field_trust_boundaries" =>
        operational_feedback_field_trust_boundaries(provenance, callbacks),
      "operational_feedback_input_keys" => provenance["input_keys"],
      "source_operational_feedback" => provenance["source_operational_feedback"],
      "source_operational_feedback_provenance" => provenance
    }
    |> compact_map(callbacks)
  end

  def build(_provenance, callbacks) when is_list(callbacks), do: %{}

  defp operational_feedback_trust_boundary_status(%{"sources" => sources}, callbacks)
       when is_list(sources) and is_list(callbacks) do
    statuses =
      sources
      |> Enum.map(&stringify_keys(&1, callbacks))
      |> Enum.map(& &1["trust_boundary_status"])
      |> Enum.reject(&is_nil/1)

    cond do
      "missing" in statuses ->
        "missing"

      operational_feedback_trust_boundaries(%{"sources" => sources}, callbacks) != [] ->
        "declared"

      "declared" in statuses ->
        "declared"

      true ->
        nil
    end
  end

  defp operational_feedback_trust_boundary_status(_provenance, callbacks)
       when is_list(callbacks),
       do: nil

  defp operational_feedback_trust_boundary(%{} = provenance, callbacks) do
    provenance
    |> operational_feedback_trust_boundaries(callbacks)
    |> case do
      [boundary] -> boundary
      _boundaries -> nil
    end
  end

  defp operational_feedback_trust_boundaries(%{} = provenance, callbacks) do
    provenance = stringify_keys(provenance, callbacks)

    direct_boundaries = [
      provenance["trust_boundary"],
      provenance["trust_boundaries"]
    ]

    source_boundaries =
      provenance
      |> Map.get("sources", [])
      |> List.wrap()
      |> Enum.flat_map(fn
        %{} = source ->
          source = stringify_keys(source, callbacks)

          [
            source["trust_boundary"],
            source["trust_boundaries"]
          ]

        _source ->
          []
      end)

    (direct_boundaries ++ source_boundaries)
    |> List.flatten()
    |> Enum.filter(&(is_binary(&1) and &1 != ""))
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp operational_feedback_field_trust_boundaries(%{} = provenance, callbacks) do
    provenance
    |> stringify_keys(callbacks)
    |> Map.get("sources", [])
    |> List.wrap()
    |> Enum.reduce(%{}, fn
      %{} = source, field_boundaries ->
        source = stringify_keys(source, callbacks)

        field_boundaries
        |> merge_feedback_field_trust_boundaries(
          source["feedback_trust_boundaries"],
          callbacks
        )
        |> merge_feedback_field_trust_boundaries(
          get_in(source, ["source_operational_feedback_provenance", "feedback_trust_boundaries"]),
          callbacks
        )

      _source, field_boundaries ->
        field_boundaries
    end)
    |> case do
      boundaries when boundaries == %{} -> nil
      boundaries -> boundaries
    end
  end

  defp merge_feedback_field_trust_boundaries(field_boundaries, %{} = incoming, callbacks) do
    incoming
    |> stringify_keys(callbacks)
    |> Enum.reduce(field_boundaries, fn {field, key_boundaries}, field_boundaries ->
      if is_map(key_boundaries) do
        normalized =
          key_boundaries
          |> stringify_keys(callbacks)
          |> Enum.reduce(%{}, fn {key, trust_boundaries}, normalized ->
            trust_boundaries =
              trust_boundaries
              |> List.wrap()
              |> Enum.map(&encode_json_value(&1, callbacks))
              |> Enum.reject(&(&1 in [nil, ""]))
              |> Enum.uniq()
              |> Enum.sort()

            if trust_boundaries == [] do
              normalized
            else
              Map.put(normalized, key, trust_boundaries)
            end
          end)

        Map.update(field_boundaries, field, normalized, fn existing ->
          Map.merge(existing, normalized, fn _key, left, right ->
            (left ++ right) |> Enum.uniq() |> Enum.sort()
          end)
        end)
      else
        field_boundaries
      end
    end)
  end

  defp merge_feedback_field_trust_boundaries(field_boundaries, _incoming, callbacks)
       when is_list(callbacks),
       do: field_boundaries

  defp stringify_keys(value, callbacks),
    do: apply(Keyword.fetch!(callbacks, :stringify_keys), [value])

  defp encode_json_value(value, callbacks),
    do: apply(Keyword.fetch!(callbacks, :encode_json_value), [value])

  defp compact_map(value, callbacks),
    do: apply(Keyword.fetch!(callbacks, :compact_map), [value])
end
