class PutsLogger
  class << self
    def colored(text, color)
      puts "\e[#{color}m#{text}\e[0m"
    end

    def info(text)
      colored(text, 34)
    end

    def success(text)
      colored(text, 32)
    end

    def warning(text)
      colored(text, 33)
    end

    def error(text)
      colored(text, 31)
    end

    def text(text)
      puts text
    end
  end
end