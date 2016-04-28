defmodule CheckerTest do
  use ExUnit.Case
  import Funchaku.Checker, only: [ check: 1 ]
  import Mock

  test "validates a URL" do
    with_mock HTTPoison, [get: fn(_url) -> mocked_validation end] do
      { status, results } = check "http://validationhell.com"

      assert status == :ok

      messages = [ first_message | _ ] = results[:messages]
      errors   = [ first_error   | _ ] = results[:errors]
      warnings = [ first_warning | _ ] = results[:warnings]

      assert length(messages) == 12
      assert length(errors)   == 11
      assert length(warnings) ==  1

      warning = %{"extract" => "<!DOCTYPE html PUBLIC \"-//W3C//DTD XHTML 1.0 Strict//EN\" \"http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd\">\n<html",
                  "firstColumn" => 1, "hiliteLength" => 109, "hiliteStart" => 0, "lastColumn" => 109, "lastLine" => 1,
                  "message" => "Obsolete doctype. Expected “<!DOCTYPE html>”.", "subType" => "warning", "type" => "info"}

      error = %{"extract" => " href=\"/\"><img\n src=\"/images/fire.png\" align=\"absmiddle\" width=\"30\" hspace=\"5\"><stron",
                "firstColumn" => 37, "firstLine" => 55, "hiliteLength" => 69, "hiliteStart" => 10, "lastColumn" => 64, "lastLine" => 56,
                "message" => "The “align” attribute on the “img” element is obsolete. Use CSS instead.", "type" => "error"}

      assert first_message == warning
      assert first_warning == warning
      assert first_error   == error
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
end
