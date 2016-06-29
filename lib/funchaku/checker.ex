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
    11
    iex> length(results[:errors])
    11
    iex> length(results[:warnings])
    0
    iex> List.first(results[:errors])["message"]
    "The “align” attribute on the “img” element is obsolete. Use CSS instead."
  """
  def check(url, options \\ []) do
    options = Keyword.merge(default_options, options)

    vnu_request_querystring(options[:checker_url], url)
    |> HTTPoison.get
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
    1
    iex> length(results[:errors])
    1
    iex> length(results[:warnings])
    0
    iex> List.first(results[:errors])["message"]
    "Element “head” is missing a required instance of child element “title”."
  """
  def check_text(html, options \\ []) do
    options = Keyword.merge(default_options, options)

    options[:checker_url]
    |> HTTPoison.post({:multipart, [{"out", "json"}, {"content", html}]})
    |> handle_response
  end

  defp vnu_request_querystring(checker_url, url) do
    "#{checker_url}?out=json&doc=#{url}"
  end

  defp handle_response({ :ok, %{ status_code: 200, body: body }}) do
    { :ok,    Poison.Parser.parse!(body) |> parsed_messages }
  end

  defp handle_response({ :ok, %{ status_code: status }}) do
    { :error, status }
  end

  defp handle_response({ :error, %{ reason: reason } }) do
    { :error, reason }
  end

  defp parsed_messages(json) do
    messages = json["messages"]
    errors   = Enum.filter(messages, &(&1["type"]    == "error"))
    warnings = Enum.filter(messages, &(&1["subType"] == "warning"))
    extra    = (messages -- errors) -- warnings

    %{
       messages: messages,
       errors:   errors,
       warnings: warnings,
       extra:    extra
    }
  end

  defp default_options do
    [
      checker_url: "http://validator.w3.org/nu/"
    ]
  end
end
