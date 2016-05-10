# Mimi::Messaging development console helpers
#
# get 'provider.name/method' [{param1: ..., param2: ...}]
# post 'provider.name/method' [{param1: ..., param2: ...}]
# listen 'notification.name'
# broadcast 'notification.name/method' [{param1: ..., param2: ...}]
#
def message_class_for(queue_name)
  message_class = Class.new(Mimi::Messaging::Message)
  message_class.queue(queue_name)
  message_class
end

def get(queue_and_method_name, params = {})
  queue_name, method_name = queue_and_method_name.split('/')
  message_class = message_class_for(queue_name)
  puts "GET #{queue_name}/#{method_name}: #{params}"
  ts = Time.now
  result = message_class.get(method_name, params)
  puts 'Completed in %.1fms' % ((Time.now - ts) * 1000.0)
  result
end

def post(queue_and_method_name, params = {})
  queue_name, method_name = queue_and_method_name.split('/')
  message_class = message_class_for(queue_name)
  puts "POST #{queue_name}/#{method_name}: #{params}"
  message_class.post(method_name, params)
end

def listen(notification_name)
  listener_class = Class.new(Mimi::Messaging::Listener)
  listener_class.notification(notification_name)
  listener_class.before do
    logger.info "** #{request.canonical_name}: #{params}"
  end
  puts "Listener for '#{notification_name}' installed"
end

def broadcast(notification_and_method_name, params = {})
  notification_name, method_name = notification_and_method_name.split('/')
  notification_class = Class.new(Mimi::Messaging::Notification)
  notification_class.notification(notification_name)
  puts "BROADCAST #{notification_name}/#{method_name}: #{params}"
  notification_class.broadcast(method_name, params)
  nil
end
