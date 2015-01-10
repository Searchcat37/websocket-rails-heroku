USERNAME_REGEX = /(@[0-9a-zA-z][0-9a-zA-Z\-]{1,15})/

def hyperlink_mentions!(node)
  node.children.each do |child|
    if child.node_type == Nokogiri::XML::Node::ELEMENT_NODE and
      !child.matches?('code,td[class=code]')
      hyperlink_mentions! child
    elsif child.node_type == Nokogiri::XML::Node::TEXT_NODE
      set = []
      remaining = child.content
      until remaining.empty?
        head, match, remaining = remaining.partition(USERNAME_REGEX)
        set << child.document.create_text_node(head)
        unless match.empty?
          link = child.document.create_element("span")
          link.set_attribute('class', 'mention')
          # link.set_attribute('href', '/' + match[1..-1])
          link.content = match
          set << link
        end
      end
      if set.length > 1
        set = Nokogiri::XML::NodeSet.new(child.document, set)
        child.replace(set)
      end
    end
  end
end

def onebox_links!(node)
  node.children.each do |child|
    # We only care about oneboxing links.
    if !child.matches?('a')
      onebox_links!(child)
    else
      # We only onebox a link if it is one its own line.
      if child.parent.children.length === 1
        child["class"] = "onebox"
      end
    end
  end
end

class KSOMarkdown < Redcarpet::Render::XHTML

  def self.render(content)
    renderer = new(renderer_options)
    markdown = Redcarpet::Markdown.new(renderer, options)
    markdown.render(content)
  end

  def self.renderer_options
    {
      hard_wrap: true,
      link_attributes: {
        rel: "nofollow",
        target: "_blank"
      },
      escape_html: true
    }
  end

  def self.options
    {
      fenced_code_blocks: true,
      no_intra_emphasis: true,
      autolink: true,
      strikethrough: true,
      lax_html_blocks: true,
      superscript: true,
      tables: true,
      space_after_headers: true,
      xhtml: true
    }
  end

  def postprocess(html_content)
    dom = Nokogiri::HTML(html_content)
    body = dom.css("body").first
    if body
      # hyperlink_mentions! body
      # onebox_links! body
      return body.inner_html
    end
    ""
  end
end