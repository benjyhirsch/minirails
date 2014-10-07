require_relative '../phase2/controller_base'
require 'active_support/core_ext'
require 'erb'

module Phase3
  class ControllerBase < Phase2::ControllerBase
    # use ERB and binding to evaluate templates
    # pass the rendered html to render_content
    def render(template_name)
      ivar_binding = binding
      controller_name = self.class.name.underscore
      f = File.read("views/#{controller_name}/#{template_name}.html.erb")
      html = ERB.new(f).result(ivar_binding)
      render_content(html, 'text/html')
    end
  end
end
