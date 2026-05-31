; extends

(comment
  content: (_) @injection.content
  (#lua-match? @injection.content "^[-][%s]*[@|]")
  (#set! injection.language "luadoc")
  (#offset! @injection.content 0 1 0 0))

; string.match("123", "%d+")
(function_call
  (dot_index_expression
    field: (identifier) @_method
    (#any-of? @_method "find" "match" "gmatch" "gsub"))
  arguments: (arguments
    .
    (_)
    .
    (string
      content: (string_content) @injection.content
      (#set! injection.language "luap")
      (#set! injection.include-children))))

; ("123"):match("%d+")
(function_call
  (method_index_expression
    method: (identifier) @_method
    (#any-of? @_method "find" "match" "gmatch" "gsub"))
  arguments: (arguments
    .
    (string
      content: (string_content) @injection.content
      (#set! injection.language "luap")
      (#set! injection.include-children))))

; string.format("pi = %.2f", 3.14159)
((function_call
  (dot_index_expression
    field: (identifier) @_method)
  arguments: (arguments
    .
    (string
      (string_content) @injection.content)))
  (#eq? @_method "format")
  (#set! injection.language "printf"))

; ("pi = %.2f"):format(3.14159)
((function_call
  (method_index_expression
    table: (_
      (string
        (string_content) @injection.content))
    method: (identifier) @_method))
  (#eq? @_method "format")
  (#set! injection.language "printf"))

; vim.filetype.add({ pattern = { ["some lua pattern here"] = "filetype" } })
((function_call
  name: (_) @_filetypeadd_identifier
  arguments: (arguments
    (table_constructor
      (field
        name: (_) @_pattern_key
        value: (table_constructor
          (field
            name: (string
              content: _ @injection.content)))))))
  (#set! injection.language "luap")
  (#eq? @_filetypeadd_identifier "vim.filetype.add")
  (#eq? @_pattern_key "pattern"))
