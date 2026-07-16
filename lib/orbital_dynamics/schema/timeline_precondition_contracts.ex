defmodule OrbitalDynamics.Schema.TimelinePreconditionContracts do
  @moduledoc false

  alias OrbitalDynamics.Schema.PrimitiveValidation

  def validate_optional(issues, path, map, field) when is_map(map) do
    case Map.get(map, field) do
      rows when is_list(rows) ->
        rows
        |> Enum.with_index()
        |> Enum.reduce(issues, fn
          {%{} = row, index}, acc ->
            validate_precondition(acc, "#{path}.#{field}[#{index}]", row)

          {_row, index}, acc ->
            [PrimitiveValidation.error("#{path}.#{field}[#{index}]", "must be an object") | acc]
        end)

      _value ->
        issues
    end
  end

  defp validate_precondition(issues, path, row) do
    issues
    |> PrimitiveValidation.expect_one_of(
      path,
      row,
      "type",
      OrbitalDynamics.Timeline.capabilities().activity_precondition_types
    )
    |> PrimitiveValidation.expect_one_of(
      path,
      row,
      "status",
      OrbitalDynamics.Timeline.capabilities().activity_precondition_statuses
    )
    |> PrimitiveValidation.expect_type(path, row, "field", :binary)
    |> PrimitiveValidation.expect_type(path, row, "reason", :binary)
  end
end
