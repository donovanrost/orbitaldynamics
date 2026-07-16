defmodule OrbitalDynamics.OperatorReview.WarningReview do
  @moduledoc false

  def rows(warnings, source) do
    warnings
    |> Enum.map(&encode_value/1)
    |> Enum.with_index(1)
    |> Enum.map(fn {warning, index} ->
      %{
        "id" => review_id(["warning", source, index]),
        "review_type" => "warning",
        "source" => source,
        "subject_id" => "warning:#{index}",
        "action" => "review_warning",
        "required_operator_action" => "review_warning",
        "approval_status" => "operator_review_required",
        "reason" => warning,
        "severity" => "warning"
      }
    end)
  end

  def candidate_refresh_rows(artifact) do
    artifact = stringify_keys(artifact)
    rows = rows(Map.get(artifact, "warnings", []), "candidate_refresh.warnings")

    case get_in(artifact, ["provenance", "operational_feedback"]) do
      %{} = feedback_provenance ->
        context = operational_feedback_warning_context(feedback_provenance)
        Enum.map(rows, &Map.merge(&1, context))

      _feedback_provenance ->
        rows
    end
  end

  def strategy_rows(branches) do
    branches
    |> Enum.map(&stringify_keys/1)
    |> Enum.flat_map(fn branch ->
      branch
      |> Map.get("warnings", [])
      |> Enum.map(&encode_value/1)
      |> Enum.with_index(1)
      |> Enum.map(fn {warning, index} ->
        branch_id = Map.get(branch, "branch_id")

        %{
          "id" => review_id(["warning", "campaign_strategy.branch", branch_id, index]),
          "review_type" => "warning",
          "source" => "campaign_strategy.branches.warnings",
          "subject_id" => branch_id,
          "branch_id" => branch_id,
          "action" => "review_branch_warning",
          "required_operator_action" => "review_branch_warning",
          "approval_status" => "operator_review_required",
          "reason" => warning,
          "severity" => "warning"
        }
        |> compact_map()
      end)
    end)
  end

  defp operational_feedback_warning_context(feedback_provenance) do
    %{
      "operational_feedback_trust_boundary_status" =>
        feedback_provenance["trust_boundary_status"],
      "operational_feedback_trust_boundary" => feedback_provenance["trust_boundary"],
      "operational_feedback_trust_boundaries" =>
        operational_feedback_trust_boundaries(feedback_provenance),
      "operational_feedback_field_trust_boundaries" =>
        operational_feedback_field_trust_boundaries(feedback_provenance),
      "operational_feedback_input_keys" => feedback_provenance["input_keys"],
      "source_operational_feedback" => feedback_provenance["source_operational_feedback"],
      "source_operational_feedback_provenance" => feedback_provenance
    }
    |> compact_map()
  end

  defp operational_feedback_trust_boundaries(%{} = provenance) do
    provenance = stringify_keys(provenance)

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
          source = stringify_keys(source)

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

  defp operational_feedback_field_trust_boundaries(%{} = provenance) do
    provenance
    |> stringify_keys()
    |> Map.get("sources", [])
    |> List.wrap()
    |> Enum.reduce(%{}, fn
      %{} = source, field_boundaries ->
        source = stringify_keys(source)

        field_boundaries
        |> merge_feedback_field_trust_boundaries(source["feedback_trust_boundaries"])
        |> merge_feedback_field_trust_boundaries(
          get_in(source, ["source_operational_feedback_provenance", "feedback_trust_boundaries"])
        )

      _source, field_boundaries ->
        field_boundaries
    end)
    |> case do
      boundaries when boundaries == %{} -> nil
      boundaries -> boundaries
    end
  end

  defp merge_feedback_field_trust_boundaries(field_boundaries, %{} = incoming) do
    incoming
    |> stringify_keys()
    |> Enum.reduce(field_boundaries, fn {field, key_boundaries}, field_boundaries ->
      if is_map(key_boundaries) do
        normalized =
          key_boundaries
          |> stringify_keys()
          |> Enum.reduce(%{}, fn {key, trust_boundaries}, normalized ->
            trust_boundaries =
              trust_boundaries
              |> List.wrap()
              |> Enum.map(&encode_value/1)
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

  defp merge_feedback_field_trust_boundaries(field_boundaries, _incoming), do: field_boundaries

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
end
