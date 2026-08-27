defmodule OrbitalDynamics.Schema.JsonExport do
  @moduledoc false

  def bundle(contracts, opts, schema_fun) when is_map(contracts) and is_function(schema_fun, 1) do
    json_schema_draft = Keyword.fetch!(opts, :json_schema_draft)
    compatibility_policy = Keyword.fetch!(opts, :compatibility_policy)
    identity_policy = Keyword.fetch!(opts, :identity_policy)

    schemas =
      contracts
      |> Map.keys()
      |> Enum.sort()
      |> Map.new(fn name ->
        {:ok, schema} = schema_fun.(name)
        {name, schema}
      end)

    %{
      "$schema" => json_schema_draft,
      "$id" => "https://orbital-dynamics.local/schemas/orbital_dynamics.schema_bundle.v1.json",
      "title" => "OrbitalDynamics Artifact Schema Bundle",
      "schema_contract" => "orbital_dynamics.schema_bundle.v1",
      "schema_count" => map_size(schemas),
      "compatibility_policy" => compatibility_policy,
      "identity_policy" => identity_policy,
      "schemas" => schemas
    }
  end

  def write_schema!(name, path, schema_fun)
      when is_binary(name) and is_binary(path) and is_function(schema_fun, 1) do
    {:ok, schema} = schema_fun.(name)
    write_json!(schema, path)
  end

  def write_bundle!(bundle, path) when is_map(bundle) and is_binary(path) do
    write_json!(bundle, path)
  end

  def write_files!(contracts, directory, schema_fun)
      when is_map(contracts) and is_binary(directory) and is_function(schema_fun, 1) do
    contracts
    |> Map.keys()
    |> Enum.sort()
    |> Enum.map(fn name ->
      write_schema!(name, Path.join(directory, "#{name}.schema.json"), schema_fun)
    end)
  end

  defp write_json!(artifact, path) do
    json =
      artifact
      |> :json.encode()
      |> IO.iodata_to_binary()

    OrbitalDynamics.Release.SafeOutput.write!(path, json <> "\n")
  end
end
