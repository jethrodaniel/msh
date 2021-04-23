module Msh
  module Tasks
    class Task
      include Rake::DSL

      def initialize name, description, *preqs
        desc description
        task name => preqs do
          puts "=== rake #{name} ==="
          setup!
          puts "=== done ==="
        end
      end

      def setup!
        raise "Subclasses of `#{self.class}` must implement `#{__method__}`!"
      end
    end
  end
end
