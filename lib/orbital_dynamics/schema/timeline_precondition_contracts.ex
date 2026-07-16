defmodule OrbitalDynamics.Schema.TimelinePreconditionContracts do
  @moduledoc false

  def validate_optional(issues, path, map, field, callbacks)
      when is_map(map) and is_list(callbacks) do
    case Map.get(map, field) do
      rows when is_list(rows) ->
        rows
        |> Enum.with_index()
        |> Enum.reduce(issues, fn
          {%{} = row, index}, acc ->
            validate_precondition(acc, "#{path}.#{field}[#{index}]", row, callbacks)

          {_row, index}, acc ->
            [error(callbacks, "#{path}.#{field}[#{index}]", "must be an object") | acc]
        end)

      _value ->
        issues
    end
  end

  defp validate_precondition(issues, path, row, callbacks) do
    issues
    |> expect_one_of(
      callbacks,
      path,
      row,
      "type",
      OrbitalDynamics.Timeline.capabilities().activity_precondition_types
    )
    |> expect_one_of(
      callbacks,
      path,
      row,
      "status",
      OrbitalDynamics.Timeline.capabilities().activity_precondition_statuses
    )
    |> expect_type(callbacks, path, row, "field", :binary)
    |> expect_type(callbacks, path, row, "reason", :binary)
  end

  defp expect_one_of(issues, callbacks, path, map, field, allowed),
    do:
      apply(require_callback(callbacks, :expect_one_of), [
        issues,
        path,
        map,
        field,
        allowed
      ])

  defp expect_type(issues, callbacks, path, map, field, type),
    do:
      apply(require_callback(callbacks, :expect_type), [
        issues,
        path,
        map,
        field,
        type
      ])

  defp error(callbacks, path, message),
    do: apply(require_callback(callbacks, :error), [path, message])

  defp require_callback(callbacks, name) do
    Keyword.fetch!(callbacks, name)
  end
end
