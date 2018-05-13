defmodule Funchaku.Checker do
  @moduledoc """
  Provides methods to validate HTML on the Nu HTML Checker.
  """

  @doc """
  Validates the given URL on the Nu HTML Checker.

  Options:

  * Will use by default the validator at http://validator.w3.org/nu/, this can
  and should be customized to use your own validator, with the `checker_url` option.

  ## Examples

      iex> { :ok, results } = Funchaku.check("http://validationhell.com")
      iex> length(results[:messages])
      21
      iex> length(results[:errors])
      19
      iex> length(results[:warnings])
      2
      iex> List.first(results[:errors])["message"]
      "Obsolete doctype. Expected “<!DOCTYPE html>”."
  """
  def check(url, options \\ []) do
    options = Keyword.merge(default_options, options)

    vnu_request_querystring(options[:checker_url], url)
    |> HTTPoison.get([], [recv_timeout: 15_000])
    |> handle_response
  end

  @doc """
  Validates the given text on the Nu HTML Checker.

  Options:

  * Will use by default the validator at http://validator.w3.org/nu/, this can
  and should be customized to use your own validator, with the `checker_url` option.

  ## Examples

      iex> { :ok, results } = Funchaku.check_text "<!DOCTYPE html><html></html>"
      iex> length(results[:messages])
      2
      iex> length(results[:non_document_errors])
      0
      iex> length(results[:errors])
      1
      iex> length(results[:warnings])
      1
      iex> List.first(results[:errors])["message"]
      "Element “head” is missing a required instance of child element “title”."
  """
  def check_text(html, options \\ []) do
    options = Keyword.merge(default_options, options)

    options[:checker_url]
    |> HTTPoison.post({:multipart, [{ "out", "json" }, { "content", html }]})
    |> handle_response
  end

  defp vnu_request_querystring(checker_url, url) do
    query = URI.encode_query(%{ doc: url, out: "json" })

    "#{checker_url}?#{query}"
  end

  defp handle_response({ :ok, %{ status_code: 200, body: body }}) do
    { :ok, Poison.Parser.parse!(body) |> parsed_messages }
  end

  defp handle_response({ :ok, %{ status_code: status }}) do
    { :error, status }
  end

  defp handle_response({ :error, %{ reason: reason } }) do
    { :error, reason }
  end

  defp parsed_messages(json) do
    messages            = json["messages"] |> adapt_message_structure
    non_document_errors = Enum.filter(messages, &(&1["type"]    == "non-document-error"))
    errors              = Enum.filter(messages, &(&1["type"]    == "error"))
    warnings            = Enum.filter(messages, &(&1["subType"] == "warning"))
    extra               = ((messages -- non_document_errors) -- errors) -- warnings

    %{
       messages:            messages,
       non_document_errors: non_document_errors,
       errors:              errors,
       warnings:            warnings,
       extra:               extra
    }
  end

  def adapt_message_structure(messages) do
    Enum.map(messages, fn(m) ->
      if is_nil(m["firstLine"]) and not is_nil(m["lastLine"]) do
        Map.put(m, "firstLine", m["lastLine"])
      else
        m
      end
    end)
  end

  defp default_options do
    [
      checker_url: "http://validator.w3.org/nu/"
    ]
  end
end
