# == Schema Information
#
# Table name: users
#
#  id                :integer          not null, primary key
#  dfe_sign_in_uid   :string
#  email             :string           not null
#  first_name        :string           not null
#  last_name         :string           not null
#  last_signed_in_at :datetime
#  discarded_at      :datetime
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#
# Indexes
#
#  index_users_on_discarded_at  (discarded_at)
#  index_users_on_email         (email) UNIQUE
#

class Persona < User
  default_scope { where(email: PERSONA_EMAILS) }

  def self.non_existing_persona
    new(NON_EXISTING_PERSONA)
  end
end
