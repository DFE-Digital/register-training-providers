module DebuggerParamHelper
  def debug_mode?
    params["debug"] == "true"
  end
end
