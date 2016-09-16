require 'clipboard'
require 'pry'

class StoryBoard

  def google_cell_input
    @manager.script("return document.querySelector('.cell-input');")
  end

  def focus_google_cell_input
    @manager.script("document.querySelector('.cell-input').focus();")
  end

  # FIXME: :command key in windows
  def is_empty_tuple?
    focus_google_cell_input
    element = @manager.find('body')

    @manager.enter_keys element, :escape, [:command, :shift, :right], [:command, 'c'], :left

    (Clipboard.paste.split("\t") rescue []).empty?
  end

  # FIXME: focus_google_cell_input, escape, home, down
  def get_to_next_row
    element = @manager.find('body')

    @manager.wait_for { element.is_a?(Capybara::Node::Element) ? element.visible? : element.displayed? }
    @heading.length.times { @manager.move :arrow_left, element: element}
    @manager.move :arrow_down, element: element
  end

  def is_current_empty?
    element = google_cell_input

    @manager.wait_for { element.is_a?(Capybara::Node::Element) ? element.visible? : element.displayed? }
    @manager.enter_keys element, :enter, [:command, 'a']

    selected_text = @manager.script('return document.getSelection().toString();')
    @manager.enter_keys element, :escape

    selected_text.strip.empty?
  end

  def move_right
    element = @manager.find('body')

    focus_google_cell_input
    @manager.enter_keys element, :escape, :right
  end

  def move_down
    element = @manager.find('body')

    focus_google_cell_input
    @manager.enter_keys element, :escape, :down
  end

  def move_to_first_column
    element = @manager.find('body')

    focus_google_cell_input
    @manager.enter_keys element, :escape
    @heading.length.times { @manager.move :arrow_left, element: element}
  end

  def copy_vertical(array = [])
    element = @manager.find('body')

    @manager.wait_for { element.is_a?(Capybara::Node::Element) ? element.visible? : element.displayed? }
    @manager.copy(element: element)

    item = Clipboard.paste

    return array if item.strip.empty?

    array << item
    @manager.move :arrow_right, element: element
    copy_vertical(array)
  end

  def display_ending_message
    prompt = MessageBox.new(MessageBox::Type::ALERT, "Automation done!")

    @manager.script prompt.message_box
    @manager.wait_for_element('#answered')
    @manager.script prompt.destroyer
  end

  def login_to_application_system
    @manager.wait_for {|session| session.current_path.include?('/users/sign_in') }

    if @manager.url.include?('/users/sign_in')
      PutsLogger.info "Logging in to #{ENV['APPLICATION_SERVER_URL']}"
      # CT MANAGER LOGIN
      login_id = @manager.find '#user_login_id'
      password = @manager.find '#user_password'

      PutsLogger.text "Entering username and password"
      @manager.enter_keys(login_id, *ENV["APPLICATION_SERVER_USERNAME"].chars)
      @manager.enter_keys(password, *ENV["APPLICATION_SERVER_PASSWORD"].chars)

      @manager.find_and_click_element(finder: 'form input[type=submit]')
      PutsLogger.success "Logged in to #{ENV['APPLICATION_SERVER_URL']}"
    else
      PutsLogger.error "Not in login page of #{ENV['APPLICATION_SERVER_URL']}"
    end
  end

  def access_application_system_admin
    PutsLogger.info "Attempting access to admin page of #{ENV['APPLICATION_SERVER_URL']}"
    @manager.wait_for_element('#bs-example-navbar-collapse-1 .dropdown-toggle')
    @manager.find_and_click_element(finder: '#bs-example-navbar-collapse-1 .dropdown-toggle')
    @manager.wait_for_element('#admin-dashboard-link')
    @manager.find_and_click_element(finder: '#admin-dashboard-link')
    @manager.wait_for_document_complete
    @manager.wait_for {|session| session.current_url.include?('/admin') }

    if @manager.url.include?('/admin')
      PutsLogger.success "Accessed admin of #{ENV['APPLICATION_SERVER_URL']}"
    else
      PutsLogger.error "Failed to access admin of #{ENV['APPLICATION_SERVER_URL']}"
    end
  end

  def access_application_system_admin_users_page
    if @manager.element_exists?('#header a[href="/admin/users"]')
      @manager.find_and_click_element(finder: '#header a[href="/admin/users"]')
      @manager.wait_for_document_complete
      @manager.wait_for {|session| session.current_path.include?('/admin/users') }

      if @manager.url.include?('/admin')
        PutsLogger.success "Accessed admin of #{ENV['APPLICATION_SERVER_URL']}"
      else
        PutsLogger.error "Failed to access admin of #{ENV['APPLICATION_SERVER_URL']}"
      end
    else
      PutsLogger.error "Cannot locate users link of #{ENV['APPLICATION_SERVER_URL']}"
    end
  end

  def prepare_application_system
    PutsLogger.text "Accessing #{ENV['APPLICATION_SERVER_URL']}"
    @manager.go ENV['APPLICATION_SERVER_URL']

    @manager.wait_for_document_complete
    login_to_application_system
    @manager.wait_for_document_complete

    access_application_system_admin
    access_application_system_admin_users_page
  end

  def attempt_google_login
    PutsLogger.info "Attempting to enter email for #{ENV['GOOGLE_DOC_URL']}"
    email_input = @manager.find "input[type='email']:not(.hidden)"

    @manager.enter_keys(email_input, *ENV["GOOGLE_DOC_USERNAME"].chars)
    @manager.find_and_click_element(finder: "input[type='submit']:not(.hidden)")
    @manager.wait_for_element("input[type='password']:not(.hidden)")

    PutsLogger.info "Attempting to enter password for #{ENV['GOOGLE_DOC_URL']}"
    pwd_input = @manager.find "input[type='password']:not(.hidden)"

    @manager.enter_keys(pwd_input, *ENV["GOOGLE_DOC_PASSWORD"].chars)
    @manager.find_and_click_element(finder: "input[type='submit']:not(.hidden)")
  end

  # Google is so complicated
  def check_for_google_butter_bar
    @manager.wait_for do |session|
      session.execute_script("return document.querySelector('#docs-butterbar-container div') == null && document.readyState == 'complete'")
    end
  end

  def check_google_completeness
    PutsLogger.info "wait for document to complete all processes"
    check_for_google_butter_bar
    @manager.wait_for { @manager.find('body').visible? }
    check_for_google_butter_bar
    @manager.wait_for_element('.docs-title-save-label.goog-inline-block')
    check_for_google_butter_bar
    PutsLogger.info "document should be ready"
  end

  def prepare_google_sheet_page
    PutsLogger.info "Attempting to open #{ENV['GOOGLE_DOC_URL']}"
    @manager.go(ENV['GOOGLE_DOC_URL'])
    @manager.wait_for_document_complete
    PutsLogger.success "Accessed #{ENV['GOOGLE_DOC_URL']}"

    attempt_google_login
    @manager.wait_for {|session| session.title.include?('CT Manager Record Sheet') }
    @manager.wait_for_document_complete

    if @manager.current_title.include?('CT Manager Record Sheet')
      PutsLogger.success "Logged in to #{ENV['GOOGLE_DOC_URL']}"

      check_google_completeness
    else
      PutsLogger.error "Failed to login to #{ENV['GOOGLE_DOC_URL']}"
    end
  end

  def run
    PutsLogger.text "Initializing"
    @manager = SessionManager.new(:firefox)

    prepare_application_system

    PutsLogger.info "Attempting to open new tab"
    if @manager.new_tab
      prepare_google_sheet_page
    end

    @heading = copy_vertical
    get_to_next_row

    while !is_empty_tuple?
      record_exists = false

      @heading.each do |column|
        element = @manager.find('body')
        @manager.wait_for { element.is_a?(Capybara::Node::Element) ? element.visible? : element.displayed? }

        if column.downcase == 'id'
          if is_current_empty?
            @manager.switch_tab {|session| session.current_url.include?(ENV['APPLICATION_SERVER_URL'])}
            @manager.find_and_click_element(finder: "span.action_item a[href='/admin/users/new']")
            @manager.wait_for {|session| session.current_path.include?('/admin/users/new') }
            @manager.wait_for_document_complete
          else
            record_exists = true
            PutsLogger.warning "Record #{Clipboard.paste} might already be in the system"
            break
          end
        else
          @manager.copy(element: element)
          @manager.switch_tab {|session| session.current_url.include?(ENV['APPLICATION_SERVER_URL'])}
          input = @manager.find("input[name='user[#{column}]']")

          @manager.enter_keys input, :escape, [:command, "v"]
        end

        @manager.switch_tab {|session| session.current_url.include?(ENV['GOOGLE_DOC_URL'])}
        move_right
      end

      move_to_first_column

      unless record_exists
        @manager.switch_tab {|session| session.current_url.include?(ENV['APPLICATION_SERVER_URL'])}
        @manager.find_and_click_element(finder: "#new_user button[type=submit]")
        @manager.wait_for {|session| session.current_path.include?('/admin/users/preview_changes') }
        @manager.wait_for_document_complete

        assigned_id = if @manager.script("return document.querySelectorAll('.field_with_errors').length").zero?
          @manager.find_and_click_element(finder: "button[type=submit]")
          @manager.wait_for {|session| !session.current_path.include?('/admin/users/preview_changes') }
          @manager.wait_for_document_complete

          uri = URI(@manager.url)

          @manager.find_and_click_element(finder: ".header-item a[href='/admin/users']")
          @manager.wait_for {|session| session.current_path.include?('/admin/users') }
          @manager.wait_for_document_complete

          uri.path.split("/").last.to_i rescue 0
        else
          PutsLogger.error "Record has errors"
          0
        end

        @manager.switch_tab {|session| session.current_url.include?(ENV['GOOGLE_DOC_URL'])}

        if assigned_id.zero?
          move_down
        else
          focus_google_cell_input
          @manager.enter_keys(@manager.find('body'), *assigned_id.to_s.chars, :enter)
        end
      else
        move_down
      end
    end

    display_ending_message
  end

  def self.initialize_story!
    story_board = StoryBoard.new
    story_board.run
  end
end