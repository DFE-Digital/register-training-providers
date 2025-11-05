require "rails_helper"

RSpec.describe DebuggerParamHelper, type: :helper do
  describe "#debug_mode?" do
    subject(:debug_mode?) { helper.debug_mode? }

    context "when params[:debug] is 'true'" do
      before { allow(helper).to receive(:params).and_return({ "debug" => "true" }) }

      it "returns true" do
        expect(debug_mode?).to be true
      end
    end

    context "when params[:debug] is 'false'" do
      before { allow(helper).to receive(:params).and_return({ "debug" => "false" }) }

      it "returns false" do
        expect(debug_mode?).to be false
      end
    end

    context "when params[:debug] is nil" do
      before { allow(helper).to receive(:params).and_return({}) }

      it "returns false" do
        expect(debug_mode?).to be false
      end
    end

    context "when params[:debug] has a non-boolean string" do
      before { allow(helper).to receive(:params).and_return({ "debug" => "yes" }) }

      it "returns false" do
        expect(debug_mode?).to be false
      end
    end

    context "when params key is symbol instead of string" do
      before { allow(helper).to receive(:params).and_return({ debug: "true" }) }

      it "returns false (string key only)" do
        expect(debug_mode?).to be false
      end
    end
  end
end
