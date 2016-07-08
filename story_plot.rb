require 'selenium-webdriver'

class StoryPlot
  attr_accessor :driver

  def initialize
    @driver = Selenium::WebDriver.for :firefox
  end
  
  def get_url
    @driver.current_url
  end

  def maximize_window
    @driver.manage.window.maximize
  end

  def sleep_for(seconds)
    sleep seconds
  end

  def go_to(url)
    if (url =~ URI::regexp).nil?
      puts "The url given does not match the format. (,'') :("
    else
      @driver.get(url)

      wait_for_document_ready
    end
  end
  
  def get_element(getter, selector)
    driver.find_element(getter => selector)
  end

  def wait_for
    wait = Selenium::WebDriver::Wait.new(:timeout => 1000)
    wait.until { yield(@driver) }
  end
  
  def wait_for_document_ready
    wait_for do |driver|
      driver.execute_script("return document.readyState;") == "complete"
    end
  end
  
  def switch_tab
    @driver.switch_to.window(@driver.window_handle)
    body = @driver.find_element(:tag_name => 'body')
    body.send_keys [:control, :tab]
    @driver.switch_to.window(@driver.window_handle)
  end
  
  def new_tab
    @driver.switch_to.window(@driver.window_handle)
    body = @driver.find_element(:tag_name => 'body')
    body.send_keys [:command, "t"]
    @driver.switch_to.window(@driver.window_handle)
  end

  def show_input_for(inputs)
    prompt = MessageBox.new(MessageBox::Type::PROMPT, "Please enter login credentials:", inputs)
    box    = @driver.execute_script(prompt.message_box)

    wait_for do |driver|
      box.find_element(css: "#answered") rescue false
    end

    choice = box.find_element(css: "input[name='choice']").attribute("value")
    if choice == MessageBox::Actions::PRIMARY.to_s
      inputs.each do |input|
        value        = @driver.find_element(css: "##{prompt.message_box_id} input[name='#{input[:name]}']").attribute("value")
        actual_input = @driver.find_element(css: "input[name='#{input[:name]}']")

        actual_input.send_keys(value)
      end
    end

    @driver.execute_script("#{prompt.destroyer}\r\n return document.body;")
    choice == MessageBox::Actions::PRIMARY.to_s
  end

  def click_button_with(find_method, having_value)
    button = @driver.find_element(find_method => having_value)

    if button
      button.click
    else
      puts "The button does not exists"
    end
  end

  def copy(element = nil)
    (element || active_element).send_keys [:command, 'c']
  end

  def paste(element = nil)
    (element || active_element).send_keys [:command, 'v']
  end

  def copy_input_from(element = nil)
    (element || active_element).send_keys [:command, 'a'], [:command, 'c']
    (element || active_element).send_keys :escape
  end

  def paste_input_to(element = nil)
    (element || active_element).send_keys [:command, 'a'], [:command, 'v']
    (element || active_element).send_keys :escape
  end

  def move_to(element, direction)
    (element || active_element).send_keys :escape, direction
  end

  def active_element
    @driver.execute_script("return document;");
  end

  def execute_block
    yield @driver
  end

  def shutdown
    @driver.quit
  end
end