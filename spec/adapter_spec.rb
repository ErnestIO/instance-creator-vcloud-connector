require_relative 'spec_helper'

describe 'vcloud_instance_creator_microservice' do
  let!(:provider) { double('provider', foo: 'bar') }

  before do
    allow_any_instance_of(Object).to receive(:sleep)
    require_relative '../adapter'
  end

  describe '#create_instance' do
    let!(:data)   do
      { instance_type: 'vcloud',
        router_name: 'adria-vse',
        client_name: 'r3labs-development',
        datacenter_name: 'r3-acidre',
        datacenter_username: 'acidre@r3labs-development',
        datacenter_password: 'ed7d0a9ffed74b2d3bc88198cbe7948c',
        network_name: 'network',
        instance_rules: [],
        instance_name: 'instance',
        instance_resource: { reference_image: 'centos65-tty-sudo-disabled', reference_catalog: 'images' } }
    end
    let!(:datacenter) { double('datacenter', private_network: true, add_compute_instance: true) }

    before do
      allow_any_instance_of(Provider).to receive(:initialize).and_return(true)
      allow_any_instance_of(Provider).to receive(:datacenter).and_return(datacenter)
      allow_any_instance_of(Provider).to receive(:image).and_return(true)
    end

    it 'create a instance on vcloud' do
      expect(create_instance(data)).to eq 'instance.create.vcloud.done'
    end
  end
end
