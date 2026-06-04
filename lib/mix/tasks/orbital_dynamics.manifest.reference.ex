defmodule Mix.Tasks.OrbitalDynamics.Manifest.Reference do
  @moduledoc """
  Prints a compact field reference for OrbitalDynamics study manifests.

  Usage:

      mix orbital_dynamics.manifest.reference
      mix orbital_dynamics.manifest.reference --format json
      mix orbital_dynamics.manifest.reference --output study_results/manifest_field_reference.json
  """

  use Mix.Task

  alias OrbitalDynamics.Study.Manifest

  @shortdoc "Prints the study manifest field reference"

  @impl Mix.Task
  def run(args) do
    opts = parse_args!(args)
    format = Keyword.fetch!(opts, :format)
    reference = Manifest.field_reference()

    maybe_write_reference(reference, Keyword.get(opts, :output))
    print_reference(reference, format)
  end

  defp parse_args!(args) do
    {parsed, rest, invalid} =
      OptionParser.parse(args, strict: [format: :string, output: :string])

    unless rest == [] and invalid == [] do
      Mix.raise("invalid manifest reference arguments: #{inspect(rest ++ invalid)}")
    end

    format = Keyword.get(parsed, :format, "text")

    unless format in ["text", "json"] do
      Mix.raise("--format must be text or json")
    end

    Keyword.put(parsed, :format, format)
  end

  defp maybe_write_reference(_reference, nil), do: :ok

  defp maybe_write_reference(reference, output_path) when is_binary(output_path) do
    output_path
    |> Path.dirname()
    |> File.mkdir_p!()

    json =
      reference
      |> :json.encode()
      |> IO.iodata_to_binary()

    File.write!(output_path, json <> "\n")
  end

  defp print_reference(reference, "json") do
    reference
    |> :json.encode()
    |> IO.iodata_to_binary()
    |> Mix.shell().info()
  end

  defp print_reference(reference, "text") do
    Mix.shell().info("")
    Mix.shell().info("OrbitalDynamics manifest field reference")
    Mix.shell().info("schema: #{reference["schema_contract"]}")
    Mix.shell().info("fields: #{reference["field_count"]}")
    Mix.shell().info("required: #{Enum.join(reference["top_level_required"], ",")}")
    Mix.shell().info("activation sections: #{Enum.join(reference["activation_sections"], ",")}")
    Mix.shell().info("supported outputs: #{Enum.join(reference["supported"]["outputs"], ",")}")

    Mix.shell().info(
      "lint error codes: #{Enum.join(reference["supported"]["lint_error_codes"], ",")}"
    )

    Mix.shell().info("stable ID pattern: #{reference["identity_policy"]["stable_id_pattern"]}")

    Mix.shell().info(
      "supported propagators: #{Enum.join(reference["supported"]["propagators"], ",")}"
    )

    Mix.shell().info("")

    Enum.each(reference["fields"], &print_field/1)
  end

  defp print_field(field) do
    required = if field["required"], do: "required", else: "optional"
    details = field_details(field)

    Mix.shell().info("#{field["path"]} #{field["type"]} #{required}#{details}")
  end

  defp field_details(field) do
    [
      field_detail("enum", field["enum"]),
      field_detail("const", field["const"]),
      field_detail("minItems", field["min_items"]),
      field_detail("maxItems", field["max_items"]),
      field_detail("minimum", field["minimum"]),
      field_detail("maximum", field["maximum"]),
      field_detail("schemaContract", field["schema_contract_ref"]),
      field_detail("additionalProperties", field["additional_properties_type"]),
      field_detail("stableIdPattern", field["stable_id_pattern"]),
      field_detail("trustBoundary", field["trust_boundary_sources"]),
      field_detail("nestedContracts", field["nested_contracts"]),
      field_detail("requiredChildren", field["required_children"]),
      field_detail("requiredAnyOf", field["required_alternatives"])
    ]
    |> Enum.reject(&is_nil/1)
    |> case do
      [] -> ""
      details -> " " <> Enum.join(details, " ")
    end
  end

  defp field_detail(_label, nil), do: nil

  defp field_detail(label, [first | _rest] = values) when is_list(first) do
    joined =
      values
      |> Enum.map(&Enum.join(&1, "+"))
      |> Enum.join("|")

    "#{label}=#{joined}"
  end

  defp field_detail(label, value) when is_list(value), do: "#{label}=#{Enum.join(value, "|")}"
  defp field_detail(label, value), do: "#{label}=#{value}"
end
