defmodule OrbitalDynamics.Schema.StationCalendarProviderContentionContracts do
  @moduledoc false

  def validate_entry_count(issues, path, group) do
    case {Map.get(group, "entry_count"), Map.get(group, "entry_ids")} do
      {count, ids} when is_integer(count) and is_list(ids) and count != length(ids) ->
        [error(path <> ".entry_count", "must equal length of entry_ids") | issues]

      _value ->
        issues
    end
  end

  defp error(path, message) do
    %{"severity" => "error", "path" => path, "message" => message}
  end
end
