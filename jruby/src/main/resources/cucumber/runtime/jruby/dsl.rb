module Cucumber
  module Runtime
    module JRuby
      class StepDefinition
        PROC_PATTERN = /[\d\w]+@(.+):(\d+).*>/
        PWD = Dir.pwd

        def initialize(regexp, proc)
          @regexp, @proc = regexp, proc
        end

        # Lifted from regexp_argument_matcher.rb in Cucumber 1.0
        def matched_arguments(step_name)
          match = @regexp.match(step_name)
          if (match)
            n = 0
            match.captures.map do |val|
              n += 1
              start = match.offset(n)[0]
              Java::GherkinFormatter::Argument.new(start, val)
            end
          else
            nil
          end
        end

        def arg_count
          @proc.arity
        end

        def execute(locale, *args)
          $world.instance_variable_set :@__cucumber_locale, locale
          $world.instance_exec(*args, &@proc)
        end

        # Lifted from proc.rb in Cucumber 1.0
        def file_and_line
          path, line = *@proc.inspect.match(PROC_PATTERN)[1..2]
          path = File.expand_path(path)
          pwd = File.expand_path(PWD)
          if path.index(pwd)
            path = path[pwd.length+1..-1]
          elsif path =~ /.*\/gems\/(.*\.rb)$/
            path = $1
          end
          [path, line.to_i]
        end

        def pattern
          @regexp.inspect
        end
      end

      class HookDefinition
        def initialize(proc)
          @proc = proc
        end

        def execute(*args)
          $world.instance_exec(*args, &@proc)
        end
      end

    end
  end
end

def register(regexp, proc)
  $backend.addStepdef(Cucumber::Runtime::JRuby::StepDefinition.new(regexp, proc))
end

def register_or_invoke(keyword, regexp_or_name, proc)
  if proc
    register(regexp_or_name, proc)
  else
    # caller[1] gets us to our stepdef, right before we enter the dsl
    uri, line = *caller[1].to_s.split(/:/)
    $backend.runStep(uri, @__cucumber_locale, keyword, regexp_or_name, line.to_i)
  end
end

def pending(reason = "TODO")
  $backend.pending(reason)
end

def Before(&proc)
  $backend.addBeforeHook(Cucumber::Runtime::JRuby::HookDefinition.new(proc))
end

def After(&proc)
  $backend.addAfterHook(Cucumber::Runtime::JRuby::HookDefinition.new(proc))
end

def World(&proc)
  $world.instance_exec(&proc)
end

# TODO: The code below should be generated, just like I18n for other backends

def Given(regexp_or_name, &proc)
  register_or_invoke('Given ', regexp_or_name, proc)
end

def When(regexp_or_name, &proc)
  register_or_invoke('When ', regexp_or_name, proc)
end

def Then(regexp_or_name, &proc)
  register_or_invoke('Then ', regexp_or_name, proc)
end
