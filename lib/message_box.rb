class MessageBox

  module Type
    ALERT   = 0
    PROMPT  = 1
  end

  module ContentType
    INPUT   = "INPUT"
    MESSAGE = "P"
  end

  module Actions
    PRIMARY   = 1
    SECONDARY = 0
  end

  attr_accessor :message
  attr_accessor :type
  attr_accessor :message_box_id
  attr_accessor :contents

  def initialize(type = Type::ALERT, message = nil, contents = [])
    @message = message
    @type = type
    @message_box_id = "message_box_#{Time.now.to_i}"
    @contents = contents
  end

  def message_box
    %(
    var css_options = []

    #{build_skeleton}
    #{add_content if @type == Type::PROMPT}
    #{add_action_buttons}

    document.body.appendChild(balloon);

    css_options.forEach(function(option, i, options){
      Object.keys(option.css).forEach(function(element, i, array){
        assign_css(element, option.css[element], option.target);
      });
    });

    return balloon;
    )
  end

  def destroyer
    %(
    var target = document.getElementById("#{@message_box_id}");
    target.parentElement.removeChild(target);
    )
  end

  private

  def add_action_buttons
    %(
    var actions     = document.createElement("DIV");
    var primary     = document.createElement("BUTTON");
    var secondary   = document.createElement("BUTTON");
    var actions_css = {
      background: "white",
      padding: "20px",
      "border-radius": "0px 0px 10px 10px"
    }

    var button_clicked = function(e){
      e = e || window.event;
      var target = e.target || e.srcElement;
      var message = document.createElement("P");
      var hidden = document.createElement("INPUT");
      var value = target.id == "primary" ? "#{@type == Type::PROMPT ? "submit" : "ok"}" : "Cancel";
      var text = "You have clicked '" + value + "'";

      hidden.type = "hidden";
      hidden.value = target.id == "primary" ? "#{Actions::PRIMARY}" : "#{Actions::SECONDARY}";
      hidden.name = "choice";
      message.appendChild(document.createTextNode(text));
      actions.innerHTML = "";
      actions.appendChild(message);
      actions.appendChild(hidden);
      actions.id = "answered";
    }

    primary.id = "primary";
    secondary.id = "secondary";
    container.appendChild(actions);
    primary.appendChild(document.createTextNode("#{@type == Type::PROMPT ? "submit" : "ok"}"));
    secondary.appendChild(document.createTextNode("Cancel"));
    actions.appendChild(primary);
    actions.appendChild(secondary);

    if (primary.addEventListener) {
      primary.addEventListener("click", button_clicked);
    } else if (primary.attachEvent) {
      primary.attachEvent("onclick", button_clicked);
    }

    if (secondary.addEventListener) {
      secondary.addEventListener("click", button_clicked);
    } else if (secondary.attachEvent) {
      secondary.attachEvent("onclick", button_clicked);
    }

    css_options.push({ target: actions, css: actions_css });
    )
  end

  def parse_contents
    parsed_contents = @contents.map do |content|
      if content[:type] == ContentType::MESSAGE
        %(
        var message = document.createElement("P");
        message.appendChild(document.createTextNode("#{content[:value]}"));

        contents.appendChild(message);
        )
      else
        %(
        var group = document.createElement("DIV");
        var label = document.createElement("LABEL");
        var input = document.createElement("INPUT");

        label.appendChild(document.createTextNode("#{content[:label]}"));
        input.value = "#{content[:value]}";
        input.name = "#{content[:name]}";
        input.type = "#{content[:input_type] || 'text'}";

        group.appendChild(label);
        group.appendChild(input);
        contents.appendChild(group);
        )
      end
    end

    parsed_contents.join
  end

  def add_content
    %(
    var contents    = document.createElement("DIV");
    var content_css = {
      background: "white",
      padding: "20px"
    }

    container.appendChild(contents);
    css_options.push({ target: contents, css: content_css });

    #{parse_contents}
    )
  end

  def build_skeleton
    %(
    var balloon       = document.createElement("DIV");
    var border        = document.createElement("DIV");
    var container     = document.createElement("DIV");
    var instructions  = document.createElement("DIV");

    var message     = "#{@message}".trim() || document.title.trim();

    instructions.appendChild(document.createTextNode(message));
    container.appendChild(instructions);
    balloon.id = "#{@message_box_id}";
    border.appendChild(container);
    balloon.appendChild(border);

    var balloon_css = {
      position: "fixed",
      top: 0,
      left: 0,
      right: 0,
      bottom: 0,
      "z-index": 1000,
      background: "rgba(120,120,120, 0.5)"
    }

    var border_css = {
      width: "50%",
      padding: "20px",
      background: "rgba(128, 128, 128, 0.8)",
      "border-radius": "10px",
      position: "relative",
      "margin-top": "5%",
      "margin-right": "auto",
      "margin-left": "auto"
    }

    var container_css = {
    }

    var instruction_css = {
      margin: "0px",
      padding: "20px",
      background: "#FAFAFA",
      "border-radius": "10px 10px 0px 0px"
    }

    var assign_css = function(key, value, element){
      element.style[key] = value;
    }

    css_options.push({ target: balloon, css: balloon_css })
    css_options.push({ target: border, css: border_css })
    css_options.push({ target: container, css: container_css })
    css_options.push({ target: instructions, css: instruction_css })
    )
  end
end