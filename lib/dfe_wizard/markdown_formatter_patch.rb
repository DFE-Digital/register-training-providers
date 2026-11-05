require "dfe/wizard/documentation/formatters/markdown_formatter"

module DfE
  module Wizard
    module Documentation
      module Formatters
        class MarkdownFormatter
          STRAY_QUOTE_LINE = /^"\n/

          alias_method :render_without_gem_compatibility, :render

          def render
            rename_edge_counts_to_transitions

            render_without_gem_compatibility.gsub(STRAY_QUOTE_LINE, "")
          ensure
            restore_edge_counts
          end

        private

          def rename_edge_counts_to_transitions
            @original_counts = @metadata[:counts] if @metadata.fetch(:counts, nil).is_a?(Hash)
            return if @original_counts.blank?

            @metadata[:counts] = @original_counts.to_h do |key, value|
              [key.to_s.sub("_edges", "_transitions").to_sym, value]
            end
          end

          def restore_edge_counts
            return if @original_counts.blank?

            @metadata[:counts] = @original_counts
            @original_counts = nil
          end
        end
      end
    end
  end
end
