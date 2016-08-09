defmodule CheckerTest do
  use ExUnit.Case
  doctest Funchaku.Checker

  import Funchaku.Checker
  import Mock

  test "validates a URL" do
    with_mock HTTPoison, [get: fn(_url, _headers, _options) -> mocked_validation end] do
      { status, results } = check "http://validationhell.com"

      assert status == :ok

      messages = [ first_message | _ ] = results[:messages]
      errors   = [ first_error   | _ ] = results[:errors]
      warnings = [ first_warning | _ ] = results[:warnings]

      assert length(messages) == 12
      assert length(errors)   == 11
      assert length(warnings) ==  1

      warning = %{"extract" => "<!DOCTYPE html PUBLIC \"-//W3C//DTD XHTML 1.0 Strict//EN\" \"http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd\">\n<html",
                  "firstColumn" => 1, "hiliteLength" => 109, "hiliteStart" => 0, "lastColumn" => 109, "firstLine" => 1, "lastLine" => 1,
                  "message" => "Obsolete doctype. Expected “<!DOCTYPE html>”.", "subType" => "warning", "type" => "info"}

      error = %{"extract" => " href=\"/\"><img\n src=\"/images/fire.png\" align=\"absmiddle\" width=\"30\" hspace=\"5\"><stron",
                "firstColumn" => 37, "firstLine" => 55, "hiliteLength" => 69, "hiliteStart" => 10, "lastColumn" => 64, "lastLine" => 56,
                "message" => "The “align” attribute on the “img” element is obsolete. Use CSS instead.", "type" => "error"}

      assert first_message == warning
      assert first_warning == warning
      assert first_error   == error
    end
  end

  test "treats non-document-error separate from errors" do
    with_mock HTTPoison, [get: fn(_url, _headers, _options) -> mocked_validation_for_non_document_error end] do
      { status, results } = check "http://example.com/404"

      assert status == :ok

      messages            = [ first_message | _ ]            = results[:messages]
      non_document_errors = [ first_non_document_error | _ ] = results[:non_document_errors]

      assert length(messages) == 1
      assert length(non_document_errors) == 1

      error = %{ "message" => "HTTP resource not retrievable. The HTTP status from the remote server was: 404.",
                 "type"    => "non-document-error",
                 "subType" => "io"}

      assert first_message == error
      assert first_non_document_error == error
    end
  end

  test "firstLine is taken from lastLine if missing" do
    with_mock HTTPoison, [get: fn(_url, _headers, _options) -> mocked_validation end] do
      { :ok, results } = check "http://validationhell.com"

      [ first_message | [second_message | _] ] = results[:messages]

      assert first_message["firstLine"] == 1
      assert second_message["firstLine"] == 55
    end
  end

  test "validates via text" do
    with_mock HTTPoison, [post: fn(_url, _body) -> mocked_validation_for_text end] do
      { status, results } = check_text """
        <!DOCTYPE html>
        <html>
          <head>
            <script language='javascript'></script>
            <title>Test
          </head>
          <body>
            <p>
          </body>
        </html>
      """

      assert status == :ok

      messages = [ first_message | _ ] = results[:messages]
      errors   = [ first_error   | _ ] = results[:errors]
      warnings = [ first_warning | _ ] = results[:warnings]

      assert length(messages) == 3
      assert length(errors)   == 2
      assert length(warnings) == 1

      warning = %{ "hiliteStart"  => 10,
                   "extract"      => "          <script language='javascript'></scri",
                   "hiliteLength" => 30,
                   "lastColumn"   => 42,
                   "firstLine"    => 4,
                   "lastLine"     => 4,
                   "message"      => "The “language” attribute on the “script” element is obsolete. You can safely omit it.",
                   "type"         => "info",
                   "firstColumn"  => 13,
                   "subType"      => "warning"}

      error = %{ "hiliteLength"   => 1,
                 "hiliteStart"    => 10,
                 "firstLine"      => 10,
                 "lastLine"       => 10,
                 "message"        => "End of file seen when expecting text or an end tag.",
                 "type"           => "error",
                 "extract"        => "    </html>",
                 "lastColumn"     => 15}

      assert first_message == warning
      assert first_warning == warning
      assert first_error   == error
    end
  end

  test "uses http://validator.w3.org/nu/ by default" do
    with_mock HTTPoison, [get: fn("http://validator.w3.org/nu/?out=json&doc=http://validationhell.com", _headers, _options) -> mocked_validation end] do
      { :ok, _ } = check "http://validationhell.com"
    end
  end

  test "can use another validator via the checker_url option" do
    with_mock HTTPoison, [get: fn("http://example.com/validator/?out=json&doc=http://validationhell.com", _headers, _options) -> mocked_validation end] do
      { :ok, _ } = check("http://validationhell.com", checker_url: "http://example.com/validator/")
    end
  end

  test "handles http errors" do
    with_mock HTTPoison, [get: fn(_url, _headers, _options) -> mocked_http_error(:timeout) end] do
      { :error, :timeout } = check("http://example.com")
    end

    with_mock HTTPoison, [get: fn(_url, _headers, _options) -> mocked_http_error(:econnrefused) end] do
      { :error, :econnrefused } = check("http://example.com")
    end
  end

  test "treats non-200 status code as errors" do
    with_mock HTTPoison, [get: fn(_url, _headers, _options) -> mocked_response(301) end] do
      { :error, 301 } = check("http://example.com")
    end

    with_mock HTTPoison, [get: fn(_url, _headers, _options) -> mocked_response(404) end] do
      { :error, 404 } = check("http://example.com")
    end

    with_mock HTTPoison, [get: fn(_url, _headers, _options) -> mocked_response(500) end] do
      { :error, 500 } = check("http://example.com")
    end
  end

  defp mocked_validation do
    { :ok, %{ status_code: 200, body: mocked_json } }
  end

  defp mocked_json do
    """
    {
      "url": "http://validationhell.com",
      "messages": [{
        "type": "info",
        "lastLine": 1,
        "lastColumn": 109,
        "firstColumn": 1,
        "subType": "warning",
        "message": "Obsolete doctype. Expected “<!DOCTYPE html>”.",
        "extract": "<!DOCTYPE html PUBLIC \\"-//W3C//DTD XHTML 1.0 Strict//EN\\" \\"http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd\\">\n<html",
        "hiliteStart": 0,
        "hiliteLength": 109
      }, {
        "type": "error",
        "lastLine": 56,
        "firstLine": 55,
        "lastColumn": 64,
        "firstColumn": 37,
        "message": "The “align” attribute on the “img” element is obsolete. Use CSS instead.",
        "extract": " href=\\"/\\"><img\n src=\\"/images/fire.png\\" align=\\"absmiddle\\" width=\\"30\\" hspace=\\"5\\"><stron",
        "hiliteStart": 10,
        "hiliteLength": 69
      }, {
        "type": "error",
        "lastLine": 56,
        "firstLine": 55,
        "lastColumn": 64,
        "firstColumn": 37,
        "message": "The “hspace” attribute on the “img” element is obsolete. Use CSS instead.",
        "extract": " href=\\"/\\"><img\n src=\\"/images/fire.png\\" align=\\"absmiddle\\" width=\\"30\\" hspace=\\"5\\"><stron",
        "hiliteStart": 10,
        "hiliteLength": 69
      }, {
        "type": "error",
        "lastLine": 56,
        "firstLine": 55,
        "lastColumn": 64,
        "firstColumn": 37,
        "message": "An “img” element must have an “alt” attribute, except under certain conditions. For details, consult guidance on providing text alternatives for images.",
        "extract": " href=\\"/\\"><img\n src=\\"/images/fire.png\\" align=\\"absmiddle\\" width=\\"30\\" hspace=\\"5\\"><stron",
        "hiliteStart": 10,
        "hiliteLength": 69
      }, {
        "type": "error",
        "lastLine": 73,
        "lastColumn": 67,
        "firstColumn": 64,
        "message": "Stray end tag “a”.",
        "extract": "idates</a></a></li>\n",
        "hiliteStart": 10,
        "hiliteLength": 4
      }, {
        "type": "error",
        "lastLine": 83,
        "lastColumn": 66,
        "firstColumn": 62,
        "message": "End tag “li” seen, but there were open elements.",
        "extract": "e Abyss...</li>\n     ",
        "hiliteStart": 10,
        "hiliteLength": 5
      }, {
        "type": "error",
        "lastLine": 83,
        "lastColumn": 43,
        "firstColumn": 19,
        "message": "Unclosed element “a”.",
        "extract": "      <li><a href=\\"/pages/abyss/1\\">Enter ",
        "hiliteStart": 10,
        "hiliteLength": 25
      }, {
        "type": "error",
        "lastLine": 84,
        "firstLine": 83,
        "lastColumn": 12,
        "firstColumn": 67,
        "message": "Element “a” not allowed as child of element “ul” in this context. (Suppressing further errors from this subtree.)",
        "extract": "ss...</li>\n            </ul>\n",
        "hiliteStart": 10,
        "hiliteLength": 13
      }, {
        "type": "error",
        "lastLine": 84,
        "lastColumn": 17,
        "firstColumn": 13,
        "message": "End tag “ul” seen, but there were open elements.",
        "extract": "          </ul>\n\n    ",
        "hiliteStart": 10,
        "hiliteLength": 5
      }, {
        "type": "error",
        "lastLine": 87,
        "lastColumn": 161,
        "firstColumn": 15,
        "message": "An “a” start tag seen but an element of the same type was already open.",
        "extract": "          <a href=\\"https://twitter.com/share\\" class=\\"twitter-share-button\\" data-url=\\"http://validationhell.com\\" data-via=\\"SiteValidator\\" data-hashtags=\\"w3c\\">Tweet<",
        "hiliteStart": 10,
        "hiliteLength": 147
      }, {
        "type": "error",
        "lastLine": 87,
        "lastColumn": 161,
        "firstColumn": 15,
        "message": "End tag “a” violates nesting rules.",
        "extract": "          <a href=\\"https://twitter.com/share\\" class=\\"twitter-share-button\\" data-url=\\"http://validationhell.com\\" data-via=\\"SiteValidator\\" data-hashtags=\\"w3c\\">Tweet<",
        "hiliteStart": 10,
        "hiliteLength": 147
      }, {
        "type": "error",
        "lastLine": 87,
        "lastColumn": 161,
        "firstColumn": 15,
        "subType": "fatal",
        "message": "Cannot recover after last error. Any further errors will be ignored.",
        "extract": "          <a href=\\"https://twitter.com/share\\" class=\\"twitter-share-button\\" data-url=\\"http://validationhell.com\\" data-via=\\"SiteValidator\\" data-hashtags=\\"w3c\\">Tweet<",
        "hiliteStart": 10,
        "hiliteLength": 147
      }]
    }
    """
  end

  defp mocked_validation_for_non_document_error do
    { :ok, %{ status_code: 200, body: mocked_json_for_non_document_error } }
  end

  defp mocked_json_for_non_document_error do
    """
    {
      "url": "http://example.com/404",
      "messages": [{
        "type": "non-document-error",
        "subType": "io",
        "message": "HTTP resource not retrievable. The HTTP status from the remote server was: 404."
      }]
    }
    """
  end

  defp mocked_validation_for_text do
    { :ok, %{ status_code: 200, body: mocked_json_for_text } }
  end

  defp mocked_json_for_text do
    """
    {
      "messages": [{
        "type": "info",
        "lastLine": 4,
        "lastColumn": 42,
        "firstColumn": 13,
        "subType": "warning",
        "message": "The “language” attribute on the “script” element is obsolete. You can safely omit it.",
        "extract": "          <script language='javascript'></scri",
        "hiliteStart": 10,
        "hiliteLength": 30
      }, {
        "type": "error",
        "lastLine": 10,
        "lastColumn": 15,
        "message": "End of file seen when expecting text or an end tag.",
        "extract": "    </html>",
        "hiliteStart": 10,
        "hiliteLength": 1
      }, {
        "type": "error",
        "lastLine": 5,
        "lastColumn": 19,
        "firstColumn": 13,
        "message": "Unclosed element “title”.",
        "extract": "          <title>Test\n ",
        "hiliteStart": 10,
        "hiliteLength": 7
      }],
      "source": {
        "type": "text/html",
        "encoding": "utf-8",
        "code": "        <!DOCTYPE html>\n        <html>\n          <head>\n            <script language='javascript'></script>\n            <title>Test\n          </head>\n          <body>\n            <p>\n          </body>\n        </html>"
      }
    }
    """
  end

  defp mocked_response(status) do
    { :ok, %{ status_code: status } }
  end

  defp mocked_http_error(reason) do
    { :error, %HTTPoison.Error{id: nil, reason: reason} }
  end
end
