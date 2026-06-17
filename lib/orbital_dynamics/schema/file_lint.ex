defmodule OrbitalDynamics.Schema.FileLint do
  @moduledoc false

  def lint_file(path, opts, validate_fun)
      when is_binary(path) and is_list(opts) and is_function(validate_fun, 2) do
    path
    |> decode_json_file()
    |> validate_fun.(opts)
  end

  def lint_file_report(path, opts, validation_report_fun)
      when is_binary(path) and is_list(opts) and is_function(validation_report_fun, 2) do
    artifact = decode_json_file(path)

    validation_report_fun.(
      artifact,
      opts
      |> Keyword.put(:validation_mode, "artifact_file")
      |> Keyword.put(:artifact_path, path)
    )
  end

  defp decode_json_file(path) do
    path
    |> File.read!()
    |> :json.decode()
  end
end
