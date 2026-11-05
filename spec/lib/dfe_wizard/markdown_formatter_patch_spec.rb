require "rails_helper"
require "dfe_wizard/markdown_formatter_patch"

RSpec.describe DfE::Wizard::Documentation::Formatters::MarkdownFormatter do
  def render_with_original_stub(original_body)
    formatter = described_class.new(metadata)
    allow(formatter).to receive(:render_without_gem_compatibility, &original_body)

    formatter.render
  end

  let(:counts) do
    {
      steps: 4,
      simple_edges: 2,
      conditional_edges: 1
    }
  end
  let(:metadata) { { structure_type: :linear, counts: counts, steps: [], transitions: [] } }

  describe "edge-count key mapping" do
    it "exposes the _edges counts under _transitions keys during render" do
      seen_during_render = nil

      render_with_original_stub lambda {
        seen_during_render = metadata[:counts].dup
        "rendered"
      }

      expect(seen_during_render).to include(
        steps: 4,
        simple_transitions: 2,
        conditional_transitions: 1
      )
    end

    it "restores the original counts afterwards" do
      render_with_original_stub -> { metadata[:counts][:steps] = "mutated during render" }

      expect(metadata[:counts]).to equal(counts)
    end

    it "is idempotent across repeated renders on a single instance" do
      formatter = described_class.new(metadata)
      seen_during_render = []

      allow(formatter).to receive(:render_without_gem_compatibility) do
        seen_during_render << metadata[:counts].dup
        "rendered"
      end

      formatter.render
      expect(metadata[:counts]).to equal(counts)

      formatter.render
      expect(metadata[:counts]).to equal(counts)

      expect(seen_during_render.length).to eq(2)
      expect(seen_during_render.uniq.length).to eq(1)
      expect(seen_during_render.first).to include(simple_transitions: 2, conditional_transitions: 1, steps: 4)
    end
  end

  describe "stray quote stripping" do
    it "drops lines holding a lone closing quote" do
      rendered = lambda do
        <<~MARKDOWN
          **Flow Logic:**

          Evaluates the predicate `reason_capture_required?`:
          - If condition is **true** → proceed to `reasons`
          "
        MARKDOWN
      end

      output = render_with_original_stub(rendered)

      expect(output.split("\n").last)
        .to eq("- If condition is **true** → proceed to `reasons`")
    end

    it "keeps quotes that share a line with other content" do
      output = render_with_original_stub -> { 'Condition | `"reason_capture_required?"` | kept' }

      expect(output).to include('"reason_capture_required?"')
    end
  end
end
