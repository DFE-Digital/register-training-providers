# Compatibility patch for dfe-wizard (pinned github: DFE-Digital/dfe-wizard,
# branch: main, as of October 2026).
#
# 1. Edge counts: `StepsProcessor` emits counts under `_edges` keys
#    (`simple_edges`, `conditional_edges`, ...) — see
#    `StepsProcessor::Graph#metadata` in the gem — but the
#    `MarkdownFormatter` Overview and Statistics sections read `_transitions`
#    keys (`simple_transitions`, ...), so every row renders 0 while the
#    per-transition tables and the `Total Transitions` fallback sum agree on
#    the real counts. Generated docs therefore open with "Total Transitions
#    0" and later claim 3.
#
#    Mapping the keys at render time (and restoring them afterwards) makes
#    both tables read the same source of truth.
#
# 2. Stray quote: `MarkdownFormatter#render_conditional_transitions` emits
#    `#{sections}"` — a lone `"` on its own line after the Flow Logic section
#    of every conditional transition (see the gem's markdown_formatter.rb).
#    Only wizards with a conditional edge show it; stripping here keeps the
#    regenerated docs clean.
#
# Remove this patch once the gem renders `_edges` counts itself and emits no
# stray quote after the Flow Logic section.
require "dfe/wizard/documentation/formatters/markdown_formatter"

module DfE
  module Wizard
    module Documentation
      module Formatters
        class MarkdownFormatter
          STRAY_QUOTE_LINE = /^"\n/

          alias_method :render_without_gem_compatibility, :render

          def render
            rename_edge_counts
            render_without_gem_compatibility.gsub(STRAY_QUOTE_LINE, "")
          ensure
            restore_edge_counts
          end

        private

          def rename_edge_counts
            @original_counts = @metadata[:counts] if @metadata.fetch(:counts, nil).is_a?(Hash)
            return if @original_counts.blank?

            @metadata[:counts] = @original_counts.each_with_object({}) do |(key, value), renamed|
              renamed[key.to_s.sub("_edges", "_transitions").to_sym] = value
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
