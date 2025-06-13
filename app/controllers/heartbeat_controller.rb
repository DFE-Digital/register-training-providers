class HeartbeatController < ActionController::API
  def ping
    render(body: "PONG")
  end

  def healthcheck
    checks = {
      database: database_alive?
    }

    status = checks.values.all? ? :ok : :service_unavailable

    render(status: status,
           json: {
             checks:
           })
  end

  def sha
    render(json: { sha: Env.commit_sha })
  end

private

  def database_alive?
    ActiveRecord::Base.connection_pool.with_connection do |connection|
      connection.execute("SELECT 1")
    end

    ActiveRecord::Base.connected?
  rescue ActiveRecord::ConnectionNotEstablished, PG::ConnectionBad
    false
  end
end
