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

def get_timeout(value = nil)
  return @get_current_timeout = value if value
  help_get_timeout
  puts
  puts "Curret GET timeout is set at #{get_current_timeout}s"
end

def help_get_timeout
  puts 'Usage: get_timeout <seconds>'
  puts
  puts 'Sets a timeout for GET requests.'
  puts
  puts 'Example:'
  puts "  > get_timeout 15"
end

def get_current_timeout
  @get_current_timeout || 5 # seconds
end

def get(queue_and_method_name = nil, params = {})
  return help_get unless queue_and_method_name
  queue_name, method_name = queue_and_method_name.split('/')
  message_class = message_class_for(queue_name)
  puts "GET #{queue_name}/#{method_name}: #{params}"
  ts = Time.now
  result = message_class.get(method_name, params, timeout: get_current_timeout)
  puts 'Completed in %.1fms' % ((Time.now - ts) * 1000.0)
  result
end

def help_get
  puts "Usage: get '<queue_name>/<method_name>' [, params]"
  puts
  puts 'Issues a GET request to a given queue/method and sends the message'
  puts "constructed from params Hash. Awaits for a response for at most 'get_timeout' seconds."
  puts
  puts 'Example:'
  puts "  > get 'accounts/list', page: 2"
end

def post(queue_and_method_name = nil, params = {})
  return help_post unless queue_and_method_name
  queue_name, method_name = queue_and_method_name.split('/')
  message_class = message_class_for(queue_name)
  puts "POST #{queue_name}/#{method_name}: #{params}"
  message_class.post(method_name, params)
  nil
end

def help_post
  puts "Usage: post '<queue_name>/<method_name>' [, params]"
  puts
  puts 'Issues a POST request to a given queue/method and sends the message'
  puts 'constructed from params Hash. Returns immediately'
  puts
  puts 'Example:'
  puts "  > post 'accounts/create', name: 'Primary account', currency: 'BTC'"
end

def listen(notification_name = nil, *method_names)
  return help_listen unless notification_name
  listener_class = Class.new(Mimi::Messaging::Listener)
  listener_class.notification(notification_name)
  method_names.each do |method_name|
    listener_class.send :define_method, method_name.to_sym do
      puts "LISTEN #{listener_class.resource_name}/#{request.method_name}: #{params}"
    end
    puts "Listener for '#{notification_name}/#{method_name}' registered"
  end
  listener_class.start
  puts "Listener for '#{notification_name}' started"
  nil
end

def help_listen
  puts "Usage: listen '<notification_name>' [, <method_name> ...]"
  puts
  puts 'Sets up a listener for notifications specified by notification and method names.'
  puts
  puts 'Example:'
  puts "  > listen 'accounts', :created, :updated"
end

def broadcast(notification_and_method_name = nil, params = {})
  return help_broadcast unless notification_and_method_name
  notification_name, method_name = notification_and_method_name.split('/')
  notification_class = Class.new(Mimi::Messaging::Notification)
  notification_class.notification(notification_name)
  puts "BROADCAST #{notification_name}/#{method_name}: #{params}"
  notification_class.broadcast(method_name, params)
  nil
end

def help_broadcast
  puts "Usage: broadcast '<notification_name>/<method_name>' [, params]"
  puts
  puts 'Broadcasts a notification message with a given name and method constructed'
  puts 'from params Hash.'
  puts
  puts 'Example:'
  puts "  > broadcast 'accounts/updated', id: 213, name: 'Secondary account', currency: 'BCH'"
end
