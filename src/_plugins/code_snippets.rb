# _plugins/code_snippets.rb
# This plugin is a modification and builds up on include_absolute plugin.
# It provides `code` tag allows for the inclusion of code snippets with the following syntax:
# code <filename> [from: <line>] [to: <line>] [lines: <line1,line2,...>] [lang: <language>] [cmd] [log] [noheader] [nolink] [name: <name>]
# Just so you know, I am not a Ruby developer, so this code might not be the best Ruby code you have seen :)
module Jekyll
  class CodeSnippet < Liquid::Tag
    VALID_SYNTAX = %r!
        ([\w-]+)\s*=\s*
        (?:"([^"\\]*(?:\\.[^"\\]*)*)"|'([^'\\]*(?:\\.[^'\\]*)*)'|([\w\.-]+))
    !x
    VARIABLE_SYNTAX = %r!
      (?<variable>[^{]*(\{\{\s*[\w\-\.]+\s*(\|.*)?\}\}[^\s{}]*)+)
      (?<params>.*)
    !mx

    def parse_params(context)
      params = {}
      markup = @params

      while (match = VALID_SYNTAX.match(markup))
        raw_markup = markup[1..]
        markup = markup[match.end(0)..-1]
        value = if match[2]
                  match[2].gsub(%r!\\"!, '"')
                elsif match[3]
                  match[3].gsub(%r!\\'!, "'")
                elsif match[4]
                  context[match[4]]
                end
        params[match[1]] = value
      end
      params
    end

    def initialize(tag_name, markup, tokens)
      super
      matched = markup.strip.match(VARIABLE_SYNTAX)
      if matched
        @file = matched["variable"].strip
        @params = matched["params"].strip
      else
        @file, @params = markup.strip.split(%r!\s+!, 2)
      end
      @text = markup.strip
      @tag_name = tag_name
    end

    def print_lines_header(context,type)
      from,to,lines = get_lines(context,type)
      config = context.registers[:site].config['code']
      @options = context["include"] || {}
      return "" if @options["nolines"] or !config['header']['show_lines']
      if lines
        lines = lines.map { |x| x +1 }
        "(lines ##{lines.join(", ")})"
      elsif from && to && from != to
        "(lines ##{from+1} - ##{to+1})"
      elsif from && to && from == to
        "(lines ##{from+1})"
      else
        ""
      end
    end

    def block_name(context,type)
      config = context.registers[:site].config['code']
      @options = context["include"] || {}
      if type == @tag_name
        (@options["title"] ? @options["title"] : config['labels'][type]) % @file
      else
        config['labels'][type] % @file
      end
    end

    def print_icon(context, type="code")
      config = context.registers[:site].config['code']
      @options = context["include"] || {}
      if config['header']['use_icons']
        "<i class=\"fa-solid #{config['icons'][type]}\"></i> "
      else
        ""
      end
    end

    def make_full_pathname(context,type)
      config = context.registers[:site].config['code']
      dir_path = config['dirs'][type] || config['dirs']['code']
      subtype = type == "code" ? "" : "code/"
      extension = "."+config['exts'][type] if config['exts'][type] and type != "code"
      "#{subtype}#{dir_path}/#{@file}#{extension}"
    end

    def make_name_header(context,type)
      config = context.registers[:site].config['code']
      file_path = make_full_pathname(context,type)
      name_to_use = block_name(context,type)
      if type == "code" && config['header']['link_source'] && !@options["nolink"]
        "[#{name_to_use}]({{ site.url-source }}/#{file_path}) " 
      else
        name_to_use
      end
    end

    def print_header_symbol(context)
      config = context.registers[:site].config['code']
      "\n#{config['header']['style']} "
    end

    def print_header(context,type)
      config = context.registers[:site].config['code']
      @options = context["include"] || {}
      return "" if @options["noheader"] && type == "code"
      top = print_header_symbol(context)
      top << print_icon(context,type)
      top << make_name_header(context,type) 
      top << print_lines_header(context,type)
      top << " \n"
      return top
    end
    
    def filter_lines(block_of_code,from,to,lines)
      block_of_code = block_of_code[from..to] if from && to
      block_of_code = block_of_code.select.with_index { |_, i| lines.include?(i) } if lines
      block_of_code = block_of_code.join if block_of_code
      return "" if block_of_code.nil?
      return block_of_code
    end

    def get_lines(context,type)
      config = context.registers[:site].config['code']
      @options = context["include"] || {}
      from = @options["#{type[0]}from"] -1 if @options["#{type[0]}from"]
      to = @options["#{type[0]}to"] -1 if @options["#{type[0]}to"]
      lines_s = @options["#{type[0]}lines"]
      lines = lines_s.split(",") if @options["#{type[0]}lines"]
      lines = lines.map { |x| x.to_i - 1 } if lines
      return from,to,lines
    end

    def get_file_lines(context, type)
      config = context.registers[:site].config['code']
      @options = context["include"] || {}
      from,to,lines = get_lines(context,type)
      file_path = make_full_pathname(context,type)
      source = "{% include_absolute '#{file_path}' %}"
      block_of_code = Liquid::Template.parse(source).render(context).split("\n")
      return filter_lines(block_of_code,from,to,lines)
    end

    def render_single_block(context,type)
      config = context.registers[:site].config['code']
      @options = context["include"] || {}
      return "" if @tag_name == "code" && @options["nosource"]
      header = print_header(context,type)
      block_of_code = get_file_lines(context, type)
      language = @options["lang"] ? @options["lang"] : config["defaults"]["lang"]
      language = "" if type == "output"
      "#{header}  ```#{language}\n#{block_of_code}\n```\n"
    end
    
    def render_code(context)
      config = context.registers[:site].config['code']
      @options = context["include"] || {}
      return "" if @tag_name != "code"
      r = render_single_block(context, "code")
      if !@options["noshell"]
        r += render_single_block(context, "shell")
      end
      if !@options["noout"]
        r += render_single_block(context, "output")
      end
      r
    end

    def render_sh(context)
      config = context.registers[:site].config['code']
      @options = context["include"] || {}
      return "" if @tag_name != "shell"
      r = render_single_block(context, "shell")
      if !@options["noout"]
        r += render_single_block(context, "output")
      end
      r
    end
    
    def render_output(context)
      return "" if @tag_name != "output"
      render_single_block(context, "output")
    end
    
    def render(context)
      context.stack do
        context["include"] = parse_params(context) if @params
        full_snippet = render_code(context) + render_sh(context) + render_output(context)
        partial = Liquid::Template.parse(full_snippet)
        begin
          partial.render!(context)
        rescue Liquid::Error => e
          e.template_name = path
          e.markup_context = "included " if e.markup_context.nil?
          raise e
        end
      end
    end
  end
end

Liquid::Template.register_tag('code', Jekyll::CodeSnippet)
Liquid::Template.register_tag('shell', Jekyll::CodeSnippet)
Liquid::Template.register_tag('output', Jekyll::CodeSnippet)
