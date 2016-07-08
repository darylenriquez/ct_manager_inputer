require 'clipboard'
require 'pry'

class StoryBoard
  attr_accessor :plot
  attr_accessor :heading
  
  def get_to_next_row
    @heading.length.times { @plot.move_to nil, :arrow_left}
    @plot.move_to nil, :arrow_down
  end
  
  def try_ct_manager_login
    if @plot.execute_block{|driver| driver.current_url}.include?("sign_in")
      @plot.execute_block do |driver|
        login_id = driver.find_element id: "user_login_id"
        password = driver.find_element id: "user_password"

        "administrator".split("").each{|letter| login_id.send_keys(letter)}
        "password".split("").each{|letter| password.send_keys(letter)}

        find_and_click_button(:css, "input[type=submit]")
      end
    end
  end

  def copy_vertical(array = [])
    element = @plot.get_element(:xpath, '//table/tbody/tr/td[3]/div/div')

    @plot.wait_for {|driver| element.displayed? }
    @plot.copy_input_from(element)

    item = Clipboard.paste

    if(element.text.strip == "" || array.length > 10)
      return array
    else
      array << item
      @plot.move_to element, :arrow_right
      copy_vertical(array)
    end
  end
  
  def copy_and_paste_value(property)
    @plot.switch_tab

    element = @plot.get_element(:xpath, '//table/tbody/tr/td[3]/div/div')

    @plot.move_to element, :arrow_right
    @plot.copy_input_from(element)

    item = Clipboard.paste
    puts "#{property} : #{item}"

    @plot.switch_tab
    @plot.paste_input_to(@plot.get_element(:css, "input[name='user[#{property}]']")) if @plot.get_url.include?("localhost:3000")
    @plot.sleep_for(0.5)
  end
  
  def find_and_click_button(method, selector)
    element = @plot.get_element(method, selector)
    element.click
  end

  def try_google_login_without_popup
    visible_panel_query = %(
      var panels = document.querySelectorAll(".form-panel");
      var visible_panel;

      for(var n = 0; n < panels.length; n++) {
        if(panels[n].offsetHeight > 0){
          visible_panel = panels[n]
          break;
        }
      }

      return visible_panel;
    )

    if visible_panel = @plot.execute_block { |driver| driver.execute_script(visible_panel_query) }
      inputs     = visible_panel.find_elements(css: %( input[type='email']:not(.hidden), input[type='password']:not(.hidden) ))

      inputs.each do |input| 
        value = if input.attribute("type") == "email"
          "daryl.enriquez@adish.co.jp".split("")
        elsif input.attribute("type") == "password"
          "decoder2108192".split("")
        else
          ""
        end
        value.each {|character| input.send_keys(character)}
        # input.send_keys(*value)

        submit_button = visible_panel.find_element(css: %( input[type='submit']:not(.hidden) ))
        submit_button.click

        @plot.wait_for do |driver|
          begin
            if form = driver.find_elements(css: "form#gaia_loginform").first
              mask = driver.find_element(css: "div.card-mask-wrap.no-name")

              if mask.attribute("className").include?("shift-form")
                visible_panel.attribute("offsetHeight").to_s == "0"
              else
                mask.attribute("className").include?("has-error")
              end
            else
              driver.execute_script("return document.readyState;") == "complete" 
            end
          rescue
            driver.execute_script("return document.readyState;") == "complete" 
          end
        end

        try_google_login_without_popup
      end
    else
      puts "No Visible Panel Found"
      return true
    end
  end

  def try_google_login
    puts "start try login"

    visible_panel_query = %(
      var panels = document.querySelectorAll(".form-panel");
      var visible_panel;

      for(var n = 0; n < panels.length; n++) {
        if(panels[n].offsetHeight > 0){
          visible_panel = panels[n]
          break;
        }
      }

      return visible_panel;
    )

    visible_panel = @plot.execute_block { |driver| driver.execute_script(visible_panel_query) }

    if(visible_panel)
      inputs     = visible_panel.find_elements(css: %( input[type='email']:not(.hidden), input[type='password']:not(.hidden) ))
      input_keys = inputs.map do |input| 
        {
          label: input.attribute("name"),
           name: input.attribute("name"),
           type: input.attribute("type"),
          value: "#{input.attribute("type") == 'email' ? 'daryl.enriquez@adish.co.jp' : 'decoder2108192'}"
        }
      end

      return if input_keys.length.zero?

      if(@plot.show_input_for(input_keys))
        submit_button = visible_panel.find_element(css: %( input[type='submit']:not(.hidden) ))
        submit_button.click

        @plot.wait_for do |driver|
          begin
            if form = driver.find_elements(css: "form#gaia_loginform").first
              mask = driver.find_element(css: "div.card-mask-wrap.no-name")

              if mask.attribute("className").include?("shift-form")
                visible_panel.attribute("offsetHeight").to_s == "0"
              else
                mask.attribute("className").include?("has-error")
              end
            else
              driver.execute_script("return document.readyState;") == "complete" 
            end
          rescue
            driver.execute_script("return document.readyState;") == "complete" 
          end
        end

        try_google_login
      else
        puts "cancelled login means cancel automation."
      end
    else
      puts "No Visible Panel Found"
      return true
    end
  end
  
  def display_ending_message
    prompt = MessageBox.new(MessageBox::Type::ALERT, "Automation done!")
    box = @plot.execute_block { |driver| driver.execute_script(prompt.message_box) }
    @plot.wait_for do |driver|
      box.find_element(css: "#answered") rescue false
    end
    @plot.execute_block { |driver| driver.execute_script("#{prompt.destroyer}\r\n return document.body;") }
  end
  
  def run
    @plot = StoryPlot.new
    @plot.maximize_window
    @plot.go_to "http://localhost:3000"

    try_ct_manager_login

    @plot.wait_for_document_ready
    # @plot.go_to "http://localhost:3000/admin/users"
    find_and_click_button(:css, "#bs-example-navbar-collapse-1 .dropdown-toggle")
    @plot.wait_for do |driver|
      !driver.find_elements(css: "#bs-example-navbar-collapse-1 .dropdown.open").empty?
    end
    @plot.sleep_for(0.5)
    find_and_click_button(:id, "admin-dashboard-link")

    @plot.wait_for_document_ready
    @plot.wait_for do |driver|
      !driver.find_elements(css: "#header a[href='/admin/users']").empty?
    end
    find_and_click_button(:css, "#header a[href='/admin/users']")
    @plot.wait_for_document_ready
    @plot.sleep_for(0.5)

    @plot.new_tab
    @plot.go_to "https://docs.google.com/spreadsheets/d/19lrnVygBUlyeFabeElkwJMFe6hx810AnCHNPW-htRIo/edit"

    try_google_login_without_popup

    @plot.wait_for do |driver|
      driver.find_element(id: "docs-butterbar-container").find_elements(css: "div").length.zero?
    end

    @heading = copy_vertical

    while true
      begin
        get_to_next_row

        element = @plot.get_element(:xpath, '//table/tbody/tr/td[3]/div/div')

        if element.text.strip == ""
          @plot.switch_tab
          find_and_click_button(:css, "span.action_item a[href='/admin/users/new']")
          @plot.wait_for_document_ready
          @plot.sleep_for(0.5)

          (@heading - ["id"]).each {|property| copy_and_paste_value(property) }

          find_and_click_button(:css, "#new_user button[type=submit]")
          @plot.wait_for_document_ready
          find_and_click_button(:css, "button[type=submit]")

          @plot.wait_for_document_ready
          url_string = @plot.get_url
          id = url_string.split("/").last

          @plot.switch_tab
          @heading.length.times { @plot.move_to nil, :arrow_left}
          Clipboard.copy id
          @plot.paste_input_to(@plot.active_element)
        elsif element.text.strip == "end"
          puts "Done"
          display_ending_message
          break
        end
      rescue => e
        puts "An error occured!"
        puts e.backtrace
        break
      end
    end

    puts "end of run"
  end
end