defmodule OrbitalDynamics.CandidateRefresh.SourceReports.EntryFallbacks do
  @moduledoc false

  def entries(path, values, entry_fun) when is_list(values) do
    values
    |> Enum.with_index()
    |> Enum.flat_map(fn {value, index} ->
      entries("#{path}[#{index}]", value, entry_fun)
    end)
  end

  def entries(path, %{} = value, entry_fun) do
    map_entry(path, value, entry_fun)
  end

  def entries(_path, _value, _entry_fun), do: []

  def map_entry(path, %{} = value, entry_fun) do
    entry_fun.(path, value)
    |> entries_from_result()
  end

  def map_entry(_path, _value, _entry_fun), do: []

  defp entries_from_result({_path, %{}} = entry), do: [entry]

  defp entries_from_result(entries) when is_list(entries), do: Enum.filter(entries, &entry?/1)

  defp entries_from_result(_entry), do: []

  defp entry?({_path, %{}}), do: true
  defp entry?(_entry), do: false
end
