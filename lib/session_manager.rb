class SessionManager
  SUPPORTED_BROWSERS = [:chrome, :firefox]

  attr_accessor :session

  def initialize(browser = :chrome)
    raise SessionManagerError, 'Unsupported Browser!' unless SUPPORTED_BROWSERS.include?(browser)

    Capybara.register_driver :selenium_chrome do |app|
      Capybara::Selenium::Driver.new(app, :browser => browser)
    end

    @session = Capybara::Session.new(:selenium_chrome)
  end

  def url
    @session.current_url
  end

  def current_title
    @session.title
  end

  def maximize_window
    @session.current_window.maximize
  end

  def windows
    @session.windows
  end

  def sleep_for(seconds)
    sleep seconds
  end

  def go(url)
    if (url =~ URI::regexp).nil?
      false
    else
      @session.visit(url)
    end
  end

  def find(finder, find_method = nil)
    if find_method.nil?
      @session.find(finder) unless finder.nil?
    elsif find_method == :button
      @session.find_button(finder)
    elsif find_method == :id
      @session.find_by_id(finder)
    end
  rescue
    binding.pry
  end

  # Depending on firefox preference, this method might fail
  # The rescue will ensure new tab still happens
  def new_tab
    @session.open_new_window
  rescue Capybara::WindowError => e
    new_tab_via_link
  end

  def new_tab_via_link
    session_windows = @session.windows.map(&:handle)
    link_identity   = "news-tab-id-#{Time.now.to_i}"
    clicker_script  = "
    var a = document.createElement('A');

    a.href    = 'about:blank';
    a.target  = '_blank';
    a.text    = 'link';
    a.id      = '#{link_identity}';

    document.body.appendChild(a);

    return a;
    "

    clicker = @session.execute_script clicker_script
    clicker.click()
    @session.execute_script "document.getElementById('#{link_identity}').remove();"

    if new_window = @session.windows.find{|window| !session_windows.include?(window.handle) }
      @session.switch_to_window(new_window)
    else
      PutsLogger.error "Failed to open new tab"
      false
    end
  end

  def switch_tab(window: nil, title: nil, handle: nil)
    if block_given?
      @session.switch_to_window { yield(@session) }
    else
      return switch_tab_by_window(window) unless window.nil?
      return switch_tab_by_title(title) unless title.nil?
      return switch_tab_by_handle(handle) unless handle.nil?
    end
  end

  def switch_tab_by_window(window)
    @session.switch_to_window(window)
  end

  def switch_tab_by_title(title)
    @session.switch_to_window { @session.title.include?(title) }
  end

  def switch_tab_by_handle(handle)
    @session.switch_to_window { @session.current_window.handle == handle }
  end

  def active_element
    @session.evaluate_script('document.activeElement')
  end

  def enter_keys(*args)
    target = args.first.class.name.include?('Element') ? args.shift : active_element

    args.each {|argument| target.send_keys(argument) }

    target
  end

  def find_and_click_element(finder: nil, element: nil, find_method: nil)
    target = element || find(finder, find_method)

    target.click() unless target.nil?
  end

  # supports mac only
  def select_from(finder: nil, element: nil, find_method: nil)
    target = element || find(finder, find_method) || active_element

    enter_keys(target, [:command, 'a'])
  end

  # Methods for cut, copy, and paste
  {cut: 'x', copy: 'c', paste: 'v'}.each do |key, value|
    define_method key do |finder: nil, element: nil, find_method: nil|
      target = element || find(finder, find_method) || active_element

      enter_keys(target, [:command, value])
    end

    define_method "select_and_#{key}" do |finder: nil, element: nil, find_method: nil|
      target = select_from(finder: finder, element: element, find_method: find_method)
      send(key, element: target)
    end
  end

  def move(direction, finder: nil, element: nil, find_method: nil)
    target = element || find(finder, find_method) || active_element

    wait_for { target.is_a?(Selenium::WebDriver::Element) ? target.displayed? : target.visible? }

    enter_keys(target, :escape, direction) rescue binding.pry
  end

  # I have no Idea how to wait for animations :|
  def wait_for
    wait = Selenium::WebDriver::Wait.new(:timeout => 1000)
    wait.until { yield(@session) }
  end

  def wait_for_element(finder)
    wait_for do |session|
      session.has_selector?(finder)
    end
  end

  def wait_for_document_complete
    wait_for do |session|
      session.execute_script('return document.readyState;') == "complete"
    end
  end

  def element_exists?(finder)
    @session.has_selector?(finder)
  end

  def script(script)
    @session.execute_script(script)
  end
end