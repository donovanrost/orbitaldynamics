defmodule OrbitalDynamics.Study.Manifest.ValidationError do
  @moduledoc false

  def build({:missing_field, field}, _schema_version) when is_binary(field) do
    error("missing_field", manifest_path(field), "required field is missing: #{field}", %{
      "field" => field
    })
  end

  def build({:invalid_field, field}, _schema_version) when is_binary(field) do
    error("invalid_field", manifest_path(field), "field has an invalid value: #{field}", %{
      "field" => field
    })
  end

  def build({:unsupported_schema_version, version}, schema_version) do
    error(
      "unsupported_schema_version",
      "$.schema_version",
      "unsupported study manifest schema_version: #{inspect(version)}",
      %{"expected" => schema_version, "actual" => json_safe(version)}
    )
  end

  def build({:unsupported_central_body, value}, _schema_version) do
    error("unsupported_central_body", "$.central_body", "unsupported central_body", %{
      "actual" => json_safe(value)
    })
  end

  def build({:unsupported_propagator, value}, _schema_version) do
    error("unsupported_propagator", "$.propagator", "unsupported propagator", %{
      "actual" => json_safe(value)
    })
  end

  def build({:unsupported_output, value}, _schema_version) do
    error("unsupported_output", "$.outputs", "unsupported output", %{
      "actual" => json_safe(value)
    })
  end

  def build({:invalid_output, value}, _schema_version) do
    error("invalid_output", "$.outputs", "output entries must be supported strings", %{
      "actual" => json_safe(value)
    })
  end

  def build({:missing_option, option}, _schema_version) when is_atom(option) do
    option = Atom.to_string(option)

    error(
      "missing_run_option",
      manifest_option_path(option),
      "required run option is missing: #{option}",
      %{"option" => option}
    )
  end

  def build({:invalid_option, option}, _schema_version) when is_atom(option) do
    option = Atom.to_string(option)

    error(
      "invalid_run_option",
      manifest_option_path(option),
      "run option has an invalid value: #{option}",
      %{"option" => option}
    )
  end

  def build({:unsupported_option, field, option}, _schema_version)
      when is_binary(field) and is_binary(option) do
    error("unsupported_option", manifest_path("#{field}.#{option}"), "unsupported option", %{
      "field" => field,
      "option" => option
    })
  end

  def build({:file_error, reason, path}, _schema_version) do
    error("file_error", "$", "could not read manifest file", %{
      "file_reason" => to_string(reason),
      "path" => path
    })
  end

  def build({:invalid_json, :expected_object}, _schema_version) do
    error("invalid_json_object", "$", "manifest JSON must decode to an object", %{})
  end

  def build(:invalid_json, _schema_version) do
    error("invalid_json", "$", "manifest file is not valid JSON", %{})
  end

  def build({:invalid_manifest, message}, _schema_version) do
    error("invalid_manifest", "$", to_string(message), %{})
  end

  def build(reason, _schema_version) do
    error("manifest_error", "$", "manifest validation failed", %{
      "reason" => inspect(reason)
    })
  end

  defp manifest_option_path("ground_stations"), do: "$.ground_stations"
  defp manifest_option_path("targets"), do: "$.targets"
  defp manifest_option_path("ground_track_crossings"), do: "$.ground_track_crossings"
  defp manifest_option_path(option), do: manifest_path(option)

  defp error(code, path, message, details) do
    %{
      "code" => code,
      "path" => path,
      "message" => message,
      "details" => details
    }
  end

  defp manifest_path(field), do: "$." <> field

  defp json_safe(value) do
    value
    |> :json.encode()
    |> :json.decode()
  rescue
    _error -> inspect(value)
  end
end
