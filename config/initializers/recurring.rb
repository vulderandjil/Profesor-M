if ENV["DISABLE_RECURRING"]
  Rails.logger.info "Recurring jobs disabled during build"
else
  require "solid_queue/recurring"
end
