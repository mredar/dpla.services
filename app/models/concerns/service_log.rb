module ServiceLog
  def service_log
    if Rails.env.test?
      @@service_log ||= Logger.new("#{Rails.root}/log/service-test.log")
    elsif Rails.env.development? || Rails.env.production?
      @@service_log ||= Logger.new("#{Rails.root}/log/service.log")
    end
  end
end