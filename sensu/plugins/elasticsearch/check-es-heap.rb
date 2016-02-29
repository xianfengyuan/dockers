require 'rubygems' if RUBY_VERSION < '1.9.0'
require 'sensu-plugin/check/cli'
require 'elasticsearch'
require 'json'
require 'resolv'

class ESHeap < Sensu::Plugin::Check::CLI

  option :server,
    :description => 'Elasticsearch server',
    :short => '-s SERVER',
    :long => '--server SERVER',
    :default => 'elk'

  option :port,
    :description => 'Elasticsearch port',
    :short => '-p PORT',
    :long => '--port PORT',
    :default => '9200'

  option :warn,
    :short => '-w N',
    :long => '--warn N',
    :description => 'Heap used in bytes WARNING threshold',
    :proc => proc {|a| a.to_i },
    :default => 80

  option :crit,
    :short => '-c N',
    :long => '--crit N',
    :description => 'Heap used in bytes CRITICAL threshold',
    :proc => proc {|a| a.to_i },
    :default => 90

  def elasticsearch_client
    ESHeap.elasticsearch_client config[:server], config[:port]
  end

  def self.elasticsearch_client(host, port)
    @elasticsearch_client ||= Elasticsearch::Client.new host: host, port: port, log: false
  end

  def get_heap_used_in_percentage
    begin
      node = Resolv.getaddress config[:server]
      response = elasticsearch_client.perform_request('GET', "_nodes/#{node}/stats")
      heap_used_in_percentage = response.body["nodes"].values[0]["jvm"]["mem"]["heap_used_percent"]
      warning "Could not get heap usage" if heap_used_in_percentage.nil?
    rescue Exception => e
      warning "Could not get heap usage: #{e.message}"
    end
    return heap_used_in_percentage
  end

  def run
    if get_heap_used_in_percentage >= config[:crit]
      critical
    elsif get_heap_used_in_percentage >= config[:warn]
      warning
    else
      ok
    end
  end
end

