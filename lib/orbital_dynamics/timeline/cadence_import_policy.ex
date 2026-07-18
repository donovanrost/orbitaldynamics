defmodule OrbitalDynamics.Timeline.CadenceImportPolicy do
  @moduledoc false

  def cadence_import(%{"cadence_import" => cadence_import} = activity, stable_activity_id?)
      when is_map(cadence_import) do
    if invalid_cadence_import?(activity, stable_activity_id?), do: %{}, else: cadence_import
  end

  def cadence_import(_activity, _stable_activity_id?), do: %{}

  def invalid_cadence_import?(
        %{"cadence_import" => cadence_import},
        stable_activity_id?
      ),
      do: cadence_import_issue(cadence_import, stable_activity_id?) != nil

  def invalid_cadence_import?(_activity, _stable_activity_id?), do: false

  def invalid_cadence_import_context(
        %{"cadence_import" => cadence_import},
        _stable_activity_id?,
        encode_value
      )
      when not is_map(cadence_import) do
    %{
      "invalid_cadence_import" => true,
      "invalid_cadence_import_reason" => "cadence_import_must_be_object",
      "source_cadence_import" => %{"invalid_import_shape" => encode_value.(cadence_import)}
    }
  end

  def invalid_cadence_import_context(
        %{"cadence_import" => cadence_import},
        stable_activity_id?,
        _encode_value
      )
      when is_map(cadence_import) do
    case cadence_import_issue(cadence_import, stable_activity_id?) do
      nil ->
        %{}

      reason ->
        %{
          "invalid_cadence_import" => true,
          "invalid_cadence_import_reason" => reason,
          "source_cadence_import" => cadence_import
        }
    end
  end

  def invalid_cadence_import_context(_activity, _stable_activity_id?, _encode_value), do: %{}

  def cadence_import_issue(cadence_import, _stable_activity_id?)
      when not is_map(cadence_import),
      do: "cadence_import_must_be_object"

  def cadence_import_issue(cadence_import, stable_activity_id?) do
    cond do
      cadence_import_external_id_issue?(cadence_import, stable_activity_id?) ->
        "invalid_cadence_import_external_id"

      cadence_import_adapter_context?(cadence_import) and
          missing_cadence_import_trust_boundary?(cadence_import) ->
        "missing_cadence_import_trust_boundary"

      true ->
        nil
    end
  end

  def drop_invalid_activity_context_cadence_import(context, activity, stable_activity_id?) do
    if invalid_cadence_import?(activity, stable_activity_id?),
      do: Map.delete(context, "cadence_import"),
      else: context
  end

  defp cadence_import_external_id_issue?(cadence_import, stable_activity_id?) do
    case Map.get(cadence_import, "external_id") do
      value when value in [nil, ""] -> false
      value when is_binary(value) -> not stable_activity_id?.(value)
      _value -> true
    end
  end

  defp cadence_import_adapter_context?(cadence_import) do
    Enum.any?(["provider", "adapter", "adapter_version"], &Map.has_key?(cadence_import, &1))
  end

  defp missing_cadence_import_trust_boundary?(cadence_import) do
    case Map.get(cadence_import, "trust_boundary") ||
           get_in(cadence_import, ["provenance", "trust_boundary"]) do
      value when is_binary(value) and value != "" -> false
      _value -> true
    end
  end
end
