#!/opt/puppetlabs/puppet/bin/ruby

require 'json'
require 'puppet'

def applications_create(*args)
  header_params = {}
  argstring = args[0].delete('\\')
  arg_hash = JSON.parse(argstring)

  # Remove task name from arguments - should contain all necessary parameters for URI
  arg_hash.delete('_task')
  operation_verb = 'Post'

  query_params, body_params, path_params = format_params(arg_hash)

  uri_string = "https://graph.windows.net//%{tenant_id}/applications" % path_params

  unless query_params.empty?
    uri_string = uri_string + '?' + to_query(query_params)
  end

  header_params['Content-Type'] = 'application/json' # first of #{parent_consumes}

  return nil unless authenticate(header_params) == true

  uri = URI(uri_string)
  Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == 'https') do |http|
    if operation_verb == 'Get'
      req = Net::HTTP::Get.new(uri)
    elsif operation_verb == 'Put'
      req = Net::HTTP::Put.new(uri)
    elsif operation_verb == 'Delete'
      req = Net::HTTP::Delete.new(uri)
    end

    header_params.each { |x, v| req[x] = v } unless header_params.empty?
    unless body_params.empty?
      req.body=body_params.to_json
    end

    Puppet.debug("URI is (#{operation_verb}) #{uri} headers are #{header_params}")
    response = http.request req # Net::HTTPResponse object
	Puppet.debug("Called (#{operation_verb}) endpoint at #{uri}")
    Puppet.debug("response code is #{response.code} and body is #{response.body}")
    response
  end
end

def to_query(hash)
  if hash
    return_value = hash.map { |x, v| "#{x}=#{v}" }.reduce { |x, v| "#{x}&#{v}" }
    if !return_value.nil?
      return return_value
    end
  end
  return ''
end

def op_param(name, inquery, paramalias, namesnake)
    operation_param = { :name => name, :location => inquery, :paramalias => paramalias, :namesnake => namesnake }
    return operation_param
end

def format_params(key_values)
  query_params = {}
  body_params = {}
  path_params = {}

  key_values.each do |key,value|
   if value.include? '{'
    key_values[key]=JSON.parse(value.gsub("\'","\""))
   end
  end

  op_params = [
      op_param('allowguestssignin', 'body', 'allow_guests_sign_in', 'allowguestssignin'),
      op_param('allowpassthroughusers', 'body', 'allow_passthrough_users', 'allowpassthroughusers'),
      op_param('api-version', 'query', 'api_version', 'api_version'),
      op_param('applogourl', 'body', 'app_logo_url', 'applogourl'),
      op_param('apppermissions', 'body', 'app_permissions', 'apppermissions'),
      op_param('approles', 'body', 'app_roles', 'approles'),
      op_param('availabletoothertenants', 'body', 'available_to_other_tenants', 'availabletoothertenants'),
      op_param('displayname', 'body', 'display_name', 'displayname'),
      op_param('errorurl', 'body', 'error_url', 'errorurl'),
      op_param('groupmembershipclaims', 'body', 'group_membership_claims', 'groupmembershipclaims'),
      op_param('homepage', 'body', 'homepage', 'homepage'),
      op_param('identifieruris', 'body', 'identifier_uris', 'identifieruris'),
      op_param('informationalurls', 'body', 'informational_urls', 'informationalurls'),
      op_param('isdeviceonlyauthsupported', 'body', 'is_device_only_auth_supported', 'isdeviceonlyauthsupported'),
      op_param('keycredentials', 'body', 'key_credentials', 'keycredentials'),
      op_param('knownclientapplications', 'body', 'known_client_applications', 'knownclientapplications'),
      op_param('logouturl', 'body', 'logout_url', 'logouturl'),
      op_param('oauth2allowimplicitflow', 'body', 'oauth2_allow_implicit_flow', 'oauth2allowimplicitflow'),
      op_param('oauth2allowurlpathmatching', 'body', 'oauth2_allow_url_path_matching', 'oauth2allowurlpathmatching'),
      op_param('oauth2permissions', 'body', 'oauth2_permissions', 'oauth2permissions'),
      op_param('oauth2requirepostresponse', 'body', 'oauth2_require_post_response', 'oauth2requirepostresponse'),
      op_param('optionalclaims', 'body', 'optional_claims', 'optionalclaims'),
      op_param('orgrestrictions', 'body', 'org_restrictions', 'orgrestrictions'),
      op_param('parameters', 'body', 'parameters', 'parameters'),
      op_param('passwordcredentials', 'body', 'password_credentials', 'passwordcredentials'),
      op_param('preauthorizedapplications', 'body', 'pre_authorized_applications', 'preauthorizedapplications'),
      op_param('publicclient', 'body', 'public_client', 'publicclient'),
      op_param('publisherdomain', 'body', 'publisher_domain', 'publisherdomain'),
      op_param('replyurls', 'body', 'reply_urls', 'replyurls'),
      op_param('requiredresourceaccess', 'body', 'required_resource_access', 'requiredresourceaccess'),
      op_param('samlmetadataurl', 'body', 'saml_metadata_url', 'samlmetadataurl'),
      op_param('signinaudience', 'body', 'sign_in_audience', 'signinaudience'),
      op_param('tenantID', 'path', 'tenant_id', 'tenant_id'),
      op_param('wwwhomepage', 'body', 'www_homepage', 'wwwhomepage'),
    ]
  op_params.each do |i|
    location = i[:location]
    name     = i[:name]
    paramalias = i[:paramalias]
    name_snake = i[:namesnake]
    if location == 'query'
      query_params[name] = key_values[name_snake] unless key_values[name_snake].nil?
      query_params[name] = ENV["azure__#{name_snake}"] unless ENV["<no value>_#{name_snake}"].nil?
    elsif location == 'body'
      body_params[name] = key_values[name_snake] unless key_values[name_snake].nil?
      body_params[name] = ENV["azure_#{name_snake}"] unless ENV["<no value>_#{name_snake}"].nil?
    else
      path_params[name_snake.to_sym] = key_values[name_snake] unless key_values[name_snake].nil?
      path_params[name_snake.to_sym] = ENV["azure__#{name_snake}"] unless ENV["<no value>_#{name_snake}"].nil?
    end
  end
  
  return query_params,body_params,path_params
end
def fetch_oauth2_token
  Puppet.debug('Getting oauth2 token')
  @client_id = ENV['azure_client_id']
  @client_secret = ENV['azure_client_secret']
  @tenant_id = ENV['azure_tenant_id']
  uri = URI("https://login.microsoftonline.com/#{@tenant_id}/oauth2/token")
  response = Net::HTTP.post_form(uri,
                                  'grant_type' => 'client_credentials',
                                  'client_id'     => @client_id,
                                  'client_secret' => @client_secret,
                                  'resource'      => 'https://management.azure.com/')

  Puppet.debug("get oauth2 token response code is #{response.code} and body is #{response.body}")
  success = response.is_a? Net::HTTPSuccess
  if success
    return JSON[response.body]["access_token"]
  else
    raise Puppet::Error, "Unable to get oauth2 token - response is #{response} and body is #{response.body}"
  end
end

def authenticate(header_params)
  token = fetch_oauth2_token
  if token
    header_params['Authorization'] = "Bearer #{token}"
    return true
  else
    return false
  end
end



def task
  # Get operation parameters from an input JSON
  params = STDIN.read
  result = applications_create(params)
  if result.is_a? Net::HTTPSuccess
    puts result.body
  else
    raise result.body
  end
rescue StandardError => e
  result = {}
  result[:_error] = {
    msg: e.message,
    kind: 'puppetlabs-azure_arm/error',
    details: { class: e.class.to_s },
  }
  puts result
  exit 1
end

task