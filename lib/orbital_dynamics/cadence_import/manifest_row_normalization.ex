defmodule OrbitalDynamics.CadenceImport.ManifestRowNormalization do
  @moduledoc false

  alias OrbitalDynamics.CadenceImport.JsonNormalization

  def normalize(%{} = row, accepted_statuses) do
    case Map.fetch(row, "cadence_import_status") do
      {:ok, status} ->
        normalize_status(row, status, accepted_statuses)

      :error ->
        row
    end
  end

  defp normalize_status(row, status, accepted_statuses) do
    normalized_status = JsonNormalization.encode_json_value(status)

    if normalized_status in accepted_statuses do
      Map.put(row, "cadence_import_status", normalized_status)
    else
      row
      |> Map.put("cadence_import_status", "invalid")
      |> Map.put("import_status", "review_required_before_import")
      |> Map.put("has_cadence_import", false)
      |> Map.put("invalid_cadence_import", true)
      |> Map.put_new("invalid_cadence_import_reason", "unsupported_cadence_import_status")
      |> Map.put(
        "unsupported_cadence_import_status",
        JsonNormalization.encode_json_value(status)
      )
    end
  end
end
