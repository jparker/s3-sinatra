require 'rubygems'
require 'sinatra'
require 'erb'
require 'active_support'
require 'base64'
require 'openssl'
require 'digest/sha1'

ENV['RACK_ENV'] ||= 'development'

$config = YAML.load(ERB.new(File.read('config.yml')).result)
$config = $config[ENV['RACK_ENV']] if $config.has_key? ENV['RACK_ENV']

get '/' do
  erb :index
end

get '/new' do
  @aws_access_key_id = $config[:access_key_id]
  @bucket            = $config[:bucket]
  @redirect_url      = "#{$config[:redirect_url]}/complete"
  @policy            = policy(@redirect_url)
  @signature         = Base64.encode64(OpenSSL::HMAC.digest(
                         OpenSSL::Digest::Digest.new('sha1'),
                         $config[:secret_access_key],
                         @policy
                       )).chomp
  
  erb :new, :layout => false
end

get '/complete' do
  "Upload complete!"
end

helpers do
  include Rack::Utils
  alias_method :h, :escape_html
end

def policy(redirect_url)
  Base64.encode64(%Q{
{ "expiration": "#{1.day.from_now.strftime('%Y-%m-%dT%H:%M:%SZ')}",
  "conditions": [
    {"bucket": "#{$config[:bucket]}"},
    ["starts-with", "$key", ""],
    {"acl": "private"},
    {"success_action_redirect": "#{redirect_url}"},
    ["starts-with", "$Content-Type", ""],
    ["content-length-range", 0, #{$config[:max_file_size]}]
  ]
}
  }).gsub("\n", '')
end
