require 'line/bot'
class SmallfoxController < ApplicationController
	protect_from_forgery with: :null_session


	def webhook
        # 查天氣
        reply_image = get_weather(received_text)

        # 有查到的話 後面的事情就不作了
        unless reply_image.nil?
          # 傳送訊息到 line
          response = reply_image_to_line(reply_image)

          # 回應 200
          head :ok

          return 
        end

        #紀錄頻道
        #Channel.create(channel_id: channel_id)//會重複
        Channel.find_or_create_by(channel_id: channel_id)

        #發送公告
        reply_text = send_announcement(channel_id, received_text)

		    #學說話
		    reply_text = learn(channel_id, received_text)

		    #關鍵字回覆
		    reply_text = keyword_reply(channel_id, received_text) if reply_text.nil?
		    
        # 設定回覆訊息
        #reply_text = keyword_reply(received_text)
      
        #推齊
        reply_text = echo2(channel_id, received_text) if reply_text.nil?

        #紀錄對話
        save_to_received(channel_id, received_text)
        save_to_reply(channel_id, reply_text)

        # 傳送訊息到line
        response = reply_to_line(reply_text)

        # 回應 200
        head :ok
    end 

    #取得天氣
    def get_weather(received_text)
      return nil unless received_text.include? '天氣'
      #upload_to_imgur(get_weather_from_cwb)
      get_weather_from_cwb
    end

    #圖片位址
    def get_weather_from_cwb
      #uri = URI('https://www.cwb.gov.tw/V8/C/W/OBS_Radar.html?Tab=0')
      #response = Net::HTTP.get(uri)
      #start_index = response.index('/Data/radar/CV1_3600') 
      #end_index = response.index('.png"')
      "https://www.cwb.gov.tw/Data/radar/CV1_3600.png"# + response[start_index..end_index]
    end

    #上傳圖片到 imgur
    def upload_to_imgur(image_url)
      url = URI("https://api.imgur.com/3/image")
      http = Net::HTTP.new(url.host, url.port)
      http.use_ssl = true
      request = Net::HTTP::Post.new(url)
      request["authorization"] = 'Client-ID 95ea7b33038df8b'
      request.set_form_data({"image" => image_url})
      response = http.request(request)
      json = JSON.parse(response.read_body)
      begin
        json['data']['link'].gsub("https:","https:")
      rescue
        nil
      end
    end

   # 傳送圖片到 line
    def reply_image_to_line(reply_image)
      return nil if reply_image.nil?
    
      # 取得 reply token
      reply_token = params['events'][0]['replyToken']
    
      # 設定回覆訊息
      message = {
        type: "image",
        originalContentUrl: reply_image,
        previewImageUrl: reply_image
      }

      # 傳送訊息
      line.reply_message(reply_token, message)
    end

    # 頻道 ID
    def channel_id
    	source = params['events'][0]['source']
    	source['groupId'] || source['roomId'] || source['userId']
    end

    # 儲存對話
    def save_to_received(channel_id, received_text)
    	return if received_text.nil?
    	Received.create(channel_id: channel_id, text: received_text)
    end

    # 儲存回應
    def save_to_reply(channel_id, reply_text)
        return if reply_text.nil?
        Reply.create(channel_id: channel_id, text: reply_text)
    end

    #推齊
    def echo2(channel_id, received_text)
        # 如果在 channel_id 最近沒人講過 received_text，卡米狗就不回應
        recent_received_texts = Received.where(channel_id: channel_id).last(5)&.pluck(:text)
        return nil unless received_text.in? recent_received_texts
    
        # 如果在 channel_id 卡米狗上一句回應是 received_text，卡米狗就不回應
        last_reply_text = Reply.where(channel_id: channel_id).last&.text
        return nil if last_reply_text == received_text

        received_text
    end

    #取得對方的話
    def received_text
    	message = params['events'][0]['message']
    	message['text'] unless message.nil?
    end

    #學說話
    def learn(channel_id, received_text)
    	#如果開頭不是 小狐學說話; 就跳出
    	return nil unless received_text[0..5] == '小狐學說話;'
    	received_text = received_text[6..-1]
        semicolon_index = received_text.index(';')
        
        # 找不到分號就跳出
        return nil if semicolon_index.nil?
        keyword = received_text[0..semicolon_index-1]
        message = received_text[semicolon_index+1..-1]

        KeywordMapping.create(channel_id: channel_id, keyword: keyword, message: message)
    end

    #關鍵字回覆
    def keyword_reply(channel_id, received_text)
    	#--------------分隔線--------------------
    	#學習紀錄表
    	#keyword_mapping = {
    	#	'QQ' => '神曲支援：https://www.youtube.com/watch?v=T0LfHEwEXXw&feature=youtu.be&t=1m13s',
    	#	'我難過' => '神曲支援：https://www.youtube.com/watch?v=T0LfHEwEXXw&feature=youtu.be&t=1m13s'
    	#}
    	#查表
    	#keyword_mapping[received_text]  
    	#如果 &. 的前面是 nil，那他就不會做後面的事，直接傳回 nil
    	message = KeywordMapping.where(channel_id: channel_id, keyword: received_text).last&.message  	
    	return message unless message.nil?
    	KeywordMapping.where(keyword: received_text).last&.message
    end

    #傳送訊息到line
    def reply_to_line(reply_text)
        return nil if reply_text.nil?

    	# 取得 reply token
    	reply_token = params['events'][0]['replyToken']
    	#p "======這裡是 reply_token ======"
        #p reply_token 
        #p response
        #p response.body
        #p "============"

        # 設定回覆訊息
       message = {
       	type: 'text',
       	text: reply_text
       }

        # 傳送訊息
        line.reply_message(reply_token, message)
    end

    # 發送公告
    def send_announcement(channel_id, received_text)
      return nil unless received_text[0..5] == '/發送公告;'
      text = received_text[6..-1]
      Channel.all.each do |channel|
        push_to_line(channel.channel_id, text) 
      end
    end

    # 傳送訊息到 line
    def push_to_line(channel_id, text)
      return nil if channel_id.nil? or text.nil?
      puts channel_id, text
    
      # 設定回覆訊息
      message = {
        type: 'text',
        text: text
      } 

      # 傳送訊息
      line.push_message(channel_id, message)
    end

    # Line Bot API 物件初始化
    def line
    #如果 @line 有值的話，直接回傳 @line，沒有值的話才作 Line::Bot::Client.new 並保存到 @line。
        @line ||= Line::Bot::Client.new { |config|
            config.channel_secret = '51e8b8e9ca81ab08cc54a66188e35dfe'
            config.channel_token = 'JzQkXBobsKSS7CQkHV15leq0JIdROKElvtS8dzYYI/wINUGoyCTidxc5Yd8q8CbsTUlJSA3Pe/YxERmD/68w9bNuM5CyCBo4gunoiRLT07h5fBlwYxtarNfpvRsz43TxCUYuN//F2JN+DuO4Ht3SWQdB04t89/1O/w1cDnyilFU='
        }
    end
	


	def eat
		render plain: "吃冰"
	end

	def request_headers
		render plain: request.headers.to_h.reject{ |key, value|
			key.include? '.'
	}.map{ |key, value|
			"#{key}: #{value}"
		}.sort.join("\n")
	end

	def response_headers
		response.headers['7878'] = 'QQ'
		render plain: response.headers.to_h.map{ |key, value|
			"#{key}: #{value}"
		}.sort.join("\n")
	end

	def request_body
		render plain: request.body
	end

	def show_response_body
		puts "===這是設定前的response.body:#{response.body}==="
    	render plain: "虎哇花哈哈哈"
    	puts "===這是設定後的response.body:#{response.body}==="
    end

    def sent_request
    	require 'net/http'
        uri = URI('http://localhost:3000/smallfox/eat')
    	http = Net::HTTP.new(uri.host, uri.port)
    	http_request = Net::HTTP::Get.new(uri)
    	http_response = http.request(http_request)

    	render plain: JSON.pretty_generate({
      		request_class: request.class,
      		response_class: response.class,
      		http_request_class: http_request.class,
      		http_response_class: http_response.class
    	})
    end

    def translate_to_korean(message)
    	"#{message}油~"
  	end
    
end