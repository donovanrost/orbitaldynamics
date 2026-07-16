defmodule OrbitalDynamics.CampaignPlanner.ScoreTermValues do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.ScalarValues

  def key(key) when is_atom(key) do
    key
    |> Atom.to_string()
    |> key()
  end

  def key(key) when is_binary(key) do
    key
    |> String.trim()
    |> String.downcase()
    |> String.replace(~r/[\s-]+/, "_")
  end

  def key(key), do: key

  def value(row), do: value(row, callbacks())

  def value(row, callbacks) do
    numeric_or_nil = Keyword.fetch!(callbacks, :numeric_or_nil)
    numeric_or_nil.(row["value"])
  end

  def number(row, keys), do: number(row, keys, callbacks())

  def number(row, keys, callbacks) do
    numeric_or_nil = Keyword.fetch!(callbacks, :numeric_or_nil)

    score_terms =
      row
      |> Map.get("score_terms", %{})
      |> keyed_map()

    keys
    |> Enum.map(&numeric_or_nil.(Map.get(score_terms, &1)))
    |> Enum.find(&is_number/1)
  end

  defp callbacks do
    [
      numeric_or_nil: &ScalarValues.numeric_or_nil/1
    ]
  end

  defp keyed_map(score_terms) when is_map(score_terms) do
    Map.new(score_terms, fn {key, value} -> {key(key), value} end)
  end

  defp keyed_map(_score_terms), do: %{}
end
