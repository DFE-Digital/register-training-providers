module Personas
  class ViewPreview < ViewComponent::Preview
    def multiple_personas
      personas = [active_user, soft_deleted_user, non_existence_user]
      render(Personas::View.with_collection(personas))
    end

    def active_persona
      render(Personas::View.with_collection([active_user]))
    end

    def soft_deleted_persona
      render(Personas::View.with_collection([soft_deleted_user]))
    end

    def non_existence_persona
      render(Personas::View.with_collection([non_existence_user]))
    end

  private

    def active_user
      @active_user ||= ::FactoryBot.create(:user)
    end

    def soft_deleted_user
      @soft_deleted_user ||= ::FactoryBot.create(:user, :discarded)
    end

    def non_existence_user
      @non_existence_user ||= ::FactoryBot.build(:user)
    end
  end
end
