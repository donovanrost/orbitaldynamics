defmodule OrbitalDynamics.Schema.StationCalendarProviderJsonSchema do
  @moduledoc false

  def property_field?("entries"), do: true
  def property_field?(_field), do: false

  def property_opts("entries", deps) do
    [entry_schema: fetch_dep!(deps, :entry_schema)]
  end

  def property_opts(_field, _deps), do: []

  def property_from_context(field, deps) when is_list(deps) do
    property(
      field,
      property_opts(field, deps)
    )
  end

  def property_fun_from_context(deps) when is_list(deps) do
    fn field -> property_from_context(field, deps) end
  end

  def property("entries", opts) do
    %{
      "type" => "array",
      "items" => Keyword.fetch!(opts, :entry_schema)
    }
  end

  defp fetch_dep!(deps, key), do: Keyword.fetch!(deps, key)
end
