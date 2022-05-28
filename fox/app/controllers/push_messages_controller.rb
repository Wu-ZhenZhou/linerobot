require 'line/bot'
class PushMessagesController < ApplicationController
  before_action :authenticate_user!

  # GET /push_messages/new
  def new
  end

  # POST /push_messages
  def create
    text = params[:text]
    Channel.all.each do |channel|
      push_to_line(channel.channel_id, text)
    end
    redirect_to '/push_messages/new'
  end

  # 傳送訊息到 line
  def push_to_line(channel_id, text)
    return nil if channel_id.nil? or text.nil?
    
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
end