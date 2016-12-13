require 'rubygems'
require 'bundler/setup'
require 'json'

require 'myst'

include Myst::Providers::VCloud

def create_instance(data)
  usr = ENV['DT_USR'] || data[:datacenter_username]
  pwd = ENV['DT_PWD'] || data[:datacenter_password]
  credentials = usr.split('@')
  provider = Provider.new(endpoint:     data[:vcloud_url],
                          organisation: credentials.last,
                          username:     credentials.first,
                          password:     pwd)
  instance = ComputeInstance.new(client: provider.client)
  datacenter = provider.datacenter(data[:datacenter_name])
  network = datacenter.private_network(data[:network_name])
  image = provider.image(data[:reference_image],
                         data[:reference_catalog])

  datacenter.add_compute_instance(instance, data[:name], network, image)

  unless data[:shell_commands].nil? || data[:shell_commands].empty?
    custom_section = instance.vm.getGuestCustomizationSection
    custom_section.setEnabled(true)
    custom_section.setCustomizationScript(data[:shell_commands].join("\n"))
    instance.vm.updateSection(custom_section).waitForTask(0, 1000)
  end

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
