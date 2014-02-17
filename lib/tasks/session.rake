require 'redis'

task :clear_stash => :environment do
  puts 'Rodando clear_stash...'

  redis = Redis.new(:host => "172.17.0.3", :port => "6379")

  ARGV.shift
  user_ids = ARGV.map { |username| user = User.find_by_username(username); next if user.nil?; user.id }.compact
  keys = redis.keys('*')
  keys.each do |key|
    data = redis.get(key)
    begin
      struct = Marshal.load(data)
      if struct.kind_of?(Hash)
        if struct.include?('user_id') and user_ids.include?(struct['user_id'])
          struct['submissions'] = {}
          struct['forms'] = {}
          redis.set(key, Marshal.dump(struct))
          puts 'Resetado cache do usuário de ID #' + struct['user_id'].to_s
        end
      end
    rescue
      next
    end
  end

  # hacks
  ARGV.each do |arg|
    task arg.to_sym do ; end
  end
end