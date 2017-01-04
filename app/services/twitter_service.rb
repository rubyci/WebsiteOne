module TwitterService
  def self.tweet_hangout_notification(hangout)
    return unless Settings.features.twitter.notifications.enabled
    case hangout.category
      when 'Scrum'
        tweet("#Scrum meeting with our #distributedteam is live on #{hangout.hangout_url} Join in and learn about our #opensource #projects!")
      when 'PairProgramming'
        tweet("Pair programming on #{hangout.project ? hangout.project.title : hangout.title} #{hangout.hangout_url} #pairwithme, #distributedteam")
      else
        Rails.logger.error "''#{hangout.category}'' is not a recognized event category for Twitter notifications. Must be one of: 'Scrum', 'PairProgramming'"
    end
  end

  def self.tweet_yt_link(hangout)
    return if hangout.youtube_tweet_sent || !Settings.features.twitter.notifications.enabled
    if valid_recording(hangout.yt_video_id)
      host = hangout.broadcaster ? hangout.broadcaster.split[0] : 'Host'
      response = case hangout.category
        when 'Scrum'
          tweet("#{host} just hosted an online #scrum Missed it? Catch the recording at youtu.be/#{hangout.yt_video_id} #CodeForGood #opensource")
        when 'PairProgramming'
          tweet("#{host} just finished #PairProgramming on #{hangout.project ? hangout.project.title : hangout.title} You can catch the recording at youtu.be/#{hangout.yt_video_id} #CodeForGood #pairwithme")
        end
      hangout.update(youtube_tweet_sent: true) if check_response(response)
    end
  end

  private

  def self.tweet(message)
    if Settings.features.twitter.notifications.enabled == true
      check_response twitter_client.update(message[0..139])
    else
      false
    end
  end

  def self.twitter_client
    @twitter_client ||= Twitter::REST::Client.new do |config|
      config.consumer_key        = Settings.twitter.consumer_key
      config.consumer_secret     = Settings.twitter.consumer_secret
      config.access_token        = Settings.twitter.access_token
      config.access_token_secret = Settings.twitter.access_token_secret
    end
  end

  def self.check_response(response)
    if response.kind_of?(Twitter::Tweet)
      true
    else
      Rails.logger.error "Twitterable: Could not update twitter status"
      false
    end
  end

  def self.valid_recording(code)
    if code == ''
      return false
    else
      uri = URI.parse("http://gdata.youtube.com/feeds/api/videos/#{code}")
      Net::HTTP.get(uri)
      video = Yt::Video.new id: code
      return true if video && video.duration > 2
    end
    return false
  end

end
