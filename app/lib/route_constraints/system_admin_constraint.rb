module RouteConstraints
  class SystemAdminConstraint
    def matches?(request)
      signin_user = DfESignInUser.load_from_session(request.session)
      signin_user&.system_admin?
    end
  end
end
