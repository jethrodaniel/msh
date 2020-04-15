# frozen_string_literal: true

module Msh
  class Env
    # MAN
    # ```
    # ```
    def history
      size = 3
      Readline::HISTORY.to_a.tap do |h|
        size = h.size.to_s.chars.size
      end.each.with_index(1) do |e, i|
        puts "#{i.to_s.ljust(size, ' ')} #{e}"
      end
      0
    end
    alias hist history
  end
end
