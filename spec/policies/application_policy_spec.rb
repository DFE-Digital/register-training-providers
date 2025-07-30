require "rails_helper"

RSpec.describe ApplicationPolicy do
  let(:user) { build(:user) }
  let(:record) { double("Record") }
  subject { described_class.new(user, record) }

  describe "#initialize" do
    it "sets user and record" do
      expect(subject.user).to eq(user)
      expect(subject.record).to eq(record)
    end
  end

  describe "#index?" do
    it "returns false" do
      expect(subject.index?).to be false
    end
  end

  describe "#show?" do
    it "returns false" do
      expect(subject.show?).to be false
    end
  end

  describe "#create?" do
    it "returns false" do
      expect(subject.create?).to be false
    end
  end

  describe "#new?" do
    it "delegates to create?" do
      expect(subject.new?).to eq(subject.create?)
    end
  end

  describe "#update?" do
    it "returns false" do
      expect(subject.update?).to be false
    end
  end

  describe "#edit?" do
    it "delegates to update?" do
      expect(subject.edit?).to eq(subject.update?)
    end
  end

  describe "#destroy?" do
    it "returns false" do
      expect(subject.destroy?).to be false
    end
  end

  describe "Scope" do
    let(:user) { double("User") }

    let(:scope) do
      klass = class_double("Record", kept: :filtered_scope)
      allow(klass).to receive(:kept).and_return(:filtered_scope)
      klass
    end

    subject(:policy_scope) { described_class::Scope.new(user, scope) }

    describe "#resolve" do
      it "returns scope.kept" do
        expect(policy_scope.resolve).to eq(:filtered_scope)
      end
    end
  end
end
