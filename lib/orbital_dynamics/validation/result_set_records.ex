defmodule OrbitalDynamics.Validation.ResultSetRecords do
  @moduledoc false

  def build(assumptions, registry, propagator_ids, output_ids)
      when is_map(assumptions) and is_map(registry) and is_map(propagator_ids) and
             is_map(output_ids) do
    assumptions
    |> validation_ids(propagator_ids, output_ids)
    |> Enum.uniq()
    |> Enum.map(&Map.fetch!(registry, &1))
  end

  defp validation_ids(assumptions, propagator_ids, output_ids) do
    []
    |> maybe_add_propagator(
      Map.get(assumptions, :propagator) || Map.get(assumptions, "propagator"),
      propagator_ids
    )
    |> add_outputs(
      Map.get(assumptions, :outputs) || Map.get(assumptions, "outputs") || [],
      output_ids
    )
  end

  defp maybe_add_propagator(ids, propagator, propagator_ids) do
    case Map.fetch(propagator_ids, propagator) do
      {:ok, id} -> [id | ids]
      :error -> ids
    end
  end

  defp add_outputs(ids, outputs, output_ids) when is_list(outputs) do
    output_ids =
      outputs
      |> Enum.map(&Map.get(output_ids, &1))
      |> Enum.reject(&is_nil/1)

    ids ++ output_ids
  end

  defp add_outputs(ids, _outputs, _output_ids), do: ids
end
