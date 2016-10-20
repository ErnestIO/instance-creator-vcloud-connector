require 'rubygems'
require 'bundler/setup'
require 'json'

require 'myst'

include Myst::Providers::VCloud

def create_instance(data)
  values = data.values_at(:datacenter_name, :client_name, :router_name, :network_name).compact
  return false unless data[:type] == 'vcloud' && values.length == 4

  credentials = data[:datacenter_username].split('@')
  provider = Provider.new(endpoint:     data[:vcloud_url],
                          organisation: credentials.last,
                          username:     credentials.first,
                          password:     data[:datacenter_password])
  instance = ComputeInstance.new(client: provider.client)
  datacenter = provider.datacenter(data[:datacenter_name])
  network = datacenter.private_network(data[:network_name])
  image = provider.image(data[:reference_image],
                         data[:reference_catalog])

  datacenter.add_compute_instance(instance, data[:name], network, image)

  'instance.create.vcloud.done'
rescue => e
  puts e
  puts e.backtrace
  'instance.create.vcloud.error'
end

unless defined? @@test
  @data       = { id: SecureRandom.uuid, type: ARGV[0] }
  @data.merge! JSON.parse(ARGV[1], symbolize_names: true)
  original_stdout = $stdout
  $stdout = StringIO.new
  begin
    @data[:type] = create_instance(@data)
    if @data[:type].include? 'error'
      @data['error'] = { code: 0, message: $stdout.string.to_s }
    end
  ensure
    $stdout = original_stdout
  end

  puts @data.to_json
end
