defmodule OrbitalDynamics.MissionAnalysis.Resource.Comparison do
  @moduledoc "Numerical ranges across all tested resource cadences; no cadence is assumed to be truth."
  def summarize(levels) do
    complete =
      levels != [] and
        Enum.all?(levels, &(is_map(&1["final_state"]) and &1["uncovered_intervals"] == []))

    if complete do
      keys =
        levels
        |> Enum.flat_map(fn l ->
          for {k, v} <- OrbitalDynamics.MissionAnalysis.NativeData.fields(l["final_state"]),
              is_number(v),
              do: k
        end)
        |> Enum.uniq()
        |> Enum.sort()

      final =
        Map.new(keys, fn k -> {k, range(Enum.map(levels, &Map.get(&1["final_state"], k)))} end)

      minima =
        Map.new(keys, fn k ->
          {k, range(Enum.map(levels, &get_in(&1, ["state_extrema", k, "min"])))}
        end)

      %{
        "status" =>
          if(Enum.any?(Map.values(final) ++ Map.values(minima), &(&1 == :null)),
            do: "incomplete_numeric_fields",
            else: "complete"
          ),
        "final_state_range" => final,
        "minimum_state_range" => minima,
        "limits" =>
          "ranges across tested cadences only, not physical error bounds or convergence proof"
      }
    else
      %{"status" => "incomplete", "final_state_range" => :null, "minimum_state_range" => :null}
    end
  end

  defp range(values) do
    if Enum.all?(values, &is_number/1),
      do: %{
        "min" => Enum.min(values),
        "max" => Enum.max(values),
        "spread" => Enum.max(values) - Enum.min(values)
      },
      else: :null
  rescue
    ArithmeticError -> :null
  end
end
