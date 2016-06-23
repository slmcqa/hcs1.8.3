require 'curl'
require 'json'

class Engine
  @@URL_OAUTH_DIRECT = "https://login.yahoo.com/WSLogin/V1/get_auth_token"
  @@URL_OAUTH_ACCESS_TOKEN = 'https://api.login.yahoo.com/oauth/v2/get_token'
  @@URL_YM_SESSION = 'http://developer.messenger.yahooapis.com/v1/session'
  @@URL_YM_PRESENCE = 'http://developer.messenger.yahooapis.com/v1/presence';
  @@URL_YM_CONTACT = 'http://developer.messenger.yahooapis.com/v1/contacts';
  @@URL_YM_MESSAGE = 'http://developer.messenger.yahooapis.com/v1/message/yahoo/{{USER}}';
  @@URL_YM_NOTIFICATION = 'http://developer.messenger.yahooapis.com/v1/notifications';
  @@URL_YM_NOTIFICATION_LONG = 'http://{{NOTIFICATION_SERVER}}/v1/pushchannel/{{USER}}';
  @@URL_YM_BUDDYREQUEST = 'http://developer.messenger.yahooapis.com/v1/buddyrequest/yahoo/{{USER}}';
  @@URL_YM_GROUP = 'http://developer.messenger.yahooapis.com/v1/group/{{GROUP}}/contact/yahoo/{{USER}}';

  @_oauth = nil
  @_token = Hash.new
  @_ym = Hash.new
  @_config = nil
  @_error = nil

  @includeheader = false;
  @debug = false;

  @consumer_key = nil
  @secret_key = nil
  @username = nil
  @password = nil


  def initialize(consumer_key = '', secret_key = '', username = '', password = '')
    @consumer_key = consumer_key
    @secret_key = secret_key
    @username = username
    @password = password
    @_ym = Hash.new
    @_error = nil
  end

  def fetch_request_token
    url = @@URL_OAUTH_DIRECT;
    url = url + "?&login=" + @username;
    url = url + "&passwd=" + @password;
    url = url + "&oauth_consumer_key=" + @consumer_key;
    #puts url
    c = Curl::Easy.perform(url)
    rs = c.body_str;

    ##puts rs
    return false if rs.index('RequestToken').nil?

    request_token = rs.gsub('RequestToken=', '').strip
    @_token = Hash.new
    @_token['request'] = request_token
    ##puts @_token['request']
    #@_token['request'] = "work"
    return true;
  end

  def fetch_access_token
    #prepare url
    #puts "=========" + "accessToken fetch"
    #sleep 2
    url = @@URL_OAUTH_ACCESS_TOKEN;
    url = url + '?oauth_consumer_key=' + @consumer_key
    url = url + '&oauth_nonce=' + (Random.rand(50)).to_s + "kaushik" + (Random.rand(100)).to_s
    url = url + '&oauth_signature=' + @secret_key + '%26'
    url = url + '&oauth_signature_method=PLAINTEXT'
    url = url + '&oauth_timestamp=' + Time.now.to_i.to_s
    url = url + '&oauth_token=' + @_token['request']
    url = url + '&oauth_version=1.0'
    #puts url
    #sleep 3
    c = Curl::Easy.perform(url)
    rs = c.body_str

    #sleep 3
    ##puts "--\\n" + rs
    if rs.index('oauth_token') == nil
      @_error = rs
      return false
    end

    access_token = Hash.new
    #parse access token
    tmp = rs.split('&')
    tmp.each do |row|
      col = row.split('=')
      access_token[col[0]] = col[1]
    end

    @_token['access'] = access_token
    #puts "----------\n"
    #puts @_token.inspect

    return true;
  end

  def signon(status = '', state = 0)
    #prepare url
    #puts "sign on-------------------------------------------"
    #sleep 5
    #puts @_token['access'].inspect
    #puts "---------------------------------------------------------------------------------------------"
    url = @@URL_YM_SESSION
    url = url +  '?oauth_consumer_key=' + @consumer_key
    url = url +  '&oauth_nonce=' + (Random.rand(50)).to_s + 'kaushik' + (Random.rand(100)).to_s
    url = url +  '&oauth_signature=' + @secret_key +  '%26' +  @_token['access']['oauth_token_secret']
    url = url +  '&oauth_signature_method=PLAINTEXT'
    url = url +  '&oauth_timestamp=' + Time.now.to_i.to_s

    url = url +  '&oauth_token=' + @_token['access']['oauth_token']
    url = url +  '&oauth_version=1.0'
    url = url +  '&notifyServerToken=1'

    #sleep 2
    #additional header
    header = Array.new
    header.push 'Content-type: application/json; charset=utf-8'
    postdata = '{"presenceState" : ' +  state.to_s + ', "presenceMessage" : "' +  status + '"}'
    #what is this for
    @includeheader = true
    rs = Curl::Easy.http_post(url, postdata)
    rs.headers = header
    #rs.verbose = true
    per = rs.perform
    header = rs.header_str

    body = rs.body_str
    notifytoken = ''
    m = header.scan(/set-cookie: IM=(.+?); expires/)
    #puts "length-----------"  + m.length.to_s
    if (m.length >0 )
      notifytoken = m[0][0]
    end
    #puts notifytoken

    return false if body.index('sessionId').nil?

    js = JSON.parse(body)
    js['notifytoken'] = notifytoken
    @_ym['signon'] = js
    return true
  end

  def fetch_contact_list
    #prepare url
    #puts "----------------------------------fetch contact list-------------------------------------------------"
    #sleep 3
    url = @@URL_YM_CONTACT
    url = url + '?oauth_consumer_key=' + @consumer_key
    url = url + '&oauth_nonce=' + (Random.rand(50)).to_s + 'kaushik' + (Random.rand(100)).to_s
    url = url + '&oauth_signature=' + @secret_key + '%26' + @_token['access']['oauth_token_secret']
    url = url + '&oauth_signature_method=PLAINTEXT'
    url = url + '&oauth_timestamp=' + Time.now.to_i.to_s
    url = url + '&oauth_token=' + @_token['access']['oauth_token']
    url = url + '&oauth_version=1.0'
    url = url + '&sid=' + @_ym['signon']['sessionId']
    url = url + '&fields=%2Bpresence'
    url = url + '&fields=%2Bgroups'

    #puts "----url---->" + url
    #additional header
    header = Array.new
    header.push 'Content-type: application/json; charset=utf-8'
    rs = Curl::Easy.http_get(url)
    rs.headers = header
    rs.perform

    #sleep 5

    body = rs.body_str
    #puts "body--------------------------->" + body
    #$rs = $this->curl($url, 'get', $header)

    return false if body.index('contact').nil?

    js = JSON.parse(body)

    #puts js.inspect
    return js['contacts']
  end

  def filter_online_contacts(contactlist)
    #puts "---------------------------------------------------filter-----------------------------------------------"
    #puts contactlist.inspect
    myJson = ''
    clist = contactlist
    clist.each do |con|
      contact = con['contact']
      cid = contact['id']
      presence = Integer(contact['presence']['presenceState'])
      #puts "-------------------------------------"
      if presence != -1
        #puts "Online"
        myJson = myJson + contact.to_s.gsub('=>', ':').strip + ", "
      end
      #puts cid.inspect
      #puts presence.inspect
      #puts "-------------------------------------"
    end

    myJson =  "[" + myJson[0..-3] + "]"
    #puts "*****************************************************"
    online_contacts = JSON.parse(myJson)
    #puts online_contacts
    #puts "*****************************************************"

    return online_contacts
  end

  def send_message(user, message)
    #puts "--------------------------------------------send message--------------"
    #prepare url
    url = @@URL_YM_MESSAGE
    url = url +  '?sid=' +  @_ym['signon']['sessionId']
    url = url +  '&oauth_consumer_key=' +  @consumer_key
    url = url +  '&oauth_nonce=' +  (Random.rand(50)).to_s + 'kaushik' + (Random.rand(100)).to_s
    url = url +  '&oauth_signature=' +  @secret_key +  '%26' +  @_token['access']['oauth_token_secret']
    url = url +  '&oauth_signature_method=PLAINTEXT'
    url = url +  '&oauth_timestamp=' + Time.now.to_i.to_s
    url = url +  '&oauth_token=' +  @_token['access']['oauth_token']
    url = url +  '&oauth_version=1.0'

    url = url.gsub('{{USER}}', user)
    #puts url + '<------\n'

    #additional header
    #puts "-----------------------------------------------beforesending-------------------------------"
    header = Array.new
    header.push 'Content-Type: application/json;charset=utf-8'
    postdata = '{"message" : "' + message + '"}'

    rs = Curl::Easy.http_post(url, postdata)
    #rs.verbose = true
    rs.headers = header
    #rs.verbose = true
    per = rs.perform
    return true
  end

  def signoff
    #prepare url
    #puts "signing off--------------------------------"
    url = @@URL_YM_SESSION;
    url = url + '?oauth_consumer_key=' + @consumer_key
    url = url + '&oauth_nonce=' + (Random.rand(50)).to_s + 'kaushik' + (Random.rand(100)).to_s
    url = url + '&oauth_signature=' + @secret_key + '%26' + @_token['access']['oauth_token_secret']
    url = url + '&oauth_signature_method=PLAINTEXT'
    url = url + '&oauth_timestamp=' + Time.now.to_i.to_s
    url = url + '&oauth_token=' + @_token['access']['oauth_token']
    url = url + '&oauth_version=1.0'
    url = url + '&sid=' +  @_ym['signon']['sessionId']

    #additional header
    header = Array.new
    header.push 'Content-type: application/json; charset=utf-8'
    rs = Curl::Easy.http_delete(url)
    #rs.verbose = true
    rs.headers = header
    #rs = $this->curl($url, 'delete', $header);
    rs.perform

    return true
  end

  def add_contact(user, group = 'Friends', message = 'You have been added')
    #prepare url
    #puts "-----------------------------adding contact--------------------"
    url = @@URL_YM_GROUP
    url = url + '?oauth_consumer_key=' + @consumer_key
    url = url + '&oauth_nonce=' + (Random.rand(50)).to_s + (Random.rand(100)).to_s
    url = url + '&oauth_signature=' + @secret_key + '%26' + @_token['access']['oauth_token_secret'];
    url = url + '&oauth_signature_method=PLAINTEXT'
    url = url + '&oauth_timestamp='+ Time.now.to_i.to_s
    url = url + '&oauth_token=' + @_token['access']['oauth_token']
    url = url + '&oauth_version=1.0'
    url = url + '&sid=' + @_ym['signon']['sessionId']
    url = url.gsub('{{USER}}', user)
    url = url.gsub('{{GROUP}}', group)
    ##puts url
    #additional header
    header = Array.new
    header.push 'Content-type: application/json; charset=utf-8'
    postdata = '{"message" : "' + message + '"}'
    rs = Curl::Easy.http_put(url, postdata)
    rs.put_data = postdata
    rs.verbose = true
    rs.headers = header
    #puts "---------------------------------------------"
    #puts rs.headers.inspect
    #puts rs.inspect
    ##puts rs.put_data.inspect

    rs.perform
    #puts "--------------------------------------------------8888-----------------"
    #puts rs.body_str.inspect
    #puts rs.header_str.inspect
    #puts "-----------------------------------------------over"
    return true
  end

  def respond_contact(user, accept = true, message = 'Welcome')
    #prepare url
    #puts "------------------------------------responce to contact-------------------------------------"
    url = @@URL_YM_BUDDYREQUEST
    url = url + '?oauth_consumer_key=' + @consumer_key
    url = url + '&oauth_nonce=' + (Random.rand(50)).to_s + (Random.rand(100)).to_s
    url = url + '&oauth_signature=' + @secret_key + '%26' + @_token['access']['oauth_token_secret']
    url = url + '&oauth_signature_method=PLAINTEXT'
    url = url + '&oauth_timestamp=' + Time.now.to_i.to_s
    url = url + '&oauth_token=' + @_token['access']['oauth_token']
    url = url + '&oauth_version=1.0'
    url = url + '&sid=' + @_ym['signon']['sessionId']
    url = url.gsub('{{USER}}', user)

    ##puts url
    #additional header
    header = Array.new
    header.push 'Content-type: application/json; charset=utf-8'
    postdata = '{"authReason" : "' +  message + '"}'
    rs = Curl::Easy.http_post(url,postdata)
    rs.verbose = true
    rs.headers = header
    #puts rs.headers

    rs.perform
    #$rs = $this->curl($url, strtolower($method), $header, $postdata);
    body = rs.body_str
    headerx = rs.header_str

    return true
  end

  def fetch_notification(seq = 0)
    #prepare url
    #puts "------------------------------fetch notification----------------------------------------------"
    #sleep 2
    url = @@URL_YM_NOTIFICATION;
    url = url +  '?oauth_consumer_key=' + @consumer_key
    url = url +  '&oauth_nonce=' + (Random.rand(50)).to_s + (Random.rand(100)).to_s
    url = url +  '&oauth_signature=' + @secret_key + '%26' + @_token['access']['oauth_token_secret']
    url = url +  '&oauth_signature_method=PLAINTEXT'
    url = url +  '&oauth_timestamp=' + Time.now.to_i.to_s
    url = url +  '&oauth_token=' + @_token['access']['oauth_token']
    url = url +  '&oauth_version=1.0'
    url = url +  '&sid=' + @_ym['signon']['sessionId']
    url = url +  '&seq=' + seq.to_s
    url = url +  '&count=100'

    #additional header
    header = Array.new
    header.push 'Content-type: application/json; charset=utf-8'
    rs = Curl::Easy.http_get(url)
    rs.verbose = true
    rs.headers = header
    rs.perform

    js = JSON.parse(rs.body_str)

    #I have fetched notifications, now for all add buddy requests i am going to accept the request
    res = js['responses']
    res.each do |notif|
      if notif.has_key?("buddyAuthorize")
        #puts notif.inspect
        #add the buddies
        cid = notif['buddyAuthorize']['sender']
        #puts "addding to the contact list----------------------------------" + cid
        respond_contact cid
      end
    end
  end

end
