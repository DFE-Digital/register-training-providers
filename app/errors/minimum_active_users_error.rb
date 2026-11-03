class MinimumActiveUsersError < StandardError
  attr_reader :user_id

  def initialize(user_id: nil)
    @user_id = user_id
    super()
  end
end
