# Funchaku

[![Travis](https://img.shields.io/travis/sitevalidator/funchaku.svg?style=flat-square)](https://travis-ci.org/sitevalidator/funchaku)
[![Hex.pm](https://img.shields.io/hexpm/v/funchaku.svg?style=flat-square)](https://hex.pm/packages/funchaku)

Funchaku is an Elixir client for the [Nu HTML Checker](https://github.com/validator/validator). It lets you easily check HTML markup of web pages, by querying a remote instance of the checker.

![Nunchaku image](https://dl.dropboxusercontent.com/u/2268180/nunchaku/Funchaku.png "Nunchaku image taken from http://commons.wikimedia.org/wiki/File:Nunchaku.png")

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed as:

  1. Add funchaku to your list of dependencies in `mix.exs`:

        def deps do
          [{:funchaku, "~> 0.3.0"}]
        end

  2. Ensure funchaku is started before your application:

        def application do
          [applications: [:funchaku]]
        end

## Usage

To check HTML on a web page, just pass it the URL to check, like this:

```elixir
{ status, results } = Funchaku.check("http://example.com")
```

You can also validate HTML passing directly the text, like this:

```elixir
{ status, results } = Funchaku.check_text """
  <!DOCTYPE html>
  <html>
  </html>
"""
```

Validation messages can be accessed like this:

```elixir
results[:messages]

# [%{"extract" => " href=\"/\"><img\n src=\"/images/fire.png\" align=\"absmiddle\"",
#    "firstColumn" => 37,
#    "firstLine" => 55,
#    "hiliteLength" => 69,
#    "hiliteStart" => 10, "lastColumn" => 64, "lastLine" => 56,
#    "message" => "The “align” attribute on the “img” element is obsolete. Use CSS instead.",
#    "type" => "error"}]
```

The `results[:messages]` list contains all messages returned by the checker, but you'll typically be more interested in `results[:errors]` (that contains all messages of type "error") and `results[:warnings]` (that contains all messages of subtype "warning"), and also in `results[:non_document_errors]` where you'll find errors related to 404s, misbehaving servers, etc.

## Using an alternate server

By default, Funchaku will query the Nu HTML Checker at http://validator.w3.org/nu but you're encouraged to install your own instance and use it instead. You can follow the [Nu installation instructions](https://github.com/validator/validator) and then specify the alternate server like this:

```elixir
Funchaku.check("http://example.com", checker_url: "http://example.com/validator")
```

## Specifying a custom User-Agent string

TO DO.

## Contributing

1. Fork it ( https://github.com/sitevalidator/nunchaku/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
