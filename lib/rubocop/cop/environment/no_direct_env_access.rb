require "rubocop"
require "rubocop/cop/base"

module RuboCop
  module Cop
    module Environment
      class NoDirectEnvAccess < RuboCop::Cop::Base
        extend AutoCorrector

        MSG = "Use the Env wrapper instead of direct ENV access.".freeze

        def_node_matcher :env_access?, <<~PATTERN
          (send (const nil? :ENV) {:[] :fetch} $_ ...)
        PATTERN

        def on_send(node)
          key_node = env_access?(node)
          return unless key_node

          add_offense(node, message: MSG) do |corrector|
            new_code = nil

            if key_node.str_type?
              method_name = key_node.value.downcase

              new_code = if node.method?(:[])
                           "Env.#{method_name}"
                         elsif node.method?(:fetch)
                           default_arg = node.arguments[1]
                           if default_arg
                             "Env.#{method_name}(#{default_arg.source})"
                           else
                             "Env.#{method_name}"
                           end
                         end
            end

            corrector.replace(node.source_range, new_code) if new_code
          end
        end
      end
    end
  end
end
