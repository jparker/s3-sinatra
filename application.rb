require 'rubygems'
require 'sinatra'
require 'erb'
require 'active_support'
require 'base64'
require 'openssl'
require 'digest/sha1'

ENV['RACK_ENV'] ||= 'development'

# config.yml must define the following keys:
#   :access_key_id     => AWS access key
#   :secret_access_key => AWS secret access key
#   :bucket            => S3 bucket for upload
#   :redirect_url      => URL to redirect to after successful upload
#
# These values can be defined top-level or scoped to the runtime
# environment (RACK_ENV) much like a Rails' database.yml file
$config = YAML.load(ERB.new(File.read('config.yml')).result)
$config = $config[ENV['RACK_ENV']] if $config.has_key? ENV['RACK_ENV']

get '/' do
  @params = params
  @policy = policy
  @bucket = $config[:bucket]
  @redirect_url = $config[:redirect_url]
  @encoded_policy = Base64.encode64(@policy).gsub("\n", '')
  @encoded_signature = Base64.encode64(OpenSSL::HMAC.digest(OpenSSL::Digest::Digest.new('sha1'), $config[:secret_access_key], @encoded_policy)).chomp
  @aws_access_key_id = $config[:access_key_id]
  erb :index
end

helpers do
  include Rack::Utils
  alias_method :h, :escape_html
end

def policy
  %Q{
{ "expiration": "#{1.day.from_now.strftime('%Y-%m-%dT%H:%M:%SZ')}",
  "conditions": [
    {"bucket": "#{$config[:bucket]}"},
    ["starts-with", "$key", ""],
    {"acl": "private"},
    {"success_action_redirect": "#{$config[:redirect_url]}"},
    ["starts-with", "$Content-Type", ""],
    ["content-length-range", 0, #{$config[:max_file_size]}]
  ]
}
  }
end
